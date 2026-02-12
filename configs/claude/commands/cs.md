# Commit staged command

- Please generate a commit message in English for these staged changes.
- Show the following commands for the user to run manually in order:
  1. `gh issue create` command:
     - title format: `(scope) description` (e.g., `(ai) expand workflow`)
     - no body
     - label: `bug` for `fix:` prefix, `enhancement` for others
     - assignee: self (`@me`)
  2. `gh issue develop` command to create a branch for the issue
  3. `git checkout` command to checkout the created branch
  4. `git commit` command with the generated message
  5. `git push` command to push the changes to remote
  6. `gh pr create` command:
     - no title/body specification (auto-populated from commit/branch)
     - label: same as issue
     - assignee: same as issue (`@me`)
  7. `gh pr merge` command to merge the pull request
- Do not show the commit message separately; only show it in the commands.
- Do not execute any commands, only show them for the user to run manually.
- Do not stage any files or lines.

- Predict the issue number using `gh`:
  - Get the latest number: `gh pr list --state all --limit 1 --json number --jq '.[0].number'`
  - The next issue number = latest + 1
  - Use the predicted number directly in all commands (no variables or placeholders)

- Write all commands to `/tmp/commit-<issue-number>` as a plain text file for copy-paste (no shebang, no variables, no script logic)

- At the end of your reply, show the output file path: `/tmp/commit-<issue-number>`

## Rules

1. The title should be at most 50 characters, and the body should be wrapped at 72 characters.
   For the title, use one of the following prefixes, separated from the title by a space:
   - `feat:` - Use for new feature additions
   - `fix:` - Use for bug fixes
   - `docs:` - Use for documentation-only changes
   - `style:` - Use for changes that do not affect program behavior (indentation adjustments, formatting, etc.)
   - `refactor:` - Use for code modifications other than bug fixes or feature additions
   - `perf:` - Use for code modifications aimed at performance improvements
   - `test:` - Use for adding tests or modifying existing tests
   - `chore:` - Use for changes to build process, auxiliary tools, or libraries
   - `merge:` - Use for merge commits

2. Add () after prefix and full it with the changed tool.
   For example, if GitHub Workflow file was changed: (workflow)
   If git config file was changed: (git)

3. In the body, list the changes as bullet points, each starting with "- ".

4. Leave one line between the title and body text.

5. All sentences must start with lower case. Use capital letters only for proper nouns.

6. Surround keywords with \`\`.

7. Do not add your signature.

8. If the reason for the changes is not clear from looking at the source,
   please ask questions before creating the commit message and include the answers in your considerations.

**IMPORTANT: Commit messages must be in English, but your reply must be in Japanese.**
