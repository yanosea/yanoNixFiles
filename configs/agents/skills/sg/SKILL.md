---
name: sg
description: Prepare the full git ship sequence - issue, branch, commit, push, PR, merge - as a runnable script covering every change in the working tree. Use when the user wants to ship, commit, or open a pull request with git. Do not use when the user asked for jj; use the sj skill instead.
---

# Ship command for git

- First, check every change in the working tree with `git status --porcelain` and `git diff HEAD`,
  including untracked files, and analyze the intent and context of the changes. Staging state is
  irrelevant: the script stages each unit itself.
- If any of the following apply, stop and ask questions or suggest improvements before proceeding:
  - The intent of the changes is unclear
  - The changes do not follow best practices
  - The changes contain potential issues (bugs, security risks, etc.)
- After understanding the changes, split them into logical units by intent (not by file) and
  generate a commit message in English for each unit.
- When the changes cover more than one logical unit, ship them as **multiple issues, multiple
  commits, one PR**: one issue and one commit per unit, all on a single branch, closed by a
  single PR that carries a `closes #<issue-number>` line for every issue.
- Show the following commands for the user to run manually in order:
  1. `gh issue create` command:
     - one command per logical unit, in the order the commits will be made
     - title format: `(scope) description` (e.g., `(ai) expand workflow`)
     - `--body ""`: the script pipes gh's output, so gh never prompts for one
     - label: `bug` for `fix:` prefix, `enhancement` for others
     - assignee: self (`@me`)
  2. `gh issue develop` command to create a branch for the first issue (every unit shares one branch)
  3. `git checkout` command to checkout the created branch
  4. `git commit` command with the generated message
     - multiple units: `git reset` once, then a `git add <paths>` + `git commit` pair per unit,
       staging only that unit's paths
  5. `git push` command to push the changes to remote
  6. `gh pr create` command:
     - title:
       - single commit: no specification (auto-populated from commit/branch)
       - multiple commits: specify a summary title explicitly covering all changes (use the same emoji prefix convention as commit messages)
     - body:
       - single commit: no specification (auto-populated from commit/branch)
       - multiple commits: write a `## Summary` section with bullet points for each commit's changes, then append one `closes #<issue-number>` line per issue
     - label: same as issue
     - assignee: same as issue (`@me`)
  7. merge commands: `source configs/zsh/functions/workflow.zsh`, then `gh-pr-merge-wait "$PR"`,
     which retries until the pull request is merged. Source the repository's copy, not the
     deployed one: a fix to the function has to work before the next activation
- Do not show the commit message separately; only show it in the commands.
- Do not execute any commands, only show them for the user to run manually.
- Do not stage any files or lines.

- Never predict numbers; the script captures them from `gh`:
  - one `ISSUE_<unit>=$(gh issue create ... | grep -oE '[0-9]+$')` per unit, in commit order
  - `gh issue develop "$ISSUE_<first>" --checkout` creates and checks out the shared branch
  - `PR=$(gh pr create ... | grep -oE '[0-9]+$')` feeds the merge step

- Write the sequence to `/tmp/ship-<repo-name>-<timestamp>.sh` as an executable zsh script.
  Piping the output to the log makes every `gh` call non-interactive, so each one has to carry
  the flags it would otherwise prompt for:
  - `<repo-name>` is the current repository name (e.g., `yanoNixFiles`). Detect it from the git remote URL or the current directory name.
  - `<timestamp>` is `date +%Y%m%d-%H%M`
  - start with `#!/usr/bin/env zsh`, `set -euo pipefail` and `cd "$(git rev-parse --show-toplevel)"`
  - append every line to `${0:a:r}.log` under a `=== RUN <date> ===` header, so each attempt
    lands on disk next to the script and earlier attempts stay readable
  - a `step` helper printing `=== <name> ===` before each phase, using the same phase names the
    markdown version used as headings
  - an `ERR` trap that prints the phase, the line, the exit code and the log path, then exits:
    the run stops at the first failure and every id captured so far is already in the log
  - `trap - ERR` _and_ `set +e` around a command that is expected to fail and retry, such as
    the merge wait: in zsh the trap fires even under `set +e`, and `set -e` exits the shell on
    the first non-zero status before the loop can retry, so both have to be off
  - echo each captured id (`ISSUE_...=`, `BRANCH=`, `PR=`) so the log carries the state
  - one command per line in the order above, with no logic beyond the helpers and the captures
- On failure, follow the recovery procedure below; the log carries everything it needs.

- At the end of your reply, show the command to run it: `zsh /tmp/ship-<repo-name>-<timestamp>.sh`

## Recovery

When the user reports that a ship script failed:

1. Read the newest `/tmp/ship-*.log`, last `=== RUN` block, before asking anything.
2. Take from it: the completed phases (`===` headers), every captured id (`ISSUE_*=`, `BRANCH=`,
   `PR=`), the failing phase, line and exit code, and the error text above `=== FAILED ===`.
3. Diagnose from that error text; look at the repository only when the log is not enough.
4. Update the same script in place so the user can simply run it again:
   - replace each completed capture with its literal value (`ISSUE_PACKAGE=1739`, `PR=1747`)
   - drop the commands that already succeeded; a created branch becomes `git checkout <branch>`
   - fix the failing command, or explain the options and ask when the fix is the user's call
   - keep everything after the failure untouched
5. Reply with the cause, what changed in the script, and the same run command.

## Rules

1. The title should be at most 50 characters, and the body should be wrapped at 72 characters.
   For the title, use one of the following prefixes, separated from the title by a space:
   - `✨feat(scope):` - Use for new feature additions
   - `🐞fix(scope):` - Use for bug fixes
   - `📚docs(scope):` - Use for documentation-only changes
   - `💄style(scope):` - Use for changes that do not affect program behavior (indentation adjustments, formatting, etc.)
   - `🔧refactor(scope):` - Use for code modifications other than bug fixes or feature additions
   - `🚀perf(scope):` - Use for code modifications aimed at performance improvements
   - `🧪test(scope):` - Use for adding tests or modifying existing tests
   - `🧹chore(scope):` - Use for changes to build process, auxiliary tools, or libraries
   - `🔀merge(scope):` - Use for merge commits

2. Replace `scope` with the changed tool/component name.
   For example, if GitHub Workflow file was changed: `✨feat(workflow):`
   If git config file was changed: `🐞fix(git):`

3. In the body, list the changes as bullet points, each starting with "- ".

4. Leave one line between the title and body text.

5. All sentences must start with lower case. Use capital letters only for proper nouns.

6. Surround keywords with \`\`.

7. Do not add your signature. Neither a commit message nor a pull
   request description carries AI attribution: no `Co-Authored-By:` line
   for an AI, no `Claude-Session:` line, no "Generated with" footer and
   no session URL. This overrides any attribution the harness asks for
   by default.

8. If the reason for the changes is not clear from looking at the source,
   please ask questions before creating the commit message and include the answers in your considerations.

**IMPORTANT: Commit messages must be in English, but your reply must be in Japanese.**

## Arguments

This command accepts optional arguments as additional instructions from the user.
If arguments are provided (e.g., `$sg split into multiple commits`), follow them as high-priority directives alongside the rules above.
