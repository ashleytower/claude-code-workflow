#!/bin/bash
# Run TypeScript type checking on edited files

FILE="$1"

if [ -z "$FILE" ]; then
  exit 0
fi

# Only check .ts and .tsx files
if [[ ! "$FILE" =~ \.(ts|tsx)$ ]]; then
  exit 0
fi

# Find tsconfig.json
TSCONFIG=""
DIR=$(dirname "$FILE")
while [ "$DIR" != "/" ]; do
  if [ -f "$DIR/tsconfig.json" ]; then
    TSCONFIG="$DIR/tsconfig.json"
    break
  fi
  DIR=$(dirname "$DIR")
done

if [ -z "$TSCONFIG" ]; then
  exit 0
fi

PROJECT_DIR=$(dirname "$TSCONFIG")

# Check if tsc is available
if command -v npx &> /dev/null; then
  cd "$PROJECT_DIR"
  # Run tsc with noEmit to just check types
  ERRORS=$(npx tsc --noEmit 2>&1 | grep -E "^[^(]+\([0-9]+,[0-9]+\): error" | head -10)

  if [ -n "$ERRORS" ]; then
    echo "TypeScript errors found:"
    echo "========================"
    echo "$ERRORS"
    echo ""
    echo "Run 'npx tsc --noEmit' for full output"
  fi
fi

exit 0
