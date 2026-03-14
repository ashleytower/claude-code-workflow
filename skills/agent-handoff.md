---
name: agent-handoff
description: Use any time work passes from one agent to another in a NEXUS pipeline: engineering to QA, QA failure back to developer, phase gate transition (Phase N to N+1), or escalation after 3 QA failures. Generates the correct template (Standard / QA PASS / QA FAIL / Escalation / Phase Gate) with full context so receiving agents do not lose state. Without this, agents lose context at boundaries and coordination breaks down.
---

# NEXUS Agent Handoff

Context loss at agent boundaries is the primary cause of multi-agent coordination failure. This skill generates a properly structured handoff every time.

## When to Use

Any time work passes from one agent to another:
- Engineering hand-off to QA
- QA failure sent back to developer
- Phase transition (Phase 1 -> Phase 2, etc.)
- After a sprint ends and work continues
- Escalation after 3 QA failures

## How to Invoke

Ask the user:
1. Which agent just completed work?
2. Which agent receives the work next?
3. What was produced? (brief description)
4. Did QA run? What was the verdict?

Then generate the appropriate handoff document below.

---

## Template 1: Standard Agent-to-Agent Handoff

Use for any work transfer between agents.

```markdown
# NEXUS Handoff Document

## Metadata
| Field | Value |
|-------|-------|
| From | [Agent Name] |
| To | [Agent Name] |
| Phase | Phase [N] — [Phase Name] |
| Task | [Task ID and description] |
| Priority | [Critical / High / Medium / Low] |
| Timestamp | [YYYY-MM-DDTHH:MM:SSZ] |

## Context
**Project**: [Project name]
**Current State**: [What has been completed — be specific]
**Relevant Files**:
- [file/path/1] — [what it contains]
- [file/path/2] — [what it contains]
**Dependencies**: [What this work depends on]
**Constraints**: [Technical, timeline, or resource constraints]

## Deliverable Request
**What is needed**: [Specific, measurable deliverable]
**Acceptance criteria**:
- [ ] [Criterion 1 — measurable]
- [ ] [Criterion 2 — measurable]
- [ ] [Criterion 3 — measurable]

## Quality Expectations
**Must pass**: [Quality criteria for this deliverable]
**Evidence required**: [What proof of completion looks like]
**Handoff to next**: [Who receives the output and in what format]
```

---

## Template 2: QA PASS

Use when Evidence Collector or other QA agent approves a task.

```markdown
# NEXUS QA Verdict: PASS

## Task
| Field | Value |
|-------|-------|
| Task | [ID] — [Description] |
| Developer Agent | [Agent Name] |
| QA Agent | [Agent Name] |
| Attempt | [N] of 3 |

## Verdict: PASS

## Evidence
**Functional Verification**:
- [x] [Acceptance criterion 1] — verified
- [x] [Acceptance criterion 2] — verified

**CI Status** (Travel App):
- typecheck: pass
- tests: pass
- lint: pass

## Next Action
Agents Orchestrator: Mark task complete, advance to next task in backlog.
```

---

## Template 3: QA FAIL

Use when QA rejects a task and sends it back to the developer.

```markdown
# NEXUS QA Verdict: FAIL

## Task
| Field | Value |
|-------|-------|
| Task | [ID] — [Description] |
| Developer Agent | [Agent Name] |
| QA Agent | [Agent Name] |
| Attempt | [N] of 3 |

## Verdict: FAIL

## Issues Found

### Issue 1: [Category] — [Severity: Critical / High / Medium / Low]
**Description**: [Exact description of the problem]
**Expected**: [What should happen per acceptance criteria]
**Actual**: [What actually happens]
**Fix instruction**: [Specific, actionable fix]
**Files to modify**: [Exact file paths]

### Issue 2: [Category] — [Severity]
[Same structure]

## Acceptance Criteria Status
- [x] [Criterion 1] — passed
- [ ] [Criterion 2] — FAILED (see Issue 1)
- [ ] [Criterion 3] — FAILED (see Issue 2)

## Retry Instructions
Fix ONLY the issues listed above. Do not introduce new features or changes.
This is attempt [N] of 3 maximum.
If attempt 3 fails: escalate to Agents Orchestrator.
```

---

## Template 4: Escalation (After 3 Failures)

Use when a task exceeds 3 retry attempts.

