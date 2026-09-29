# Databricks live-action validation checklist

Use this to re-validate the live Databricks side of the Claude Code setup —
after any change to `.claude/settings.json`, the hooks, or the Genie Agent's
instructions, and before treating this practice repo's setup as a template
for the real `bcm` repo. Ask Claude Code to "run the Databricks validation
checklist" to work through this.

Current state this checklist was written against (2026-09-28):
- Genie Agent ("BCM Engineering (dev)"), Space ID `01f1bb8f773317d18e3dd8177832e6f6`,
  warehouse `431f6c2d74d114de` (Serverless Starter Warehouse).
- Attached tables: `nectar.bronze.skyconnect_raw`, `nectar.bronze.nectar_da_avro_raw`,
  `nectar.bronze.users_raw`, `nectar.dev_tqaddoumi_tqaddoumi_bronze.nd_qsr`.
- No MCP server involved — Databricks integration is the `databricks` CLI
  plugin (`enabledPlugins: {"databricks@claude-plugins-official": true}` in
  `.claude/settings.json`), invoked over Bash.

## 1. Genie Agent — reachable and scoped correctly

- [ ] **Agent exists and resolves.**
  ```bash
  databricks genie get-space 01f1bb8f773317d18e3dd8177832e6f6
  ```
  Expect: returns title "BCM Engineering (dev)", the 4 tables above, no error.

- [ ] **Agent answers a real question about each attached table.** Run one
  per table via `start-conversation` / poll `get-message` (see the
  `genie-check` skill for the exact command shape), e.g.:
  ```bash
  databricks genie start-conversation --no-wait 01f1bb8f773317d18e3dd8177832e6f6 \
    "How many rows are in the skyconnect_raw table?"
  ```
  Expect: `COMPLETED` status, a real row count, no `INSUFFICIENT_PERMISSIONS`
  or `TABLE_OR_VIEW_NOT_FOUND` error. Repeat for `nectar_da_avro_raw`,
  `users_raw`, `nd_qsr`.

- [ ] **Agent refuses a table outside its scope.**
  ```bash
  databricks genie start-conversation --no-wait 01f1bb8f773317d18e3dd8177832e6f6 \
    "How many trips are in the samples.nyctaxi.trips table?"
  ```
  Expect: a text answer saying it cannot find/access that table — not a row
  count, not a generic SQL error.

- [ ] **Agent's live instructions match the git copy.** Compare:
  ```bash
  databricks genie get-space 01f1bb8f773317d18e3dd8177832e6f6 \
    --include-serialized-space -o json | jq '.serialized_space | fromjson'
  ```
  against `docs/genie_agent_instructions.md`. If they've drifted, that's the
  "fix made only in the workspace UI" failure mode the strategy doc warns
  about — reconcile in a PR that updates both.

## 2. Data boundary — the deny rules actually hold

Run each from a Claude Code session in this repo (not raw shell) so
`.claude/settings.json` and the hooks are in effect. Each should be **denied
before it runs**, not merely fail for an unrelated reason.

- [ ] `databricks experimental aitools tools query "SELECT 1"` → denied
  (bypasses the Genie Agent).
- [ ] `databricks experimental genie ask -s test "anything"` → denied
  ("Genie One" searches all workspace data, not this project's fixed table
  list).
- [ ] `databricks bundle deploy --target prod` → denied.
- [ ] Bundle deploy/run with any other target spelling or none → denied by
  `pretool-guard.sh`: `-tprod`, `--target=prod`, `--target production`,
  `-t test`, `DATABRICKS_BUNDLE_TARGET=prod databricks bundle run <job>`, and a
  bare `databricks bundle deploy`. `-t dev` passes the hook (and then asks).
- [ ] `databricks bundle destroy -t dev` and `git push --force` → denied.
- [ ] `databricks genie update-space` / `create-space` and `git push` → ask
  first (never run silently).
- [ ] Any `databricks ...` command mentioning `dev_tqaddoumi_tqaddoumi_tools`,
  `dev_tqaddoumi_tqaddoumi_silver/gold/ref/ops/config/alerting`, or
  `dev_mkiwan_sandbox` → denied.
- [ ] Paste a fake E.164 phone number, a `sip:` URI, or the placeholder
  prod-catalog token `nectar_prod` into a prompt → blocked by
  `prompt-guard.sh` before Claude sees it.
- [ ] Introduce a fake secret-shaped string (e.g. `AKIA` + 16 chars) into a
  tracked file, or into a new untracked file that is not gitignored, and end
  the turn → `stop-secret-scan.sh` blocks completion. The same string in a
  gitignored file is not scanned.
- [ ] `.github/workflows/secret-scan.yml` runs on the PR and fails on the same
  fake string (remove it before merging).

## 2b. Jira access (Atlassian MCP)

- [ ] `/mcp` lists the project's `atlassian` server. On first use each
  engineer approves it and signs in with Atlassian OAuth in the browser
  (nothing to paste, no token in the repo).
- [ ] Ask Claude to read a Jira ticket → the call asks for approval first.
  Once the real tool names are visible, move the read-only ones (search, get
  issue) from `ask` to `allow` in `.claude/settings.json` and leave every
  write tool on `ask`.
- [ ] Ask Claude to comment on a ticket with a fake SIP URI, a 10+ digit
  number, or a fake secret in the text → denied by `jira-guard.sh` before the
  approval prompt. A plain comment reaches the approval prompt.
- [ ] Confirm Claude does not post Genie result rows, and does not
  transition or close a ticket unless you asked.

## 3. Permission boundary at the Unity Catalog level (not just the Agent)

- [ ] Check the querying principal doesn't hold a broader grant than
  intended, which would make the Genie-level test in Section 1 pass for the
  wrong reason:
  ```bash
  databricks grants get schema nectar.bronze
  databricks grants get schema nectar.dev_tqaddoumi_tqaddoumi_bronze
  databricks grants get catalog nectar
  ```
  Expect: no blanket `SELECT`/`USE_SCHEMA` grant across all of `nectar` that
  would make the out-of-scope schemas readable by other means (raw SQL,
  another tool) even though the Genie Agent itself won't surface them.

## 4. Plugin install reproducibility

- [ ] On a clean checkout (or by a second engineer), confirm the Databricks
  plugin activates from the committed setting alone:
  ```bash
  cat .claude/settings.json | jq '.enabledPlugins'
  ```
  Expect: `{"databricks@claude-plugins-official": true}` — and Claude Code
  should fetch/cache the plugin automatically on session start with no extra
  per-laptop setup, since `claude-plugins-official` is the built-in official
  marketplace, not something scoped to this repo or to one person's machine.

- [ ] Confirm the plugin's own hooks (Databricks auth/context priming) don't
  conflict with this repo's hooks — `/hooks` in a Claude Code session should
  show both this repo's 5 hooks and the plugin's 3, with no errors.
