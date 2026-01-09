# Guide Command

**Purpose**: Interactive step-by-step guidance through the complete feature development workflow. This command tells you exactly what to do and when.

**User's request**: "I want to be guided like: work on this feature, send it to agents in multiple terminals. Make sure it works, then continue."

## Usage

```bash
claude /guide
# Starts or continues the guided workflow

claude /guide stats
# Shows your progress and achievements
```

## How It Works

The guide maintains state in `.claude/guide-state.json` to track:
- Current phase
- Features completed
- PRs created
- Learning captured
- Progress stats

## Complete Workflow

### Phase 0: Mandatory Codebase Exploration (CANNOT SKIP)

```
🔍 GUIDED BUILD - Phase 0: Codebase Exploration
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
⛔ CRITICAL: This phase CANNOT be skipped for existing projects
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

BEFORE anything else:

IF this is an existing project with code:

  1. ⛔ STOP: Do NOT make assumptions
  2. 🔍 EXPLORE: Use Task(Explore) to examine codebase
  3. 📖 READ: Examine key files identified
  4. ✅ VERIFY: Can you cite specific files/lines?

INVOKE: Task tool with subagent_type=Explore

Example:
  Task(Explore, "Thoroughly explore codebase:
  - What LLM/AI services are used?
  - What's the actual tech stack?
  - What features are implemented?
  - What's the architecture?
  medium thoroughness")

[Exploration completes]

✓ Exploration Results:
  - Tech stack: [actual frameworks found]
  - LLM: [actual service: Gemini/OpenAI/etc]
  - Features: [actually implemented]
  - Architecture: [actual structure]

MARK EXPLORATION COMPLETE:
  ~/.claude/scripts/agent-state.sh mark-explored

[Voice: "Exploration complete"]

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
IF new project (no code): Skip Phase 0, proceed to Phase 1
IF existing project: Phase 0 is MANDATORY before Phase 1
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

Next: Continue to Phase 1 (Project Detection)
```

### Phase 1: Project Detection & Initialization

```
🎯 GUIDED BUILD - Phase 1: Project Detection

Current Status: Analyzing project...

[Auto-detection runs]

CASE A: New Project (no package.json, no CLAUDE.md, no PRD)
─────────────────────────────────────────────────────────────
📋 New project detected. Need to create PRD first.

What are you building?
- Tell me about your project
- Who is it for?
- What problem does it solve?

[After discussion]
✓ Ready to create PRD

INVOKE: /create-prd [project-name]

✓ PRD created at ~/.claude/plans/[project-name]-prd.md
✓ Project initialized

[Voice: "PRD created"]

Next: Exit and run fresh execution:
  exit
  claude "Read PRD and begin: ~/.claude/plans/[project-name]-prd.md"

CASE B: Existing Project, New Feature (CLAUDE.md exists, no PRD for feature)
───────────────────────────────────────────────────────────────────────────
✓ Project detected: [from CLAUDE.md]
✓ Stack: [from package.json]

What feature are we building?

[User: "Add Stripe payments"]

✓ Feature: Stripe payments
✓ Skipping PRD (feature-level work)

[Voice: "Project ready"]

Next: Continue to Phase 2 (Research)

CASE C: Continuing Previous Work (PRD exists, guide-state.json exists)
─────────────────────────────────────────────────────────────────────
✓ Resuming: [feature name]
✓ Last phase: [phase name]
✓ Progress: [X/Y complete]

Continue from Phase [N]?

[User: "Yes"]

[Jumps to appropriate phase]
```

**Auto-Detection Logic**:

```javascript
// Check for project markers
const hasPackageJson = fileExists('package.json')
const hasCLAUDEmd = fileExists('CLAUDE.md') || fileExists('.claude/CLAUDE.md')
const hasPRD = fileExists('.claude/plans/*.prd.md')
const hasGuideState = fileExists('.claude/guide-state.json')

if (!hasPackageJson && !hasCLAUDEmd && !hasPRD) {
  // CASE A: New project - create PRD
  return 'new-project'
} else if (hasCLAUDEmd && !hasGuideState) {
  // CASE B: Existing project, new feature - skip to Phase 2
  return 'new-feature'
} else if (hasGuideState) {
  // CASE C: Continuing work - resume from last phase
  return 'resume'
}
```

### Phase 2: Research & Discovery

```
📚 Phase 2: Research & Discovery

What feature from the PRD are we building first?

[User: "User authentication with Supabase"]

✓ Feature selected: User authentication

Before we write ANY code, let's research:

INVOKE: /research "Supabase authentication with React Native"

[Research runs...]

✓ Research complete:
  - Official Supabase docs (v2.45.1 - latest)
  - Boilerplate found: supabase/auth-helpers (⭐ 2.3k)
  - Best practices documented
  - Code examples saved

📁 Research saved to: .claude/research/supabase-auth.md

[Voice: "Research complete"]

Ready to design the UI? (y/n)

Next: Run /guide to continue to Phase 3
```

