// Native OpenClaw 2026.9.5 hook. The openclaw counterpart of the opencode
// paid-guard (configs/opencode/plugins/paid-guard): a pay-as-you-go helper runs
// only after a fresh approval in discord, and model overrides are refused.
type Event = { toolName?: unknown; params?: Record<string, unknown> }
type API = {
  on: (event: string, callback: (event: Event) => Promise<unknown>, options?: { priority?: number }) => void
}

// By role suffix, so main-* and dev-* share them (openclaw.nix paidRoles).
export const PAID: Record<string, { model: string; role: string }> = {
  "paid-opus": { model: "opencode-premium/claude-opus-5-5", role: "planning and review, never edits" },
  "paid-opus-heavy": { model: "opencode-premium/claude-opus-5-5", role: "heavy implementation" },
  "paid-fable-architect": { model: "opencode-premium/claude-fable-5-1", role: "design decisions, never edits" },
}
const SHELL = new Set(["exec", "bash", "process", "code_execution"])
// The shell inherits the premium key, so a direct call could skip the
// approval. A pattern only raises the bar; the Console cap is the backstop.
const PREMIUM_SHELL = /opencode-premium|OPENCODE_PREMIUM_API_KEY/

const clip = (value: unknown, max: number) => {
  const text = typeof value === "string" ? value.replace(/\s+/g, " ").trim() : ""
  return text.length > max ? `${text.slice(0, max - 1)}…` : text
}
const block = (blockReason: string) => ({ block: true, blockReason })

export function decide(event: Event) {
  try {
    const params = event.params ?? {}
    if (typeof event.toolName === "string" && SHELL.has(event.toolName)) {
      return PREMIUM_SHELL.test(JSON.stringify(params)) ? block("Pay-as-you-go access from the shell is not allowed; ask for a paid agent instead.") : undefined
    }
    if (event.toolName !== "sessions_spawn") return undefined
    if (params.model !== undefined && params.model !== "") return block("Model overrides are not allowed; pick an agent instead.")
    const agent = typeof params.agentId === "string" ? params.agentId : ""
    const role = Object.keys(PAID).sort((a, b) => b.length - a.length).find((key) => agent.endsWith(`-${key}`))
    if (!role) return undefined
    return {
      requireApproval: {
        title: clip(`Paid agent: ${agent}`, 80),
        description: clip([
          `Role: ${PAID[role].role}`,
          `Model: ${PAID[role].model}`,
          "Billing: Console pay-as-you-go, charged to the service account",
          `Reason: ${clip(params.task, 240) || "not given"}`,
        ].join("\n"), 512),
        severity: "critical",
        allowedDecisions: ["allow-once", "deny"],
        pluginId: "paid-guard",
      },
    }
  } catch {
    return block("Paid guard could not evaluate this tool call.")
  }
}

export default {
  id: "paid-guard",
  name: "Paid guard",
  description: "Approval for pay-as-you-go helpers and no model overrides",
  register(api: API) {
    api.on("before_tool_call", async (event) => decide(event), { priority: 100 })
  },
}
