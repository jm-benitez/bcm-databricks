---
name: bundle-validate
description: Use when tests or the Databricks bundle need a run.
---

Run `databricks bundle validate --target dev` to check the asset bundle loads.
Never target `--target prod` or `--target production` — that's denied in
`.claude/settings.json` and re-checked by `.claude/hooks/pretool-guard.sh`.

Run `pytest tests/` for the stage you changed — `.claude/settings.json`
allows `Bash(pytest tests/*)`. Note: no pipeline code or `tests/` directory
exists in this repo yet, so this currently has nothing to run against; the
allow-rule is set up ahead of Phase 2, not a claim that tests exist today. If
Phase 2 picks a different runner instead of pytest, update this skill and the
allow-list together in the same change.

`databricks bundle deploy` is out of scope for Claude Code entirely, dev or
prod — deploy to dev happens from the default branch after human approval,
per `docs/ai_usage_strategy.md` ("CI/CD").
