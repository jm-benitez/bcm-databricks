#!/bin/bash
# PostToolUse on Edit|Write: non-blocking reminder to update the matching
# test. Never blocks — the turn still completes.

input=$(cat)
file_path=$(jq -r '.tool_input.file_path // ""' <<<"$input")

case "$file_path" in
  */docs/*|*/.claude/*|*/.github/*|*.md)
    exit 0 ;; # docs/config changes don't need this reminder
esac

jq -n '{
  hookSpecificOutput: {
    hookEventName: "PostToolUse",
    additionalContext: "Reminder: if this changed pipeline behavior, add/update the automated test before opening the PR (see CLAUDE.md)."
  }
}'
exit 0
