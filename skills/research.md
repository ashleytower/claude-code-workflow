---
name: research
description: Mandatory docs and context research before implementation
---

# Research Skill - Check Before You Code

**Rule: NEVER write code without checking docs first.**

## Process

### 1. Identify What You Need to Build

What framework/library/API are you using?

### 2. Check Official Docs

**Priority sources:**
1. Official documentation (docs.* URLs)
2. GitHub repository README
3. API reference docs
4. Migration guides

**Use WebSearch or WebFetch:**
```bash
# Example: Next.js App Router
WebSearch: "Next.js 15 App Router official documentation"
WebFetch: "https://nextjs.org/docs/app"

# Example: React Native
WebSearch: "React Native latest documentation"

# Example: Supabase
WebFetch: "https://supabase.com/docs"
```

### 3. Check Existing Codebase

**Use Grep to find patterns:**
```bash
# Find how API calls are done
Grep: "fetch.*api" output_mode: content

# Find authentication patterns
Grep: "auth|login" output_mode: content

# Find similar components
Grep: "export.*Button" output_mode: content
```

### 4. Check CLAUDE.md

Read `~/.claude/CLAUDE.md` or project's `./CLAUDE.md` for:
- Established patterns
- Known issues/learnings
- Team conventions
- Anti-patterns to avoid

### 5. Find Working Examples

**Search GitHub for proven implementations:**
```bash
# Example: Authentication in Next.js
WebSearch: "github next.js 15 authentication example stars:>1000"

# Example: React Native navigation
WebSearch: "github react native navigation example stars:>5000"
```

### 6. Verify Latest Version

Check you're looking at current docs (2026):
```bash
WebSearch: "library-name latest version 2026"
WebSearch: "library-name changelog 2026"
```

## Output Format

```markdown
## Research Results

### Library/Framework
- **Name**: [name]
- **Version**: [latest version]
- **Docs**: [official docs URL]

### Recommended Approach
[Specific pattern/method from docs]

### Code Example from Docs
```[language]
[copy exact example from official docs]
```

### Existing Patterns in Codebase
[What Grep found - how the codebase currently does this]

### CLAUDE.md Guidance
[Any relevant rules/patterns from CLAUDE.md]

### Working Examples
- [GitHub repo 1]: [URL] - [stars]
- [GitHub repo 2]: [URL] - [stars]

### Implementation Plan
1. [Step 1 based on docs]
2. [Step 2 based on docs]
3. [Step 3 based on existing patterns]

### Anti-Patterns to Avoid
- [Don't do X because...]
- [Avoid Y because...]
```

## When to Use

**ALWAYS before:**
- Writing new code
- Using a new library
- Implementing unfamiliar patterns
- Making architectural decisions

**NEVER:**
- Guess implementation details
- Use outdated patterns
- Ignore official docs
- Copy code without understanding

## Integration with Agents

All agents should call this skill when they need to implement something new:

```bash
# Agent realizes it needs to check docs
Skill: research "How to implement authentication in Next.js 15"
# Gets research results
# Then implements based on findings
```

## Notes

- Official docs > Stack Overflow > Blog posts
- Latest version matters (check 2026)
- Existing codebase patterns > new patterns
- CLAUDE.md is the source of truth for team
- GitHub stars indicate battle-tested code
