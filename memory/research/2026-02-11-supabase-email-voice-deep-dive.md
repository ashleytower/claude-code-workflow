# Deep Dive: Supabase, Email, Voice CRM - Feb 11, 2026

## Supabase Mapping (VERIFIED)

Two separate projects, zero table overlap:

### Project 1: clnxmkbqdwtyywmgtnjj (Max AI Employee)
- Apps: max-ai-employee, agency-dashboard, second-brain
- Tables (12): email_queue, draft_corrections, dm_queue, leads, lead_scrape_runs, tasks, memory, documents, audit_log, scheduled_jobs, clients, credentials
- 3 migrations

### Project 2: ctyxnhcljruyciebkwef (MTL Craft Cocktails CRM)
- Apps: mtl-craft-cocktails-ai (voice dashboard), client-portal-proposal
- Tables (35+): events, quotes, emails, domain_memory, draft_feedback, draft_patterns, entities, facts, episodes, contact_identifiers, correction_patterns, user_preferences, email_filters, workflows, portal_config, etc.
- 34 migrations

## Email Architecture
[decision] Gmail stays as single source of truth for conversations (Max via Rube MCP). Resend only for transactional/fire-and-forget from portal. Do NOT introduce Resend for conversation email -- breaks thread integrity and correction learning.

## Dashboard Email System (Resend-based)
[research] mtl-craft-cocktails-ai uses Resend at mail.mtlcraftcocktails.com. Has 23 voice email commands, 4-level autonomy (AUTO/DRAFT/PROPOSAL/ESCALATE), ValidatorAgent, SalesAgent with pricing engine, draft learning with behavior injection. More advanced than Max's email-master.

## Supabase Consolidation
[decision] Can share one Supabase. Recommend evaluating merge direction: dashboard project has 35+ tables and is more mature. Max's 12 tables could merge into it.

## Voice CRM Agents
[research] 7 agent types with ThinkingProtocol base (Perceive->Retrieve->Reason->Plan->Act->Verify->Learn):
- DirectorAgent (router), EmailAgent (7-step), SalesAgent (pricing engine), OperationsAgent (logistics), ValidatorAgent (6-check gate), InquiryQualifier (lead scoring), WorkflowCoordinator
