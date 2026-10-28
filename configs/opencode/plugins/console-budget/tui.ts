// OpenCode 2.0.32 TUI half: two sidebar blocks fed by server.ts over RPC. Written without JSX,
// in the compiled form opencode-quota 5.0.3 ships (dist/tui.js), so no Solid transform is needed.
import { Plugin } from "@opencode/plugin/tui"
import { createComponent, createElement, effect, insert, setProp } from "@opentui/solid"
import { createSignal, onCleanup } from "solid-js"
import { BudgetRpc, SEARCH_TITLE } from "./budget.ts"

const REFRESH = 60_000
const PREMIUM = "[Premium (service account)]"
type Part = "premium" | "search"
const title = (part: Part) => part === "premium" ? PREMIUM : SEARCH_TITLE

function message(error: unknown) {
  const type = (error as any)?.type
  if (type === "rpc.unavailable") return "server plugin not loaded"
  return typeof type === "string" ? type : "rpc failed"
}

function text(context: Plugin.Context, line: string, bold: boolean) {
  const node = createElement("text")
  setProp(node, "wrapMode", "none")
  if (bold) {
    const b = createElement("b")
    insert(b, line)
    insert(node, b)
  } else insert(node, line || " ")
  effect((previous: unknown) => setProp(node, "fg", bold ? context.theme.text.base : context.theme.text.muted, previous))
  return node
}

// formatBudget returns both blocks in one list; the sidebar shows them apart.
function split(lines: string[], part: Part) {
  const at = lines.indexOf(SEARCH_TITLE)
  if (at < 0) return part === "premium" ? lines : []
  return part === "premium" ? trimEnd(lines.slice(0, at)) : lines.slice(at)
}

function trimEnd(lines: string[]) {
  let end = lines.length
  while (end > 0 && lines[end - 1] === "") end--
  return lines.slice(0, end)
}

function BudgetView(props: { context: Plugin.Context; sessionID: string; part: Part }) {
  const context = props.context
  const [lines, setLines] = createSignal<string[]>([title(props.part), "loading"])
  let running = false
  const refresh = () => {
    if (running) return
    running = true
    context.client.rpc(BudgetRpc).lines({}, {
      location: context.location ?? context.data.location.default(),
      signal: AbortSignal.timeout(30_000),
    }).then((output: any) => {
      setLines(Array.isArray(output?.lines) && output.lines.every((x: unknown) => typeof x === "string")
        ? split(output.lines, props.part) : [title(props.part), "unavailable (bad rpc output)"])
    }, (error: unknown) => setLines([title(props.part), `unavailable (${message(error)})`])).finally(() => { running = false })
  }
  refresh()
  const interval = setInterval(refresh, REFRESH)
  // The server caches for a minute, so idles in a busy session cost nothing extra.
  const stop = context.data.on("session.execution.succeeded", (event: any) => {
    if (event.data?.sessionID === props.sessionID) refresh()
  })
  onCleanup(() => {
    clearInterval(interval)
    stop()
  })
  const box = createElement("box")
  setProp(box, "flexDirection", "column")
  insert(box, () => lines().map((line) => text(context, line, line.startsWith("["))))
  return box
}

export default Plugin.define({
  id: "console-budget",
  setup(context) {
    // createComponent untracks the body, so a slot update does not rebuild the view.
    const view = (part: Part) => (input: { sessionID: string }) =>
      createComponent(BudgetView, { context, get sessionID() { return input.sessionID }, part })
    // Both blocks sit after the host content, so hosted search lands right under
    // Premium instead of below the footer's path line.
    const premium = context.ui.slot({ after: "sidebar.content", render: view("premium") })
    const search = context.ui.slot({ after: "sidebar.content", render: view("search") })
    return () => {
      premium?.()
      search?.()
    }
  },
})
