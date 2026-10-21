import { describe, expect, test } from "bun:test"
import plugin, { decide } from "../bridges/openclaw-paid-guard/index.ts"

describe("OpenClaw paid guard", () => {
  test("asks every time before a paid helper runs", () => {
    for (const [agent, model] of [
      ["dev-paid-opus", "opencode-premium/claude-opus-5-5"],
      ["main-paid-opus-heavy", "opencode-premium/claude-opus-5-5"],
      ["dev-paid-fable-architect", "opencode-premium/claude-fable-5-1"],
    ]) {
      const result: any = decide({ toolName: "sessions_spawn", params: { agentId: agent, task: "Review   the\nplan" } })
      expect(result.requireApproval.title).toBe(`Paid agent: ${agent}`)
      expect(result.requireApproval.description).toContain(`Model: ${model}`)
      expect(result.requireApproval.description).toContain("Reason: Review the plan")
      expect(result.requireApproval.allowedDecisions).toEqual(["allow-once", "deny"])
      expect(result.requireApproval.severity).toBe("critical")
    }
    const thinking: any = decide({ toolName: "sessions_spawn", params: { agentId: "dev-paid-opus", task: "t" } })
    expect(thinking.params).toEqual({ agentId: "dev-paid-opus", task: "t", thinking: "high" })
    const kept: any = decide({ toolName: "sessions_spawn", params: { agentId: "dev-paid-opus", thinking: "max" } })
    expect(kept.params.thinking).toBe("max")
    const heavy: any = decide({ toolName: "sessions_spawn", params: { agentId: "main-paid-opus-heavy" } })
    expect(heavy.requireApproval.description).toContain("heavy implementation")
    expect(heavy.requireApproval.description).toContain("Reason: not given")
    const long: any = decide({ toolName: "sessions_spawn", params: { agentId: "main-paid-opus", task: "x".repeat(2000) } })
    expect(long.requireApproval.description.length).toBeLessThanOrEqual(512)
  })
  test("lets go helpers through and refuses model overrides", () => {
    expect(decide({ toolName: "sessions_spawn", params: { agentId: "dev-reviewer", task: "review" } })).toBeUndefined()
    expect(decide({ toolName: "sessions_spawn", params: { agentId: "dev-reviewer", model: "" } })).toBeUndefined()
    for (const agentId of ["dev-reviewer", "main-paid-opus"]) {
      expect(decide({ toolName: "sessions_spawn", params: { agentId, model: "opencode/claude-opus-5-5" } }))
        .toEqual({ block: true, blockReason: "Model overrides are not allowed; pick an agent instead." })
    }
  })
  test("blocks the premium key from the shell only", () => {
    for (const toolName of ["exec", "bash", "process", "code_execution"]) {
      expect((decide({ toolName, params: { command: "curl -H \"x-api-key: $OPENCODE_PREMIUM_API_KEY\" …" } }) as any)?.block).toBe(true)
    }
    expect(decide({ toolName: "exec", params: { command: "git status" } })).toBeUndefined()
    expect(decide({ toolName: "read", params: { path: "opencode-premium.md" } })).toBeUndefined()
  })
  test("fails closed when the call cannot be read", () => {
    const params = { get agentId() { throw new Error("broken") } }
    expect(decide({ toolName: "sessions_spawn", params } as any))
      .toEqual({ block: true, blockReason: "Paid guard could not evaluate this tool call." })
  })
  test("registers one before_tool_call hook", async () => {
    const handlers = new Map<string, Function>()
    plugin.register({ on(name: string, fn: Function) { handlers.set(name, fn) } } as any)
    expect([...handlers.keys()]).toEqual(["before_tool_call"])
    expect(await handlers.get("before_tool_call")!({ toolName: "sessions_spawn", params: { agentId: "main-explore" } })).toBeUndefined()
  })
})
