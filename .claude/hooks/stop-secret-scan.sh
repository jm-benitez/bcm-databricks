#!/bin/bash
# Stop: scan the working-tree diff for secret-shaped strings and block
# completion on a match. Prefers gitleaks if installed; falls back to a
# regex scan. The same scan should run in CI (.github/workflows/claude-review.yml)
# so the two can't drift.

input=$(cat)
cwd=$(jq -r '.cwd // "."' <<<"$input")
cd "$cwd" || exit 0

block() {
  jq -n --arg reason "$1" '{decision: "block", reason: $reason}'
  exit 0
}

if command -v gitleaks >/dev/null 2>&1; then
  findings=$(gitleaks detect --source . --no-git -v 2>&1)
  if [[ $? -ne 0 ]]; then
    block "gitleaks found a secret-shaped string in the working tree. Remove it before continuing:\n${findings}"
  fi
  exit 0
fi

# Regex fallback: AWS keys, private-key headers, generic long hex/base64 "key"-looking
# assignments, and a Databricks personal access token shape.
diff_output=$(git diff --unified=0 2>/dev/null; git diff --cached --unified=0 2>/dev/null)

pattern='(AKIA[0-9A-Z]{16}|-----BEGIN [A-Z ]*PRIVATE KEY-----|dapi[0-9a-f]{32,}|(secret|api[_-]?key|token|password)\s*[:=]\s*["'"'"']?[A-Za-z0-9/+_-]{16,}["'"'"']?)'

match=$(echo "$diff_output" | grep -inE "$pattern" | grep '^[0-9]*:+' )

if [[ -n "$match" ]]; then
  block "Secret-shaped string found in the diff. Remove it before continuing:\n${match}"
fi

exit 0
