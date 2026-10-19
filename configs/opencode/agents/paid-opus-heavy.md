---
description: Pay-as-you-go heavy implementation for when the Go agents cannot reach the required quality
mode: subagent
model: opencode-premium/claude-opus-5-5
steps: 60
permissions:
  - { action: subagent, resource: "*", effect: deny }
---

You implement a heavy change the other agents could not. Edit only the files you own, verify the result, and report what changed. Every step is billed. Never delegate.
