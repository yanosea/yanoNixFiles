import { afterAll, describe, expect, test } from "bun:test"
import { existsSync, mkdirSync, mkdtempSync, readFileSync, rmSync, utimesSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { tmpdir } from "node:os"

const dir = mkdtempSync(join(tmpdir(), "agent-sync-"))
afterAll(() => rmSync(dir, { recursive: true, force: true }))
writeFileSync(join(dir, "fixture.ts"), "export const Plugin = { define: (value: any) => value }\n")
const source = readFileSync(join(import.meta.dir, "../../../opencode/plugins/agent-sync.ts"), "utf8")
  .replace(`from "@opencode/plugin"`, `from ${JSON.stringify(join(dir, "fixture.ts"))}`)
expect(source).not.toContain(`"@opencode/plugin"`)
writeFileSync(join(dir, "agent-sync.ts"), source)
const plugin = await import(join(dir, "agent-sync.ts"))

const home = join(dir, "home")
for (const script of plugin.SCRIPTS.slice(0, 2)) {
  mkdirSync(join(home, script, ".."), { recursive: true })
  writeFileSync(join(home, script), "")
}
const waitFor = async (check: () => boolean) => {
  for (let i = 0; i < 50 && !check(); i++) await Bun.sleep(100)
  return check()
}

describe("agent-sync", () => {
  test("runs the installed scripts once per session, at most once an interval", () => {
    const runs: [string, string[]][] = []
    let clock = 0
    const start = plugin.chores((lock: string, paths: string[]) => runs.push([lock, paths]), home, () => clock)
    start("a")
    expect(runs).toEqual([[join(home, plugin.LOCK), plugin.SCRIPTS.slice(0, 2).map((script: string) => join(home, script))]])
    start("a")
    clock = plugin.INTERVAL - 1
    start("b")
    expect(runs.length).toBe(1)
    clock = plugin.INTERVAL * 2
    start("b")
    expect(runs.length).toBe(1)
    start("c")
    expect(runs.length).toBe(2)
  })

  test("one detached shell runs the scripts in turn, without blocking", async () => {
    const log = join(dir, "order")
    const lock = join(dir, "locks/run.lock")
    const first = join(dir, "first.sh")
    const second = join(dir, "second.sh")
    writeFileSync(first, `sleep 1; echo first >>${JSON.stringify(log)}\n`)
    writeFileSync(second, `echo second >>${JSON.stringify(log)}\n`)
    const before = Date.now()
    plugin.detached(lock, [first, join(dir, "missing.sh"), second])
    expect(Date.now() - before).toBeLessThan(500)
    expect(await waitFor(() => existsSync(lock))).toBe(true)
    // a second run while the first holds the lock does nothing
    plugin.detached(lock, [second])
    expect(await waitFor(() => !existsSync(lock))).toBe(true)
    expect(readFileSync(log, "utf8")).toBe("first\nsecond\n")
  })

  test("a lock older than an hour is taken over", async () => {
    const log = join(dir, "stale")
    const lock = join(dir, "stale.lock")
    mkdirSync(lock)
    const old = Date.now() / 1000 - 2 * 3600
    utimesSync(lock, old, old)
    const script = join(dir, "stale.sh")
    writeFileSync(script, `echo ran >>${JSON.stringify(log)}\n`)
    plugin.detached(lock, [script])
    expect(await waitFor(() => existsSync(log) && !existsSync(lock))).toBe(true)
  })

  test("a review notice reaches the agent once per text", () => {
    const notice = plugin.notices(home)
    expect(notice()).toBeUndefined()
    mkdirSync(join(home, plugin.NOTICE, ".."), { recursive: true })
    writeFileSync(join(home, plugin.NOTICE), "new plugin: x\n")
    expect(notice()).toBe("new plugin: x")
    expect(notice()).toBeUndefined()
    writeFileSync(join(home, plugin.NOTICE), "  \n")
    expect(notice()).toBeUndefined()
    writeFileSync(join(home, plugin.NOTICE), "new plugin: y\n")
    expect(notice()).toBe("new plugin: y")
    rmSync(join(home, plugin.NOTICE))
  })

  test("registers the prompt and context hooks; context gets the notice", async () => {
    const hooks: Record<string, Function> = {}
    await plugin.default.setup({ session: { hook: async (name: string, callback: Function) => { hooks[name] = callback } } })
    expect(plugin.default.id).toBe("agent-sync")
    expect(Object.keys(hooks)).toEqual(["prompt", "context"])
    const event = { system: [] as any[] }
    hooks.context(event)
    expect(Array.isArray(event.system)).toBe(true)
  })
})
