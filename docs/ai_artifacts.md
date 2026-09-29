# AI artifacts in this repo

## Instructions and configuration

| Artifact | What it is for |
|---|---|
| [CLAUDE.md](../CLAUDE.md) | The rules Claude Code loads every session: scope, what not to invent, the data boundary, and how dev data is reached. |
| [.claude/settings.json](../.claude/settings.json) | Shared permissions (allow, ask, deny) and the hook wiring that every engineer gets. |
| `.claude/settings.local.json`, `CLAUDE.local.md` | Personal overrides that stay on one laptop and are gitignored. |
| [.mcp.json](../.mcp.json) | Connects the Atlassian server so Claude can read and update Jira tickets. |
| [.claudeignore](../.claudeignore) | Keeps build output, checkpoints, large fixtures and the realtime-database checkout out of Claude's context. |
| `databricks` plugin (enabled in settings.json) | Supplies the `databricks:*` skills that teach Claude how to drive the Databricks CLI. |

## Hooks (`.claude/hooks/`)

| Hook | Runs when | What it is for |
|---|---|---|
| [session-start.sh](../.claude/hooks/session-start.sh) | A session starts | Reminds Claude that the design here is the source of truth and that dev rows come only through Genie. |
| [prompt-guard.sh](../.claude/hooks/prompt-guard.sh) | You submit a prompt | Blocks a prompt that contains a phone number, SIP URI, production catalog name or pasted raw record. |
| [pretool-guard.sh](../.claude/hooks/pretool-guard.sh) | Before a Bash command | Blocks direct SQL, Genie One, non-dev bundle commands, `bundle destroy`, environment dumps, and Redis or EventBridge access. |
| [jira-guard.sh](../.claude/hooks/jira-guard.sh) | Before an Atlassian call | Blocks a Jira or Confluence write that contains a phone number, SIP URI, secret or production catalog name. |
| [posttool-reminder.sh](../.claude/hooks/posttool-reminder.sh) | After an edit to a code file | Reminds Claude to update the test, without blocking. |
| [stop-secret-scan.sh](../.claude/hooks/stop-secret-scan.sh) | Claude finishes a turn | Blocks the turn if the diff or an untracked file contains a secret-shaped string. |

## Skills (`.claude/skills/`)

| Skill | What it is for |
|---|---|
| [decision-check](../.claude/skills/decision-check/SKILL.md) | Makes Claude confirm a signed decision or design covers a change to classification, enrich, stitching, score, thresholds or partner filters before it writes code. |
| [genie-check](../.claude/skills/genie-check/SKILL.md) | Gives the exact `databricks genie` steps for asking the dev Genie Space a question and recording the result. |
| [bundle-validate](../.claude/skills/bundle-validate/SKILL.md) | Runs the dev-target bundle validation and the unit tests. |
| [code-review](../.claude/skills/code-review/SKILL.md) | Starts the read-only reviewer on a diff, on a laptop or in CI. |
| [create-jira-issue](../.claude/skills/create-jira-issue/SKILL.md) | Makes every Jira issue Claude drafts follow the same five parts: Title, What?, Why?, Technical Tasks and Acceptance Criteria. |
| [realtime-patterns](../.claude/skills/realtime-patterns/SKILL.md) | Shows how Nectar's realtime database does something today, as a pattern to mirror and not code to copy. |

## Agent

| Agent | What it is for |
|---|---|
| [code-reviewer](../.claude/agents/code-reviewer.md) | A read-only reviewer that checks a diff against the review checklist, test coverage and other observations, and cannot edit anything. |

## Automation (`.github/`, pre-commit)

| Artifact | What it is for |
|---|---|
| [claude-review.yml](../.github/workflows/claude-review.yml) | Posts one comment-only Claude review on each pull request. |
| [secret-scan.yml](../.github/workflows/secret-scan.yml) | Fails a pull request if gitleaks finds a secret in the repo history or tree. |
| [.pre-commit-config.yaml](../.pre-commit-config.yaml) | Runs gitleaks and basic file checks before each commit. |

## Databricks-side objects

| Artifact | What it is for |
|---|---|
| Genie Space "BCM Engineering (dev)" | The only AI path that runs SQL over stored dev rows, limited to its attached tables. |

## Documents

| Document | What it is for |
|---|---|
| [ai_usage_strategy.md](ai_usage_strategy.md) | The strategy: which tool does which job, the data boundary, and the review policy. |
| [genie_agent_instructions.md](genie_agent_instructions.md) | The reviewed git copy of the Genie Space's instructions, with the Space ID and the steps to create one. |
| [databricks_validation_checklist.md](databricks_validation_checklist.md) | The checklist for re-proving that the Genie scope, deny rules and hooks still hold. |
| [decisions/](decisions/) | The decision files (one per plan session, plus the field-scope cuts) that Claude must follow and may not invent around. |
