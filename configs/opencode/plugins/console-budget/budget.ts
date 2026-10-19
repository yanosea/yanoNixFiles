// Shared by server.ts and tui.ts. Plain functions only, so tests can import it.

// Undocumented Console route, same family opencode-quota reads (billing/status).
export const CONSOLE = "https://opencode.ai/console"
export const INTEGRATION = "opencode"

type Rule = { limit: number; spent: number }
export type Budget =
  | { state: "ok"; service: Rule; workspace?: Rule }
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

// Console budgets reset at 00:00 UTC on the 1st.
export function resetDate(now: Date) {
  return new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth() + 1, 1))
}

// The sidebar is 42 columns with padding, so rows stay under 38.
export function formatBudget(budget: Budget, now: Date) {
  const title = "[Premium (service account)]"
  if (budget.state !== "ok") return [title, `unavailable (${budget.reason})`]
  const row = (label: string, value: Rule) => `${label.padEnd(10)}${money(value.spent)} / ${money(value.limit)} (${percent(value)})`
  const reset = resetDate(now)
  return [
    title,
    row("Budget", budget.service),
    `${"Resets".padEnd(10)}${MONTHS[reset.getUTCMonth()]} ${reset.getUTCDate()} (UTC)`,
    ...(budget.workspace ? [row("Workspace", budget.workspace)] : []),
  ]
}

// Same headers as opencode-quota 5.0.3 lib/opencode-console-auth.js consoleHeaders. Cloudflare
// rejects some user agents with error 1010, so name one.
export async function fetchBudget(credential: any, request: typeof fetch = fetch): Promise<Budget> {
  if (credential?.type !== "oauth" || typeof credential.access !== "string" || !credential.access) {
    return { state: "unavailable", reason: "no console sign-in" }
  }
  const metadata = credential.metadata ?? {}
  const base = typeof metadata.server === "string" && metadata.server ? metadata.server : CONSOLE
  try {
    const response = await request(`${base.replace(/\/+$/, "")}/api/policies`, {
      headers: {
        Authorization: `Bearer ${credential.access}`,
        Accept: "application/json",
        "User-Agent": "opencode",
        ...(typeof metadata.orgID === "string" ? { "x-org-id": metadata.orgID } : {}),
      },
      signal: AbortSignal.timeout(15_000),
    })
    if (!response.ok) return { state: "unavailable", reason: `HTTP ${response.status}` }
    return parsePolicies(await response.json())
  } catch (error) {
    // Name only: a message could echo the request.
    return { state: "unavailable", reason: error instanceof Error && error.name === "TimeoutError" ? "timeout" : "request failed" }
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
