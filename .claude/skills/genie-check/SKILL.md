---
name: genie-check
description: Use when a change is ready to check against dev data, or when exploring a dev table before writing pipeline code.
---

The engineering Genie Agent is the only path to stored rows (see `CLAUDE.md`,
"How dev data is actually reached"). It's a Databricks Genie Space, reached
via the `databricks genie` CLI over Bash — not an MCP tool, and not
`databricks experimental aitools tools query` or `databricks experimental
genie ask`, both of which bypass it and are denied.

Its Space ID lives in `docs/genie_agent_instructions.md` once the Space
exists. Until then, this skill has nothing to check against — say so instead
of falling back to a direct SQL command.

## Asking a question

```bash
# Start a conversation (async — returns immediately)
databricks genie start-conversation --no-wait <SPACE_ID> "<question>"
# → {"conversation_id": "...", "message_id": "..."}

# Poll until status is COMPLETED / FAILED / CANCELLED
databricks genie get-message <SPACE_ID> <CONV_ID> <MSG_ID> | jq '{status, error}'

# Pull the generated SQL and text reply
databricks genie get-message <SPACE_ID> <CONV_ID> <MSG_ID> \
  | jq '.attachments[] | {sql: .query.query, text: .text.content}'

# Follow-up in the same conversation
databricks genie create-message --no-wait <SPACE_ID> <CONV_ID> "<follow-up>"
```

## In the same change

1. Paste the question, the SQL Genie generated, and the result grain into the
   PR description.
2. Update the matching row in `docs/genie_prompt_pack.md` (question, partner +
   level, table grain, decision file it checks, status).
3. If the answer was wrong because the agent's instructions were wrong, fix
   `docs/genie_agent_instructions.md` in the same change, then push the same
   fix to the live Agent (`databricks genie update-space`, see the
   `databricks-genie-agents` skill from the installed `databricks` plugin)
   and say in the PR that you did both — a fix made only in the workspace UI
   is invisible to the next reviewer.

Never paste a raw result row containing a subscriber identifier (phone
number, SIP URI) into the PR or into this session — aggregates and grains
only, per the data boundary in `docs/ai_usage_strategy.md`.
