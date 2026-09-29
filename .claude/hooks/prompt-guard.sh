#!/bin/bash
# UserPromptSubmit: block a prompt that looks like a raw production sample
# instead of a masked/aggregated one. Heuristic, not exhaustive — the point is
# to catch an accidental paste, per the "Data boundary" section of
# docs/ai_usage_strategy.md.

input=$(cat)
prompt=$(jq -r '.prompt // ""' <<<"$input")

block() {
  jq -n --arg reason "$1" '{decision: "block", reason: $reason}'
  exit 0
}

# Placeholder production-catalog token — replace once a real prod catalog is named.
if [[ "$prompt" == *"nectar_prod"* ]]; then
  block "Blocked: this mentions the placeholder production catalog name. Dev work stays inside nectar.bronze/silver/gold/ops and nectar.dev_tqaddoumi_tqaddoumi_bronze — see CLAUDE.md."
fi

# SIP URI
if [[ "$prompt" =~ sip:[a-zA-Z0-9._%+-]+@ ]]; then
  block "Blocked: this looks like a SIP URI. Mask it by hand first (see Data boundary in docs/ai_usage_strategy.md), then resubmit."
fi

# E.164-shaped phone number (10-15 digits, optional leading +)
if [[ "$prompt" =~ \+?[0-9]{10,15} ]]; then
  block "Blocked: this looks like a phone number. Mask it by hand first (see Data boundary in docs/ai_usage_strategy.md), then resubmit."
fi

# A long comma/pipe-delimited line — heuristic for a pasted raw CDR row
if echo "$prompt" | grep -qE '^([^,|]{1,40}[,|]){8,}'; then
  block "Blocked: this looks like a pasted raw record (many comma/pipe-delimited fields). Aggregates only, per the data boundary — mask or summarize it first."
fi

exit 0