### Phase 3: UI Design (If Applicable)

```
🎨 Phase 3: UI Design

Does this feature include UI components?

[User: "Yes - login and registration screens"]

✓ UI components identified

INVOKE: /ui-design "login and registration screens for React Native"

[UI design runs...]

Mockup generated:
- Login screen: Email/password + social auth
- Registration: Email, password, confirm password
- Design: Modern, clean, follows iOS HIG

[Shows mockup or detailed description]

Does this design look good? Need any changes?

[User: "Move social buttons above email/password"]

[Regenerates with changes]

Updated design ready. Approve?

[User: "Looks great!"]

✓ Design approved and saved to .claude/designs/auth-screens.md

[Voice: "UI design approved"]

Next: Run /guide to continue to Phase 4
```

### Phase 4: Planning

```
📝 Phase 4: Planning

Now let's plan the implementation.

INVOKE: /prime

[Loads PRD, research, approved UI designs, explores codebase]

✓ Context loaded:
  - PRD: [project name]
  - Research: supabase-auth.md
  - UI Design: auth-screens.md
  - Codebase explored

Based on the PRD and research, here's what we'll build:

Features:
1. Login screen (approved design)
2. Registration screen (approved design)
3. Supabase auth integration
4. Session management
5. Protected routes
6. Error handling

Technical approach:
- Use @supabase/auth-helpers-react-native
- AsyncStorage for session persistence
- Context API for auth state
- React Navigation auth flow

INVOKE: /plan user-authentication

✓ Structured plan created: .claude/plans/user-authentication.md

[Voice: "Planning complete"]

Review the plan. Does it look good?

[User: "Yes"]

Next: Run /guide to continue to Phase 5
```

### Phase 5: Context Reset & Execution

```
💻 Phase 5: Execution

⚠️  IMPORTANT: CONTEXT RESET REQUIRED

Why: Keep context light for better reasoning during implementation

Here's what to do:

1. Close this Claude Code session
2. Open 5 NEW terminal tabs (numbered 1-5)
3. In Terminal 1, run:

   claude /execute .claude/plans/user-authentication.md

This will:
- Load ONLY the plan (no other context)
- Execute step-by-step
- Run tests after each step
- Report results

While Terminal 1 executes, Terminals 2-5 will be used for parallel agents if needed.

[Voice: "Ready for execution. Please start new session."]

⏸️  PAUSED - Resume by running /guide after execution completes
```

### Phase 6: Post-Execution Verification

```
✅ Phase 6: Verification

[Detects you're back from execution session]

Welcome back! Let's verify the implementation.

INVOKE: /code-review

[Runs ruthless code review...]

Code Review Results:
❌ 2 critical issues found
⚠️  3 edge cases missing
✓ 1 performance concern

[Shows detailed feedback]

Please fix the critical issues and edge cases.

[User fixes issues]

Ready to re-verify?

[User: "Yes"]

INVOKE: /code-review

✓ All code review issues resolved!

INVOKE: /verify-app

[Runs E2E testing...]

Verification Results:
✓ All manual tests passed
✓ Auth flow works end-to-end
✓ Session persistence works
✓ Protected routes working

[Voice: "Verification complete. All checks passed."]

Next: Run /guide to continue to Phase 7
```

### Phase 7: Automated Quality Checks

```
🔍 Phase 7: Quality Checks

AUTOMATIC: Orchestrator running quality checks...

[Stop-Hook automatically triggers @orchestrator]

@orchestrator analyzing changes...

Detected changes:
- UI components: 2 files
- API integration: 3 files
- Tests: 4 files

Invoking quality agents:
- @frontend (checking UI against approved design)
- @api-expert (checking API integration)
- @verify-app (E2E testing)

[All agents run in parallel...]

✓ @frontend: UI matches approved design
✓ @api-expert: API integration looks good
✓ @verify-app: E2E tests pass

[Voice: "Quality checks complete. All passed."]

Next: Run /guide to continue to Phase 8
```

### Phase 8: Commit & PR

```
🚀 Phase 8: Commit & Create PR

Everything verified and quality checks passed!

INVOKE: /commit-push-pr

[Runs automated git workflow...]

✓ Changes staged (12 files)
✓ Commit created: abc1234 "feat(auth): implement Supabase authentication"
✓ Pushed to origin/feat/user-auth
✓ PR created: https://github.com/user/repo/pull/42

[Voice: "Pull request created"]

PR Summary:
- Branch: feat/user-auth
- Files: 12 changed
- PR: #42

Next: Run /guide to continue to Phase 9
```

