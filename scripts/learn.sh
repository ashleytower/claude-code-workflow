#!/bin/bash
# Extract successful implementation into reusable skill
set -e

SKILL_NAME=$1
SKILL_DIR="$HOME/.claude/skills"
SKILL_FILE="$SKILL_DIR/$SKILL_NAME.md"
SPEAK_SCRIPT="$HOME/.claude/scripts/speak.sh"

# Validate input
if [ -z "$SKILL_NAME" ]; then
  echo "Usage: learn.sh <skill-name>"
  echo "Example: learn.sh stripe-payments"
  exit 1
fi

# Create skills directory if missing
mkdir -p "$SKILL_DIR"

# Detect framework
detect_framework() {
  if [ -f "package.json" ]; then
    if grep -q '"next"' package.json 2>/dev/null; then
      echo "nextjs"
    elif grep -q '"expo"' package.json 2>/dev/null; then
      echo "react-native"
    elif grep -q '"react"' package.json 2>/dev/null; then
      echo "react"
    else
      echo "nodejs"
    fi
  elif [ -f "requirements.txt" ]; then
    if grep -q "fastapi" requirements.txt 2>/dev/null; then
      echo "fastapi"
    else
      echo "python"
    fi
  else
    echo "unknown"
  fi
}

# Extract recently changed files (last commit)
extract_files() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git diff --name-only HEAD~1 HEAD 2>/dev/null || git diff --name-only --cached 2>/dev/null || echo "No git changes detected"
  else
    echo "Not a git repository"
  fi
}

# Extract environment variables from code
extract_env_vars() {
  {
    # JavaScript/TypeScript
    grep -rh "process\.env\." --include="*.ts" --include="*.tsx" --include="*.js" --include="*.jsx" . 2>/dev/null | \
      grep -oE "process\.env\.[A-Z_]+" | sort -u

    # Python
    grep -rh "os\.getenv\|os\.environ" --include="*.py" . 2>/dev/null | \
      grep -oE "\"[A-Z_]+\"" | tr -d '"' | sort -u
  } | sort -u
}

# Extract recently added dependencies
extract_dependencies() {
  if git rev-parse --git-dir > /dev/null 2>&1; then
    {
      # package.json changes
      git diff HEAD~1 HEAD package.json 2>/dev/null | grep "^\+" | grep -v "+++" | grep -v "^+$"

      # requirements.txt changes
      git diff HEAD~1 HEAD requirements.txt 2>/dev/null | grep "^\+" | grep -v "+++" | grep -v "^+$"
    } 2>/dev/null || echo "No dependency changes detected"
  fi
}

# Detect integration type from package name
detect_integration() {
  local deps=$(extract_dependencies)

  if echo "$deps" | grep -iq "stripe"; then
    echo "stripe"
  elif echo "$deps" | grep -iq "resend"; then
    echo "resend"
  elif echo "$deps" | grep -iq "uploadthing"; then
    echo "uploadthing"
  elif echo "$deps" | grep -iq "telegram"; then
    echo "telegram"
  elif echo "$deps" | grep -iq "sentry"; then
    echo "sentry"
  elif echo "$deps" | grep -iq "posthog"; then
    echo "posthog"
  elif echo "$deps" | grep -iq "@clerk"; then
    echo "clerk"
  elif echo "$deps" | grep -iq "supabase"; then
    echo "supabase"
  else
    echo "$SKILL_NAME"
  fi
}

# Get file contents of changed files
get_changed_file_contents() {
  local files=$(extract_files)

  if [ "$files" = "No git changes detected" ] || [ "$files" = "Not a git repository" ]; then
    echo "No files to analyze"
    return
  fi

  echo "Changed file contents:"
  echo ""

  while IFS= read -r file; do
    if [ -f "$file" ]; then
      echo "=== $file ==="
      cat "$file"
      echo ""
      echo ""
    fi
  done <<< "$files"
}

echo "Extracting implementation for: $SKILL_NAME"
echo ""

FRAMEWORK=$(detect_framework)
INTEGRATION=$(detect_integration)

echo "Framework detected: $FRAMEWORK"
echo "Integration detected: $INTEGRATION"
echo ""

# Create context file for Claude
CONTEXT_FILE="/tmp/learn-context-$$.md"

cat > "$CONTEXT_FILE" <<EOF
# Skill Extraction Request

**Skill Name**: $SKILL_NAME
**Framework**: $FRAMEWORK
**Integration Type**: $INTEGRATION
**Date**: $(date +%Y-%m-%d)

## Context

Extract this implementation into a reusable skill at:
$SKILL_FILE

## Files Changed

$(extract_files)

## Environment Variables Used

$(extract_env_vars)

## Dependencies Added

$(extract_dependencies)

## File Contents

$(get_changed_file_contents)

## Instructions

Generate a comprehensive skill following this template:

\`\`\`markdown
---
name: $SKILL_NAME
category: [integration|auth|payments|email|storage|monitoring]
frameworks: [$FRAMEWORK]
last_updated: $(date +%Y-%m-%d)
version: [detect from package.json]
---

# [Service Name] Integration

## Quick Start

[One-liner showing how to use this skill in future projects]

## Installation

\`\`\`bash
# $FRAMEWORK
[installation commands from dependencies]
\`\`\`

## Environment Variables

\`\`\`.env
[from extracted env vars]
\`\`\`

## Setup Code

### Configuration
\`\`\`typescript
// Extract initialization/setup code from changed files
\`\`\`

### Initialization
\`\`\`typescript
// Extract init patterns
\`\`\`

## Common Use Cases

### [Use Case 1 - from implementation]
\`\`\`typescript
// Actual working code from implementation
\`\`\`

### [Use Case 2]
\`\`\`typescript
// Actual working code
\`\`\`

## Framework-Specific Code

[Only if multiple frameworks are relevant]

### Next.js
\`\`\`typescript
// Next.js specific code
\`\`\`

### React Native
\`\`\`typescript
// RN specific code
\`\`\`

## Error Handling

\`\`\`typescript
// Extract error handling patterns from implementation
\`\`\`

## Testing

\`\`\`typescript
// Extract test examples if they exist
\`\`\`

## Gotchas

- [List issues you encountered during implementation]
- [Solutions that worked]
- [Things to avoid]
- [Performance considerations]

## Next Time

When adding $INTEGRATION to a project:

1. Copy installation commands
2. Add environment variables
3. Copy setup code
4. Adapt use cases to your needs
5. Reference gotchas

Saves 1-2 hours every time.

## Updates

- $(date +%Y-%m-%d): Initial skill created from successful implementation
\`\`\`

## Requirements

1. **Extract actual code** - Don't generate examples, use the real implementation
2. **Include gotchas** - What was tricky? What failed first?
3. **Copy-paste ready** - Code should work as-is
4. **Framework-aware** - Adapt for Next.js vs React Native vs FastAPI
5. **Environment variables** - List all required vars
6. **Testing patterns** - If tests exist, include examples
7. **Version info** - Capture package versions used

Write the skill to: $SKILL_FILE
EOF

echo "Context prepared: $CONTEXT_FILE"
echo ""
echo "Invoking Claude to extract skill..."
echo ""

# Let Claude extract the skill
# (This would be called by the /learn command with the context)

# Cleanup
# rm "$CONTEXT_FILE"

# Voice notification
if [ -f "$SPEAK_SCRIPT" ]; then
  "$SPEAK_SCRIPT" "Skill extraction complete" &
fi

echo ""
echo "Context file created at: $CONTEXT_FILE"
echo "Use this context to generate: $SKILL_FILE"
echo ""
echo "Next: Claude will read this context and generate the skill"
