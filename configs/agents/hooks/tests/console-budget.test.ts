import { afterAll, describe, expect, test } from "bun:test"
import { mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs"
import { join } from "node:path"
import { tmpdir } from "node:os"
import { fetchBudget, formatBudget, parseModels, parsePolicies, parseSummary, resetDate } from "../../../opencode/plugins/console-budget/budget.ts"

const root = join(import.meta.dir, "../../../opencode/plugins/console-budget")
const policy = (mode: string, spent: number, limit: number, extra = {}) => ({
  id: mode, audience: { mode }, memberCount: 0, serviceAccountCount: 0, hitLimitCount: 0, ...extra,
  rules: [{ kind: "budget", limitDollars: limit, spentDollars: spent, period: "month", scope: "each", per: "set" }],
})
const now = new Date("2026-10-19T12:00:00Z")

describe("parsePolicies", () => {
  test("finds the service-account and workspace budgets", () => {
    expect(parsePolicies({ policies: [policy("everyone", 9, 50), policy("workspace", 3.5, 100), policy("all-service-accounts", 0.14, 20)] }))
      .toEqual({ state: "ok", service: { spent: 0.14, limit: 20 }, workspace: { spent: 3.5, limit: 100 } })
  })
  test("falls back to a policy covering service accounts", () => {
    expect(parsePolicies({ policies: [policy("custom", 1, 10, { serviceAccountCount: 1 })] }))
      .toEqual({ state: "ok", service: { spent: 1, limit: 10 } })
  })
  test("missing service-account policy is unavailable", () => {
    expect(parsePolicies({ policies: [policy("everyone", 1, 10)] })).toEqual({ state: "unavailable", reason: "no service-account budget" })
    expect(parsePolicies({ policies: [] }).state).toBe("unavailable")
  })
  test("shape changes are unavailable, never thrown", () => {
    for (const body of [null, "x", [], {}, { policies: {} }, { policies: [null, 1, "x"] },
      { policies: [{ audience: { mode: "all-service-accounts" }, rules: [{ kind: "budget", limitDollars: "20", spentDollars: 1 }] }] },
      { policies: [{ audience: { mode: "all-service-accounts" }, rules: [{ kind: "budget", limitDollars: 0, spentDollars: 0 }] }] },
      { policies: [{ audience: { mode: "all-service-accounts" }, rules: "budget" }] },
      { policies: [{ audience: { mode: "all-service-accounts" }, rules: [{ kind: "budget", limitDollars: 20, spentDollars: 1, period: "day" }] }] },
    ]) expect(parsePolicies(body).state).toBe("unavailable")
  })
})

describe("usage routes", () => {
  test("summary without web search counts zero searches", () => {
    expect(parseSummary({ totalRequests: "5", totalCostMicroCents: "100000000", services: [] }))
      .toEqual({ count: 5, cost: 1, search: { count: 0, cost: 0 } })
  })
  test("shape changes are undefined, never thrown", () => {
    for (const body of [null, "x", [], {}, { totalRequests: 5, totalCostMicroCents: "1" }, { totalRequests: "-1", totalCostMicroCents: "1" }])
      expect(parseSummary(body)).toBeUndefined()
    for (const body of [null, {}, { items: {} }]) expect(parseModels(body)).toBeUndefined()
    expect(parseModels({ items: [null, { model: "m", totalRequests: "x" }] })).toEqual([])
  })
})

describe("resetDate", () => {
  test("is the next 1st at 00:00 UTC", () => {
    expect(resetDate(now).toISOString()).toBe("2026-11-01T00:00:00.000Z")
    expect(resetDate(new Date("2026-12-31T23:59:59Z")).toISOString()).toBe("2027-01-01T00:00:00.000Z")
    // Still October in UTC although November 1st in Tokyo.
    expect(resetDate(new Date("2026-10-31T20:00:00Z")).toISOString()).toBe("2026-11-01T00:00:00.000Z")
    expect(resetDate(new Date("2026-11-01T00:00:00Z")).toISOString()).toBe("2026-12-01T00:00:00.000Z")
  })
})

describe("formatBudget", () => {
  test("rows fit the sidebar", () => {
    const models = [
      { model: "claude-opus-5-5", count: 3, cost: 0.1396 },
      { model: "claude-haiku-5-5", count: 2, cost: 0.0005 },
      { model: "a-model-name-longer-than-the-column", count: 1234, cost: 1234.5 },
      { model: "fourth", count: 1, cost: 0 },
    ]
    const lines = formatBudget({ state: "ok", service: { spent: 0.14, limit: 20 }, workspace: { spent: 123.456, limit: 1000 },
      calls: { count: 1239, cost: 1234.64, models }, search: { count: 16, cost: 0.16 } }, now)
    expect(lines).toEqual([
      "[Premium (service account)]",
      "Budget    $0.14 / $20.00 (0.7%)",
      "Calls     1239 ($1234.64)",
      "  opus-5-5         3 $0.14",
      "  haiku-5-5        2 $0.00",
      "  a-model-name-lon 1234 $1234.50",
      "Resets    Nov 1 (UTC)",
      "Workspace $123.46 / $1000.00 (12.3%)",
      "",
      "[Hosted Web Search]",
      "Searches  16 ($0.16)",
    ])
    for (const line of lines) expect(line.length).toBeLessThanOrEqual(38)
  })
  test("missing usage shows unavailable rows", () => {
    const lines = formatBudget({ state: "ok", service: { spent: 0, limit: 20 } }, now)
    expect(lines).toContain("Calls     unavailable")
    expect(lines).toContain("Searches  unavailable")
  })
  test("unavailable shows the reason", () => {
    expect(formatBudget({ state: "unavailable", reason: "HTTP 403" }, now)).toEqual(["[Premium (service account)]", "unavailable (HTTP 403)"])
  })
})

describe("fetchBudget", () => {
  const credential = { type: "oauth", access: "secret-token", refresh: "r", expires: 0, metadata: { orgID: "org_1" } }
  test("sends the console headers and parses the body", async () => {
    let seen: any
    const fake = (async (url: string, init: any) => {
      seen ??= { url, headers: init.headers }
      return new Response(JSON.stringify({ policies: [policy("all-service-accounts", 2, 20)] }))
    }) as any
    expect(await fetchBudget(credential, fake)).toEqual({ state: "ok", service: { spent: 2, limit: 20 } })
    expect(seen).toEqual({ url: "https://opencode.ai/console/api/policies", headers: {
      Authorization: "Bearer secret-token", Accept: "application/json", "User-Agent": "opencode", "x-org-id": "org_1" } })
  })
  test("adds the month's service-account calls and web searches", async () => {
    const urls: string[] = []
    const fake = (async (url: string) => {
      urls.push(url)
      const path = url.replace("https://opencode.ai/console/api/", "")
      if (path === "policies") return new Response(JSON.stringify({ policies: [policy("all-service-accounts", 0.14, 20)],
        serviceAccounts: [{ serviceAccountID: "svcacct_1", name: "opencode-premium" }] }))
      if (path.startsWith("usage/models")) return new Response(JSON.stringify({ items: [
        { provider: "opencode", model: "claude-opus-5-5", totalRequests: "3", totalCostMicroCents: "13961360" },
        { provider: "opencode", model: 1, totalRequests: "1", totalCostMicroCents: "1" }] }))
      if (path.includes("serviceAccountId")) return new Response(JSON.stringify({ totalRequests: "5", totalCostMicroCents: "14009774", services: [] }))
      return new Response(JSON.stringify({ totalRequests: "1258", totalCostMicroCents: "2578266423",
        services: [{ service: "web-search", totalRequests: "16", totalCostMicroCents: "16000000" }] }))
    }) as any
    expect(await fetchBudget(credential, fake, now)).toEqual({ state: "ok", service: { spent: 0.14, limit: 20 },
      calls: { count: 5, cost: 0.14009774, models: [{ model: "claude-opus-5-5", count: 3, cost: 0.1396136 }] },
      search: { count: 16, cost: 0.16 } })
    const since = "range=30d&since=2026-10-01T00%3A00%3A00.000Z"
    expect(urls.slice(1).sort()).toEqual([
      `https://opencode.ai/console/api/usage/models?${since}&page=1&pageSize=10&costOrder=desc&serviceAccountId=svcacct_1`,
      `https://opencode.ai/console/api/usage/summary?${since}`,
      `https://opencode.ai/console/api/usage/summary?${since}&serviceAccountId=svcacct_1`,
    ])
  })
  test("usage failures keep the budget", async () => {
    const fake = (async (url: string) => url.endsWith("/policies")
      ? new Response(JSON.stringify({ policies: [policy("all-service-accounts", 1, 20)], serviceAccounts: [{ serviceAccountID: "svcacct_1" }] }))
      : new Response("no", { status: 400 })) as any
    expect(await fetchBudget(credential, fake, now)).toEqual({ state: "ok", service: { spent: 1, limit: 20 } })
  })
  test("uses the login's server", async () => {
    let url = ""
    await fetchBudget({ ...credential, metadata: { server: "https://example.test/console/" } }, (async (u: string) => {
      url = u
      return new Response("{}")
    }) as any)
    expect(url).toBe("https://example.test/console/api/policies")
  })
  test("failures are reasons without the token", async () => {
    expect(await fetchBudget(credential, (async () => new Response("no", { status: 403 })) as any)).toEqual({ state: "unavailable", reason: "HTTP 403" })
    expect(await fetchBudget(credential, (async () => new Response("<html>")) as any)).toEqual({ state: "unavailable", reason: "request failed" })
    const leak = await fetchBudget(credential, (async () => { throw new Error("Bearer secret-token") }) as any)
    expect(JSON.stringify(leak)).not.toContain("secret-token")
    expect(await fetchBudget({ type: "key", key: "k" })).toEqual({ state: "unavailable", reason: "no console sign-in" })
    expect(await fetchBudget(undefined)).toEqual({ state: "unavailable", reason: "no console sign-in" })
  })
})

describe("server", () => {
  const dir = mkdtempSync(join(tmpdir(), "console-budget-"))
  afterAll(() => rmSync(dir, { recursive: true, force: true }))
  writeFileSync(join(dir, "fixture.ts"), "export const Plugin = { define: (value: any) => value }\n")
  const source = readFileSync(join(root, "server.ts"), "utf8")
    .replace(`from "@opencode/plugin"`, `from ${JSON.stringify(join(dir, "fixture.ts"))}`)
    .replace(`from "./budget.ts"`, `from ${JSON.stringify(join(root, "budget.ts"))}`)
  expect(source).not.toContain(`"@opencode/plugin"`)
  writeFileSync(join(dir, "server.ts"), source)

  const setup = async (active: () => Promise<any>, resolve: () => Promise<any>) => {
    const plugin = (await import(join(dir, `server.ts?${Math.random()}`))).default
    let handlers: any
    await plugin.setup({
      integration: { connection: { active, resolve } },
      rpc: { register: async (definition: any, value: any) => { expect(definition.id).toBe("yanosea.console-budget"); handlers = value } },
    })
    return handlers
  }
  test("reports a missing or broken sign-in", async () => {
    expect((await (await setup(async () => undefined, async () => undefined)).lines({})).lines[1]).toBe("unavailable (no console sign-in)")
    expect((await (await setup(async () => ({ type: "env", name: "X" }), async () => undefined)).lines({})).lines[1]).toBe("unavailable (no console sign-in)")
    expect((await (await setup(async () => { throw new Error("db") }, async () => undefined)).lines({})).lines[1]).toBe("unavailable (sign-in unreadable)")
  })
  test("shares one read a minute", async () => {
    let resolves = 0
    const handlers = await setup(async () => ({ type: "credential", id: "c" }), async () => { resolves++; return { type: "key", key: "k" } })
    await Promise.all([handlers.lines({}), handlers.lines({}), handlers.lines({})])
    expect(resolves).toBe(1)
  })
})
