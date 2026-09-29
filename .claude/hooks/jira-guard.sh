#!/bin/bash
# PreToolUse on mcp__atlassian__*: Jira and Confluence are shared systems, so
# whatever Claude writes there is published. Deny a call whose input carries the
# things the data boundary keeps out of every shared surface (see "Data boundary"
# in docs/ai_usage_strategy.md): production catalog token, SIP URIs, phone-number
# shaped digit runs, and secret-shaped strings. Heuristic, like prompt-guard.sh.
# permissions.ask in .claude/settings.json still makes the engineer approve each call.

input=$(cat)
payload=$(jq -c '.tool_input // {}' <<<"$input")

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

if [[ "$payload" == *"nectar_prod"* ]]; then
  deny "Blocked: the Jira/Confluence call mentions the placeholder production catalog name. Remove it, then retry."
fi

sip_re='sip:[a-zA-Z0-9._%+-]+@'
if [[ "$payload" =~ $sip_re ]]; then
  deny "Blocked: the Jira/Confluence call contains something shaped like a SIP URI. Mask or remove it, then retry."
fi

phone_re='\+?[0-9]{10,15}'
if [[ "$payload" =~ $phone_re ]]; then
  deny "Blocked: the Jira/Confluence call contains a 10+ digit number that could be a phone number (or a long id or timestamp). Mask or shorten it, then retry."
fi

secret_re='(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|dapi[0-9a-f]{32,}|(secret|api[_-]?key|token|password)[[:space:]]*[:=][[:space:]]*["'"'"']?[A-Za-z0-9/+_-]{16,})'
if [[ "$payload" =~ $secret_re ]]; then
  deny "Blocked: the Jira/Confluence call contains a secret-shaped string. Remove it, then retry."
fi

exit 0
