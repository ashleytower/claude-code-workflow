# Gemini to Claude Migration Plan
## MTL Craft Cocktails AI - Non-Voice Services

**Date:** 2026-02-24  
**Status:** Planning Phase  
**Objective:** Migrate all non-voice Gemini services to Claude API

---

## Executive Summary

This codebase uses Gemini across 7 non-voice services:
- **Email operations** (2 services): draftService, draftLearningService
- **Quote/proposal generation** (1 service): proposalService
- **Memory & entity management** (1 service): memoryIngestion
- **Wearable transcript classification** (1 service): omiClassifier
- **Location extraction** (1 service): placeExtractionService
- **Email orchestration** (1 service): emailAgent (delegates to draftService)

**Total Gemini API calls:** ~6 distinct call patterns across the system
**Migration complexity:** HIGH (especially memoryIngestion with embeddings)
**Timeline estimate:** 3-4 weeks with full agent team

---

## Service-by-Service Migration Strategy

### 1. **placeExtractionService.ts** ⭐ START HERE
**Complexity:** LOW | **Priority:** HIGH (easy win for team morale)

#### Current Gemini Usage
- Model: gemini-2.0-flash (fallback only, not primary)
- Call type: generateContent()
- Input: Plain text task description
- Output: JSON (hasPlace, placeName, confidence)
- Temperature: Default (not specified)
- Usage frequency: Only when pattern matching uncertain

#### Migration Path to Claude
```typescript
// OLD (Gemini)
const response = await genAI.models.generateContent({
  model: 'gemini-2.0-flash',
  contents: prompt,
});

// NEW (Claude)
const response = await claude.messages.create({
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 200,
  messages: [{ role: 'user', content: prompt }],
});
```

#### Key Changes
- Replace GoogleGenAI import with @anthropic-ai/sdk
- Change response.text → response.content[0].text
- Adjust prompt: Claude doesn't need "Respond with ONLY JSON" as aggressively; native JSON mode better
- JSON parsing identical
- Temperature removal (Claude uses top_p/temperature differently; default 1.0 is fine for fallback)

#### Migration Difficulty
- ✅ Trivial input/output transformation
- ✅ No structured output schema needed
- ✅ Simple text prompt
- ❌ None - this is the simplest migration

#### Regression Test
```typescript
test('extractPlaceFromText migrates from Gemini to Claude', async () => {
  const result = await extractPlaceFromText('pick up sugar at Costco');
  expect(result.hasPlace).toBe(true);
  expect(result.placeName).toEqual('Costco');
  expect(result.confidence).toBe('high');
});
```

**Estimated effort:** 2 hours (implement + test)

---

### 2. **omiClassifier.ts** ⭐ SECOND
**Complexity:** MEDIUM | **Priority:** HIGH (structured output pattern reusable)

#### Current Gemini Usage
- Model: gemini-2.0-flash
- Call types: 
  - generateContent() with responseMimeType='application/json' + responseSchema
  - Used twice: classifyIntent() and extractEntities()
- Input: Voice transcript classification prompt with detailed schema
- Output: Structured JSON via Gemini's schema enforcement
- Temperature: 0.1 (strict classification)
- Gemini-specific features: responseMimeType + responseSchema

#### Migration Path to Claude
```typescript
// OLD (Gemini with schema enforcement)
const response = await genAI.models.generateContent({
  model: 'gemini-2.0-flash',
  contents: `${CLASSIFICATION_PROMPT}\n\nTRANSCRIPT: "${transcript}"`,
  config: {
    responseMimeType: 'application/json',
    responseSchema: CLASSIFICATION_SCHEMA,
    temperature: 0.1,
  }
});

// NEW (Claude with structured output via claude.messages + manual parsing)
// Option A: Manual JSON parsing (simpler for small payloads)
const response = await claude.messages.create({
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 500,
  temperature: 0.1,
  system: CLASSIFICATION_PROMPT,
  messages: [{ 
    role: 'user', 
    content: `Classify this transcript and return JSON:\n\nTRANSCRIPT: "${transcript}"\n\nReturn ONLY valid JSON matching this structure: ${JSON.stringify(CLASSIFICATION_SCHEMA)}` 
  }],
});

// Option B: Structured output (if available in Claude 3.7+)
const response = await claude.messages.create({
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 500,
  temperature: 0.1,
  system: CLASSIFICATION_PROMPT,
  messages: [...],
  response_format: {
    type: 'json_schema',
    json_schema: CLASSIFICATION_SCHEMA  // May not be available yet
  }
});
```

