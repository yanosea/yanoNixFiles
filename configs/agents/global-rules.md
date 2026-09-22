# Global rules

- Always respond in Japanese. Keep technical terms and code identifiers in their original form.
- If a task touches library/API versions, tool behavior, pricing, or best practices that may have changed since training, search the web before answering. Do not rely on training-data memory for anything time-sensitive.
- If a `HANDOVER.md` exists at the project root and its content is not already in context, read it before starting work: it carries the previous session's context.
- Work whose approach is not settled starts in plan mode: the change spans multiple files or commits, two or more approaches are viable, or the cause of a defect is unidentified. Skip plan mode for single-file fixes, CI triage, formatting, dependency bumps, and lookups; it can run on a model with a tighter usage limit.
- Enter plan mode yourself where a tool exists (`EnterPlanMode` on Claude Code, `enter_plan_mode` on Grok). Codex and Antigravity only let the user switch, so ask before touching anything.
