// OpenCode 2.0.32 TUI half: puts the paid-guard text above the permission prompt. Written
// without JSX, like console-budget/tui.ts, so no Solid transform is needed.
import { Plugin } from "@opencode/plugin/tui"
import { createComponent, createElement, effect, insert, setProp } from "@opentui/solid"
import { notices } from "./notice.ts"

function text(context: Plugin.Context, line: string, color: (theme: any) => unknown) {
  const node = createElement("text")
  insert(node, line || " ")
  effect((previous: unknown) => setProp(node, "fg", color(context.theme), previous))
  return node
}

// Only the first pending request is prompted, so only its text is shown. Children ask
// through the root session's prompt, as routes/session/index.tsx collects them.
function NoticeView(props: { context: Plugin.Context; sessionID: string }) {
  const data = props.context.data
  const box = createElement("box")
  setProp(box, "flexDirection", "column")
  setProp(box, "paddingLeft", 2)
  insert(box, () => {
    if (data.session.get(props.sessionID)?.parentID) return []
    const family = [props.sessionID, ...data.session.family(props.sessionID).filter((id: string) => id !== props.sessionID)]
    const pending = family.flatMap((id: string) => data.session.permission.list(id) ?? [])
    const first = notices(pending.slice(0, 1))[0]
    if (!first) return []
    return first.lines.map((line, index) => text(props.context, line,
      (theme) => index === 0 ? theme.text.feedback.warning.base : theme.text.base))
  })
  return box
}

export default Plugin.define({
  id: "paid-guard.tui",
  setup(context) {
    return context.ui.slot({
      append: "session.composer.top",
      render: (input) => createComponent(NoticeView, { context, get sessionID() { return input.sessionID } }),
    })
  },
})
