# Planning and delegation

The primary agent (opencode's manager, openclaw's main and dev) applies these rules. They come before any other guidance about planning or delegation, including the delegation section and the plan-mode exclusions in `AGENTS.md`. A subagent or helper does the work itself and reads the last section instead.

## Plan before you edit

Planning applies whenever the change touches two or more files or commits, two or more approaches are viable, or the cause of a defect is unknown. Small files and an easy-looking task do not exempt it.

Skip planning only for a single-file fix, CI triage, formatting, a dependency bump and a lookup. When planning applies, hand it to `planner` with the findings and the answers the user gave. Do not design the plan yourself.

## Use each agent (mandatory)

A matching condition means use that agent. If a condition matched and you did not use it, add one line to your report: `未使用 <agent>: <reason>`. In openclaw the helper carries your agent's prefix (`main-explore`, `dev-planner`); in opencode use the bare role name.

- **explore** (read-only research): a question needs three or more file reads, or a repository-wide grep or glob, or the output would flood your context. One targeted read or a search you can run yourself does not match.
- **planner** (read-only planning): planning applies, as defined above.
- **worker** (isolated implementation): an independent edit with a clear contract (task, owned files, expected evidence) that can run in parallel with other work, or that would flood your context.
- **smart** (hard design and debugging): the cause of a defect is unknown, or the design needs deeper reasoning than a straight edit.
- **reviewer** (independent review): every change before you report it done, single-file fixes and doc, config and refactor changes included. Give it the task, the changed files and the command output you verified. Skip it only when you changed no file or the user told you to. Never send a review to a paid agent, even when `reviewer` falls short.

Call independent reads, searches and agents together in one turn, not one per turn. Never let two agents edit the same file.

## Delegate correctly

Keep small, sequential and shared-context work yourself, including small edits. Parallelize independent work only. Give each agent a clear contract: the task, scope, owned files and the evidence its result must contain. Verify every result before you rely on it or report it.

Fix what the review finds. A finding you decide not to fix stays in the report as unresolved and does not start another round. When `reviewer` cannot run, say so and never call the change reviewed.

## If you are a subagent

Do the assigned work yourself. Never launch another agent, edit only the files you own, and report with the evidence you were asked for. The conditions above are for the agent that delegated to you.
