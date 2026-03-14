---
name: nexus-content-pipeline
description: Content creation pipeline using NEXUS agent sequence. Sprint Prioritizer -> Content Creator -> SEO Specialist -> Reality Checker. Use for blog posts, landing pages, email sequences, social campaigns.
---

# NEXUS Content Pipeline

A coordinated multi-agent pipeline for content creation with quality gates at each step.

## When to Use

- Blog posts, articles, chapters
- Landing page copy
- Email sequences or drip campaigns
- Social media campaigns (multi-platform)
- Product marketing content
- Any content requiring strategy + creation + SEO + QA

## Pipeline Overview

```
Sprint Prioritizer -> Content Creator -> SEO Specialist -> Reality Checker
```

Each step produces a handoff. No step skips to the next without its gate passing.

---

## Step 1: Sprint Prioritizer (Strategy & Scoping)

Ask the user:
- What content are you creating?
- Who is the audience?
- What outcome do you want (traffic, signups, awareness, sales)?
- Timeline?

Activation prompt:

```
Activate Sprint Prioritizer.

Content project: [DESCRIBE WHAT IS BEING CREATED]
Target audience: [WHO YOU'RE WRITING FOR]
Goal: [TRAFFIC / SIGNUPS / AWARENESS / SALES / OTHER]
Timeline: [WHEN IT NEEDS TO BE DONE]

Prioritize and scope the content work:
1. Define the content goal and success metrics
2. Identify key messages and angles (3-5 options, RICE-scored)
3. Select the best angle based on audience and goal
4. Define acceptance criteria for the final piece
5. Specify what the Content Creator needs to know

Output: Content brief with selected angle, key messages, acceptance criteria.
```

**Gate**: Content brief approved before proceeding to Step 2.

---

## Handoff 1: Prioritizer -> Content Creator

```
FROM: Sprint Prioritizer
TO: Content Creator
TASK: [Content piece description]
CONTEXT:
  - Selected angle: [angle]
  - Key messages: [messages]
  - Audience: [audience description]
  - Tone: [tone guidance]
  - Format: [blog post / landing page / email / etc]
  - Word count target: [N words]
DELIVERABLES: Content brief
QUALITY STATUS: PASS
ACCEPTANCE CRITERIA FOR NEXT PHASE:
  - [ ] Draft covers all key messages
  - [ ] Tone matches audience
  - [ ] Strong hook in first paragraph
  - [ ] Clear CTA
```

---

## Step 2: Content Creator (Draft)

Activation prompt:

```
Activate Content Creator.

Content brief: [PASTE SPRINT PRIORITIZER OUTPUT]

Write [CONTENT TYPE] for [AUDIENCE].
Angle: [SELECTED ANGLE]
Key messages: [LIST]
Tone: [TONE]
Format requirements: [LENGTH / SECTIONS / CTA]

Quality bar:
- Strong hook that earns the reader's attention
- Every claim tied to evidence or flagged as assertion
- No generic filler — each sentence earns its place
- Ends with explicit next step for the reader

Produce: Full draft ready for SEO review.
```

**Gate**: Draft covers all key messages, has a strong hook, clear CTA, and no generic filler.

---

## Handoff 2: Content Creator -> SEO Specialist

```
FROM: Content Creator
TO: SEO Specialist
TASK: SEO optimization of [content piece]
CONTEXT:
  - Draft: [ATTACH OR PASTE FULL DRAFT]
  - Target audience: [audience]
  - Goal: [traffic goal if applicable]
  - Primary topic: [topic]
DELIVERABLES: Full content draft
QUALITY STATUS: PASS
ACCEPTANCE CRITERIA FOR NEXT PHASE:
  - [ ] Primary keyword identified and placed appropriately
  - [ ] Meta title and description written
  - [ ] Header structure (H1/H2/H3) optimized
  - [ ] Internal linking opportunities identified
  - [ ] No keyword stuffing or unnatural language introduced
```

---

## Step 3: SEO Specialist (Optimization)

Activation prompt:

```
Activate SEO Specialist.

Content draft: [PASTE CONTENT CREATOR OUTPUT]
Target: [ORGANIC TRAFFIC / FEATURED SNIPPET / LOCAL / OTHER]
Domain: [WEBSITE URL IF KNOWN]

Optimize for search without degrading readability:
1. Identify primary keyword and 2-3 secondary keywords
2. Optimize title, H1, H2s for keyword intent
3. Write meta title (50-60 chars) and meta description (150-160 chars)
4. Identify internal linking opportunities
5. Check for E-E-A-T signals (experience, expertise, authority, trust)
6. Flag any thin content sections that need expansion

Output: SEO-optimized draft + meta tags + keyword report.
Do NOT introduce keyword stuffing or make copy feel unnatural.
```

**Gate**: SEO improvements made without degrading voice or readability.

---

## Handoff 3: SEO Specialist -> Reality Checker

```
FROM: SEO Specialist
TO: Reality Checker
TASK: Final quality gate for [content piece]
CONTEXT:
  - Original brief: [BRIEF SUMMARY]
  - Final draft with SEO: [ATTACH]
  - Meta tags: [title + description]
  - Keyword targets: [list]
DELIVERABLES: SEO-optimized draft + meta tags
QUALITY STATUS: PENDING REALITY CHECK
ACCEPTANCE CRITERIA FOR PASS:
  - [ ] All key messages from brief are present
  - [ ] Tone matches audience
  - [ ] Strong hook in first paragraph
  - [ ] CTA is clear and present
  - [ ] Meta title is 50-60 chars
  - [ ] Meta description is 150-160 chars
  - [ ] No keyword stuffing (reads naturally)
  - [ ] No generic filler sentences
```

---

## Step 4: Reality Checker (Final Gate)

Activation prompt:

```
Activate Reality Checker.

YOUR DEFAULT VERDICT IS: NEEDS WORK

What is being validated: [CONTENT PIECE TITLE]

Original brief: [PASTE BRIEF]
Final content: [PASTE FINAL DRAFT]
SEO report: [PASTE SEO OUTPUT]

Acceptance criteria:
- [ ] All key messages from brief are present
- [ ] Tone matches the target audience
- [ ] Strong hook — earns attention in first paragraph
- [ ] CTA is clear and actionable
- [ ] Meta title: 50-60 characters
- [ ] Meta description: 150-160 characters
- [ ] Reads naturally — no keyword stuffing
- [ ] No generic filler — every sentence earns its place
- [ ] Brand voice consistent throughout

Issue every NEEDS WORK with specific line-level feedback.
Only issue PASS if all criteria are met with evidence.
```

---

## After Reality Checker PASS

Content is ready for:
- Publishing / scheduling
- A/B testing (if applicable)
- Distribution planning

If Reality Checker issues NEEDS WORK, return to the appropriate step (usually Content Creator) with the specific feedback, then re-run from that step forward.

## Quick Reference

| Platform | Primary Agent | Key Focus |
|----------|--------------|-----------|
| Blog / SEO | Content Creator + SEO Specialist | E-E-A-T, keyword intent |
| Landing page | Content Creator + Growth Hacker | Conversion, CTA |
| Email sequence | Content Creator | Open rate hook, single CTA |
| Social campaign | Social Media Strategist + Content Creator | Platform-native format |
| Product marketing | Brand Guardian + Content Creator | Positioning, voice |
