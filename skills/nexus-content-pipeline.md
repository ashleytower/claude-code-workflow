---
name: nexus-content-pipeline
description: Use when content output requires strategy, quality control, and SEO — not for quick one-off writing. Runs Sprint Prioritizer -> Content Creator -> SEO Specialist -> Reality Checker, with a gate at each step so no draft advances without a content brief approved, no SEO pass without an approved draft, and no publish without Reality Checker PASS. Covers blog posts, landing page copy, email sequences, and multi-platform social campaigns.
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

## Evals

### Eval 1: Full pipeline activation for a blog post
Prompt: "I need a blog post about the top 10 travel planning mistakes. The audience is first-time international travelers. Goal is organic traffic from Google. Timeline is end of this week."
Expected: Activates the full Sprint Prioritizer -> Content Creator -> SEO Specialist -> Reality Checker pipeline. Starts with Sprint Prioritizer to scope the content brief. Outputs a brief with RICE-scored angles before proceeding. Does not skip to writing the draft without the brief being approved.
Pass if: Activates Sprint Prioritizer first, produces a content brief with angle options, gates the handoff to Content Creator on brief approval, mentions the SEO Specialist and Reality Checker as subsequent steps.

### Eval 2: Gate enforcement — brief not approved before drafting
Prompt: "Skip the strategy step, just go ahead and write the blog post draft now. I know what I want."
Expected: Explains that the content brief gate exists to ensure the draft covers the right angle, messages, and acceptance criteria. Offers a fast-track — asks 3-4 quick questions to produce a minimal brief that the user can approve in under 2 minutes — rather than skipping the gate entirely.
Pass if: Does not skip to drafting without any brief. Explains why the gate matters. Offers a streamlined path to get a brief quickly rather than eliminating it.

### Eval 3: Reality Checker NEEDS WORK on content — keyword stuffing
Prompt: "Reality Checker: the SEO Specialist added the keyword 'budget travel tips' 11 times in a 600-word post. The meta title and description are correct lengths. Everything else looks good."
Expected: Issues NEEDS WORK for keyword stuffing. Identifies keyword density as a specific issue (reads unnaturally). References the acceptance criterion 'no keyword stuffing'. Provides a Path to PASS requiring the Content Creator to reduce keyword repetition while maintaining search intent. Does not issue PASS.
Pass if: Issues NEEDS WORK not PASS, identifies keyword stuffing as the specific failure, references the no-stuffing acceptance criterion, specifies which criterion failed and what the fix is.
