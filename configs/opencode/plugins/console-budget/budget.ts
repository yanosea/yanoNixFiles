// Shared by server.ts and tui.ts. Plain functions only, so tests can import it.

// Undocumented Console route, same family opencode-quota reads (billing/status).
export const CONSOLE = "https://opencode.ai/console"
export const INTEGRATION = "opencode"

type Rule = { limit: number; spent: number }
type Usage = { count: number; cost: number }
type Model = Usage & { model: string }
// calls and search stay unset when the usage routes fail, so the budget rows still show.
export type Budget =
  | { state: "ok"; service: Rule; workspace?: Rule; calls?: Usage & { models: Model[] }; search?: Usage }
  | { state: "unavailable"; reason: string }

const MONTHS = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
const money = (value: number) => `$${value.toFixed(2)}`
const percent = (rule: Rule) => `${(rule.spent / rule.limit * 100).toFixed(1)}%`

function rule(policy: any): Rule | undefined {
  const found = Array.isArray(policy?.rules)
    ? policy.rules.find((item: any) => item?.kind === "budget" && (item.period ?? "month") === "month")
    : undefined
  const limit = found?.limitDollars, spent = found?.spentDollars
  if (typeof limit !== "number" || typeof spent !== "number" || !(limit > 0) || !(spent >= 0)) return undefined
  return { limit, spent }
}

export function parsePolicies(body: unknown): Budget {
  const policies = (body as any)?.policies
  if (!Array.isArray(policies)) return { state: "unavailable", reason: "unexpected response" }
  const mode = (policy: any) => policy?.audience?.mode
  const service = policies.find((policy) => mode(policy) === "all-service-accounts" && rule(policy))
    ?? policies.find((policy) => policy?.serviceAccountCount > 0 && rule(policy))
  if (!service) return { state: "unavailable", reason: "no service-account budget" }
  const workspace = policies.find((policy) => mode(policy) === "workspace" && rule(policy))
  return { state: "ok", service: rule(service)!, ...(workspace ? { workspace: rule(workspace) } : {}) }
}

// usage/* counts are decimal strings and costs microcents, $1 = 1e8 (opencode-quota 5.0.3
// lib/opencode-zen.js).
const count = (value: unknown) => typeof value === "string" && /^\d+$/.test(value) ? Number(value) : undefined
const usage = (item: any): Usage | undefined => {
  const requests = count(item?.totalRequests), micro = count(item?.totalCostMicroCents)
  return requests === undefined || micro === undefined ? undefined : { count: requests, cost: micro / 1e8 }
}

// usage/summary: totals, with web search under services[].
export function parseSummary(body: unknown) {
  const total = usage(body)
  if (!total) return undefined
  const services = (body as any)?.services
  const search = Array.isArray(services) ? services.find((item: any) => item?.service === "web-search") : undefined
  return { ...total, search: search ? usage(search) : { count: 0, cost: 0 } }
}

// usage/models: items[] already sorted by cost.
export function parseModels(body: unknown): Model[] | undefined {
  const items = (body as any)?.items
  if (!Array.isArray(items)) return undefined
  return items.flatMap((item: any) => {
    const value = usage(item)
    return value && typeof item?.model === "string" ? [{ model: item.model, ...value }] : []
  })
}

// Console budgets reset at 00:00 UTC on the 1st.
export function resetDate(now: Date) {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1))
}

export const SEARCH_TITLE = "[Hosted Web Search]"

// The sidebar is 42 columns with padding, so rows stay under 38.
export function formatBudget(budget: Budget, now: Date) {
  const title = "[Premium (service account)]"
  if (budget.state !== "ok") return [title, `unavailable (${budget.reason})`]
  const row = (label: string, value: Rule) => `${label.padEnd(10)}${money(value.spent)} / ${money(value.limit)} (${percent(value)})`
  const spend = (value?: Usage) => value ? `${value.count} (${money(value.cost)})` : "unavailable"
  const reset = resetDate(now)
  return [
    title,
    row("Budget", budget.service),
    `${"Calls".padEnd(10)}${spend(budget.calls)}`,
    ...(budget.calls?.models ?? []).slice(0, 3).map((item) =>
      `  ${item.model.replace(/^claude-/, "").slice(0, 16).padEnd(17)}${item.count} ${money(item.cost)}`),
    `${"Resets".padEnd(10)}${MONTHS[reset.getUTCMonth()]} ${reset.getUTCDate()} (UTC)`,
    ...(budget.workspace ? [row("Workspace", budget.workspace)] : []),
    "",
    SEARCH_TITLE,
    `${"Searches".padEnd(10)}${spend(budget.search)}`,
  ]
}

// Same headers as opencode-quota 5.0.3 lib/opencode-console-auth.js consoleHeaders. Cloudflare
// rejects some user agents with error 1010, so name one.
class HttpError extends Error {
  constructor(readonly status: number) {
    super(`HTTP ${status}`)
  }
}

export async function fetchBudget(credential: any, request: typeof fetch = fetch, now = new Date()): Promise<Budget> {
  if (credential?.type !== "oauth" || typeof credential.access !== "string" || !credential.access) {
    return { state: "unavailable", reason: "no console sign-in" }
  }
  const metadata = credential.metadata ?? {}
  const base = typeof metadata.server === "string" && metadata.server ? metadata.server : CONSOLE
  const get = async (path: string) => {
    const response = await request(`${base.replace(/\/+$/, "")}/api/${path}`, {
      headers: {
        Authorization: `Bearer ${credential.access}`,
        Accept: "application/json",
        "User-Agent": "opencode",
        ...(typeof metadata.orgID === "string" ? { "x-org-id": metadata.orgID } : {}),
      },
      signal: AbortSignal.timeout(15_000),
    })
    if (!response.ok) throw new HttpError(response.status)
    return response.json()
  }
  let body: unknown
  try {
    body = await get("policies")
  } catch (error) {
    if (error instanceof HttpError) return { state: "unavailable", reason: error.message }
    // Name only: a message could echo the request.
    return { state: "unavailable", reason: error instanceof Error && error.name === "TimeoutError" ? "timeout" : "request failed" }
  }
  const budget = parsePolicies(body)
  if (budget.state !== "ok") return budget
  // The routes the Console Overview reads; since narrows them to this budget month.
  const month = `range=30d&since=${encodeURIComponent(new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth(), 1)).toISOString())}`
  const account = (body as any)?.serviceAccounts?.[0]?.serviceAccountID
  const service = typeof account === "string" ? `&serviceAccountId=${encodeURIComponent(account)}` : undefined
  const [all, calls, models] = await Promise.all([
    get(`usage/summary?${month}`).then(parseSummary, () => undefined),
    service ? get(`usage/summary?${month}${service}`).then(parseSummary, () => undefined) : undefined,
    service ? get(`usage/models?${month}&page=1&pageSize=10&costOrder=desc${service}`).then(parseModels, () => undefined) : undefined,
  ])
  return {
    ...budget,
    ...(calls ? { calls: { count: calls.count, cost: calls.cost, models: models ?? [] } } : {}),
    ...(all?.search ? { search: all.search } : {}),
  }
}

// A Standard Schema that passes the value through, like opencode-quota's rpc.js.
const object = {
  "~standard": {
    version: 1 as const,
    vendor: "console-budget",
    validate: (value: unknown) => value && typeof value === "object" && !Array.isArray(value)
      ? { value: value as Record<string, unknown> }
      : { issues: [{ message: "must be an object" }] },
  },
}
export const BudgetRpc = {
  id: "yanosea.console-budget",
  events: {},
  methods: { lines: { input: object, output: object } },
}
