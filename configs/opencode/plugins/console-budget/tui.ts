// OpenCode 2.0.32 TUI half: a sidebar block fed by server.ts over RPC. Written without JSX,
// in the compiled form opencode-quota 5.0.3 ships (dist/tui.js), so no Solid transform is needed.
import { Plugin } from "@opencode/plugin/tui"
import { createComponent, createElement, effect, insert, setProp } from "@opentui/solid"
import { createSignal, onCleanup } from "solid-js"
import { BudgetRpc } from "./budget.ts"

const REFRESH = 60_000
const TITLE = "[Premium (service account)]"

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

function BudgetView(props: { context: Plugin.Context; sessionID: string }) {
  const context = props.context
  const [lines, setLines] = createSignal<string[]>([TITLE, "loading"])
  let running = false
  const refresh = () => {
    if (running) return
    running = true
    context.client.rpc(BudgetRpc).lines({}, {
      location: context.location ?? context.data.location.default(),
      signal: AbortSignal.timeout(30_000),
    }).then((output: any) => {
      setLines(Array.isArray(output?.lines) && output.lines.every((x: unknown) => typeof x === "string")
        ? output.lines : [TITLE, "unavailable (bad rpc output)"])
    }, (error: unknown) => setLines([TITLE, `unavailable (${message(error)})`])).finally(() => { running = false })
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
    return context.ui.slot({
      append: "sidebar.content",
      // createComponent untracks the body, so a slot update does not rebuild the view.
      render: (input) => createComponent(BudgetView, { context, get sessionID() { return input.sessionID } }),
    })
  },
})