#### Key Changes
- Replace responseMimeType + responseSchema with JSON-in-prompt instruction
- Claude's structured output is evolving; manual JSON parsing safer for now
- Temperature: 0.1 → temp: 0.1 (equivalent)
- Prompt injection: Move CLASSIFICATION_PROMPT to system role
- Response parsing: Identical (JSON.parse after response.content[0].text)

#### Gemini-Specific Features Needing Translation
| Gemini Feature | Claude Equivalent |
|---|---|
| responseMimeType: 'application/json' | System prompt: "Return only valid JSON" |
| responseSchema validation | Manual validation after JSON.parse() |

#### Migration Difficulty
- ⚠️ Schema enforcement lost (will rely on prompt clarity)
- ✅ JSON response format works identically
- ✅ Temperature equivalent
- ⚠️ Need to add post-parse validation to replace schema enforcement

#### Regression Test
```typescript
test('classifyIntent migrates from Gemini to Claude', async () => {
  const result = await classifyIntent('pick up limes tomorrow');
  expect(result.type).toBe('task');
  expect(result.confidence).toBeGreaterThan(0.7);
  expect(result.entities.taskDescription).toContain('limes');
});
```

#### Post-Migration Validation
Add validation after JSON.parse:
```typescript
function validateClassificationResult(result: any): ClassificationResult {
  if (!result.type || !validTypes.includes(result.type)) {
    throw new Error(`Invalid type: ${result.type}`);
  }
  if (typeof result.confidence !== 'number' || result.confidence < 0 || result.confidence > 1) {
    throw new Error(`Invalid confidence: ${result.confidence}`);
  }
  return result;
}
```

**Estimated effort:** 4 hours (implement + validation + test)

---

### 3. **proposalService.ts** ⭐ THIRD (Dual Model)
**Complexity:** HIGH | **Priority:** MEDIUM (bilingual + quote integration)

#### Current Gemini Usage
- Models: 
  - gemini-2.0-flash (proposal generation, line 75)
  - gemini-3-flash-preview (event detail extraction, line 260)
- Call types: generateContent() x2
- Inputs: 
  - Proposal: Complex prompt with EVENT DETAILS, INVESTMENT & INCLUSIONS, CLIENT HISTORY, BRAND VALUES
  - Event extraction: Email text → structured event details
- Outputs:
  - Proposal: Free-form email body text
  - Event extraction: Structured JSON (eventDate, headcount, eventType, etc.)
- Temperature: 0.7 for proposals, 0.2 for extraction
- Language support: Bilingual (en/fr) templates built into prompt

#### Migration Path to Claude
```typescript
// OLD: Dual Gemini models
const proposalResponse = await ai.models.generateContent({
  model: 'gemini-2.0-flash',
  contents: prompt,
  config: { temperature: 0.7, maxOutputTokens: 2048 }
});

const extractResponse = await ai.models.generateContent({
  model: 'gemini-3-flash-preview',  // Different model for extraction
  contents: extractPrompt,
  config: { temperature: 0.2, maxOutputTokens: 500 }
});

// NEW: Single Claude model for both
const proposalResponse = await claude.messages.create({
  model: 'claude-3-5-sonnet-20241022',  // Single model handles both
  max_tokens: 2048,
  temperature: 0.7,
  system: buildProposalSystemPrompt(details, quote, language),
  messages: [{ role: 'user', content: 'Generate proposal email body only' }]
});

const extractResponse = await claude.messages.create({
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 500,
  temperature: 0.2,
  messages: [{ 
    role: 'user', 
    content: `Extract event details from email:\n${emailText}\n\nReturn JSON with: eventDate, headcount, eventType, etc.` 
  }]
});
```

#### Key Changes
- Gemini uses 2 different models; Claude uses 1 (simpler)
- Move complex prompt sections to system role
- Split proposal instructions into clearer prompt sections
- Event extraction: Same JSON pattern as omiClassifier (manual parsing)
- Bilingual support: Keep in system prompt, Claude handles en/fr equally well
- maxOutputTokens 2048 → max_tokens: 2048 (equivalent)

