#!/bin/bash
# Git push review gate - pause for review before pushing

echo ""
echo "========================================="
echo "  GIT PUSH REVIEW GATE"
echo "========================================="
echo ""
echo "About to push to remote. Quick checklist:"
echo ""
echo "  [ ] Tests passing?"
echo "  [ ] No console.log statements?"
echo "  [ ] No sensitive data/secrets?"
echo "  [ ] Commit messages clear?"
echo ""
echo "Recent commits to be pushed:"
git log --oneline @{u}..HEAD 2>/dev/null || git log --oneline -5
echo ""
echo "Changed files:"
git diff --stat @{u}..HEAD 2>/dev/null || git diff --stat HEAD~1
echo ""
echo "========================================="

exit 0
