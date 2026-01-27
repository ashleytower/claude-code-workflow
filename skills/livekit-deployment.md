---
name: livekit-deployment
category: integrations
frameworks: [python, livekit-agents]
last_updated: 2026-01-23
version: livekit-agents 1.3
---

# LiveKit Agents Deployment

## Pre-Deployment Checklist (MANDATORY)

Before ANY deployment, complete this checklist:

```bash
# 1. Trace ALL dependencies
grep -r "os\.getenv\|os\.environ" *.py --include="*.py"

# 2. Trace imported modules
grep -r "^from\|^import" livekit_agent.py | grep -v "livekit\|typing\|dataclasses"

# 3. For each imported module, trace its env vars
for module in inventory_manager invoice_processor log_config; do
  echo "=== $module ==="
  grep -r "os\.getenv\|os\.environ" ${module}.py
done

# 4. Check requirements.txt versions
cat requirements.txt | grep livekit
```

## Required Environment Variables

### Critical (will crash without these)

| Variable | Purpose | Source |
|----------|---------|--------|
| `LIVEKIT_URL` | WebSocket server URL | LiveKit Cloud |
| `LIVEKIT_API_KEY` | API authentication | LiveKit Cloud |
| `LIVEKIT_API_SECRET` | API authentication | LiveKit Cloud |
| `ANTHROPIC_API_KEY` | Claude LLM | Anthropic |
| `DEEPGRAM_API_KEY` | Speech-to-text | Deepgram |
| `CARTESIA_API_KEY` | Text-to-speech | Cartesia |

### Optional (with defaults)

| Variable | Purpose | Default |
|----------|---------|---------|
| `CARTESIA_VOICE_ID` | TTS voice | `694f9389-aac1-45b6-b726-9d9369183238` (official greeter) |

### Application-Specific (trace your imports)

| Variable | Purpose | Check Command |
|----------|---------|---------------|
| `GOOGLE_SHEETS_ID` | Spreadsheet ID | `grep GOOGLE_SHEETS *.py` |
| `GOOGLE_SERVICE_ACCOUNT_JSON` | Google auth | `grep SERVICE_ACCOUNT *.py` |
| `GEMINI_API_KEY` | Invoice OCR | `grep GEMINI *.py` |

## Correct API Patterns

### Instructions go on Agent class, NOT AgentSession

```python
# CORRECT
class MyAgent(Agent):
    def __init__(self):
        super().__init__(instructions="You are a helpful assistant...")

# WRONG - AgentSession doesn't accept instructions
session = AgentSession(instructions="...")  # TypeError!

# WRONG - LLM doesn't accept instructions
llm = anthropic.LLM(instructions="...")  # TypeError!
```

### Module-level entrypoint for multiprocessing

```python
# CORRECT - at module level
server = AgentServer()

@server.rtc_session()
async def entrypoint(ctx: JobContext):
    ...

if __name__ == "__main__":
    cli.run_app(server)

# WRONG - nested inside __main__
if __name__ == "__main__":
    server = AgentServer()
    @server.rtc_session()
    async def entrypoint(ctx):  # Can't pickle nested functions!
        ...
```

### Pass dependencies to constructors

```python
# CORRECT - get env vars and pass explicitly
class MyAgent(Agent):
    def __init__(self):
        super().__init__(instructions=get_instructions())
        spreadsheet_id = os.getenv("GOOGLE_SHEETS_ID")
        if not spreadsheet_id:
            raise ValueError("GOOGLE_SHEETS_ID required")
        self.manager = InventoryManager(spreadsheet_id)

# WRONG - assume dependencies exist
class MyAgent(Agent):
    def __init__(self):
        self.manager = InventoryManager()  # Missing required arg!
```

## Deployment Workflow

### 1. Dependency Audit (ALWAYS FIRST)

```bash
# Create env var manifest
python3 -c "
import ast
import sys

def find_env_vars(filename):
    with open(filename) as f:
        tree = ast.parse(f.read())
    for node in ast.walk(tree):
        if isinstance(node, ast.Call):
            if hasattr(node.func, 'attr') and node.func.attr in ('getenv', 'get'):
                if node.args:
                    print(f'{filename}: {ast.literal_eval(node.args[0])}')

for f in sys.argv[1:]:
    find_env_vars(f)
" *.py
```

### 2. Validate Before Push

```bash
# Check all required vars are set in Railway
railway variables | grep -E "LIVEKIT|ANTHROPIC|DEEPGRAM|CARTESIA|GOOGLE"
```

### 3. Test Locally First

```bash
# Console mode - no server needed
python livekit_agent.py console

# Dev mode with hot reload
python livekit_agent.py dev
```

### 4. Deploy

```bash
git add . && git commit -m "feat: description" && git push
```

### 5. Verify Logs

```bash
# Check for these success messages:
# - "Starting LiveKit Voice Agent Server"
# - "registered worker"
# - "received job request"
# - "New session: room=..."

# Check for these errors:
# - "TypeError" - wrong API usage
# - "missing required positional argument" - missing dependency
# - "unexpected keyword argument" - wrong parameter location
```

## Common Errors and Fixes

| Error | Cause | Fix |
|-------|-------|-----|
| `Can't get attribute 'entrypoint'` | Nested function | Move entrypoint to module level |
| `unexpected keyword argument 'instructions'` | Wrong location | Put instructions on Agent class |
| `missing required positional argument` | Missing dependency | Trace constructor requirements |
| `No agent connected` after 30s | Worker not registered | Check LIVEKIT_URL, API_KEY, API_SECRET |
| `no audio frames were pushed for text` | TTS IP blocking | Use official voice ID (see below) |