#### Gemini-Specific Features
| Gemini Feature | Claude Equivalent |
|---|---|
| gemini-3-flash-preview for "faster" extraction | Not needed; Claude 3.5-Sonnet is fast enough |
| Dual model approach | Single Claude model; temperature adjustment sufficient |

#### Migration Difficulty
- ⚠️ Two models become one (verify Claude 3.5-Sonnet handles both tasks well)
- ✅ Prompt structure translates cleanly
- ✅ Bilingual support identical
- ✅ Quote calculation integration unchanged

#### Regression Tests
```typescript
test('generateProposal migrates to Claude', async () => {
  const details: EventDetails = {
    clientName: 'John',
    eventType: 'wedding',
    headcount: 100,
    eventDate: '2026-06-15'
  };
  const result = await generateProposal(details, 'en');
  expect(result.success).toBe(true);
  expect(result.body).toContain('$'); // Has pricing
  expect(result.subject).toContain('Wedding');
});

test('extractEventDetails migrates to Claude', async () => {
  const email = 'We need bartending for our wedding on June 15, about 100 guests';
  const details = await extractEventDetails(email, 'john@example.com');
  expect(details.eventType).toBe('wedding');
  expect(details.headcount).toBe(100);
});
```

**Estimated effort:** 6 hours (dual model testing, bilingual verification, quote integration)

---

### 4. **draftService.ts** ⭐ FOURTH (Core Email Generation)
**Complexity:** VERY HIGH | **Priority:** CRITICAL (core business logic)

#### Current Gemini Usage
- Model: gemini-2.0-flash
- Call types: generateContent() x4 (generateEmailDraft, generateEmailSummary, modifyDraft, regenerateDraft)
- Inputs: Complex system prompts with CLIENT HISTORY, LEARNED PATTERNS, BEHAVIOR INJECTION, WRITING STYLE
- Outputs: Raw text email drafts
- Temperature: 0.4 (consistent, reliable)
- maxOutputTokens: 2048
- Gemini-specific: Pattern injection, behavior injection from draftLearningService

#### Migration Path to Claude
```typescript
// OLD (Gemini)
const response = await ai.models.generateContent({
  model: 'gemini-2.0-flash',
  contents: prompt,
  config: {
    temperature: 0.4,
    maxOutputTokens: 2048,
  }
});

// NEW (Claude)
const response = await claude.messages.create({
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 2048,
  temperature: 0.4,
  system: systemPrompt,  // Move complex instructions to system
  messages: [{ role: 'user', content: userPrompt }]
});
```

#### Key Changes
- Break complex prompt into system + user messages
- System prompt: INCOMING EMAIL, WRITING STYLE, BUSINESS KNOWLEDGE, BEHAVIOR RULES
- User prompt: Specific task (draft, modify, regenerate, summarize)
- Pattern/behavior injection: Identical mechanism (both in system prompt)
- Temperature: 0.4 unchanged
- Response parsing: response.content[0].text instead of response.text

#### Gemini-Specific Features
| Gemini Feature | Claude Equivalent |
|---|---|
| Single prompt with headers | Split into system + user messages |
| Pattern injection in prompt | Identical mechanism in system prompt |
| Behavior injection | Identical mechanism in system prompt |

#### Migration Difficulty
- ⚠️ HIGHEST complexity due to:
  - 4 different call patterns (draft, summary, modify, regenerate)
  - Complex context injection (client history, learned patterns)
  - Tight integration with draftLearningService
  - Email validation loops (validateDraft function)
  - Behavior injection mechanism needs careful testing
- ⚠️ Must maintain existing behavior:
  - missingInfoDetection logic
  - autonomy levels (AUTONOMY_LEVELS enum)
  - Thread context inclusion
- ✅ Prompt structure translates well
- ✅ Temperature equivalent
- ✅ Pattern injection mechanism identical

