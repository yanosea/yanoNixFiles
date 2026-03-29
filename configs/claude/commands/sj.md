# Ship command for jj (Jujutsu)

- First, check the current working copy changes using `git diff` and analyze the intent and context of the changes.
- If any of the following apply, stop and ask questions or suggest improvements before proceeding:
  - The intent of the changes is unclear
  - The changes do not follow best practices
  - The changes contain potential issues (bugs, security risks, etc.)
- After understanding the changes, generate a commit message in English.

- Show the following commands for the user to run manually in order:
  1. `gh issue create` command:
     - title format: `(scope) description` (e.g., `(ai) expand workflow`)
     - no body
     - label: `bug` for `fix:` prefix, `enhancement` for others
     - assignee: self (`@me`)
  2. `nix fmt` command to format files
  3. `jj describe` command with the generated message
  4. `jj bookmark create` command to create a bookmark matching `gh issue develop` default format:
     - format: `<issue-number>-<issue-title-in-kebab-case>` (e.g., `1154-hypr-migrate-windowrulev2-to-new-windowrule-syntax`)
  5. `jj git push` command to push the changes to remote with `-b <bookmark> --allow-new`
  6. `gh pr create` command:
     - **IMPORTANT: use `--head <bookmark>` flag** (jj does not use git branches, so branch detection fails without this)
     - title:
       - single commit: use `$(git log <bookmark> -1 --format='%s')` to extract from commit (must specify bookmark name, not `-1` alone, because jj uses detached HEAD)
       - multiple commits: specify a summary title explicitly covering all changes (use the same emoji prefix convention as commit messages)
     - body:
       - single commit: use `$(printf '%s\n\ncloses #<issue-number>' "$(git log <bookmark> -1 --format='%b')")` to extract from commit and append closes
       - multiple commits: write a `## Summary` section with bullet points for each commit's changes, then append `closes #<issue-number>`
     - label: same as issue
     - assignee: same as issue (`@me`)
  7. `gh pr merge <pr-number>` command to merge the pull request
  8. cleanup commands:
     - `jj git fetch && jj rebase -d main && jj bookmark delete <bookmark>`

- Do not show the commit message separately; only show it in the commands.

- Do not execute any commands, only show them for the user to run manually.

- When you need to check diffs, status, or logs, use `git` commands instead of `jj` commands.
  jj operations may require GPG signing which is not available in this environment.
  - Use `git diff` instead of `jj diff`
  - Use `git status` instead of `jj status`
  - Use `git log` instead of `jj log`

- Predict the issue number and PR number using `gh`:
  - Get the latest number: `gh pr list --state all --limit 1 --json number --jq '.[0].number'`
  - The next issue number = latest + 1, PR number = latest + 2
  - Use the predicted numbers directly in all commands (no variables or placeholders)

- Write all commands to `/tmp/ship-<repo-name>-<issue-number>.md` as a markdown file with the following format:
  - `<repo-name>` is the current repository name (e.g., `yanoNixFiles`). Detect it from the git remote URL or the current directory name.
  - Use `# Ship #<issue-number>` as the document title
  - Group each step with a `##` heading (e.g., `## Issue`, `## Format`, `## Commit`, `## Branch`, `## Push`, `## PR`, `## Merge`, `## Cleanup`)
  - Wrap each command in a ```bash code block
  - No shebang, no variables, no script logic

- At the end of your reply, show the output file path: `/tmp/ship-<repo-name>-<issue-number>.md`

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
   If jj config file was changed: `🐞fix(jj):`

3. In the body, list the changes as bullet points, each starting with "- ".

4. Leave one line between the title and body text.

5. All sentences must start with lower case. Use capital letters only for proper nouns.

6. Surround keywords with \`\`.

7. Do not add your signature.

8. If the reason for the changes is not clear from looking at the source,
   please ask questions before creating the commit message and include the answers in your considerations.

**IMPORTANT: Commit messages must be in English, but your reply must be in Japanese.**

## Arguments

This command accepts optional arguments as additional instructions from the user.
If arguments are provided (e.g., `/sj split into multiple commits`), follow them as high-priority directives alongside the rules above.
