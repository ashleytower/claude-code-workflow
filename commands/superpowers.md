---
name: superpowers
description: Multi-repo orchestration and coordination
model: opus
---

# Superpowers - Multi-Repo Orchestration

Coordinate work across multiple repositories simultaneously. Full-stack development at scale.

## Concept

**Orchestrate entire system across repos**:
- Frontend repo
- Backend repo
- Mobile repo
- Infrastructure repo
- Documentation repo

All updated in parallel, kept in sync, deployed together.

## Multi-Repo Architecture

```
project/
├── frontend/          (Next.js)
├── backend/           (FastAPI)
├── mobile/            (React Native)
├── infrastructure/    (Terraform)
└── docs/              (Documentation)
```

Each repo:
- Own git repository
- Own CI/CD pipeline
- Own deployment
- Own Claude session

But coordinated as one system.

## Setup

### 1. Define System

Create `~/.claude/systems/my-app.yaml`:

```yaml
name: my-app
repos:
  frontend:
    path: ~/projects/my-app-frontend
    tech: nextjs
    agent: frontend
  backend:
    path: ~/projects/my-app-backend
    tech: fastapi
    agent: backend
  mobile:
    path: ~/projects/my-app-mobile
    tech: react-native
    agent: react-native-expert
  infrastructure:
    path: ~/projects/my-app-infra
    tech: terraform
    agent: bash
  docs:
    path: ~/projects/my-app-docs
    tech: markdown
    agent: bash

dependencies:
  - mobile depends_on frontend  # Shares types
  - frontend depends_on backend # API contract
  - infrastructure deploys_all  # Deployment orchestration
```

### 2. Launch Orchestrator

```bash
/superpowers my-app "Add user authentication"
```

This:
1. Analyzes which repos need changes
2. Opens terminal per repo
3. Launches appropriate agent per repo
4. Coordinates changes to keep them in sync
5. Voice notifications per repo completion

## Example: Add Authentication

### Command

```bash
/superpowers my-app "Add user authentication with JWT"
```

### Orchestrator Analyzes

```markdown
## System Analysis

Feature: User authentication with JWT

Repos requiring changes:
✓ backend: JWT generation, auth endpoints
✓ frontend: Login UI, auth context, API client
✓ mobile: Login screen, auth storage, API client
✓ infrastructure: Environment variables, secrets
✓ docs: API documentation, setup guide

Execution plan:
1. Backend: Implement auth first (others depend on it)
2. Frontend + Mobile: Parallel (both consume backend)
3. Infrastructure: After backend (needs new env vars)
4. Docs: After all (documents final implementation)
```

### Terminal Layout

```
Terminal 1 (Orchestrator - Main):
  Coordination and monitoring

Terminal 2 (Backend):
  cd ~/projects/my-app-backend
  claude "@backend 'Implement JWT authentication'"

Terminal 3 (Frontend):
  cd ~/projects/my-app-frontend
  claude "@frontend 'Add login UI and auth context'"

Terminal 4 (Mobile):
  cd ~/projects/my-app-mobile
  claude "@react-native-expert 'Add login screen and auth'"

Terminal 5 (Infrastructure):
  cd ~/projects/my-app-infra
  claude "Add JWT_SECRET to environment config"

Terminal 6 (Docs):
  cd ~/projects/my-app-docs
  claude "Document authentication API and setup"
```

### Coordination

**Phase 1: Backend First**
```bash
Terminal 2: [Working...]
[Voice: "Backend authentication complete"]

# Orchestrator waits for backend to finish
# before starting frontend/mobile
```

**Phase 2: Frontend + Mobile (Parallel)**
```bash
Terminal 3: [Working...]
Terminal 4: [Working...]

[Voice: "Frontend auth complete"]
[Voice: "Mobile auth complete"]
```

**Phase 3: Infrastructure**
```bash
Terminal 5: [Working...]
[Voice: "Infrastructure updated"]
```

**Phase 4: Documentation**
```bash
Terminal 6: [Working...]
[Voice: "Documentation complete"]
```

### Integration Verification

Orchestrator runs cross-repo verification:

```bash
# Check API contract matches
diff backend/openapi.json frontend/src/api/types.ts

# Check mobile uses same types
diff frontend/src/api/types.ts mobile/src/api/types.ts

# Check env vars match
grep JWT_SECRET backend/.env.example infrastructure/terraform/env_vars.tf

# All match! ✓
```

## Shared Type Safety

Keep types in sync across repos:

### Option A: Shared Package

```bash
# Create shared types repo
my-app-types/
└── src/
    ├── User.ts
    ├── Auth.ts
    └── index.ts

# Each repo imports
backend: from '@my-app/types'
frontend: from '@my-app/types'
mobile: from '@my-app/types'
```

### Option B: OpenAPI Generation

```bash
# Backend generates OpenAPI
backend/openapi.json

# Frontend generates types from it
cd frontend && npm run generate-types

# Mobile generates types from it
cd mobile && npm run generate-types
```