#### Regression Tests
```typescript
test('generateEmailDraft migrates to Claude', async () => {
  const incomingEmail = 'Hi, I want to book bartenders for my wedding...';
  const draft = await generateEmailDraft(incomingEmail, 'en', {});
  expect(draft).toBeTruthy();
  expect(draft.subject).toBeTruthy();
  expect(draft.body).toBeTruthy();
});

test('modifyDraft migrates to Claude', async () => {
  const original = 'Thank you for your inquiry...';
  const modified = await modifyDraft(original, 'Make it friendlier', 'en');
  expect(modified).toBeTruthy();
  // Qualitative: Should sound friendlier (manual verification)
});

test('behavior injection maintains quality', async () => {
  // Behavior from draftLearningService should still apply
  const behaviorInjection = 'Always mention "peace of mind" when talking about service';
  const draft = await generateEmailDraft(incomingEmail, 'en', {}, behaviorInjection);
  expect(draft.body).toContain('peace of mind');
});
```

**Estimated effort:** 10 hours (4 call patterns × complex testing)

---

### 5. **draftLearningService.ts** ⭐ FIFTH (Pattern Extraction)
**Complexity:** HIGH | **Priority:** HIGH (supports draftService quality)

#### Current Gemini Usage
- Model: gemini-2.0-flash
- Call types: generateContent() x3 for JSON responses
  - analyzeCorrectionWithAI() - Compare original vs. corrected
  - suggestPatternFromCorrection() - Extract behavioral pattern
  - addExplicitPattern() - Convert pattern to prompt injection
- Inputs: Comparison prompts with ORIGINAL, CORRECTED, INSTRUCTION sections
- Outputs: Structured JSON (summary, type, pattern_type, pattern_description, prompt_injection)
- Temperature: 0.2-0.3 (consistency for learning)
- Gemini-specific: JSON schema enforcement via responseMimeType

#### Migration Path to Claude
```typescript
// OLD (Gemini with JSON schema)
const response = await ai.models.generateContent({
  model: 'gemini-2.0-flash',
  contents: prompt,
  config: { temperature: 0.2, maxOutputTokens: 300 }
});

// NEW (Claude with JSON in prompt)
const response = await claude.messages.create({
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 300,
  temperature: 0.2,
  messages: [{
    role: 'user',
    content: `${prompt}\n\nReturn ONLY valid JSON with structure: ${JSON.stringify(expectedSchema)}`
  }]
});
```

