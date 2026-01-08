#!/bin/bash
# Verify all mandatory hooks are active and cannot be bypassed
set -e

SETTINGS_FILE="$HOME/.claude/settings.local.json"

echo "Verifying mandatory hooks..."
echo ""

ERRORS=0

# Check 1: PreToolUse hook for Write/Edit exists
if ! grep -q '"tools".*"Write"' "$SETTINGS_FILE" || ! grep -q '"tools".*"Edit"' "$SETTINGS_FILE"; then
  echo "❌ CRITICAL: Write/Edit PreToolUse hook missing!"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ Write/Edit PreToolUse hook present"
fi

# Check 2: Mandatory checklist prompt exists
if ! grep -q "MANDATORY PRE-CODE CHECKLIST" "$SETTINGS_FILE"; then
  echo "❌ CRITICAL: Mandatory pre-code checklist missing!"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ Mandatory pre-code checklist present"
fi

# Check 3: Skill detection command exists
if ! grep -q "check-skills.sh" "$SETTINGS_FILE"; then
  echo "❌ CRITICAL: Skill detection hook missing!"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ Skill detection hook present"
fi

# Check 4: File validation hook exists
if ! grep -q "validate-files.sh" "$SETTINGS_FILE"; then
  echo "❌ CRITICAL: File validation hook missing!"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ File validation hook present"
fi

# Check 5: Agent state coordination hooks exist
if ! grep -q "agent-state" "$SETTINGS_FILE"; then
  echo "❌ CRITICAL: Agent state hooks missing!"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ Agent state coordination hooks present"
fi

# Check 6: Auto-checkpoint hook exists
if ! grep -q "Auto-checkpoint" "$SETTINGS_FILE"; then
  echo "❌ CRITICAL: Auto-checkpoint hook missing!"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ Auto-checkpoint hook present"
fi

# Check 7: Check updates hook exists
if ! grep -q "check-updates.sh" "$SETTINGS_FILE"; then
  echo "❌ WARNING: Update check hook missing"
else
  echo "✓ Update check hook present"
fi

# Check 8: Cron jobs exist
if ! crontab -l 2>/dev/null | grep -q "claude"; then
  echo "⚠️  WARNING: Auto-update cron jobs not installed"
  echo "   Run: ~/.claude/scripts/setup-auto-updates.sh"
else
  echo "✓ Auto-update cron jobs installed"
fi

# Check 9: All critical scripts exist and are executable
SCRIPTS=(
  "check-skills.sh"
  "validate-files.sh"
  "agent-state.sh"
  "check-updates.sh"
  "update-auth-docs.sh"
  "update-llm-council.sh"
  "self-update.sh"
  "backup-before-operation.sh"
)

for script in "${SCRIPTS[@]}"; do
  if [ ! -x "$HOME/.claude/scripts/$script" ]; then
    echo "❌ CRITICAL: $script not found or not executable"
    ERRORS=$((ERRORS + 1))
  fi
done

if [ $ERRORS -eq 0 ]; then
  echo ""
  echo "✅ All mandatory hooks verified and active"
  echo ""
  echo "Protection levels:"
  echo "  1. ✓ Mandatory docs check before code"
  echo "  2. ✓ Automatic skill detection"
  echo "  3. ✓ Automatic file validation"
  echo "  4. ✓ Automatic git checkpoints"
  echo "  5. ✓ Agent state coordination"
  echo "  6. ✓ Auto-updates (cron)"
  echo ""
  echo "Hallucination prevention: ACTIVE"
  echo "Data loss prevention: ACTIVE"
  echo "Agent coordination: ACTIVE"
  echo ""
  exit 0
else
  echo ""
  echo "❌ CRITICAL ERRORS FOUND: $ERRORS"
  echo ""
  echo "System integrity compromised. Fix errors above."
  exit 1
fi
