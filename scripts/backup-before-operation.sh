#!/bin/bash
# Automatic backup before risky operations
set -e

BACKUP_DIR="$HOME/.claude/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)

# Create backup directory
mkdir -p "$BACKUP_DIR"

# Detect what's being modified from bash command
OPERATION=$1  # The bash command being executed

# Determine what to backup based on operation
backup_needed=false

# Check if operation touches critical files
if [[ "$OPERATION" == *"agents"* ]]; then
  backup_needed=true
  TARGET="agents"
elif [[ "$OPERATION" == *"skills"* ]]; then
  backup_needed=true
  TARGET="skills"
elif [[ "$OPERATION" == *"commands"* ]]; then
  backup_needed=true
  TARGET="commands"
elif [[ "$OPERATION" == *"settings.local.json"* ]]; then
  backup_needed=true
  TARGET="settings"
elif [[ "$OPERATION" == *"scripts"* ]]; then
  backup_needed=true
  TARGET="scripts"
fi

if [ "$backup_needed" = true ]; then
  echo "⚠️  Backing up $TARGET before operation..."

  # Create backup
  case "$TARGET" in
    agents)
      cp -r ~/.claude/agents "$BACKUP_DIR/agents-$TIMESTAMP"
      echo "✓ Backup created: $BACKUP_DIR/agents-$TIMESTAMP"
      ;;
    skills)
      cp -r ~/.claude/skills "$BACKUP_DIR/skills-$TIMESTAMP"
      echo "✓ Backup created: $BACKUP_DIR/skills-$TIMESTAMP"
      ;;
    commands)
      cp -r ~/.claude/commands "$BACKUP_DIR/commands-$TIMESTAMP"
      echo "✓ Backup created: $BACKUP_DIR/commands-$TIMESTAMP"
      ;;
    settings)
      cp ~/.claude/settings.local.json "$BACKUP_DIR/settings-$TIMESTAMP.json"
      echo "✓ Backup created: $BACKUP_DIR/settings-$TIMESTAMP.json"
      ;;
    scripts)
      cp -r ~/.claude/scripts "$BACKUP_DIR/scripts-$TIMESTAMP"
      echo "✓ Backup created: $BACKUP_DIR/scripts-$TIMESTAMP"
      ;;
  esac

  # Git commit for version control
  cd ~/.claude
  if git rev-parse --git-dir > /dev/null 2>&1; then
    git add -A
    git commit -m "Auto-backup: Before $TARGET modification" --allow-empty
    echo "✓ Git snapshot created"
  fi

  # Cleanup: Keep only last 10 backups per type
  ls -t "$BACKUP_DIR/$TARGET"-* 2>/dev/null | tail -n +11 | xargs rm -rf 2>/dev/null || true
fi

exit 0
