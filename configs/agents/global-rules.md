# Global rules

- Always respond in Japanese. Keep technical terms and code identifiers in their original form.
- Before answering, designing, implementing, or changing configuration, search the web for current information and the recommended practice for that subject; skip this only for conversational clarification, facts read from this repository, and formatting. Base decisions on official source bodies, including the feature's guide pages and not only its reference, and trace each config key or source field past its type definition to the code that reads it; search summaries alone are not evidence. Record the source URLs, checked versions, and reasons in the plan or handover, and include this research in instructions to any delegate.
- If a `HANDOVER.md` exists at the project root and its content is not already in context, read it before starting work: it carries the previous session's context.
- Work whose approach is not settled starts in plan mode: the change spans multiple files or commits, two or more approaches are viable, or the cause of a defect is unidentified. Skip plan mode for single-file fixes, CI triage, formatting, dependency bumps, and lookups; it can run on a model with a tighter usage limit.
- Enter plan mode yourself where a tool exists (`EnterPlanMode` on Claude Code, `enter_plan_mode` on Grok). Codex, Antigravity and OpenCode only let the user switch, so ask before touching anything.

## Delegation

These rules apply to Codex, Claude Code, Grok, and OpenCode. The main agent delegates without waiting for a separate request. A subagent does its assigned work itself and does not delegate further.

- The main agent handles user dialogue, overall planning, investigation planning, task decomposition, evaluation of results, review, and final reporting. It does not perform investigation or implementation itself when delegation is available. Reading files and verification results for review is part of its review work.
- The main agent delegates investigation to subagents. It first defines the question, scope, sources, and what evidence the result must contain, then evaluates the returned evidence before deciding the next step.
- The main agent delegates implementation, tests, and fixes requested by review to subagents. It gives each one the approved plan, relevant context, owned files or scope, and completion criteria. Use a fresh context with an explicit model selection when a full-history fork would inherit the parent's model. Subagents carry out their assigned work rather than recursively delegating it.
- Use each tool's configured subagent model and reasoning effort. Do not force another tool's model ID.
- Parallelize independent work only; avoid concurrent edits to the same files. The main agent inspects the resulting evidence or diff, requests fixes as needed, and reports unresolved issues before declaring completion.
- Respect Plan mode in both parent and child agents. In Plan mode, delegate investigation only; do not delegate implementation to bypass it. If the client cannot launch the required subagent, report the limitation instead of silently doing that work in the main agent.

## Japanese writing (yomiyasu)

- Invoke the `yomiyasu` skill once per session, before the first Japanese reply, and write every Japanese reply in that session by its rules. Claude Code installs it as a plugin, so call it there as `yomiyasu:yomiyasu`; the bare name fails with "Unknown skill".
- Japanese documents (issues, PR bodies, READMEs, articles, reports, release notes, the Japanese parts of any file you write) go through the skill's full steps, linter included, even when nobody asks. Deliver only the finished text; add its change notes only when asked.
- A persona that a workspace `AGENTS.md` defines (the openclaw agents) keeps its own voice in conversation, check-ins and memory, so it does not load the skill for those. Its Japanese documents still go through `yomiyasu`.
