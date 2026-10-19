// OpenCode 2.0.32 Effect plugin. Keeps Console pay-as-you-go agents behind a
// fresh approval and blocks subagent model overrides (anomalyco/opencode#51071).
import { Plugin } from "@opencode/plugin/effect"
// The host exposes @opencode/plugin and effect, not @opencode/schema.
import { Error as ToolError } from "@opencode/plugin/promise/tool"
import { Effect } from "effect"
import { readFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"

const PREMIUM = "opencode-premium"
// Used with the live agent catalog, so a renamed model cannot drop these.
const PREMIUM_AGENTS = new Set(["paid-opus", "paid-opus-heavy", "paid-fable-architect"])
const SUBAGENT = "subagent"
const SHELL = "shell"
const OVERRIDES = ["model", "provider", "providerID", "modelID", "variant"]
// The shell inherits the premium key, so a nested `opencode run` could skip the
// approval. A pattern only raises the bar; the Console cap is the backstop.
const PREMIUM_SHELL = /opencode-premium|OPENCODE_PREMIUM_API_KEY/

type Ref = { providerID: string; id: string }
type Call = { agent?: unknown; description?: unknown; prompt?: unknown; sessionID?: unknown }

const clip = (value: unknown, max: number) => {
  const text = typeof value === "string" ? value.replace(/\s+/g, " ").trim() : ""
  return text.length > max ? `${text.slice(0, max - 1)}…` : text
}
const name = (ref?: Ref) => ref ? `${ref.providerID}/${ref.id}` : "inherited"

// Returns the call, or a denial reason. A JSON string arrives when the input
// repair hook has not run yet.
function screen(input: unknown): Call | string {
  try {
    const call = typeof input === "string" ? JSON.parse(input) : input
    if (!call || typeof call !== "object" || Array.isArray(call)) return "Paid guard could not read this subagent call."
    if (OVERRIDES.some((key) => key in call && (call as any)[key] !== "" && (call as any)[key] !== undefined)) {
      return "Model overrides are not allowed; pick an agent instead."
    }
    return call
  } catch {
    return "Paid guard could not read this subagent call."
  }
}

export async function goQuota(path = join(process.env.XDG_CACHE_HOME || join(homedir(), ".cache"), "opencode/quota-export.json")) {
  try {
    const go = JSON.parse(await readFile(path, "utf8"))?.providers?.["opencode-go"]
    if (!go || !Array.isArray(go.entries)) return `quota unknown (opencode-go ${go?.status || "missing"})`
    const age = Math.max(0, Math.round((Date.now() / 1000 - go.fetchedAt) / 60))
    const rows = go.entries.filter((entry: any) => entry.renderType === "percent").map((entry: any) => {
      const reset = Number.isFinite(entry.resetAt) ? `, resets ${new Date(entry.resetAt * 1000).toISOString().slice(0, 16)}Z` : ""
      return `${entry.window || entry.name} ${Math.round(100 - entry.percentRemaining)}% used${reset}`
    })
    return rows.length ? `opencode-go (${age}m old): ${rows.join("; ")}` : "quota unknown (no opencode-go windows)"
  } catch {
    return "quota unknown"
  }
}

export default Plugin.define({
  id: "paid-guard",
  effect: Effect.fn(function* (ctx) {
    // Subagent calls by tool call ID; the permission request carries only that ID.
    const calls = new Map<string, Call>()
    // Parent session and agent pairs that went through the forced prompt.
    const asked = new Set<string>()
    const warned = new Set<string>()
    const model = Effect.fn(function* (sessionID: string) {
      return (yield* ctx.session.get({ sessionID: sessionID as any })).model as Ref | undefined
    })

    yield* ctx.tool.hook("execute.before", Effect.fn(function* (event) {
      if (event.tool === SHELL) {
        const text = typeof event.input === "string" ? event.input : JSON.stringify(event.input ?? "")
        if (PREMIUM_SHELL.test(text)) {
          return yield* Effect.fail(new ToolError({ message: "Pay-as-you-go access from the shell is not allowed; ask for a paid agent instead." }))
        }
        return
      }
      if (event.tool !== SUBAGENT) return
      const call = screen(event.input)
      if (typeof call === "string") return yield* Effect.fail(new ToolError({ message: call }))
      calls.set(event.id, call)
    }))
    yield* ctx.tool.hook("execute.after", Effect.fn(function* (event) {
      calls.delete(event.id)
    }))

    // Runs after saved "always" rules are merged; a configured deny never reaches it.
    const evaluate = Effect.fn(function* (event: any) {
      const call = event.source ? calls.get(event.source.id) : undefined
      const paid: string[] = []
      for (const resource of event.resources) {
        const agent = (yield* ctx.agent.get({ agentID: resource })).data
        // Without its own model a new child runs on the parent's, a resumed one keeps its own.
        // A sessionID that does not resolve resumes nothing, so it cannot carry a paid model.
        const resumed = typeof call?.sessionID === "string" && call.sessionID !== ""
          ? yield* model(call.sessionID).pipe(Effect.catchCause(() => Effect.succeed(undefined)))
          : undefined
        const ref = (agent.model as Ref | undefined) ?? resumed ?? (yield* model(event.sessionID))
        if (!PREMIUM_AGENTS.has(agent.id) && ref?.providerID !== PREMIUM && resumed?.providerID !== PREMIUM) continue
        asked.add(`${event.sessionID}:${agent.id}`)
        paid.push(`Role: ${agent.id} (${clip(agent.description, 120) || "no description"})\nModel: ${name(ref)}`)
      }
      if (!paid.length) return
      event.effect = "ask"
      event.message = [
        ...paid,
        "Billing: Console pay-as-you-go, charged to the service account",
        `Reason: ${clip([call?.description, call?.prompt].filter((x) => typeof x === "string").join(" - "), 300) || "not given"}`,
        "Monthly cap enforced by Console; the sidebar shows what is left",
      ].join("\n")
    })
    yield* ctx.permission.hook("evaluate", (event) => {
      if (event.action !== SUBAGENT || event.effect === "deny") return Effect.void
      return evaluate(event).pipe(Effect.catchCause(() => Effect.sync(() => {
        event.effect = "deny"
        event.message = "Paid guard could not evaluate this subagent; denied."
      })))
    })

    // Observation only: session hooks have no failure channel.
    yield* ctx.session.hook("model.request", (event) => Effect.gen(function* () {
      if (warned.has(event.sessionID)) return
      const session = yield* ctx.session.get({ sessionID: event.sessionID })
      if (session.parentID && asked.has(`${session.parentID}:${session.agent}`)) return
      warned.add(event.sessionID)
      yield* Effect.logWarning("paid-guard: pay-as-you-go model outside an approved subagent", {
        sessionID: event.sessionID, agent: event.agent, model: name(event.model), kind: event.kind })
    }).pipe(Effect.catchCause(() => Effect.logWarning("paid-guard: could not check a pay-as-you-go request", {
      sessionID: event.sessionID }))), { providerID: PREMIUM })

    yield* ctx.tool.transform((editor) => editor.add({
      name: "go_quota",
      description: "Used percent and reset time of each OpenCode Go window (five-hour, weekly, monthly), from the opencode-quota export. Read-only.",
      input: { type: "object", properties: {} },
      options: { codemode: false },
      execute: () => Effect.promise(() => goQuota()).pipe(Effect.map((content) => ({ content }))),
    }))
  }),
})
