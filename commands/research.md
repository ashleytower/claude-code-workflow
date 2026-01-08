# Research Command

**Purpose**: Research official docs, find boilerplates, and verify up-to-date patterns BEFORE writing ANY code. Prevents hallucination!

## Usage

```bash
claude /research "[topic]"
# Example: claude /research "Supabase authentication with React Native"
```

## CRITICAL Rule

**NO CODE is written without running /research first!**

This command must complete before any implementation begins.

## Process

### 1. Search Official Documentation
Use WebSearch and Rube MCP to find:
- Official docs for the technology
- Latest version and release notes
- Official examples and code samples
- Breaking changes from previous versions
- Best practices from maintainers

### 2. Find Existing Boilerplates/Repos
Search GitHub for:
- `"[technology] boilerplate 2025"`
- `"[technology] starter template"`
- `"[technology] example app"`

Filter by:
- Stars (>100 preferred)
- Last updated (within 6 months)
- Active maintenance (recent commits)

Look for:
- Official examples from package maintainers
- Well-documented repos
- Active communities

### 3. Verify Everything is Up-to-Date
Check:
- package.json / requirements.txt versions
- Compare with latest releases on npm/PyPI
- Look for deprecation warnings in docs
- Verify patterns are current (2025+)
- Check for breaking changes

### 4. Community Research (YouTube, Reddit, X)
Search for:
- YouTube tutorials (recent, good engagement)
- Reddit discussions (r/reactnative, r/webdev, etc.)
- X posts (#ReactNative, #NextJS, etc.)

Extract:
- Common pain points
- User recommendations
- What works vs what doesn't

### 5. Document Findings
Create: `.claude/research/[topic-name].md`

## Output Template

```markdown
# Research: [Topic]

*Researched on: [date]*

## Official Documentation

**Source**: [URL to official docs]
**Current Version**: v[X.Y.Z]
**Last Updated**: [date]
**Status**: ✓ Active / ⚠ Maintenance Mode / ❌ Deprecated

### Key Points
- Feature 1: [description]
- Feature 2: [description]

### Breaking Changes (if upgrading)
- Change 1: [what changed, how to migrate]

## Boilerplates/Examples Found

### Option 1: [Repo Name]
- **GitHub**: [URL]
- **Stars**: [count] ⭐
- **Last Updated**: [date]
- **Status**: ✓ Active / ⚠ Outdated
- **What it includes**: [features]
- **Pros**: [advantages]
- **Cons**: [disadvantages]

### Option 2: [Repo Name]
[Same structure]

### Recommendation
Use [Option X] because: [reasoning]

## Current Best Practices (2025)

### Pattern 1: [Name]
```[language]
// Code example from official docs
[code]
```
**Why**: [explanation]

### Pattern 2: [Name]
[Same structure]

## Deprecated Patterns (DO NOT USE)

### Anti-Pattern 1: [Name]
```[language]
// Old way (don't do this!)
[code]
```
**Why deprecated**: [explanation]
**Use instead**: [new pattern]

## Dependencies & Versions

| Package | Current Version | Latest Version | Status |
|---------|-----------------|----------------|--------|
| [package-1] | v[X.Y.Z] | v[X.Y.Z] | ✓ Up-to-date |
| [package-2] | v[X.Y.Z] | v[A.B.C] | ⚠ Update available |

## Community Insights

### YouTube
- [Video Title] by [Channel] - [views] views
  - Key takeaway: [summary]

### Reddit/X
- Common pain points: [list]
- Recommended approaches: [list]
- Things to avoid: [list]

## Code Examples (From Official Docs)

### Example 1: [Use Case]
```[language]
// Attribution: [source URL]
[code from official docs]
```

### Example 2: [Use Case]
[Same structure]

## Ready-to-Use Checklist

- [ ] Official docs reviewed
- [ ] Latest version confirmed
- [ ] Boilerplate found (or conscious decision to start fresh)
- [ ] Best practices documented
- [ ] Deprecated patterns identified
- [ ] Dependencies verified as current
- [ ] Code examples available

## Notes

[Any additional context, warnings, or considerations]
```

## Integration with Other Commands

**Before /plan**:
Always run `/research` first to gather context

**Before /execute**:
Reference research docs in execution plan

**In /guide**:
Phase 2 automatically runs /research

## Rube MCP Integration

```javascript
// Search Supabase documentation
RUBE_SEARCH_TOOLS: "Supabase authentication documentation"

// Find GitHub boilerplates
RUBE_SEARCH_TOOLS: "React Native Supabase starter template"

// Search across Google Drive, Notion, etc.
RUBE_MULTI_EXECUTE_TOOL: [...]
```

## Example Research Session

```bash
User: "I need to implement Supabase auth in my React Native app"

Claude: "Let me research this before we write any code..."

[Runs /research "Supabase authentication with React Native"]

Output:
- Official Supabase docs (v2.45.1 - latest)
- Boilerplate found: supabase/auth-helpers (⭐ 2.3k, updated 2 weeks ago)
- Current best practice: Use supabase-js v2 + @supabase/auth-helpers-react
- Deprecated: supabase-js v1 (use v2 instead)
- Code examples saved to .claude/research/supabase-auth.md

Ready to proceed with planning!
```

## Notes

- NEVER skip this step - it's your protection against hallucination
- Always verify dates (things change fast in web dev!)
- Trust official docs over blog posts
- Recent (6 months) > older repos
- Check GitHub issues for known problems