### Option C: Monorepo (Alternative)

```bash
# Single repo with workspaces
my-app/
├── packages/
│   ├── types/
│   ├── frontend/
│   ├── backend/
│   └── mobile/
└── package.json (workspaces)
```

Superpowers can work with monorepos too.

## Deployment Coordination

### Sequential Deployment (Safe)

```bash
# 1. Deploy backend first
cd backend && deploy

# 2. Wait for health check
curl https://api.myapp.com/health

# 3. Deploy frontend (consumes new API)
cd frontend && deploy

# 4. Deploy mobile (submit to stores)
cd mobile && deploy
```

### Parallel Deployment (Risky)

```bash
# Deploy all at once
cd backend && deploy &
cd frontend && deploy &
cd mobile && deploy &
wait

# Risk: Frontend/mobile may deploy before backend ready
# Mitigation: Use feature flags
```

### Blue-Green Deployment

```bash
# Deploy new version alongside old
cd infrastructure && terraform apply -var="version=v2"

# Test v2
curl https://v2.api.myapp.com/health

# Switch traffic
terraform apply -var="active_version=v2"

# Rollback if issues
terraform apply -var="active_version=v1"
```

## Cross-Repo PRs

Create PRs in all repos:

```bash
# Orchestrator creates linked PRs
cd backend && /commit-push-pr "Add user authentication backend"
cd frontend && /commit-push-pr "Add user authentication frontend"
cd mobile && /commit-push-pr "Add user authentication mobile"
cd infrastructure && /commit-push-pr "Add auth environment variables"
cd docs && /commit-push-pr "Document authentication API"

# Link PRs together
gh pr create --body "Related: frontend#123, mobile#456, infra#789"
```

## Monitoring Progress

Orchestrator dashboard:

```markdown
## Multi-Repo Progress

Feature: User Authentication

Status by Repo:
├─ backend:         ✓ Complete (PR #123)
├─ frontend:        🔄 In Progress (45%)
├─ mobile:          🔄 In Progress (60%)
├─ infrastructure:  ⏸️  Waiting (depends on backend)
└─ docs:            ⏸️  Waiting (depends on all)

Overall: 40% complete

Blockers: None
ETA: 2 hours
```

## Voice Notifications

Essential for multi-repo work:

```bash
"Backend authentication complete"
"Frontend at 50 percent"
"Mobile authentication complete"
"All repos complete. System ready for testing"
```

## Integration Testing

Test cross-repo integration:

```bash
# Start all services locally
docker-compose up

# Run E2E tests
cd frontend && npm run test:e2e
cd mobile && npm run test:e2e

# All pass! ✓
```

## Ralph Loop + Superpowers

Ultimate autonomy:

```bash
/superpowers my-app "Implement complete user management" --ralph-loop

# Runs each repo in Ralph Loop
# Keeps going until entire system complete
# Can run overnight
# Voice alerts when each repo finishes
```

## When to Use

✅ **Great for**:
- Full-stack features (touch multiple repos)
- System-wide refactors
- API version upgrades
- Type system changes
- Infrastructure updates affecting all repos

❌ **Not ideal for**:
- Single repo changes
- Hotfixes (too much coordination overhead)

## Example Workflows

### API Version Upgrade

```bash
/superpowers my-app "Upgrade to API v2"

# Orchestrator:
# 1. Backend: Implement v2 endpoints
# 2. Frontend: Update API client to v2
# 3. Mobile: Update API client to v2
# 4. Infrastructure: Add v2 routing
# 5. Docs: Update API documentation
# 6. Verify: Cross-repo integration tests
```

### Database Schema Change

```bash
/superpowers my-app "Add user_preferences table"

# Orchestrator:
# 1. Backend: Migration + models + endpoints
# 2. Frontend: UI for preferences
# 3. Mobile: UI for preferences
# 4. Infrastructure: Database permissions
# 5. Docs: Schema documentation
```

### Dependency Upgrade

```bash
/superpowers my-app "Upgrade React to v19"

# Orchestrator:
# 1. Frontend: Upgrade React, fix breaking changes
# 2. Mobile: Upgrade React Native, fix breaking changes
# 3. Docs: Update setup guides
```

## Notes

- Requires Opus (best coordination reasoning)
- Multiple terminals (one per repo)
- Voice notifications essential
- Git coordination critical
- Can combine with Ralph Loop
- Ultimate development velocity
- Used by YC hackathon teams (shipped 6+ repos overnight)

---

**Philosophy**: Think in systems, not repos. Coordinate the whole, not just parts.

**Real-world success**: YC hackathon teams shipped complete multi-repo products overnight using this approach + Ralph Loop.

**Sources:**
- [Ralph Loop Multi-Repo Guide](https://mejba.me/blog/ralph-loop-claude-code-autonomous-ai-coding-framework-guide)
- [Autonomous Coding at Scale](https://medium.com/@joe.njenga/ralph-wiggum-claude-code-new-way-to-run-autonomously-for-hours-without-drama-095f47fbd467)
