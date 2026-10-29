// OpenCode 2.0.32 Effect plugin. execute.before denies via native Tool.Error.
import { Plugin } from "@opencode/plugin/effect"
// The host exposes @opencode/plugin and effect, not @opencode/schema.
// This public re-export resolves to the host's exact native Tool.Error class.
import { Error as ToolError } from "@opencode/plugin/promise/tool"
import { Effect, Stream } from "effect"
import { execFile } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"

type Result = { decision?: string; reason?: string; context?: string; action?: string; claimed?: boolean; valid?: boolean;
  loop?: { id: string; state: string; request_id?: string; owner_epoch?: number } }
function invoke(event: string, payload: object, entry?: string, timeoutMs = 120_000): Promise<Result> {
  return new Promise((resolve) => {
    const path = entry || process.env.COMMON_HOOK_ENTRY || join(homedir(), ".agents/hooks/common_hook.py")
    const child = execFile("python3", [path, "--harness", "opencode", "--event", event], {
      encoding: "utf8", timeout: timeoutMs, maxBuffer: 1024 * 1024,
    }, (error, stdout) => {
      try {
        if (error) throw error
        const result = JSON.parse(stdout)
        if (!result || typeof result !== "object" || Array.isArray(result)) throw new Error("invalid hook result")
        resolve(result)
      } catch {
        resolve(event === "execute.before"
          ? { decision: "deny", reason: "Common hook could not evaluate this tool call." }
          : { context: "Common hook could not finish this observation." })
      }
    })
    child.stdin?.on("error", () => {})
    child.stdin?.end(JSON.stringify(payload))
  })
}

