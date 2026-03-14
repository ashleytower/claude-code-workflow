---
name: nexus-sprint
description: Use when starting a new feature, MVP, or multi-week build that requires design + engineering + QA coordination. Activates NEXUS-Sprint: 5-phase pipeline (Strategy -> Foundation -> Build -> Quality -> Launch), assigns agents by task type, enforces phase gates so no phase advances without passing quality criteria, and runs Dev-QA loops with 3-retry escalation to Orchestrator. Do NOT use for bug fixes or single-day tasks — use nexus-micro instead.
---

# NEXUS-Sprint Mode

NEXUS (Network of EXperts, Unified in Strategy) turns AI specialists into a coordinated pipeline. Sprint mode is for building a specific feature or MVP in 2-6 weeks.

## When to Use

- Building a new feature end-to-end
- Building an MVP from scratch (market already validated)
- Any work requiring design + engineering + QA coordination
- Timeline: 2-6 weeks

Not this? Use nexus-micro for bug fixes and 1-5 day tasks.

## Step 1: Gather Requirements

Ask the user:
1. What are you building? (feature/MVP description)
2. Target timeline? (in weeks)
3. Team size / available agents?

## Step 2: Activate

Copy and customize this activation prompt:

```
Activate Agents Orchestrator in NEXUS-Sprint mode.

Feature/MVP: [DESCRIBE WHAT YOU'RE BUILDING]
Timeline: [TARGET WEEKS]
Skip Phase 0 (market already validated).

Sprint team:
- PM: Senior Project Manager, Sprint Prioritizer
- Design: UX Architect, Brand Guardian
- Engineering: Frontend Developer, Backend Architect, DevOps Automator
- QA: Evidence Collector, Reality Checker, API Tester
- Support: Analytics Reporter

Begin at Phase 1 with architecture and sprint planning.
Run Dev-QA loops for all implementation tasks.
Reality Checker approval required before launch.
```

## Phase Structure

| Phase | Name | Key Agents | Gate |
|-------|------|-----------|------|
| 1 | Strategy & Architecture | Sprint Prioritizer, UX Architect, Backend Architect | Architecture approved |
| 2 | Foundation & Scaffolding | DevOps Automator, Frontend Developer, Backend Architect | Foundation verified |
| 3 | Build & Iterate | Dev-QA loops (all engineering + Evidence Collector) | All tasks pass QA |
| 4 | Quality & Hardening | Reality Checker, API Tester, Performance Benchmarker | Reality Checker PASS |
| 5 | Launch & Growth | Growth Hacker, Content Creator, DevOps Automator | Launched |

## Quality Gate Rules

**No phase advances without a passing gate.** Specifically:

- Phase 1 -> 2: Architecture spec complete + accepted
- Phase 2 -> 3: CI/CD pipeline operational + design system ready
- Phase 3 -> 4: All sprint tasks pass QA, no P0/P1 bugs, API endpoints validated
- Phase 4 -> 5: Reality Checker issues PASS (not NEEDS WORK)

## Dev-QA Loop (Phase 3 Core Mechanic)

```
FOR EACH task IN sprint_backlog:
  1. Assign to Developer Agent
  2. Developer implements
  3. Evidence Collector validates (screenshots + functional check)
  4. IF PASS: mark complete, next task
     IF FAIL (attempt < 3): send feedback, developer fixes, retry
     IF FAIL (attempt = 3): ESCALATE to Orchestrator
```

Escalation options (after 3 retries):
- Reassign to different developer agent
- Decompose task into smaller sub-tasks
- Revise approach / architecture
- Accept with documented limitations
- Defer to future sprint

## Agent Assignment by Task Type

| Task | Primary Agent | QA Agent |
|------|--------------|----------|
| React/RN UI | Frontend Developer | Evidence Collector |
| REST/GraphQL API | Backend Architect | API Tester |
| Database | Backend Architect | API Tester |
| CI/CD/Infra | DevOps Automator | Performance Benchmarker |
| Complex features | Senior Developer | Evidence Collector |
| Quick prototypes | Rapid Prototyper | Evidence Collector |

## Handoff Format Between Agents

Every agent handoff must use this structure:

```
FROM: [Agent Name]
TO: [Agent Name]
PHASE: Phase [N] — [Phase Name]
TASK: [Task ID and description]
CONTEXT: [What has been completed, relevant files, constraints]
DELIVERABLES: [Specific output produced]
QUALITY STATUS: PASS / FAIL / ESCALATE
ACCEPTANCE CRITERIA FOR NEXT PHASE:
  - [ ] [Criterion 1]
  - [ ] [Criterion 2]
RELEVANT FILES:
  - [path/to/file] — [what it contains]
```

## Travel App Context

For Travel App (React Native + Expo + Supabase), the CI command is:
```bash
npm run typecheck && npm test && npm run lint
```

Reality Checker must see all three pass before issuing PASS.

## Sprint Planning Output Format

Sprint Prioritizer should produce RICE-scored backlog:
- Reach: How many users affected (1-10)
- Impact: How much it improves experience (1-10)
- Confidence: Confidence in estimates (1-10)
- Effort: Person-days to implement
- RICE Score: (R x I x C) / E

## Key Principles

1. Evidence over claims — require proof (screenshots, test results, data) for all quality assessments
2. No phase advances without passing gate
3. Every handoff carries full context (agents do not share memory)
4. Max 3 retries per task before escalation
5. Reality Checker defaults to NEEDS WORK — requires overwhelming evidence for PASS

## Evals

### Eval 1: Basic sprint activation
Prompt: "I want to build a maps feature for my travel app — show nearby restaurants and points of interest on a map. We have about 3 weeks."
Expected: Activates NEXUS-Sprint, outputs Phase 1 agent assignments including Sprint Prioritizer and UX Architect, mentions quality gates and Dev-QA loop, includes sprint team composition.
Pass if: Mentions NEXUS-Sprint mode, includes Phase 1 as starting point, references Dev-QA loop or quality gates, assigns appropriate agents (Sprint Prioritizer, UX Architect, Backend Architect minimum).

### Eval 2: Quality gate enforcement — user tries to skip Reality Checker
Prompt: "The backend API looks pretty good, let's skip the Reality Checker and go straight to launch. We're behind schedule."
Expected: Refuses to skip the Phase 4 -> 5 gate. Explains that Reality Checker PASS is required before launch. Does not advance to Phase 5. Offers to expedite the Reality Checker process instead.
Pass if: Does not agree to skip Reality Checker, explains the gate requirement, does not proceed to Phase 5/launch, references the gate rules.

### Eval 3: Escalation after 3 Dev-QA failures
Prompt: "The Frontend Developer has failed QA 3 times on the map tile rendering task. Evidence Collector keeps flagging that markers don't appear on iOS. What do we do?"
Expected: Triggers the escalation path. Presents the 5 escalation options to the user (reassign agent, decompose task, revise architecture, accept with limitations, defer). Does not silently retry a 4th time.
Pass if: Presents escalation options explicitly, references the 3-retry limit, asks user to choose a resolution path rather than automatically retrying.
