-- Prompt for commit message generation
return {
	prompt = [[
Please write a commit message in English for these changes.
The title should be at most 50 characters, and the body should be wrapped at 72 characters.
For the title, use one of the following prefixes, separated from the title by a space:

- feat:
  - Use for new feature additions
- fix:
  - Use for bug fixes
- doc:
  - Use for documentation-only changes
- style:
  - Use for changes that do not affect program behavior (indentation adjustments, formatting, etc.)
- refactor:
  - Use for code modifications other than bug fixes or feature additions
- perf:
  - Use for code modifications aimed at performance improvements
- test:
  - Use for adding tests or modifying existing tests
- chore:
  - Use for changes to build process, auxiliary tools, or libraries
- merge:

In the body, list the changes as bullet points, each starting with "- ".
If the reason for the changes is not clear from looking at the source,
please ask questions before creating the commit message and include the answers in your considerations.

Please format your response as follows:

```
title:
<title>

body:
<body>
```

# IMPORTANT: Commit messages must be in English, but your reply must be in Japanese.
]],
}
