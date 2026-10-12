// handover.ts - load HANDOVER.md into every request and drop a placeholder before compaction.
// The placeholder comes from configs/agents/hooks/generate-handover.sh, the hook the other clis run.
import { execFile } from "node:child_process"
import { readFile } from "node:fs/promises"
import { homedir } from "node:os"
import { join } from "node:path"

type Session = { location: { directory: string } }
type Request = { sessionID: string; system: { type: "text"; text: string }[] }
type Context = {
  session: {
    get: (input: { sessionID: string }) => Promise<Session>
    hook: (name: "context" | "compaction", callback: (event: Request) => Promise<void>) => Promise<unknown>
  }
}

export default {
  id: "handover",
  async setup(ctx: Context) {
    // a background service serves many projects, so ask the session where it runs
    const directory = async (sessionID: string) => (await ctx.session.get({ sessionID })).location.directory

    // v2 accepts but ignores `instructions`, so the handover goes in here
    await ctx.session.hook("context", async (event) => {
      const text = await readFile(join(await directory(event.sessionID), "HANDOVER.md"), "utf8").catch(() => "")
      if (text) event.system.push({ type: "text", text })
    })

    await ctx.session.hook("compaction", async (event) => {
      const input = JSON.stringify({
        cwd: await directory(event.sessionID),
        session_id: event.sessionID,
        trigger: "compaction",
      })
      await new Promise<void>((resolve) => {
        const child = execFile("bash", [join(homedir(), ".agents/hooks/generate-handover.sh")], () => resolve())
        child.stdin?.end(input)
      })
    })
  },
}
