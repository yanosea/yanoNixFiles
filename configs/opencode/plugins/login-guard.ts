// OpenCode 2.0.32 plugin: once per session, name the logins that no longer work.
// A notice is a courtesy, so every failure path stays silent instead of blocking the prompt.
import { Plugin } from "@opencode/plugin"

// EDIT ME: the integrations that should stay connected.
export const EXPECTED = ["firecrawl", "openai", "opencode", "opencode-premium", "tavily", "xai"]

// Integrations without a connection can still work from a variable the CLI reads
// itself: firecrawl has no env method, and its plugin falls back to process.env.
export const ENV_FALLBACK: Record<string, string> = { firecrawl: "FIRECRAWL_API_KEY" }

type Connection = { type: string; name?: string }

// Pure so the test can drive it without a host.
export async function unusable(
  active: (id: string) => Promise<Connection | undefined>,
  ids: readonly string[] = EXPECTED,
  env: Record<string, string | undefined> = process.env,
) {
  const dead: string[] = []
  for (const id of ids) {
    let connection: Connection | undefined
    try {
      connection = await active(id)
    } catch {
      connection = undefined
    }
    if (!connection) {
      const name = ENV_FALLBACK[id]
      if (!(name && env[name])) dead.push(`${id} not connected`)
    } else if (connection.type === "env" && !env[connection.name ?? ""]) {
      dead.push(`${id} ${connection.name} not set`)
    }
  }
  return dead
}

export default Plugin.define({
  id: "login-guard",
  async setup(ctx) {
    const seen = new Set<string>()
    await ctx.session.hook("prompt", async (event) => {
      // Claim the session before the first await: concurrent prompts must not both report.
      if (seen.has(event.sessionID)) return
      seen.add(event.sessionID)
      try {
        // Subagent sessions inherit the parent's credentials and never show quota notices either.
        if ((await ctx.session.get({ sessionID: event.sessionID })).parentID) return
        const dead = await unusable((id) => ctx.integration.connection.active(id))
        if (dead.length) {
          await ctx.session.synthetic({ sessionID: event.sessionID, resume: false, text: `login-guard: ${dead.join("; ")}` })
        }
      } catch {
        // A prompt hook failure would block the prompt; the notice is not worth that.
      }
    })
  },
})
