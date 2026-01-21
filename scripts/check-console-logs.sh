#!/bin/bash
# Check for console.log statements in staged/modified files

# Get the file from argument or check all staged files
if [ -n "$1" ]; then
  FILES="$1"
else
  FILES=$(git diff --cached --name-only --diff-filter=ACM 2>/dev/null | grep -E '\.(js|jsx|ts|tsx)$')
fi

if [ -z "$FILES" ]; then
  exit 0
fi

FOUND=0
for file in $FILES; do
  if [ -f "$file" ]; then
    # Check for console.log, console.warn, console.error, console.debug
    MATCHES=$(grep -n "console\.\(log\|warn\|error\|debug\)" "$file" 2>/dev/null | grep -v "// eslint-disable" | grep -v "// allowed")
    if [ -n "$MATCHES" ]; then
      if [ $FOUND -eq 0 ]; then
        echo "WARNING: console.log statements found:"
        echo "========================================="
        FOUND=1
      fi
      echo "$file:"
      echo "$MATCHES"
      echo ""
    fi
  fi
done

if [ $FOUND -eq 1 ]; then
  echo "Consider removing debug statements before committing."
  echo "Add '// allowed' comment to keep intentional logs."
fi

exit 0
