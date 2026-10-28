import { afterAll, describe, expect, test } from "bun:test"
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import { tmpdir } from "node:os"
import { join } from "node:path"

const dir = mkdtempSync(join(tmpdir(), "login-guard-"))
afterAll(() => rmSync(dir, { recursive: true, force: true }))
writeFileSync(join(dir, "fixture.ts"), "export const Plugin = { define: (value: any) => value }\n")
const source = readFileSync(join(import.meta.dir, "../../../opencode/plugins/login-guard.ts"), "utf8")
  .replace(`from "@opencode/plugin"`, `from ${JSON.stringify(join(dir, "fixture.ts"))}`)
expect(source).not.toContain(`"@opencode/plugin"`)
writeFileSync(join(dir, "login-guard.ts"), source)
const { EXPECTED, unusable } = await import(join(dir, "login-guard.ts"))

const connection = (value: unknown) => async () => value as any

describe("login-guard", () => {
  test("a stored credential is usable without an environment variable", async () => {
    expect(await unusable(connection({ type: "credential" }), ["openai"], {})).toEqual([])
  })

  test("an env connection is dead when its variable is empty", async () => {
    const active = connection({ type: "env", name: "TAVILY_API_KEY" })
    expect(await unusable(active, ["tavily"], {})).toEqual(["tavily TAVILY_API_KEY not set"])
    expect(await unusable(active, ["tavily"], { TAVILY_API_KEY: "x" })).toEqual([])
  })

  test("a missing or failing connection is reported once", async () => {
    expect(await unusable(connection(undefined), ["firecrawl"], {})).toEqual(["firecrawl not connected"])
    const failing = async () => { throw new Error("no connection") }
    expect(await unusable(failing, ["xai"], {})).toEqual(["xai not connected"])
  })

  test("a CLI-only integration is usable from its env variable", async () => {
    const none = connection(undefined)
    expect(await unusable(none, ["firecrawl"], { FIRECRAWL_API_KEY: "x" })).toEqual([])
    expect(await unusable(none, ["openai"], { FIRECRAWL_API_KEY: "x" })).toEqual(["openai not connected"])
  })

  test("the expected list is the six kept connected", () => {
    expect(EXPECTED).toEqual(["firecrawl", "openai", "opencode", "opencode-premium", "tavily", "xai"])
  })
})
