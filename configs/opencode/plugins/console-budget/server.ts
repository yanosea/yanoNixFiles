// OpenCode 2.0.32 server half. Only the server can read logins (the TUI binds none, see
// opencode-quota 5.0.3 lib/opencode-auth.js), so the TUI asks here over RPC.
import { Plugin } from "@opencode/plugin"
import { BudgetRpc, fetchBudget, formatBudget, INTEGRATION, type Budget } from "./budget.ts"

// Every sidebar shares one Console read a minute.
const TTL = 60_000

export default Plugin.define({
  id: "console-budget.server",
  async setup(ctx) {
    let cached: { at: number; value: Promise<Budget> } | undefined
    const read = async (): Promise<Budget> => {
      try {
        const connection = await ctx.integration.connection.active(INTEGRATION)
        if (connection?.type !== "credential") return { state: "unavailable", reason: "no console sign-in" }
        // resolve() refreshes a token within five minutes of expiry.
        return await fetchBudget(await ctx.integration.connection.resolve(connection))
      } catch {
        return { state: "unavailable", reason: "sign-in unreadable" }
      }
    }
    // Awaited so the RPC exists before the TUI's first call is routed.
    await ctx.rpc.register(BudgetRpc, {
      lines: async () => {
        if (!cached || Date.now() - cached.at >= TTL) cached = { at: Date.now(), value: read() }
        return { lines: formatBudget(await cached.value, new Date()) }
      },
    })
  },
})
