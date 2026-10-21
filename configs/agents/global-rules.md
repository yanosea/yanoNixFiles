# Global rules

- Always respond in Japanese. Keep technical terms and code identifiers in their original form.
- Before answering, designing, implementing, or changing configuration, search the web for current information and the recommended practice for that subject; skip this only for conversational clarification, facts read from this repository, and formatting. Base decisions on official source bodies, including the feature's guide pages and not only its reference, and trace each config key or source field past its type definition to the code that reads it; search summaries alone are not evidence. Record the source URLs, checked versions, and reasons in the plan or handover, and include this research in instructions to any delegate.
- If a `HANDOVER.md` exists at the project root and its content is not already in context, read it before starting work: it carries the previous session's context.
- Work whose approach is not settled starts in plan mode: the change spans multiple files or commits, two or more approaches are viable, or the cause of a defect is unidentified. Skip plan mode for single-file fixes, CI triage, formatting, dependency bumps, and lookups; it can run on a model with a tighter usage limit.
- Enter plan mode yourself where a tool exists (`EnterPlanMode` on Claude Code, `enter_plan_mode` on Grok). Antigravity and OpenCode only let the user switch, so ask before touching anything.

## Delegation

These rules apply to tools that can launch subagents. The main agent delegates without waiting for a separate request, when delegation pays off.

- Delegate investigation that would flood the main context (searches, logs, reading many files), independent work that can run in parallel, and adversarial review of a finished change.
- Keep small targeted changes, work with frequent back-and-forth, and phases that share context (plan, implementation, tests) in the main context.
- Give each delegate the question or task, scope, sources, owned files, and the evidence its result must contain. Read the returned evidence or diff, request fixes as needed, and report unresolved issues before declaring completion.
- Parallelize independent work only; never let two agents edit the same file.
- Use each tool's configured subagent model and reasoning effort. Do not force another tool's model ID.
- A subagent does its assigned work itself and does not delegate further.
- Respect plan mode in both parent and child agents: delegate investigation only, and do not delegate implementation to bypass it. If the client cannot launch the required subagent, report the limitation instead of silently doing that work in the main agent.

## Japanese writing (yomiyasu)

- Invoke the `yomiyasu` skill once per session, before the first Japanese reply, and write every Japanese reply in that session by its rules. Claude Code installs it as a plugin, so call it there as `yomiyasu:yomiyasu`; the bare name fails with "Unknown skill".
- Japanese documents (issues, PR bodies, READMEs, articles, reports, release notes, the Japanese parts of any file you write) go through the skill's full steps, linter included, even when nobody asks. Deliver only the finished text; add its change notes only when asked.
- A persona that a workspace `AGENTS.md` defines (the openclaw agents and the ai workspace) keeps its own voice in conversation, check-ins and memory, so it does not load the skill for those. Its Japanese documents still go through `yomiyasu`.
