#!/bin/bash
# Auto-format file with Prettier

FILE="$1"

if [ -z "$FILE" ]; then
  exit 0
fi

# Only format JS/TS/JSON/CSS files
if [[ ! "$FILE" =~ \.(js|jsx|ts|tsx|json|css|scss|md)$ ]]; then
  exit 0
fi

# Check if file exists
if [ ! -f "$FILE" ]; then
  exit 0
fi

# Find prettier config or use defaults
DIR=$(dirname "$FILE")
HAS_PRETTIER=0

while [ "$DIR" != "/" ]; do
  if [ -f "$DIR/.prettierrc" ] || [ -f "$DIR/.prettierrc.json" ] || [ -f "$DIR/prettier.config.js" ]; then
    HAS_PRETTIER=1
    PROJECT_DIR="$DIR"
    break
  fi
  if [ -f "$DIR/package.json" ]; then
    PROJECT_DIR="$DIR"
    break
  fi
  DIR=$(dirname "$DIR")
done

# Run prettier if available
if command -v npx &> /dev/null && [ -n "$PROJECT_DIR" ]; then
  cd "$PROJECT_DIR"
  if npx prettier --check "$FILE" &> /dev/null; then
    : # File is already formatted
  else
    npx prettier --write "$FILE" 2>/dev/null
    echo "Formatted: $FILE"
  fi
fi

exit 0
