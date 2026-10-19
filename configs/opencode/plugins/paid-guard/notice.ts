// Shared by tui.ts and the tests. Plain functions only.

// The TUI permission prompt ignores a request's message (opencode 2.0.32
// packages/tui/src/util/permission.ts), so tui.ts shows the one server.ts writes.
export function notices(requests: ReadonlyArray<unknown>) {
  return requests.flatMap((request: any) =>
    request?.action === "subagent" && typeof request.message === "string" && request.message.trim()
      ? [{ id: String(request.id), lines: request.message.trim().split("\n") }]
      : [])
}
