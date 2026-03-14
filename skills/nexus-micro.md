---
name: nexus-micro
description: Use when fixing a specific bug, adding a single self-contained feature, running an audit (performance, accessibility, compliance), or investigating an isolated issue — any task completable in 1-5 days by a small agent team. Runs PLAN -> BUILD -> QA -> SHIP pipeline with stall detection (2 identical outputs = halt) and a 1-retry Dev-QA loop that escalates to the user on second failure. Do NOT use for multi-week builds — use nexus-sprint instead.
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

## Evals

### Eval 1: Bug fix activation
Prompt: "There's a bug where the trip detail screen crashes when a trip has no itinerary items. It throws a TypeError. Can you fix it?"
Expected: Activates NEXUS-Micro in bug fix scenario. Assigns Frontend Developer or Backend Architect to investigate, followed by Evidence Collector for QA. Runs CI checks (typecheck, test, lint) before marking complete. Does not set up multi-week Sprint phases.
Pass if: Uses Micro pipeline (PLAN -> BUILD -> QA -> SHIP), not Sprint, assigns appropriate developer agent plus a QA agent, includes CI verification.

### Eval 2: Stall detection — two identical outputs
Prompt: "The Backend Architect tried to add a database index but got 'column does not exist' twice in a row and produced the same error output both times. What do we do?"
Expected: Recognizes the stall condition (2 identical outputs = halt). Stops the agent. Reports to the user what was attempted and what stalled. Asks for direction before continuing. Does not attempt a third identical run automatically.
Pass if: Halts the agent, reports the stall to the user, asks for direction rather than retrying, references the stall detection rule.

### Eval 3: Micro vs Sprint routing — single feature
Prompt: "I want to add a dark mode toggle to the settings screen. The user flips a switch and the whole app changes theme."
Expected: Recognizes this as a self-contained single feature within 1-5 day scope. Activates NEXUS-Micro with Frontend Developer as primary and Evidence Collector for QA. Does not activate full NEXUS-Sprint with multi-week phases.
Pass if: Chooses Micro mode explicitly, does not spin up Sprint phase structure, assigns Frontend Developer and Evidence Collector as the agent pair.
