---
name: code-review
description: Use when a diff is ready to review, on the engineer's machine or in the GitHub Actions job.
---

Start the read-only `code-reviewer` subagent (`.claude/agents/code-reviewer.md`)
and give it the diff, `CLAUDE.md`, and the `docs/decisions/*.md` files the
changed paths touch. It applies the checklist in that agent file and returns
Blocking / Questions / Not reviewed.

- **On a laptop**: print its findings to the terminal. Do not push, do not
  open a branch.
- **In GitHub Actions** (`.github/workflows/claude-review.yml`): post exactly
  one comment on the pull request with `gh pr comment`. Do not use inline
  review comments, do not push a commit, do not open a follow-up branch. The
  job is comment-only — it never blocks the merge (see
  `docs/ai_usage_strategy.md`, "Merge request review").

Run this before opening the pull request, so the author answers the Claude
comment before asking a human to review — the human reviews the decision, not
the first-draft mistakes.
