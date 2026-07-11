#!/usr/bin/env bash
# Hook runs from workspace root. Expects the attempted command as arguments.
BLOCKED_PATTERNS=('terraform destroy' 'rm -rf')
INJECT_CONTEXT="Repository guidance: prefer Makefile targets such as make plan/apply/deploy and preserve the raw -> cleaned -> curated flow; avoid destructive infrastructure changes unless explicitly requested."
BEHAVIOR="block"

CMD="$*"
for p in "${BLOCKED_PATTERNS[@]}"; do
  if [[ "$CMD" =~ $p ]]; then
    if [[ "$BEHAVIOR" == "block" ]]; then
      echo "PreToolUse hook: Action blocked (matches pattern: $p)"
      exit 1
    else
      echo "PreToolUse hook: Warning (matches pattern: $p)"
    fi
  fi
done

if [[ -n "$INJECT_CONTEXT" ]]; then
  echo "Injected context: $INJECT_CONTEXT"
fi

# Allow the tool use to proceed
exit 0