## Cartesia TTS "No Audio Frames" Error

### The Error
```
livekit.agents._exceptions.APIError: no audio frames were pushed for text: [response text] (body=None, retryable=True)
```

### Root Cause
Cloud providers (Railway, Render, etc.) have datacenter IPs that TTS providers like Cartesia and ElevenLabs may block. This is documented in [GitHub issue #4171](https://github.com/livekit/agents/issues/4171).

### Symptoms
- Agent connects to LiveKit successfully
- STT (Deepgram) works - transcribes user speech
- LLM (Claude/OpenAI) works - generates response text
- TTS fails with "no audio frames" error
- `body=None` indicates empty response from Cartesia API

### Debugging Steps

1. **Test Cartesia API directly** (from local machine):
```bash
curl -X POST "https://api.cartesia.ai/tts/bytes" \
  -H "X-API-Key: $CARTESIA_API_KEY" \
  -H "Cartesia-Version: 2024-06-10" \
  -H "Content-Type: application/json" \
  -d '{"transcript": "Hello", "model_id": "sonic-3", "voice": {"mode": "id", "id": "YOUR_VOICE_ID"}, "output_format": {"container": "raw", "encoding": "pcm_f32le", "sample_rate": 24000}}'
```

2. **If local works but Railway fails** → IP blocking confirmed

3. **Check Cartesia plan** - Free tier may have stricter IP restrictions

### Solution: Use Official Voice IDs

Official example voice IDs are whitelisted and work from cloud providers:

```python
# Working voice IDs from official LiveKit examples
CARTESIA_VOICE_IDS = {
    "greeter": "694f9389-aac1-45b6-b726-9d9369183238",  # Recommended
    "docs": "f786b574-daa5-4673-aa0c-cbe3e8534c02",
}

# In your agent
tts=cartesia.TTS(
    model="sonic-3",  # Use sonic-3, not sonic-2
    voice="694f9389-aac1-45b6-b726-9d9369183238"
)
```

### Configuration Pattern

```python
# Allow override via env var, default to working voice ID
CARTESIA_VOICE_ID = os.getenv(
    "CARTESIA_VOICE_ID",
    "694f9389-aac1-45b6-b726-9d9369183238"  # Official greeter voice
)

session = AgentSession(
    stt=deepgram.STT(model="nova-3", language="en"),
    llm=anthropic.LLM(model="claude-sonnet-4-20250514"),
    tts=cartesia.TTS(model="sonic-3", voice=CARTESIA_VOICE_ID),
)
```

### If You Need Custom Voice

1. Upgrade Cartesia plan (paid tier ~$5/month)
2. Wait for plan upgrade to propagate (can take hours)
3. May need to regenerate API key after upgrade
4. Test with official voice ID first to confirm pipeline works

## Testing Checklist

```
[ ] All env vars documented and set
[ ] Local console test passes
[ ] Imports traced for dependencies
[ ] Constructor arguments validated
[ ] Entrypoint at module level
[ ] Instructions on Agent class
[ ] Logs show "registered worker"
[ ] Agent joins playground room
[ ] TTS produces audio (check for "no audio frames" error)
[ ] Using official Cartesia voice ID if deploying to cloud
```

## Gotchas Learned

1. **LiveKit plugins read API keys from environment** - ANTHROPIC_API_KEY, DEEPGRAM_API_KEY, CARTESIA_API_KEY must be set even though code doesn't explicitly reference them

2. **Python multiprocessing requires module-level functions** - Anything decorated with `@server.rtc_session()` must be importable

3. **AgentSession is just a container** - It manages the pipeline, doesn't accept business logic parameters

4. **Trace the full import chain** - If you import `inventory_manager`, trace what IT imports and what env vars IT needs

5. **Railway shared variables** - Copy ALL required vars from main service, not just the obvious ones

6. **Check ALL constructor signatures** - Don't just check the class you're instantiating, check what IT instantiates:
   ```python
   # Wrong - didn't check InvoiceProcessor's __init__
   self.manager = InventoryManager(spreadsheet_id)
   self.invoice_processor = InvoiceProcessor()  # Needs manager!

   # Right - traced dependency chain
   self.manager = InventoryManager(spreadsheet_id)
   self.invoice_processor = InvoiceProcessor(self.manager)
   ```

7. **Cartesia TTS IP blocking from cloud providers** - TTS providers like Cartesia may block datacenter IPs:
   - Error: "no audio frames were pushed for text" (GitHub issue #4171)
   - Solution: Use official example voice IDs which are whitelisted
   - Working voice ID: `694f9389-aac1-45b6-b726-9d9369183238` (greeter)
   - Custom voice IDs may require upgraded plans + time to propagate

## Updates

- 2026-01-23 (PM): Fixed Cartesia TTS "no audio frames" error
  - Root cause: IP blocking from Railway datacenter
  - Fix: Use official Cartesia voice ID (694f9389-aac1-45b6-b726-9d9369183238)
  - Learned: TTS providers may block cloud provider IPs

- 2026-01-23: Initial skill created after deployment debugging session
  - Learned: Always trace full dependency chain before deploying
  - Learned: instructions parameter goes on Agent, not AgentSession or LLM
  - Learned: Module-level functions required for multiprocessing
