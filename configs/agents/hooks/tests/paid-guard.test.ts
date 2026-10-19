import { afterAll, describe, expect, test } from "bun:test"
import { mkdirSync, mkdtempSync, readFileSync, writeFileSync, rmSync } from "node:fs"
import { join } from "node:path"
import { tmpdir } from "node:os"

const dir = mkdtempSync(join(tmpdir(), "paid-guard-"))
afterAll(() => rmSync(dir, { recursive: true, force: true }))

// Same direct Effect fixture as bridges.test.ts, plus the operators this plugin uses.
const logs: string[] = []
const run = async (value: any): Promise<any> => typeof value === "function" ? value() : value?.run ? value.run() : value
const fx = (task: Function): any => ({ run: task, *[Symbol.iterator]() { return yield task }, pipe: (...fs: Function[]) => fs.reduce((x, f) => f(x), fx(task)) })
const Effect = {
  gen: (f: Function) => fx(async () => { const g = f(); let item = g.next(); while (!item.done) { try { item = g.next(await run(item.value)) } catch (error) { item = g.throw(error) } } return item.value }),
  fn: (f: Function) => (...args: any[]) => Effect.gen(() => f(...args)),
  promise: (f: Function) => fx(f),
  sync: (f: Function) => fx(f),
  succeed: (value: any) => fx(() => value),
  void: fx(() => undefined),
  map: (f: Function) => (x: any) => fx(async () => f(await run(x))),
  fail: (e: any) => fx(() => { throw e }),
  catchCause: (f: Function) => (x: any) => fx(async () => { try { return await run(x) } catch (e) { return run(f(e)) } }),
  logWarning: (message: string) => fx(() => { logs.push(message) }),
}
const ToolError = class extends Error { _tag = "Tool.Error"; constructor(input: any) { super(input.message) } }
// mock.module is process-wide and bridges.test.ts mocks "effect" differently,
// so a copy of the plugin imports these fixtures from a local module instead.
;(globalThis as any).paidGuardFixture = { Effect, Plugin: { define: (value: any) => value }, ToolError }
writeFileSync(join(dir, "fixture.ts"), "const f = (globalThis as any).paidGuardFixture\nexport const { Effect, Plugin, ToolError: Error } = f\n")
const source = readFileSync(join(import.meta.dir, "../../../opencode/plugins/paid-guard/server.ts"), "utf8")
  .replace(/from "(effect|@opencode\/plugin\/effect|@opencode\/plugin\/promise\/tool)"/g, `from ${JSON.stringify(join(dir, "fixture.ts"))}`)
