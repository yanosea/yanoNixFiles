// Native OpenClaw 2026.9.5 hooks. Only explicit interactive loops may revise.
import { execFile } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"

type Context = { sessionId?: string; sessionKey?: string; runId?: string; workspaceDir?: string; trigger?: string; inputProvenance?: { kind?: string } }
type HookResult = { block?: boolean; blockReason?: string; context?: string; report?: string; action?: string; reason?: string }
type API = {
  on: (event: string, callback: (event: any, ctx: Context) => Promise<any>, options?: { timeoutMs: number }) => void
  logger: { warn: (message: string) => void }
}

function invoke(event: string, payload: object): Promise<HookResult> {
  return new Promise((resolve) => {
    const path = process.env.COMMON_HOOK_ENTRY || join(homedir(), ".agents/hooks/common_hook.py")
    // OpenClaw puts /usr/bin first in PATH at startup, and macOS python3 there is too old
    const python = process.env.COMMON_HOOK_PYTHON_DIR ? join(process.env.COMMON_HOOK_PYTHON_DIR, "python3") : "python3"
    const child = execFile(python, [path, "--harness", "openclaw", "--event", event], {
      encoding: "utf8", timeout: 120_000, maxBuffer: 1024 * 1024,
    }, (error, stdout) => {
      try {
        if (error) throw error
        const result = JSON.parse(stdout)
        if (!result || typeof result !== "object" || Array.isArray(result)) throw new Error("invalid hook result")
        resolve(result)
      } catch {
        resolve(event === "before_tool_call"
          ? { block: true, blockReason: "Common hook could not evaluate this tool call." }
          : { report: "Common hook could not finish this observation." })
      }
    })
    child.stdin?.on("error", () => {})
    child.stdin?.end(JSON.stringify(payload))
  })
}

export default {
  id: "common-hooks",
  name: "Common hooks",
  description: "Shared local policy checks through native lifecycle hooks",
  register(api: API) {
    // Tool contexts have no workspaceDir in this release. Remember the host's
    // authoritative agent context; never substitute the gateway process cwd.
    const locations = new Map<string, Context>()
    const initialized = new Map<string, string | undefined>()
    const keys = (ctx: Context) => [ctx.runId && `run:${ctx.runId}`, ctx.sessionId && `session:${ctx.sessionId}`, ctx.sessionKey && `key:${ctx.sessionKey}`].filter((v): v is string => !!v)
    const payload = (event: object, ctx: Context) => {
      const known = keys(ctx).map((id) => locations.get(id)).find(Boolean)
      return {
        ...event, sessionId: ctx.sessionId || known?.sessionId || ctx.sessionKey,
        sessionKey: ctx.sessionKey || known?.sessionKey, runId: ctx.runId,
        workspaceDir: ctx.workspaceDir || known?.workspaceDir,
        // Never carry provenance from another run in the same session.
        origin: ctx.trigger === "cron" ? "cron" : ctx.trigger === "heartbeat" ? "heartbeat" :
          ctx.trigger === "user" && ctx.inputProvenance?.kind === "external_user" ? "interactive" : "unknown",
      }
    }
    const observe = async (eventName: string, event: object, ctx: Context) => {
      const input = payload(event, ctx)
      if (!input.workspaceDir) { api.logger.warn("Common hook has no authoritative workspace for this observation."); return }
      const output = await invoke(eventName, input)
      if (output.report) api.logger.warn(output.report)
    }
    api.on("before_prompt_build", async (event, ctx) => {
      if (!ctx.workspaceDir) { api.logger.warn("Common hook has no authoritative workspace."); return }
      for (const identity of keys(ctx)) {
        if (locations.size >= 768 && !locations.has(identity)) locations.delete(locations.keys().next().value!)
        locations.set(identity, { ...ctx })
      }
      const identity = ctx.sessionId || ctx.sessionKey
      const first = !!identity && !initialized.has(identity)
      const input = payload(event, ctx)
      const newUserRun = !!identity && !first && !!ctx.runId && initialized.get(identity) !== ctx.runId && input.origin === "interactive"
      if (identity) initialized.set(identity, ctx.runId)
      const output = await invoke(newUserRun ? "UserPromptSubmit" : "before_prompt_build", {
        ...input, context_only: !first && !newUserRun, prompt_event_id: ctx.runId,
      })
      return output.context ? { prependContext: output.context } : undefined
    }, { timeoutMs: 150_000 })
    api.on("before_tool_call", async (event, ctx) => {
      const input = payload(event, ctx)
      if (!input.workspaceDir) return { block: true, blockReason: "Common hook has no authoritative workspace for this tool call." }
      const output = await invoke("before_tool_call", input)
      return output.block ? { block: true, blockReason: output.blockReason } : undefined
    }, { timeoutMs: 150_000 })
    api.on("after_tool_call", (event, ctx) => observe("after_tool_call", event, ctx), { timeoutMs: 150_000 })
    api.on("before_agent_finalize", async (event, ctx) => {
      const input = payload(event, ctx)
      if (!input.workspaceDir || input.origin !== "interactive") return
      const output = await invoke("before_agent_finalize", input)
      // Core authorizes revision only for a running, explicitly started loop.
      if (output.action === "revise") return { action: "revise", reason: output.reason }
      if (output.report) api.logger.warn(output.report)
    }, { timeoutMs: 150_000 })
    api.on("agent_end", (event, ctx) => observe("agent_end", event, ctx), { timeoutMs: 150_000 })
    api.on("before_compaction", (event, ctx) => observe("before_compaction", event, ctx), { timeoutMs: 150_000 })
  },
}
