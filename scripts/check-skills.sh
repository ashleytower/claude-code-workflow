#!/bin/bash
# Check for available skills before implementation
# This script helps Claude auto-detect reusable skills

SKILLS_DIR="$HOME/.claude/skills"
PROJECT_DIR=$(pwd)

# Exit if not in a project directory
if [ ! -d "$PROJECT_DIR" ]; then
  exit 0
fi

# Function to check if package/dependency exists in project
has_dependency() {
  local dep=$1

  # Check package.json
  if [ -f "package.json" ]; then
    if grep -q "\"$dep\"" package.json 2>/dev/null; then
      return 0
    fi
  fi

  # Check requirements.txt
  if [ -f "requirements.txt" ]; then
    if grep -q "^$dep" requirements.txt 2>/dev/null; then
      return 0
    fi
  fi

  return 1
}

# Function to check for recent mentions in code/commits
mentioned_recently() {
  local keyword=$1

  # Check git diff (staged or recent commit)
  if git rev-parse --git-dir > /dev/null 2>&1; then
    if git diff --cached | grep -iq "$keyword" 2>/dev/null; then
      return 0
    fi
    if git diff HEAD~1 HEAD 2>/dev/null | grep -iq "$keyword" 2>/dev/null; then
      return 0
    fi
  fi

  return 1
}

# Check for available skills
AVAILABLE_SKILLS=()

# Check each skill file
if [ -d "$SKILLS_DIR" ]; then
  for skill_file in "$SKILLS_DIR"/*.md; do
    if [ -f "$skill_file" ]; then
      skill_name=$(basename "$skill_file" .md)

      # Skip meta skills
      if [[ "$skill_name" == "research" || "$skill_name" == "guide" ]]; then
        continue
      fi

      # Detect if skill is relevant
      case "$skill_name" in
        stripe*|stripe-*)
          if has_dependency "stripe" || mentioned_recently "stripe"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
        resend*|resend-*)
          if has_dependency "resend" || mentioned_recently "resend"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
        uploadthing*|uploadthing-*)
          if has_dependency "uploadthing" || mentioned_recently "uploadthing"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
        telegram*|telegram-*)
          if has_dependency "telegram" || mentioned_recently "telegram"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
        clerk*|clerk-*)
          if has_dependency "@clerk" || mentioned_recently "clerk"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
        supabase*|supabase-*)
          if has_dependency "supabase" || mentioned_recently "supabase"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
        sentry*|sentry-*)
          if has_dependency "@sentry" || mentioned_recently "sentry"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
        posthog*|posthog-*)
          if has_dependency "posthog" || mentioned_recently "posthog"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
        auth|auth-*)
          if mentioned_recently "auth"; then
            AVAILABLE_SKILLS+=("$skill_name")
          fi
          ;;
      esac
    fi
  done
fi

# Output available skills
if [ ${#AVAILABLE_SKILLS[@]} -gt 0 ]; then
  echo ""
  echo "💡 AVAILABLE SKILLS DETECTED:"
  echo ""
  for skill in "${AVAILABLE_SKILLS[@]}"; do
    echo "  ✓ $skill.md - Read ~/.claude/skills/$skill.md"
  done
  echo ""
  echo "These skills contain copy-paste code for this integration."
  echo "READ THEM BEFORE implementing from scratch."
  echo ""
fi

exit 0
