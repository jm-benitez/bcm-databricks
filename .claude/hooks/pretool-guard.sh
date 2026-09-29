#!/bin/bash
# PreToolUse on Bash: defense-in-depth re-check of the
# .claude/settings.json deny list (permissions.deny alone isn't always
# sufficient for Bash), plus checks no other rule covers: bundle commands run
# against dev only, and no Bash path to dev data other than the Genie Space.

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

# Bundle commands that deploy, run or change bound resources: dev only, and the
# target must be explicit (a bare command would use the bundle's default target).
# The whole command is checked, so `-tprod`, `--target=prod`, `--target production`
# and DATABRICKS_BUNDLE_TARGET=prod don't slip past the permission deny rules.
bundle_mutating='bundle[[:space:]]+(deploy|run|destroy|bind|unbind|deployment)([[:space:]]|$)'
if [[ "$tool_name" == "Bash" && "$command" =~ $bundle_mutating ]]; then
  if [[ "${BASH_REMATCH[1]}" == "destroy" ]]; then
    deny "databricks bundle destroy is never run from Claude Code."
  fi
  targets=$(
    {
      printf '%s\n' "$command" | grep -oE '(^|[[:space:]])(--target|-t)(=|[[:space:]]+)?["'"'"']?[A-Za-z0-9_.-]+'
      printf '%s\n' "$command" | grep -oE 'DATABRICKS_BUNDLE_TARGET=["'"'"']?[A-Za-z0-9_.-]+'
    } | sed -E 's/^[[:space:]]*(--target|-t|DATABRICKS_BUNDLE_TARGET)(=|[[:space:]]+)?["'"'"']?//'
  )
  found_dev=0
  while IFS= read -r t; do
    [[ -z "$t" ]] && continue
    if [[ "$t" == "dev" ]]; then
      found_dev=1
    else
      deny "Bundle commands run against the dev target only (found target '$t'). Other targets are deployed by CI."
    fi
  done <<<"$targets"
  if [[ $found_dev -eq 0 ]]; then
    deny "Pass an explicit dev target (-t dev) on bundle deploy/run. A bare command falls back to the bundle's default target."
  fi
fi

if [[ "$tool_name" == "Bash" ]]; then
  case "$command" in
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
