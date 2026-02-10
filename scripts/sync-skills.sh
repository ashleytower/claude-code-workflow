#!/usr/bin/env bash
# sync-skills.sh -- Bidirectional skill sync between Claude Code and OpenClaw
# Syncs skills across three directories:
#   ~/.agents/skills/     (npx skills add destination, directories with SKILL.md)
#   ~/.claude/skills/     (Claude Code reads from here, mix of symlinks + standalone .md)
#   ~/.openclaw/skills/   (OpenClaw/Max reads from here, directories with SKILL.md)

set -euo pipefail

QUIET=false
[[ "${1:-}" == "--quiet" ]] && QUIET=true

AGENTS_DIR="$HOME/.agents/skills"
CLAUDE_DIR="$HOME/.claude/skills"
OPENCLAW_DIR="$HOME/.openclaw/skills"
MEMORY_LOG="$HOME/.claude/memory/topics/skill-sync.md"

# Counters
SYNCED_TO_OPENCLAW=0
SYNCED_TO_CLAUDE=0
SKIPPED=0

# Skip list -- directories that are not real skills
SKIP_LIST="shared rube last30days"

should_skip() {
  local name="$1"
  for skip in $SKIP_LIST; do
    [[ "$name" == "$skip" ]] && return 0
  done
  return 1
}

log() {
  $QUIET || echo "$@"
}

# Ensure target directories exist
mkdir -p "$OPENCLAW_DIR" "$CLAUDE_DIR"

# ──────────────────────────────────────────────
# Direction A: Claude Code -> OpenClaw
# ──────────────────────────────────────────────

# A1: Sync directories from ~/.agents/skills/ to ~/.openclaw/skills/
if [[ -d "$AGENTS_DIR" ]]; then
  for skill_dir in "$AGENTS_DIR"/*/; do
    [[ ! -d "$skill_dir" ]] && continue
    name=$(basename "$skill_dir")
    should_skip "$name" && continue
    [[ ! -f "$skill_dir/SKILL.md" ]] && continue

    if [[ ! -e "$OPENCLAW_DIR/$name" ]]; then
      ln -s "../../.agents/skills/$name" "$OPENCLAW_DIR/$name"
      log "  [->openclaw] $name (symlink from agents)"
      SYNCED_TO_OPENCLAW=$((SYNCED_TO_OPENCLAW + 1))
    fi
  done
fi

# A2: Sync standalone .md files from ~/.claude/skills/ to ~/.openclaw/skills/
for md_file in "$CLAUDE_DIR"/*.md; do
  [[ ! -f "$md_file" ]] && continue
  filename=$(basename "$md_file")
  name="${filename%.md}"
  should_skip "$name" && continue

  # Skip if already exists in OpenClaw with content
  if [[ -L "$OPENCLAW_DIR/$name" ]]; then
    continue
  fi
  if [[ -d "$OPENCLAW_DIR/$name" && -f "$OPENCLAW_DIR/$name/SKILL.md" ]]; then
    continue
  fi

  # Create directory with SKILL.md wrapper
  mkdir -p "$OPENCLAW_DIR/$name"

  # Extract frontmatter fields if they exist
  description=""
  skill_name=""
  if head -1 "$md_file" | grep -q '^---'; then
    # File has YAML frontmatter -- extract name and description
    # Use awk to get lines between first and second --- (macOS compatible)
    frontmatter=$(awk 'BEGIN{n=0} /^---$/{n++; next} n==1{print} n>=2{exit}' "$md_file")
    skill_name=$(echo "$frontmatter" | grep '^name:' | sed 's/^name: *//' | head -1 || true)
    description=$(echo "$frontmatter" | grep '^description:' | sed 's/^description: *//' | head -1 || true)
  fi

  # Fallback: extract first heading as description
  if [[ -z "$description" ]]; then
    description=$(grep '^# ' "$md_file" | head -1 | sed 's/^# //' || true)
  fi
  [[ -z "$skill_name" ]] && skill_name="$name"
  [[ -z "$description" ]] && description="Skill synced from Claude Code standalone file"

  # Read the original content (skip existing frontmatter if present)
  if head -1 "$md_file" | grep -q '^---'; then
    # Strip existing frontmatter, take everything after second ---
    body=$(awk 'BEGIN{n=0} /^---$/{n++; if(n==2){found=1; next}} found{print}' "$md_file")
  else
    body=$(cat "$md_file")
  fi

  # Write SKILL.md with proper frontmatter
  cat > "$OPENCLAW_DIR/$name/SKILL.md" <<SKILLEOF