export function createPlugin(options: { entry?: string; id?: string; timeoutMs?: number } = {}) {
  // Project idle gates may need a longer audit; other events stay within 120s.
  const timeoutMs = options.timeoutMs ?? 120_000
  if (!Number.isFinite(timeoutMs) || timeoutMs <= 0 || timeoutMs > 600_000) {
    throw new Error("Hook timeoutMs must be greater than zero and at most 600000")
  }
  const id = options.id || "common-hooks"
  return Plugin.define({
    id,
    effect: Effect.fn(function* (ctx) {
      const initialized = new Set<string>()
      const epochs = new Map<string, number>()
      const finishes = new Map<string, string>()
      const productLimits = new Set<string>()
      const boundaries = new Map<string, number>()
      const pending = new Map<string, { request: string; epoch: number; loop: Result["loop"] }>()
      const sessionContexts = new Map<string, string>()
      const deferredContexts = new Map<string, string>()
      const stops = new Map<string, string>()
      // Stop results otherwise reach only the journal; the next dispatch carries the latest one.
      const keepStop = (sessionID: string, result: Result) => {
        if (result.action === "allow") {
          const passed = (result.context || "").split("\n").flatMap((line) => line.endsWith(": PASS") ? [line.slice(0, -": PASS".length)] : [])
          // A clean stop runs no check unless the tree changed, and the hooks
          // print no PASS line yet, so a stop without one carries no result.
          if (passed.length) stops.set(sessionID, `Post-work checks after the previous turn (${id}): all PASS (${passed.join(", ")})`)
        } else {
          stops.set(sessionID, `Post-work checks after the previous turn (${id}) reported:\n` + (result.context || result.reason || "No details were returned."))
        }
      }
      const epoch = (id: string) => epochs.get(id) || 0
      const call = Effect.fn(function* (name: string, event: { sessionID: string } & object) {
        const session = yield* ctx.session.get({ sessionID: event.sessionID as any })
        return yield* Effect.promise(() => invoke(name, { ...event, host_pid: process.pid, cwd: session.location.directory }, options.entry, ["session.idle", "session.execution.succeeded"].includes(name) ? timeoutMs : Math.min(timeoutMs, 120_000)))
      })
      yield* ctx.session.hook("prompt", Effect.fn(function* (event) {
        const own = event.metadata?.commonLoopRequest
        if (typeof own === "string") {
          const request = pending.get(event.sessionID)
          if (request && (request.request !== own || request.epoch !== epoch(event.sessionID))) {
            return yield* Effect.fail(new Error("Development loop continuation was revoked by new input."))
          }
          // Global/project plugins share one durable coordinator. A non-sender
          // admission callback validates the claimed request without reclaiming.
          const validated = yield* call("LoopValidateDelivery", { sessionID: event.sessionID,
            request_id: own, loop_id: event.metadata?.commonLoopID, owner_epoch: event.metadata?.commonLoopOwnerEpoch })
          if (!validated.valid) return yield* Effect.fail(new Error("Development loop continuation is no longer authorized."))
          return
        }
        // Admission hook runs before inbox enqueue. Advance synchronously so an
        // in-flight check/claim cannot race a new human prompt into a second turn.
        epochs.set(event.sessionID, epoch(event.sessionID) + 1)
        const request = pending.get(event.sessionID)
        if (request) {
          pending.delete(event.sessionID)
          yield* call("LoopDeliveryAborted", { sessionID: event.sessionID, request_id: request.request,
            loop_id: request.loop?.id, owner_epoch: request.loop?.owner_epoch })
        }
        yield* call("UserPromptSubmit", { sessionID: event.sessionID, prompt: event.prompt.text,
          prompt_event_id: event.messageID, stop_reason: "abort" })
      }))
      yield* ctx.session.hook("context", Effect.fn(function* (event) {
        const texts = (event.messages || []).flatMap((message) => {
          if (message.role !== "assistant") return []
          const content = message.content
          return typeof content === "string" ? [content] : (content || []).flatMap((part) => part.type === "text" ? [part.text] : [])
        })
        if (texts.some((text) => text.startsWith("CRITICAL - MAXIMUM STEPS REACHED\n") && text.includes("Tools are disabled until next user input."))) productLimits.add(event.sessionID)
        const first = !initialized.has(event.sessionID)
        // The host reads event.system when this hook first suspends, so the texts
        // already held in memory go in before the python call; that call's fresh
        // result waits for the next dispatch instead.
        const session = sessionContexts.get(event.sessionID)
        const deferred = deferredContexts.get(event.sessionID)
        const stop = stops.get(event.sessionID)
        deferredContexts.delete(event.sessionID)
        stops.delete(event.sessionID)
        for (const text of [session, deferred, stop]) {
          if (text) event.system.push({ type: "text", text })
        }
        const result = yield* call(first ? "SessionStart" : "context", { ...event, context_only: !first })
        initialized.add(event.sessionID)
        if (first) {
          if (result.context) sessionContexts.set(event.sessionID, result.context)
        } else if (result.context && !session?.includes(result.context)) {
          deferredContexts.set(event.sessionID, result.context)
        }
      }))
      yield* ctx.session.hook("compaction", Effect.fn(function* (event) {
        yield* call("compaction", event)
      }))
      yield* ctx.tool.hook("execute.before", Effect.fn(function* (event) {
        const result = yield* call("execute.before", event)
        if (result.decision === "deny") return yield* Effect.fail(new ToolError({ message: result.reason || "Common policy denied this tool call." }))
      }))
      yield* ctx.tool.hook("execute.after", Effect.fn(function* (event) {
        const result = yield* call("execute.after", event)
        if (!result.context) return
        if (event.status === "completed") {
          const content = event.result.content
          event.result = { ...event.result, content: [
            ...(typeof content === "string" ? [{ type: "text" as const, text: content }] : content || []),
            { type: "text", text: result.context },
          ] }
        } else {
          console.error(result.context)
        }
      }))
      // V2 exposes a durable positive execution boundary. An idle status is
      // observation only; failed/interrupted/new-input events revoke delivery.
      yield* ctx.event.subscribe().pipe(Stream.runForEach(Effect.fn(function* (event) {
        const sessionID = (event.data as { sessionID?: string }).sessionID
        if (!sessionID) return
        const seq = event.durable?.seq
        const lifecycle = event.type.startsWith("session.execution.") || event.type === "session.step.ended"
        if (lifecycle) {
          if (!Number.isSafeInteger(seq) || typeof event.id !== "string" || !event.id.startsWith("evt_")) return
          if (seq <= (boundaries.get(sessionID) ?? -1)) return
          boundaries.set(sessionID, seq)
        }
        if (event.type === "session.execution.started") {
          epochs.set(sessionID, epoch(sessionID) + 1)
          finishes.delete(sessionID)
          productLimits.delete(sessionID)
          return
        }
        if (event.type === "session.step.ended") {
          finishes.set(sessionID, event.data.finish)
          return
        }
        if (event.type === "session.execution.interrupted" || event.type === "session.execution.failed") {
          epochs.set(sessionID, epoch(sessionID) + 1)
          const request = pending.get(sessionID)
          if (request) {
            pending.delete(sessionID)
            yield* call("LoopDeliveryAborted", { sessionID, request_id: request.request,
              loop_id: request.loop?.id, owner_epoch: request.loop?.owner_epoch })
          }
          yield* call(event.type, { sessionID, stop_reason: event.type.endsWith("failed") ? "error" : "abort" })
          return
        }
        if (event.type === "session.status" && event.data.status.type === "idle") {
          const result = yield* call("session.idle", { sessionID, stop_reason: "unknown" })
          if (result.context) console.error(result.context)
          keepStop(sessionID, result)
          return
        }
        if (event.type !== "session.execution.succeeded") return
        const observedEpoch = epoch(sessionID)
        // Keep the subscriber available to process aborts during command checks.
        yield* Effect.fn(function* () {
          const stopReason = productLimits.has(sessionID) ? "abort" : finishes.get(sessionID) === "stop" ? "natural" : "unknown"
          const result = yield* call("session.execution.succeeded", { sessionID, stop_reason: stopReason,
            stop_event_id: event.id, stop_event_seq: seq })
          const request = result.loop?.request_id
          if (stopReason !== "natural" || result.action !== "continue" || result.loop?.state !== "running" || !request) {
            if (result.context) console.error(result.context)
            keepStop(sessionID, result)
            return
          }
          const delivery = { sessionID, request_id: request, loop_id: result.loop.id, owner_epoch: result.loop.owner_epoch }
          if (observedEpoch !== epoch(sessionID)) {
            yield* call("LoopDeliveryAborted", delivery)
            return
          }
          const claimed = yield* call("LoopClaimDelivery", delivery)
          if (!claimed.claimed) return
          if (observedEpoch !== epoch(sessionID)) {
            yield* call("LoopDeliveryAborted", delivery)
            return
          }
          pending.set(sessionID, { request, epoch: observedEpoch, loop: result.loop })
          yield* ctx.session.prompt({ sessionID: sessionID as any, text: result.context || result.reason || "Continue the next ordered development task.",
            metadata: { commonLoopRequest: request, commonLoopID: result.loop.id, commonLoopOwnerEpoch: result.loop.owner_epoch } }).pipe(
            Effect.flatMap(() => call("LoopDeliveryAccepted", delivery)),
            Effect.catch(() => call("LoopDeliveryUnknown", delivery)),
          )
          if (pending.get(sessionID)?.request === request) pending.delete(sessionID)
        })().pipe(Effect.forkScoped({ startImmediately: true }))
      })), Effect.forkScoped({ startImmediately: true }))
    }),
  })
}

export default createPlugin()
