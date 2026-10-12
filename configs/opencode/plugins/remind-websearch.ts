// remind-websearch.ts - add the web search reminder to every model request.
// The text comes from configs/agents/hooks/remind-websearch.sh, the hook the other clis run per prompt.
import { execFileSync } from "node:child_process"
import { homedir } from "node:os"
import { join } from "node:path"

type Request = { system: { type: "text"; text: string }[] }
type Context = { session: { hook: (name: "context", callback: (event: Request) => void) => Promise<unknown> } }

export default {
  id: "remind-websearch",
  async setup(ctx: Context) {
    // the hook drains stdin, so close it with an empty input
    const stdout = execFileSync("bash", [join(homedir(), ".agents/hooks/remind-websearch.sh")], {
      encoding: "utf8",
      input: "",
    })
    const text: string = JSON.parse(stdout).hookSpecificOutput.additionalContext
    await ctx.session.hook("context", (event) => {
      event.system.push({ type: "text", text })
    })
  },
}