```markdown
# NEXUS Escalation Report

## Task
| Field | Value |
|-------|-------|
| Task | [ID] — [Description] |
| Developer Agent | [Agent Name] |
| QA Agent | [Agent Name] |
| Attempts Exhausted | 3/3 |
| Escalation To | Agents Orchestrator |

## Failure History

### Attempt 1
- Issues found: [Summary]
- Fixes applied: [What changed]
- Result: FAIL — [Why it still failed]

### Attempt 2
- Issues found: [Summary]
- Fixes applied: [What changed]
- Result: FAIL — [Why it still failed]

### Attempt 3
- Issues found: [Summary]
- Fixes applied: [What changed]
- Result: FAIL — [Why it still failed]

## Root Cause Analysis
[Why the task keeps failing]

## Recommended Resolution
Choose one:
- [ ] Reassign to different developer agent ([recommended agent])
- [ ] Decompose into smaller sub-tasks ([proposed breakdown])
- [ ] Revise approach — architecture/design change needed
- [ ] Accept current state with documented limitations
- [ ] Defer to future sprint

## Impact Assessment
**Blocking**: [What other tasks are blocked]
**Timeline Impact**: [Effect on schedule]
```

---

## Template 5: Phase Gate

Use when transitioning between NEXUS phases.

```markdown
# NEXUS Phase Gate Handoff

## Transition
| Field | Value |
|-------|-------|
| From Phase | Phase [N] — [Name] |
| To Phase | Phase [N+1] — [Name] |
| Gate Result | PASSED / FAILED |

## Gate Criteria Results
| Criterion | Threshold | Result | Evidence |
|-----------|-----------|--------|----------|
| [Criterion] | [Threshold] | PASS / FAIL | [Evidence] |

## Documents Carried Forward
1. [Document] — [Purpose for next phase]
2. [Document] — [Purpose for next phase]

## Constraints for Next Phase
- [Constraint from this phase's findings]

## Agents for Next Phase
| Agent | Role | Priority |
|-------|------|----------|
| [Agent] | [Role] | Immediate / As needed |

## Risks Carried Forward
| Risk | Severity | Mitigation |
|------|----------|------------|
| [Risk] | [P0-P3] | [Plan] |
```

---

## Quick Reference

| Situation | Template |
|-----------|----------|
| Assigning work to another agent | Template 1 (Standard) |
| QA approved | Template 2 (PASS) |
| QA rejected | Template 3 (FAIL) |
| 3 retries exhausted | Template 4 (Escalation) |
| Moving between phases | Template 5 (Phase Gate) |

## Evals

### Eval 1: Standard agent-to-agent handoff
Prompt: "The Backend Architect just finished implementing the trip-sharing API endpoint. Now the API Tester needs to validate it. Generate the handoff."
Expected: Generates a Template 1 (Standard) handoff document. Includes FROM: Backend Architect, TO: API Tester. Populates Context, Deliverable Request, and Acceptance Criteria sections. Asks for relevant files and specific acceptance criteria if not already provided.
Pass if: Uses correct template structure with all required fields (From, To, Phase, Task, Context, Deliverable Request, Quality Expectations), includes measurable acceptance criteria.

### Eval 2: QA FAIL handoff with specific issues
Prompt: "Evidence Collector found two issues on attempt 2: the save button is missing on tablet layout, and the loading spinner doesn't show during async operations. Generate the QA FAIL handoff back to the Frontend Developer."
Expected: Generates a Template 3 (QA FAIL) handoff. Sets Attempt to 2 of 3. Lists both issues with Category and Severity. Includes specific Fix instructions and file references. Notes this is attempt 2 and warns that attempt 3 would escalate.
Pass if: Uses Template 3, correctly shows attempt number, lists each issue with description/expected/actual/fix format, references the 3-attempt limit.

### Eval 3: Phase Gate transition
Prompt: "Phase 2 (Foundation) is complete. CI/CD is operational, the design system is in place, and we're ready to move to Phase 3 (Build). Generate the phase gate handoff."
Expected: Generates a Template 5 (Phase Gate) handoff. Shows Phase 2 -> Phase 3 transition with PASSED gate result. Includes gate criteria results table. Lists documents carried forward and agents needed for Phase 3 build work.
Pass if: Uses Template 5, includes gate criteria table with PASS results, documents Phase 3 agent assignments, carries forward relevant constraints or risks.