---
name: $skill_name
description: $description
---

$body
SKILLEOF

  log "  [->openclaw] $name (wrapped standalone .md)"
  SYNCED_TO_OPENCLAW=$((SYNCED_TO_OPENCLAW + 1))
done

# ──────────────────────────────────────────────
# Direction B: OpenClaw -> Claude Code
# ──────────────────────────────────────────────

for skill_entry in "$OPENCLAW_DIR"/*/; do
  [[ ! -d "$skill_entry" ]] && continue
  name=$(basename "$skill_entry")
  should_skip "$name" && continue

  # Must have SKILL.md to be a valid skill
  # Resolve through symlinks for this check
  if [[ -L "$skill_entry" ]]; then
    resolved=$(readlink "$skill_entry" 2>/dev/null || true)
    # Resolve relative symlinks
    if [[ "$resolved" != /* ]]; then
      resolved="$OPENCLAW_DIR/$resolved"
    fi
    [[ ! -f "$resolved/SKILL.md" ]] && continue
  else
    [[ ! -f "$skill_entry/SKILL.md" ]] && continue
  fi

  # Skip if it's already a symlink pointing to agents (already synced Direction A)
  if [[ -L "$OPENCLAW_DIR/$name" ]]; then
    target=$(readlink "$OPENCLAW_DIR/$name" 2>/dev/null || true)
    if [[ "$target" == *".agents/skills/"* ]]; then
      continue
    fi
  fi

  # Check if already in Claude skills
  if [[ -e "$CLAUDE_DIR/$name" || -e "$CLAUDE_DIR/$name.md" ]]; then
    continue
  fi

  # Check if already in agents skills
  if [[ -e "$AGENTS_DIR/$name" ]]; then
    continue
  fi

  # This is an OpenClaw-only skill -- symlink into Claude skills
  # Use absolute path since OpenClaw skills may be symlinks themselves
  real_path=$(cd "$OPENCLAW_DIR/$name" 2>/dev/null && pwd -P)
  ln -s "$real_path" "$CLAUDE_DIR/$name"
  log "  [->claude] $name (symlink from openclaw)"
  SYNCED_TO_CLAUDE=$((SYNCED_TO_CLAUDE + 1))
done

# ──────────────────────────────────────────────
# Summary
# ──────────────────────────────────────────────

SUMMARY="Synced $SYNCED_TO_OPENCLAW skills Claude->OpenClaw, $SYNCED_TO_CLAUDE skills OpenClaw->Claude"
log ""
log "$SUMMARY"

# Log to memory
if [[ -d "$(dirname "$MEMORY_LOG")" ]]; then
  if [[ ! -f "$MEMORY_LOG" ]]; then
    cat > "$MEMORY_LOG" <<'EOF'
# Skill Sync Log

Tracks bidirectional skill syncing between Claude Code and OpenClaw.

EOF
  fi

  if (( SYNCED_TO_OPENCLAW > 0 || SYNCED_TO_CLAUDE > 0 )); then
    cat >> "$MEMORY_LOG" <<EOF
### $(date +%Y-%m-%d) - $SUMMARY
[pattern] Ran sync-skills.sh. $SYNCED_TO_OPENCLAW to OpenClaw, $SYNCED_TO_CLAUDE to Claude.
EOF
  fi
fi

exit 0
