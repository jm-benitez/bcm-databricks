#!/bin/bash
# PreToolUse on Bash: defense-in-depth re-check of the
# .claude/settings.json deny list (permissions.deny alone isn't always
# sufficient for Bash), plus a check no other rule covers: no Bash path to
# dev data other than the Genie Space.

input=$(cat)
tool_name=$(jq -r '.tool_name // ""' <<<"$input")
command=$(jq -r '.tool_input.command // ""' <<<"$input")

deny() {
  jq -n --arg reason "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $reason
    }
  }'
  exit 0
}

if [[ "$tool_name" == "Bash" ]]; then
  case "$command" in
    *"databricks bundle deploy"*prod*|*"databricks bundle deploy"*production*)
      deny "databricks bundle deploy to prod/production is denied for Claude Code." ;;
    *"databricks experimental aitools tools query"*)
      deny "Direct SQL against a warehouse bypasses the Genie Agent. Use the genie-check skill instead." ;;
    *"databricks experimental genie ask"*)
      deny "Genie One searches all data in the workspace, not this project's fixed table list. Use the genie-check skill's databricks genie commands against this project's Space ID instead." ;;
    "env"|"env "*|"env;"*|"env|"*|"env&"*|"printenv"|"printenv "*|"printenv;"*|"printenv|"*|"printenv&"*)
      deny "Dumping the environment is denied." ;;
    *"redis-cli"*|*"aws events"*|*"eventbridge"*)
      deny "Redis/EventBridge access from Claude Code is denied — those stay as-is per the architecture." ;;
  esac
fi

exit 0
