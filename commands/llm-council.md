# LLM Council Command

**Purpose**: Query multiple LLMs via OpenRouter and compare their responses. Get consensus or diverse perspectives on any question.

## Usage

```bash
# Ask a question to the council
/llm-council "What's the best way to handle authentication in a React app?"

# Update model IDs to latest versions
/llm-council --update
```

## How It Works

When you ask a question:
1. Sends your question to multiple models via OpenRouter API
2. Collects responses from each model in parallel
3. Presents responses side-by-side for comparison
4. Optionally summarizes consensus/disagreements

## Models in the Council

| Model | Provider | Strength |
|-------|----------|----------|
| Claude Opus 4.5 | Anthropic | Complex reasoning, architecture |
| GPT-5.2 | OpenAI | General development, broad knowledge |
| Gemini Pro 3 | Google | Fast analysis, multimodal |
| Grok 2 | xAI | Real-time knowledge, direct answers |
| Claude Sonnet 4.5 | Anthropic | Balanced speed/quality |

## Configuration

Models are configured in `config/llm-council.json`:

```json
{
  "models": {
    "opus": { "openrouter_id": "anthropic/claude-opus-4.5" },
    "gpt": { "openrouter_id": "openai/gpt-5.2" },
    "gemini": { "openrouter_id": "google/gemini-3-pro" },
    "grok": { "openrouter_id": "x-ai/grok-2" },
    "sonnet": { "openrouter_id": "anthropic/claude-sonnet-4.5" }
  }
}
```

## Process

### When Asked a Question

Execute the following steps:

#### Step 1: Load Configuration
Read model IDs from `config/llm-council.json` in this repository, or fall back to `~/.claude/config/llm-council.json`.

#### Step 2: Query Models via OpenRouter
For each model, send the user's question via OpenRouter API:

```bash
curl -s "https://openrouter.ai/api/v1/chat/completions" \
  -H "Authorization: Bearer $OPENROUTER_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "model": "[MODEL_ID]",
    "messages": [{"role": "user", "content": "[USER_QUESTION]"}],
    "max_tokens": 1000
  }'
```

Query all models in parallel for speed.

#### Step 3: Format Responses

Present responses in this format:

```markdown
## LLM Council Responses

### Question
> [User's question]

---

### Claude Opus 4.5
[Response]

---

### GPT-5.2
[Response]

---

### Gemini Pro 3
[Response]

---

### Grok 2
[Response]

---

### Claude Sonnet 4.5
[Response]

---

## Consensus Summary
- **Agreement**: [Points where models agree]
- **Disagreement**: [Points where models differ]
- **Recommendation**: [Synthesized best answer]
```

### When --update Flag Used

Run the update script to fetch latest model versions:

```bash
./scripts/update-llm-council.sh
```

This will:
1. Fetch latest models from OpenRouter API
2. Compare with current configuration
3. Update model IDs if newer versions available
4. Back up previous config

## Requirements

- `OPENROUTER_API_KEY` environment variable set
- `jq` installed for JSON parsing
- `curl` for API requests

## Example Session

```
User: /llm-council "Should I use Redux or Zustand for state management in 2026?"

Claude: Querying 5 models via OpenRouter...

## LLM Council Responses

### Question
> Should I use Redux or Zustand for state management in 2026?

---

### Claude Opus 4.5
Zustand is the better choice for most new projects in 2026. Redux has become
overly complex with its middleware ecosystem, while Zustand provides a simpler
API with comparable performance...

---

### GPT-5.2
Both are valid choices, but the trend has shifted toward Zustand due to its
minimal boilerplate. Redux Toolkit has improved DX significantly, but Zustand's
learning curve is much gentler...

---

[... more responses ...]

## Consensus Summary
- **Agreement**: All models favor Zustand for new projects due to simplicity
- **Disagreement**: GPT and Gemini note Redux still preferred for large teams
- **Recommendation**: Use Zustand unless you need Redux's middleware ecosystem
```

## Cost Awareness

Each query uses tokens across multiple models. Approximate costs per question:

| Model | ~Cost per 1K tokens |
|-------|---------------------|
| Opus 4.5 | $0.015 input / $0.075 output |
| GPT-5.2 | $0.010 input / $0.030 output |
| Gemini Pro 3 | $0.002 input / $0.006 output |
| Sonnet 4.5 | $0.003 input / $0.015 output |

Typical question: ~$0.10-0.20 total across all models.

## Tips

- Use for important architectural decisions
- Great for getting diverse perspectives on trade-offs
- Not needed for simple questions (just ask Claude directly)
- Run `--update` weekly to keep models current

## Related

- `/research` - Deep research before coding
- `/plan` - Planning with single model
- `config/llm-council.json` - Model configuration
