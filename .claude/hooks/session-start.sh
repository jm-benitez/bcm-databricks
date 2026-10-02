#!/bin/bash
cat > /dev/null # consume stdin, unused

jq -n '{
  hookSpecificOutput: {
    hookEventName: "SessionStart",
    additionalContext: "This is the bcm-databricks practice repo for docs/ai_usage_strategy.md. The design in this repo (CLAUDE.md and the design docs under docs/) is the source of truth. The realtime database (realtimedb/) is read-only evidence to mirror, not to copy field names from. Dev rows are read only through the engineering Genie Agent (see CLAUDE.md, \"How dev data is actually reached\") — never through a direct SQL warehouse command. Do not paste production payloads, phone numbers, or SIP URIs into this session."
  }
}'
exit 0
