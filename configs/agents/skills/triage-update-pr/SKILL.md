---
name: triage-update-pr
description: Triage a failing daily flake.lock auto-update PR (branch auto-update/flake-lock/<date>) - find the failing job, identify the root cause, check upstream nixpkgs, then comment in English and close or merge. Use when the user says today's auto-update PR or its CI failed.
---

# Triage the flake.lock auto-update PR

## 1. Find the PR and the runs that count

```bash
gh pr list --state open --json number,title,headRefName,createdAt
gh run list --limit 15 --json databaseId,name,status,conclusion,headBranch,event,createdAt
```

- The PR's own `pull_request` runs sit at `action_required`; ignore them. The updater tests the PR branch through `repository_dispatch` (`test-flake`), so the runs that count are listed under `main` and created at the same time.
- If all three test workflows passed and only `Auto Merge Dependency PR` failed, it is a timeout, not a breakage: say so and offer `gh pr merge <n> --merge`.

## 2. Extract the error

```bash
gh run view <run-id> --json jobs --jq '.jobs[]|"\(.name) \(.conclusion)"'
gh run view <run-id> --log-failed | sed 's/.*UNKNOWN STEP\t[^ ]* //' | grep -E -A8 'Cannot build|Failed tests|error:'
```

- Note the failing derivation name and its `/nix/store/<hash>-...drv` path.
- Check whether every host fails on the same derivation.

## 3. Decide whether it is upstream

- Read memory `ci-quality-backlog` and `ci-failure-triage-policy` before proposing any fix.
- Search upstream:

```bash
gh search issues --repo NixOS/nixpkgs "<package or failing test>" --json number,title,state,url
gh search prs --repo NixOS/nixpkgs "<package>" --json number,title,state,url
```

- If Hydra fails on the same `.drv` hash, the failure is upstream and there is no cached binary.
- For a merged fix, compare its merge time with the pinned `nixpkgs` rev from `gh pr diff <n>`. If the fix is newer than the rev, it has not reached the channel yet.
- Upstream breakage is never patched locally (no overlays, no pins). Wait for a later auto-update.

## 4. Comment and close

Write the comment in English to a scratchpad file and pass it with `--body-file`, so backticks are not escaped:

```bash
gh pr comment <n> --body-file <file>
gh pr close <n> --delete-branch
```

The comment covers:

- which workflow and jobs fail, with the failing derivation and a short log excerpt in a code block
- why it is upstream: the Hydra `.drv` match, the upstream issue link, and the fix PR with its state or merge time
- the `nixpkgs` rev bump (`old` → `new`) and which workflows passed
- closing without a local patch, and what will unblock the next auto-update

Past examples: #1640, #1643, #1646, #1717.

## 5. Report

Reply in Japanese with the cause, the upstream links, and the closed PR.
