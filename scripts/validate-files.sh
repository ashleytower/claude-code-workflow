#!/bin/bash
# Validate files after modification to detect corruption
set -e

FILES_TO_CHECK=$@

if [ -z "$FILES_TO_CHECK" ]; then
  # Default: Check all critical files
  FILES_TO_CHECK="~/.claude/agents/*.md ~/.claude/skills/*.md ~/.claude/commands/*.md ~/.claude/settings.local.json"
fi

echo "Validating files..."

ERRORS=0

for file_pattern in $FILES_TO_CHECK; do
  # Expand glob pattern
  for file in $file_pattern; do
    if [ -f "$file" ]; then
      # Check 1: File is not empty
      if [ ! -s "$file" ]; then
        echo "❌ ERROR: $file is empty!"
        ERRORS=$((ERRORS + 1))

        # Auto-restore from git if available
        if git rev-parse --git-dir > /dev/null 2>&1; then
          echo "   Attempting to restore from git..."
          git checkout HEAD -- "$file" 2>/dev/null && echo "   ✓ Restored from git" || echo "   ✗ Could not restore"
        fi

        # Try backup if git restore failed
        if [ ! -s "$file" ]; then
          BACKUP_DIR="$HOME/.claude/backups"
          filename=$(basename "$file")
          dirname=$(basename $(dirname "$file"))

          # Find most recent backup
          latest_backup=$(ls -t "$BACKUP_DIR/$dirname"-* 2>/dev/null | head -1)

          if [ -n "$latest_backup" ] && [ -f "$latest_backup/$filename" ]; then
            echo "   Restoring from backup: $latest_backup"
            cp "$latest_backup/$filename" "$file"
            echo "   ✓ Restored from backup"
          fi
        fi

        continue
      fi

      # Check 2: YAML frontmatter is valid (for .md files)
      if [[ "$file" == *.md ]]; then
        if ! grep -q "^---$" "$file"; then
          echo "⚠️  WARNING: $file missing YAML frontmatter"
        fi
      fi

      # Check 3: JSON is valid (for .json files)
      if [[ "$file" == *.json ]]; then
        if ! python3 -m json.tool "$file" > /dev/null 2>&1; then
          echo "❌ ERROR: $file has invalid JSON!"
          ERRORS=$((ERRORS + 1))
        fi
      fi

      # Check 4: File has reasonable size (not suspiciously small)
      size=$(wc -c < "$file")
      if [[ "$file" == *"/agents/"* ]] && [ $size -lt 500 ]; then
        echo "⚠️  WARNING: $file is suspiciously small ($size bytes)"
      fi

      echo "✓ $file validated"
    fi
  done
done

if [ $ERRORS -gt 0 ]; then
  echo ""
  echo "❌ Validation failed with $ERRORS errors"
  echo "   Check the files above and restore from backups if needed"
  exit 1
else
  echo ""
  echo "✅ All files validated successfully"
  exit 0
fi