expect(source.match(/fixture\.ts"/g)?.length).toBe(3)
writeFileSync(join(dir, "paid-guard.ts"), source)

const agents: Record<string, any> = {
  worker: { id: "worker", description: "Implements a change", model: { providerID: "opencode-go", id: "kimi-k3" } },
  explore: { id: "explore", description: "Reads code" },
  "paid-opus-heavy": { id: "paid-opus-heavy", description: "Hard reasoning", model: { providerID: "opencode-premium", id: "claude-opus-5-5" } },
  "paid-fable-architect": { id: "paid-fable-architect", description: "Designs", model: { providerID: "opencode-go", id: "renamed" } },
  custom: { id: "custom", description: "Unlisted", model: { providerID: "opencode-premium", id: "claude-fable-5-1" } },
}
const sessions: Record<string, any> = {
  parent: { id: "parent", agent: "manager", model: { providerID: "opencode-go", id: "kimi-k3" } },
  paidParent: { id: "paidParent", agent: "manager", model: { providerID: "opencode-premium", id: "claude-opus-5-5" } },
  oldChild: { id: "oldChild", parentID: "parent", agent: "paid-opus-heavy", model: { providerID: "opencode-premium", id: "claude-opus-5-5" } },
  child: { id: "child", parentID: "parent", agent: "paid-opus-heavy" },
}

async function load(overrides: Record<string, any> = {}) {
  const { default: plugin } = await import(join(dir, "paid-guard.ts"))
  const hooks = new Map<string, Function>(); const options = new Map<string, any>(); const tools: any[] = []
  const register = (prefix: string) => (name: string, fn: Function, opts?: any) => fx(() => { hooks.set(`${prefix}.${name}`, fn); options.set(`${prefix}.${name}`, opts) })
  const lookup = (table: Record<string, any>, key: string) => { if (!table[key]) throw new Error(`missing ${key}`); return table[key] }
  const ctx = {
    tool: { hook: register("tool"), transform: (cb: Function) => fx(() => cb({ add: (tool: any) => tools.push(tool) })) },
    permission: { hook: register("permission") },
    session: { hook: register("session"), get: ({ sessionID }: any) => fx(() => lookup(sessions, sessionID)) },
    agent: { get: ({ agentID }: any) => fx(() => ({ data: lookup(agents, agentID) })) },
    ...overrides,
  }
  await run(plugin.effect(ctx as any))
  expect(plugin.id).toBe("paid-guard")
  const before = (id: string, input: unknown, tool = "subagent") => run(hooks.get("tool.execute.before")!({ tool, id, sessionID: "parent", input }))
  const evaluate = async (event: any) => { await run(hooks.get("permission.evaluate")!(event)); return event }
  return { hooks, options, tools, before, evaluate }
}
const permission = (resource: string, effect = "allow", id = "c1", sessionID = "parent") =>
  ({ sessionID, action: "subagent", resources: [resource], source: { type: "tool", messageID: "m", id }, effect })

describe("paid guard", () => {
  test("denies a model or provider override on the subagent tool", async () => {
    const { before } = await load()
    for (const input of [
      { agent: "worker", description: "d", prompt: "p", model: "opencode-premium/claude-opus-5-5" },
      JSON.stringify({ agent: "worker", description: "d", prompt: "p", model: "opencode-premium/claude-fable-5-1" }),
      { agent: "worker", description: "d", prompt: "p", provider: "opencode-premium" },
    ]) {
      try { await before("c0", input); throw new Error("denial missing") }
      catch (error: any) { expect(error._tag).toBe("Tool.Error"); expect(error.message).toContain("Model overrides are not allowed") }
    }
    expect(await before("c0", { agent: "worker", description: "d", prompt: "p", model: "", sessionID: "" })).toBeUndefined()
    expect(await before("c0", { command: "anything", model: "x/y" }, "shell")).toBeUndefined()
  })

  test("denies shell commands that reach the premium provider or its key", async () => {
    const { before } = await load()
    for (const command of [
      "opencode run -m opencode-premium/claude-opus-5-5 'Reply OK' </dev/null",
      "curl -H \"x-api-key: $OPENCODE_PREMIUM_API_KEY\" https://opencode.ai/inference/anthropic/v1/messages",
    ]) {
      try { await before("c1", { command }, "shell"); throw new Error("denial missing") }
      catch (error: any) { expect(error._tag).toBe("Tool.Error"); expect(error.message).toContain("not allowed") }
    }
    expect(await before("c1", { command: "opencode run -m opencode-go/kimi-k3 'Reply OK'" }, "shell")).toBeUndefined()
  })

  test("forces a fresh prompt for a premium agent despite a saved always or config allow", async () => {
    const { before, evaluate } = await load()
    await before("c1", { agent: "paid-opus-heavy", description: "Review the migration", prompt: "Check every step of the plan" })
    const event = await evaluate(permission("paid-opus-heavy", "allow"))
    expect(event.effect).toBe("ask")
    for (const text of ["Role: paid-opus-heavy (Hard reasoning)", "Model: opencode-premium/claude-opus-5-5",
      "Console pay-as-you-go, charged to the service account", "Reason: Review the migration - Check every step", "Monthly cap enforced by Console; the sidebar shows what is left"]) {
      expect(event.message).toContain(text)
    }
    // Live catalog and fallback list each mark an agent as premium on their own.
    expect((await evaluate(permission("custom"))).effect).toBe("ask")
    expect((await evaluate(permission("paid-fable-architect"))).effect).toBe("ask")
    // A long prompt is truncated.
    await before("c2", { agent: "paid-opus-heavy", description: "d", prompt: "x".repeat(2000) })
    expect((await evaluate(permission("paid-opus-heavy", "allow", "c2"))).message.length).toBeLessThan(700)
  })

  test("premium also covers a resumed paid child and a model inherited from a paid parent", async () => {
    const { before, evaluate } = await load()
    await before("c3", { agent: "worker", description: "d", prompt: "p", sessionID: "oldChild" })
    expect((await evaluate(permission("worker", "allow", "c3"))).effect).toBe("ask")
    expect((await evaluate(permission("explore", "allow", "c4", "paidParent"))).effect).toBe("ask")
  })

  test("a sessionID that does not resolve resumes nothing and is not denied", async () => {
    const { before, evaluate } = await load()
    await before("c10", { agent: "worker", description: "d", prompt: "p", sessionID: "ses" })
    expect((await evaluate(permission("worker", "allow", "c10"))).effect).toBe("allow")
    await before("c11", { agent: "paid-opus-heavy", description: "d", prompt: "p", sessionID: "ses" })
    expect((await evaluate(permission("paid-opus-heavy", "allow", "c11"))).effect).toBe("ask")
  })

  test("leaves non-premium subagents, other actions and configured denies untouched", async () => {
    const { before, evaluate } = await load()
    await before("c5", { agent: "worker", description: "d", prompt: "p" })
    const allowed = await evaluate(permission("worker", "allow", "c5"))
    expect(allowed.effect).toBe("allow"); expect(allowed.message).toBeUndefined()
    expect((await evaluate(permission("explore", "ask", "c6"))).effect).toBe("ask")
    expect((await evaluate({ ...permission("paid-opus-heavy"), action: "shell" })).effect).toBe("allow")
    expect((await evaluate(permission("paid-opus-heavy", "deny"))).effect).toBe("deny")
  })

  test("fails closed when the decision cannot be made", async () => {
    const { before, evaluate } = await load()
    for (const input of [42, "not json", null, ["agent"]]) {
      try { await before("c7", input); throw new Error("denial missing") }
      catch (error: any) { expect(error._tag).toBe("Tool.Error"); expect(error.message).toContain("could not read") }
    }
    const unknown = await evaluate(permission("ghost"))
    expect(unknown.effect).toBe("deny"); expect(unknown.message).toContain("could not evaluate")
    const broken = await load({ agent: { get: () => fx(() => { throw new Error("catalog down") }) } })
    expect((await broken.evaluate(permission("worker"))).effect).toBe("deny")
  })

  test("warns once for a paid request outside an approved child, never blocks", async () => {
    const { before, evaluate, hooks, options } = await load()
    expect(options.get("session.model.request")).toEqual({ providerID: "opencode-premium" })
    const request = (sessionID: string) => run(hooks.get("session.model.request")!({ sessionID, agent: "manager", kind: "primary", model: { providerID: "opencode-premium", id: "claude-opus-5-5" } }))
    logs.length = 0
    await before("c9", { agent: "paid-opus-heavy", description: "d", prompt: "p" })
    await evaluate(permission("paid-opus-heavy", "allow", "c9"))
    await request("child")
    expect(logs).toEqual([])
    await request("paidParent"); await request("paidParent")
    expect(logs).toEqual(["paid-guard: pay-as-you-go model outside an approved subagent"])
    await request("missing")
    expect(logs.at(-1)).toContain("could not check")
  })

  test("go_quota reports opencode-go windows or quota unknown", async () => {
    const { tools } = await load()
    const tool = tools.find((x) => x.name === "go_quota")
    expect(tool.options).toEqual({ codemode: false })
    const previous = process.env.XDG_CACHE_HOME
    process.env.XDG_CACHE_HOME = dir
    try {
      expect((await run(tool.execute({}, {}))).content).toBe("quota unknown")
      const now = Math.floor(Date.now() / 1000)
      mkdirSync(join(dir, "opencode"), { recursive: true })
      writeFileSync(join(dir, "opencode/quota-export.json"), JSON.stringify({ version: 2, providers: { "opencode-go": { status: "ok", fetchedAt: now - 120, entries: [
        { name: "OpenCode Go 5h", window: "5h", renderType: "percent", percentRemaining: 70, resetAt: Date.UTC(2026, 9, 19, 12, 0) / 1000 },
        { name: "OpenCode Go Weekly", window: "Weekly", renderType: "percent", percentRemaining: 10 },
        { name: "Balance", renderType: "value", value: "$3" },
      ] } } }))
      expect((await run(tool.execute({}, {}))).content).toBe("opencode-go (2m old): 5h 30% used, resets 2026-10-19T12:00Z; Weekly 90% used")
      writeFileSync(join(dir, "opencode/quota-export.json"), JSON.stringify({ version: 2, providers: { "opencode-go": { status: "unavailable" } } }))
      expect((await run(tool.execute({}, {}))).content).toBe("quota unknown (opencode-go unavailable)")
      writeFileSync(join(dir, "opencode/quota-export.json"), "{broken")
      expect((await run(tool.execute({}, {}))).content).toBe("quota unknown")
    } finally {
      if (previous === undefined) delete process.env.XDG_CACHE_HOME
      else process.env.XDG_CACHE_HOME = previous
    }
  })
})

describe("notices", () => {
  test("picks subagent requests that carry a message", async () => {
    const { notices } = await import("../../../opencode/plugins/paid-guard/notice.ts")
    expect(notices([
      { id: "a", action: "shell", message: "x" },
      { id: "b", action: "subagent" },
      { id: "c", action: "subagent", message: "  " },
      { id: "d", action: "subagent", message: "Role: paid-opus\nModel: opencode-premium/claude-opus-5-5\n" },
      null,
    ])).toEqual([{ id: "d", lines: ["Role: paid-opus", "Model: opencode-premium/claude-opus-5-5"] }])
  })
})
