// OpenCode 2.0.32 plugin. Runs the session-start chores of the other agent clis,
// detached, so a session never waits on them or sees their output.
import { Plugin } from "@opencode/plugin"
import { spawn } from "node:child_process"
import { existsSync, readFileSync } from "node:fs"
import { homedir } from "node:os"
import { join } from "node:path"

// agy skips its own hooks once ~30 plugins are loaded, so opencode runs these
export const SCRIPTS = [
  ".gemini/config/scripts/sync-mcp-servers.sh",
  ".gemini/config/scripts/sync-plugins.sh",
  ".gemini/config/scripts/save-settings.sh",
]
// the background service outlives sessions, so the first prompt of a session
// stands in for its start, and sessions close together share one run
export const INTERVAL = 10 * 60_000
export const LOCK = ".cache/agent-sync/run.lock"
// sync-plugins.sh leaves the plugins.conf review here; the service is long-lived,
// so each text reaches the agent once per process, not every session
export const NOTICE = ".cache/antigravity-plugin-sync/notice.txt"

// one shell runs the scripts in turn; a run already holding the lock (another
// opencode process) wins, and a lock left by a killed run expires in an hour.
// mkdir, not flock: macOS has no flock
const RUNNER = `lock=$1; shift
mkdir -p "$(dirname "$lock")" 2>/dev/null
[ -n "$(find "$lock" -maxdepth 0 -mmin +60 2>/dev/null)" ] && rmdir "$lock" 2>/dev/null
mkdir "$lock" 2>/dev/null || exit 0
trap 'rmdir "$lock" 2>/dev/null' EXIT
for script; do bash "$script" </dev/null >/dev/null 2>&1; done`

export function detached(lock: string, paths: string[]) {
  try {
    spawn("bash", ["-c", RUNNER, "agent-sync", lock, ...paths], { detached: true, stdio: "ignore" })
      .on("error", () => {})
      .unref()
  } catch {}
}

export function chores(run = detached, home = homedir(), now = Date.now) {
  const seen = new Set<string>()
  let last = -Infinity
  return (sessionID: string) => {
    if (seen.has(sessionID)) return
    seen.add(sessionID)
    if (now() - last < INTERVAL) return
    last = now()
    const paths = SCRIPTS.map((script) => join(home, script)).filter((path) => existsSync(path))
    if (paths.length) run(join(home, LOCK), paths)
  }
}

export function notices(home = homedir()) {
  const shown = new Set<string>()
  return (): string | undefined => {
    try {
      const text = readFileSync(join(home, NOTICE), "utf8").trim()
      if (!text || shown.has(text)) return
      shown.add(text)
      return text
    } catch {}
  }
}

export default Plugin.define({
  id: "agent-sync",
  async setup(ctx) {
    const start = chores()
    const notice = notices()
    await ctx.session.hook("prompt", (event) => {
      start(event.sessionID)
    })
    await ctx.session.hook("context", (event) => {
      const text = notice()
      if (text) event.system.push({ type: "text", text })
    })
  },
})
