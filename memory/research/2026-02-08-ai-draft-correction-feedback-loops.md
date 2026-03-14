# AI Draft Correction Feedback Loop Research

### 2026-02-08 - Comprehensive research on how AI assistants learn from human corrections/feedback on drafts

[research] Investigated 6 major approaches for AI learning from human edits. Key finding: the best practical approach for a solo-founder AI employee is **RAG-based correction retrieval** (store correction triplets, retrieve at generation time) combined with **periodic rule summarization** into the system prompt. Fine-tuning/DPO is overkill at this scale. DSPy GEPA optimizer is interesting for automated prompt improvement but adds complexity. LangSmith "Self-Learning GPTs" pattern is the most production-ready open-source reference implementation.

## Top Approaches Ranked (for Max AI Employee context)

1. **RAG Correction Retrieval** - Store (original, corrected, reason) triplets in vector DB, retrieve similar ones at generation time as few-shot examples
2. **Periodic Rule Summarization** - Every N corrections, LLM summarizes patterns into rules appended to system prompt
3. **LangSmith Self-Learning GPTs** - Automated feedback-to-dataset pipeline with dynamic few-shot injection
4. **Mem0 Memory Layer** - Already integrated in this project, handles fact extraction and contradiction resolution
5. **DSPy GEPA Optimizer** - Automated prompt optimization from textual feedback, good for batch improvement
6. **DPO/RLHF Fine-tuning** - Most powerful but requires significant data volume and compute, not practical for small scale

## Key Implementation Detail
For email-drafter specifically: store correction pairs in Supabase `email_corrections` table, embed them, and retrieve top-3 similar corrections when drafting new emails. Periodically (weekly) summarize correction patterns into system prompt rules.
