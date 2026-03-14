---
name: nexus-micro
description: Activate NEXUS-Micro mode for targeted tasks (1-5 days). Use for bug fixes, single features, audits, and focused improvements. Streamlined pipeline with stall detection.
---

# NEXUS-Micro Mode

Streamlined multi-agent coordination for targeted tasks. 5-10 agents max. 1-5 days.

## When to Use

- Fixing a specific bug
- Adding a single feature
- Running an audit (performance, compliance, accessibility)
- Investigating an issue
- One-day content or design tasks

Not this? Use nexus-sprint for multi-week feature builds.

## Scenarios

### Fix a Bug

```
Activate Backend Architect to investigate and fix [BUG DESCRIPTION].
After fix, activate API Tester to verify the fix.
Then activate Evidence Collector to confirm no visual regressions.
```

### Single Feature

```
Activate [Frontend Developer / Backend Architect] to implement [FEATURE].
Acceptance criteria: [LIST SPECIFIC CRITERIA]
After implementation, activate Evidence Collector for QA.
Reality Checker to gate completion.
```

### Performance Audit

```
Activate Performance Benchmarker to diagnose performance issues.
Scope: [API response times / Page load / Database queries / All]
After diagnosis, activate Infrastructure Maintainer for optimization.
DevOps Automator deploys any infrastructure changes.
```

### Compliance or Accessibility Audit

```
Activate Legal Compliance Checker for comprehensive compliance audit.
Scope: [GDPR / CCPA / HIPAA / ALL] or [Accessibility WCAG 2.1 AA]
After audit, activate Executive Summary Generator to create stakeholder report.
```

### UX Improvement

```
Activate UX Researcher to identify usability issues in [FEATURE/AREA].
After research, activate UX Architect to design improvements.
Frontend Developer implements changes.
Evidence Collector verifies improvements.
```

## Pipeline Structure

```
PLAN -> BUILD -> QA -> SHIP
```

| Step | Agent(s) | Output |
|------|----------|--------|
| PLAN | Sprint Prioritizer | Scoped task list with acceptance criteria |
| BUILD | Frontend / Backend / Relevant specialist | Implementation |
| QA | Evidence Collector + API Tester (if API work) | PASS or FAIL with evidence |
| SHIP | DevOps Automator or Reality Checker gate | Deployed / approved |

## Stall Detection

**2 identical outputs = halt.**

If the same agent produces two outputs without meaningful progress:
1. Stop that agent immediately
2. Report to user: what was attempted and what stalled
3. Request direction before continuing

This prevents loops where an agent retries the same broken approach repeatedly.

## Dev-QA Loop (Simplified)

```
1. Developer implements task
2. Evidence Collector validates
3. IF PASS: done
   IF FAIL: one retry with specific fixes
   IF FAIL again: halt and report to user (no 3rd blind attempt in Micro mode)
```

## Travel App Specific

For Travel App tasks, before QA submits PASS:
```bash
npm run typecheck  # must pass
npm test           # must pass (or pre-existing failures only)
npm run lint       # must pass
```

## Agent Quick Reference

| Task | Use |
|------|-----|
| UI bug | Frontend Developer + Evidence Collector |
| API bug | Backend Architect + API Tester |
| Performance | Performance Benchmarker + Infrastructure Maintainer |
| Content | Content Creator + Brand Guardian |
| Security | Legal Compliance Checker |
| Data issue | Data Analytics Reporter |

## Handoff Format (Compact)

For micro tasks, use this condensed handoff:

```
FROM: [Agent]
TO: [Agent]
TASK: [What needs doing]
CONTEXT: [What you completed, what files you touched]
DELIVERABLES: [What you produced]
STATUS: PASS / FAIL / NEEDS-DIRECTION
NEXT: [One clear instruction for the receiving agent]
```

## Output

When NEXUS-Micro completes:
- Summary of what was done
- Files changed
- QA evidence (pass/fail status)
- Any remaining concerns flagged
