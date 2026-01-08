# Commit-Push-PR Command

**Purpose**: Automate the complete git workflow: stage → commit → push → create PR

**Boris's pattern**: Uses inline bash to pre-compute ALL git context upfront, minimizing round trips.

## Usage

```bash
claude /commit-push-pr
# Handles everything automatically
```

## Bash Pre-Computation (Run First!)

```bash
BRANCH=$(git branch --show-current)
STATUS=$(git status --porcelain)
DIFF_STAT=$(git diff --cached --stat 2>/dev/null || git diff --stat 2>/dev/null)
DIFF_FILES=$(git diff --cached --name-only 2>/dev/null || git diff --name-only 2>/dev/null)
RECENT_COMMITS=$(git log --oneline -5 2>/dev/null || echo "No commits yet")
REMOTE_BRANCH=$(git rev-parse --abbrev-ref --symbolic-full-name @{u} 2>/dev/null || echo "none")

# Auto-detect commit type from files
if echo "$DIFF_FILES" | grep -q "test\|spec"; then
  COMMIT_TYPE="test"
elif echo "$DIFF_FILES" | grep -q "\.md$"; then
  COMMIT_TYPE="docs"
elif echo "$DIFF_FILES" | grep -q "package\.json\|requirements\.txt"; then
  COMMIT_TYPE="chore"
else
  COMMIT_TYPE="feat"
fi

echo "╔════════════════════════════════════════╗"
echo "║         GIT STATUS SUMMARY             ║"
echo "╚════════════════════════════════════════╝"
echo ""
echo "Branch: $BRANCH"
echo "Files changed: $(echo "$DIFF_FILES" | wc -l | xargs)"
echo "Suggested commit type: $COMMIT_TYPE"
echo ""
echo "Files:"
echo "$DIFF_FILES" | sed 's/^/  - /'
echo ""
echo "Diff stats:"
echo "$DIFF_STAT" | sed 's/^/  /'
echo ""
echo "Recent commits (for style reference):"
echo "$RECENT_COMMITS" | sed 's/^/  /'
echo ""
```

## Workflow Steps

### 1. Stage All Changes
```bash
git add -A
```

### 2. Generate Commit Message
Analyze the diff and create a conventional commit message:

**Format**: `<type>(<scope>): <subject>`

**Types**:
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `style`: Code style changes (formatting, etc.)
- `refactor`: Code refactoring
- `test`: Adding/updating tests
- `chore`: Maintenance (dependencies, config, etc.)

**Guidelines**:
- Subject line: 50 chars max, imperative mood ("add feature" not "added feature")
- Body: Explain WHY, not WHAT (code shows what)
- Reference issues: "Closes #123"
- Keep it concise but informative

### 3. Create Commit
```bash
git commit -m "$(cat <<'EOF'
[generated commit message]

Co-Authored-By: Claude Sonnet 4.5 <noreply@anthropic.com>
EOF
)"
```

### 4. Push to Remote
```bash
# If remote branch exists
git push

# If new branch (no upstream)
git push -u origin $BRANCH
```

### 5. Create Pull Request (if not on main/master)
```bash
# Only if not on main/master branch
if [ "$BRANCH" != "main" ] && [ "$BRANCH" != "master" ]; then
  gh pr create --fill
fi
```

## Error Handling

### Pre-commit Hook Failed
- **NEVER use --amend** (Boris's rule!)
- Show the error
- Fix the issues
- Create a NEW commit

### Push Failed (Behind Remote)
- Suggest: `git pull --rebase`
- Then: `git push`

### PR Creation Failed
- Provide manual command: `gh pr create --title "..." --body "..."`
- Or: Open browser to create PR manually

## Example Output

```
✓ Staged 5 files
✓ Commit created: abc1234 "feat(auth): add Supabase authentication"
✓ Pushed to origin/feat/auth
✓ PR created: https://github.com/user/repo/pull/42

Summary:
- Branch: feat/auth
- Files changed: 5
- Commit: abc1234
- PR: #42
```

## Integration with Workflow

**After /execute completes**:
```bash
claude /code-review  # Review first!
# Fix any issues
claude /commit-push-pr  # Then commit
```

**In /guide workflow**:
Phase 6 automatically runs /commit-push-pr after verification passes

## Notes

- Runs fast because all context pre-computed in bash
- No back-and-forth with model
- Follows conventional commits standard
- Auto-includes Co-Authored-By footer
- Handles new branches gracefully
- Won't create PR on main/master (safety)