### Phase 9: System Evolution & Learning

```
🎓 Phase 9: System Evolution & Learning

Two types of learning to capture:

A. BUG/ISSUE LEARNING (System Evolution)
─────────────────────────────────────────

Did we encounter any bugs or issues during this build?

Any patterns that caused problems?
Any integration issues?
Anything Claude struggled with?

[User: "Yes, Claude forgot to handle token expiration initially"]

✓ Learning opportunity identified

INVOKE: /system-evolve "Auth implementation missing token expiration handling"

[Analyzes workflow and proposes system improvements...]

Proposed system improvements:

1. Update ~/.claude/reference/api-development.md:
   Add section: "Authentication Token Handling"
   ```markdown
   - [ ] Handle token expiration
   - [ ] Implement refresh logic
   - [ ] Test expired token scenarios
   - [ ] Clear sensitive data on logout
   ```

2. Update /plan command template:
   Add checklist: "Auth Considerations"

3. Add to CLAUDE.md institutional knowledge:
   "Supabase Auth: Always handle token expiration explicitly. Use onAuthStateChange listener."

Apply these improvements?

[User: "Yes"]

✓ System updated
✓ Bug fixes captured

B. SUCCESS LEARNING (Reusable Skills)
──────────────────────────────────────

💡 Save this implementation as a reusable skill?

What did you build that could be reused?
- Third-party integrations (Stripe, Resend, Uploadthing)
- Authentication patterns (Clerk, Supabase)
- Complex workflows
- API integrations

[Auto-detects integrations from dependencies and code]

Detected:
├─ Stripe integration (stripe package, STRIPE_SECRET_KEY)
└─ Resend emails (resend package, RESEND_API_KEY)

Save as skills?

[User: "Yes, save Stripe"]

INVOKE: /learn 'stripe-payments'

[Extracts implementation into ~/.claude/skills/stripe-payments.md...]

✓ Skill saved: stripe-payments.md
✓ Includes: Setup code, use cases, gotchas, testing

Next time you "Add Stripe" = instant (uses saved skill)

[Voice: "Skill saved. Stripe ready for reuse."]

─────────────────────────────────────────

✓ System evolution complete
✓ Knowledge captured
✓ Skills saved for reuse

BUILD CYCLE COMPLETE

Feature: User Authentication + Payments
Status: ✓ Implemented, ✓ Verified, ✓ Committed, ✓ Learning Captured

Stats:
- Time: [duration]
- Files: 12 changed
- Tests: 15 added
- PRs: 1 created
- Skills saved: 1 (stripe-payments)

Next feature?
- Run /guide to start next feature from PRD
- Or run /guide stats to see overall progress
```

## Progress Tracking

```bash
claude /guide stats

📊 YOUR PROGRESS

Project: [from PRD]

Features Completed: 3/10
├─ ✓ User Authentication
├─ ✓ Profile Management
└─ ✓ Settings Screen

PRs Created: 3
Tests Added: 42
Commits: 18

System Improvements: 8
└─ Last: Auth token expiration handling

Current Streak: 7 days

Next Up (from PRD):
1. Push Notifications
2. Social Sharing
3. Analytics Dashboard
```

## State Management

Maintains state in: `.claude/guide-state.json`

```json
{
  "currentPhase": "verification",
  "currentFeature": "user-authentication",
  "featuresCompleted": ["..."],
  "prsCreated": ["..."],
  "systemImprovements": ["..."],
  "stats": {
    "features": 3,
    "prs": 3,
    "commits": 18,
    "tests": 42,
    "streak": 7
  }
}
```

## Integration with Other Commands

The guide command orchestrates ALL other commands:
- Phase 1: `/create-prd`
- Phase 2: `/research`
- Phase 3: `/ui-design`
- Phase 4: `/prime` + `/plan`
- Phase 5: `/execute`
- Phase 6: `/code-review` + `/verify-app`
- Phase 7: Orchestrator (automatic)
- Phase 8: `/commit-push-pr`
- Phase 9: `/system-evolve`

## Voice Notifications

Throughout the workflow:
- "PRD created successfully"
- "Research complete"
- "UI design approved"
- "Planning complete"
- "Ready for execution"
- "Verification complete"
- "Quality checks passed"
- "Pull request created"
- "System evolution complete"

## Multi-Terminal Coordination

When guide reaches execution phase:
- Instructs you to open 5 terminals
- Tells you exactly what to run in each
- Uses voice to notify when agents complete
- Coordinates parallel work automatically

## Notes

- Follow the guide's instructions exactly
- Don't skip phases (especially research and UI design!)
- The guide enforces best practices
- Progress is saved (can resume anytime)
- Voice keeps you informed even when away from desk
