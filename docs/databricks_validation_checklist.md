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
- [ ] Any `databricks ...` command mentioning `dev_tqaddoumi_tqaddoumi_tools`,
  `dev_tqaddoumi_tqaddoumi_silver/gold/ref/ops/config/alerting`, or
  `dev_mkiwan_sandbox` → denied.
- [ ] Ask Claude Code to edit a file under `realtimedb/` (create the
  directory with a dummy file first if it doesn't exist locally) → denied by
  `pretool-guard.sh`.
- [ ] Paste a fake E.164 phone number, a `sip:` URI, or the placeholder
  prod-catalog token `nectar_prod` into a prompt → blocked by
  `prompt-guard.sh` before Claude sees it.
- [ ] Introduce a fake secret-shaped string (e.g. `AKIA` + 16 chars) into a
  tracked file and end the turn → `stop-secret-scan.sh` blocks completion.

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

## 5. Warehouse behavior

- [ ] Stop the warehouse (`databricks warehouses stop --id 431f6c2d74d114de`)
  and confirm a Genie question still completes (it should auto-start the
  warehouse — expect a longer first response, status passing through
  `PENDING_WAREHOUSE`).