#### Key Changes
- Remove responseMimeType + responseSchema
- Add JSON structure to prompt instruction
- Add post-parse validation (since Claude won't enforce schema)
- Temperature: 0.2-0.3 unchanged
- Response parsing: response.content[0].text

#### Validation After JSON.parse
```typescript
function validateLearningResult(result: any, expectedType: string): void {
  if (!result.summary || typeof result.summary !== 'string') {
    throw new Error('Invalid summary');
  }
  if (!result.type || !['improvement', 'style', 'tone'].includes(result.type)) {
    throw new Error(`Invalid type: ${result.type}`);
  }
  if (!result.pattern_description || typeof result.pattern_description !== 'string') {
    throw new Error('Missing pattern description');
  }
  // Additional validation per result.type
}
```

#### Regression Tests
```typescript
test('analyzeCorrectionWithAI migrates to Claude', async () => {
  const original = 'Thanks for your inquiry';
  const corrected = 'Thank you so much for reaching out...';
  const analysis = await analyzeCorrectionWithAI(original, corrected, 'en');
  expect(analysis.summary).toBeTruthy();
  expect(analysis.type).toBeTruthy();
});

test('extracted patterns are valid for injection', async () => {
  const pattern = await suggestPatternFromCorrection(original, corrected, instruction);
  const injection = pattern.prompt_injection;
  expect(typeof injection).toBe('string');
  expect(injection.length).toBeGreaterThan(10);
});
```

#### Integration Test
```typescript
test('learned patterns improve draft quality', async () => {
  // Step 1: Generate initial draft
  const draft1 = await generateEmailDraft(email, 'en');
  
  // Step 2: User corrects it
  const correction = { original: draft1.body, corrected: 'User correction...' };
  
  // Step 3: Learn pattern
  const pattern = await suggestPatternFromCorrection(
    correction.original,
    correction.corrected,
    'Maintain professional tone'
  );
  
  // Step 4: Next draft uses learned pattern
  const draft2 = await generateEmailDraft(newEmail, 'en', {}, pattern.prompt_injection);
  
  // Verify improvement (manual or via Claude evaluation)
  expect(draft2.body).toBeTruthy();
});
```

**Estimated effort:** 8 hours (3 call patterns + validation + integration testing)

---

### 6. **memoryIngestion.ts** ⭐ FINAL (Most Complex)
**Complexity:** EXTREME | **Priority:** MEDIUM (foundational but can defer if time-constrained)

#### Current Gemini Usage - MOST COMPLEX SERVICE
- Models: gemini-2.0-flash + **gemini-embedding-001** (embeddings)
- Call types:
  1. generateContent() for entity extraction
  2. generateContent() for fact extraction
  3. embedContent() for semantic embeddings ← **NO CLAUDE EQUIVALENT**
  4. generateContent() for episode summaries
- Inputs: Structured extraction prompts with entity/fact type definitions
- Outputs: 
  - Structured JSON for entities/facts
  - Float arrays (768-dim embeddings) for semantic search
- Temperature: 0.1 for extraction, 0.2 for summaries
- Gemini-specific features:
  - embedContent() API (Gemini has native embeddings)
  - Embedding model: gemini-embedding-001
  - Semantic similarity matching using embeddings

#### THE EMBEDDING PROBLEM
**Gemini-specific feature with no direct Claude equivalent:**
```typescript
// OLD (Gemini embeddings)
const embeddingResponse = await ai.models.embedContent({
  model: 'gemini-embedding-001',
  contents: text,
  config: {
    taskType: 'RETRIEVAL_DOCUMENT',
    outputDimensionality: 768
  }
});
const embedding = embeddingResponse.embeddings[0].values; // 768-dim vector
```

**Claude Ecosystem:**
- Claude API does NOT provide embedding models
- Options:
  1. **Replace with Voyage AI** (specialize in embeddings, 768-dim available)
  2. **Use OpenAI embeddings** (widely available, 1536-dim)
  3. **Keep Gemini embeddings** (minimal change, only this model)
  4. **Remove embeddings** (if semantic search not critical)

#### Migration Path Option 1: Voyage AI (Recommended)
```typescript
// Import Voyage AI client
import Voyage from '@voyageai/voyageai';
const voyageClient = new Voyage({ apiKey: process.env.VOYAGE_API_KEY });

// OLD (Gemini embeddings)
const embedding = await genAI.models.embedContent({...});

// NEW (Voyage embeddings)
const embeddingResponse = await voyageClient.embed({
  input: text,
  model: 'voyage-3-large',  // 1024-dim, can request 768-dim via API
  input_type: 'document'
});
const embedding = embeddingResponse.data[0].embedding; // 1024-dim vector
```

#### Migration Path Option 2: Keep Gemini Embeddings Only
```typescript
// Hybrid approach: Claude for extraction, Gemini for embeddings only
import Anthropic from '@anthropic-ai/sdk';
import { GoogleGenAI } from '@google/genai';

const claude = new Anthropic();
const geminiEmbeddings = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

// Use Claude for text generation (extractEntities, extractFacts, summarization)
const entities = await claude.messages.create({...});

// Use Gemini ONLY for embeddings
const embedding = await geminiEmbeddings.models.embedContent({...});
```

#### Key Changes for Non-Embedding Functions
```typescript
// For extractEntities, extractFacts, generateEpisodeSummary

// OLD (Gemini)
const response = await genAI.models.generateContent({
  model: 'gemini-2.0-flash',
  contents: prompt,
  config: { temperature: 0.1, maxOutputTokens: 300 }
});

// NEW (Claude)
const response = await claude.messages.create({
  model: 'claude-3-5-sonnet-20241022',
  max_tokens: 300,
  temperature: 0.1,
  messages: [{ role: 'user', content: prompt }]
});

const result = JSON.parse(response.content[0].text);
// Validate result matches expected schema
```

#### Gemini-Specific Features Needing Translation
| Gemini Feature | Claude Equivalent | Migration Path |
|---|---|---|
| generateContent() for extraction | claude.messages.create() | Direct translation |
| JSON response parsing | Identical mechanism | No change needed |
| embedContent() embeddings | Voyage AI or keep Gemini | Hybrid or replace |
| Temperature control | Identical | No change needed |

#### Migration Difficulty
- ⚠️ EXTREME complexity:
  - Multiple call patterns (4 distinct types)
  - Embeddings require new dependency (Voyage AI) OR hybrid approach
  - Semantic search depends on embedding quality matching
  - TTL handling, contradiction detection tied to embeddings
  - Large integration surface with rest of system
  - Vector search database integration must maintain compatibility
- ⚠️ Embedding migration risks:
  - Dimension mismatch (768 → 1024) affects similarity thresholds
  - Embedding quality differs between models (may need re-indexing)
  - Semantic search results may change (requires re-evaluation)
- ✅ Non-embedding functions translate cleanly
- ⚠️ Requires careful testing of semantic search quality

#### Regression Tests
```typescript
test('extractEntities migrates to Claude', async () => {
  const transcript = 'Sarah is getting married in June with 100 guests';
  const entities = await extractEntities(transcript);
  expect(entities.name).toContain('Sarah');
  expect(entities.eventType).toBe('wedding');
  expect(entities.guestCount).toBe(100);
});

test('extractFacts migrates to Claude', async () => {
  const episode = 'Client Karen is allergic to citrus';
  const facts = await extractFacts(episode);
  expect(facts.some(f => f.type === 'client_preference')).toBe(true);
});

test('embeddings maintain semantic search quality', async () => {
  // Generate embedding for query
  const queryEmbedding = await generateEmbedding('wedding bartending');
  
  // Search should find relevant memories
  const results = await searchEntitiesSemantic('wedding bartending', 5);
  expect(results.length).toBeGreaterThan(0);
  expect(results[0].similarity).toBeGreaterThan(0.7);
});

test('semantic search threshold adjusts for new embedding model', async () => {
  // If switching from 768-dim Gemini to 1024-dim Voyage,
  // re-calibrate similarity thresholds
  const results = await searchEntitiesSemantic(query, 5);
  // Verify results are still relevant (manual inspection)
  results.forEach(r => console.log(`${r.entity}: ${r.similarity}`));
});
```

#### Integration Test - Semantic Search
```typescript
test('semantic search finds correct memories after migration', async () => {
  // Step 1: Add memories
  await logEpisode({
    id: 'ep1',
    text: 'Client John loves whiskey cocktails, dislikes gin',
    type: 'client_preference'
  });

  // Step 2: Search with different phrasing
  const results = await searchEntitiesSemantic('whiskey loving client', 5);
  
  // Should find John's preference despite different wording
  expect(results.some(r => r.content.includes('John'))).toBe(true);
  expect(results.some(r => r.content.includes('whiskey'))).toBe(true);
});
```

**Estimated effort:** 16 hours
- 4 hours: Non-embedding functions (extractEntities, extractFacts, summaries)
- 6 hours: Embedding migration (Voyage AI integration + threshold calibration)
- 6 hours: Semantic search testing + re-indexing

---

## Migration Roadmap (Prioritized)

| Phase | Service | Effort | Risk | Start | End |
|-------|---------|--------|------|-------|-----|
| **1 (Weeks 1)** | placeExtractionService | 2h | LOW | - | - |
| **1** | omiClassifier | 4h | LOW | - | - |
| **2 (Week 2)** | proposalService | 6h | MEDIUM | - | - |
| **2** | draftService | 10h | HIGH | - | - |
| **3 (Weeks 3-4)** | draftLearningService | 8h | MEDIUM | - | - |
| **3** | memoryIngestion | 16h | EXTREME | - | - |
| **Total** | | **46h** | Mixed | | |

**Team recommendation:** 
- Phase 1 (2 days): Frontend + Backend pair, code-reviewer oversight
- Phase 2 (2 days): Backend lead, both developers, daily verification
- Phase 3 (4 days): Backend specialist on memoryIngestion, parallel on draftLearningService

---

## Configuration Changes Required

### 1. Environment Variables
```bash
# NEW (for all services)
VITE_ANTHROPIC_API_KEY=sk-ant-...
ANTHROPIC_API_KEY=sk-ant-...

# OPTIONAL (if using Voyage AI for embeddings)
VOYAGE_API_KEY=pa-...

# REMOVE (if fully migrated)
VITE_GEMINI_API_KEY=
VITE_GOOGLE_GENAI_API_KEY=
```

### 2. SDK Imports
```typescript
// Remove
import { GoogleGenAI } from '@google/genai';

// Add
import Anthropic from '@anthropic-ai/sdk';
import Voyage from '@voyageai/voyageai';  // If using for embeddings
```

### 3. SDK Initialization
```typescript
// OLD
const genAI = new GoogleGenAI({ apiKey: process.env.GEMINI_API_KEY });

// NEW
const claude = new Anthropic({ apiKey: process.env.ANTHROPIC_API_KEY });
const voyage = new Voyage({ apiKey: process.env.VOYAGE_API_KEY });  // Optional
```

---

## Risk Mitigation Strategies

### 1. **Quality Regression Risk** (draftService, draftLearningService)
- Keep both implementations side-by-side during Phase 2-3
- A/B test draft quality (Claude vs. Gemini) with real emails
- Rollback procedure: Env flag to switch API per service
- Acceptance criteria: Draft quality metrics >= Gemini baseline

### 2. **Embedding Compatibility Risk** (memoryIngestion)
- Option A: Keep Gemini embeddings only (minimal risk)
- Option B: Pre-compute all embeddings with Voyage before cutover
- Option C: Shadow mode: Generate both embeddings, compare search results
- Test semantic search on 100+ real memories before go-live

### 3. **API Rate Limit Risk**
- Claude pricing differs from Gemini
- Estimate: draftService ~500 calls/day × 2KB avg = high token usage
- Mitigation: Request Claude API rate limit increase before Phase 2
- Monitor token usage daily during Phase 2-3

### 4. **Bilingual Support Risk** (proposalService)
- Claude handles en/fr identically to Gemini
- Test with 10+ French proposals before Phase 2 completion
- Regression test: French subject lines + body quality

---

## Post-Migration Validation

### Automated Checks
```bash
# Run for each service after migration
npm test -- --testPathPattern=draftService
npm test -- --testPathPattern=proposalService
npm test -- --testPathPattern=omiClassifier
npm test -- --testPathPattern=memoryIngestion

# Regression test suite
npm test -- --testNamePattern="migrat"
```

### Manual Verification Checklist
- [ ] Draft quality visual inspection (5 real emails)
- [ ] French proposal generation working
- [ ] Learned patterns improving future drafts
- [ ] Semantic search finding correct memories
- [ ] No API errors in production logs (24h)
- [ ] Response times within acceptable range

---

## Rollback Plan

If migration fails:

1. **Service-Level Rollback** (per service)
   ```typescript
   // Keep both implementations, switch via env var
   const useClaude = process.env.MIGRATE_TO_CLAUDE === 'true';
   const client = useClaude ? claude : gemini;
   ```

2. **Full Rollback** (if Phase 3 breaks system)
   - Revert commits (git revert)
   - Restore Gemini credentials
   - Restore .env variables
   - Downtime: ~15 minutes

3. **Decision Criteria for Rollback**
   - Draft quality < 80% of Gemini baseline
   - Semantic search accuracy < 90% match rate
   - API errors > 1% of requests
   - Response time regression > 50%

---

## Success Criteria

Migration is complete when ALL of the following are true:

- [ ] All 7 services using Claude instead of Gemini
- [ ] Regression test suite passes 100%
- [ ] Draft quality metrics >= Gemini baseline
- [ ] Semantic search accuracy >= 90%
- [ ] API cost reduced by 15-30% (estimate)
- [ ] Response times within 10% of current baseline
- [ ] 24h production monitoring shows no errors
- [ ] French proposal generation verified
- [ ] Learned patterns working correctly
- [ ] Full verification checklist passes

---

## Questions for Planning Phase

Before starting Phase 1, clarify:

1. **Embedding strategy:** Keep Gemini embeddings only, or migrate to Voyage AI?
2. **Rollback tolerance:** How many draft quality regressions acceptable before rollback?
3. **Team availability:** Can 2 developers dedicate 4 weeks full-time?
4. **Testing rigor:** Should we A/B test drafts in production or shadow-mode only?
5. **French verification:** Who will verify French proposal quality?
6. **Cutover timeline:** Phased rollout (one service at a time) or big-bang?

---

**Plan Status:** Ready for team review and approval before Phase 1 starts.
