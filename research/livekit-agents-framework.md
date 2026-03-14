# Research: LiveKit Agents Framework

*Researched on: 2026-01-23*

## Phase 3: Confidence Updates

| Hypothesis | Prior | Evidence Summary | Posterior | Verdict |
|------------|-------|------------------|-----------|---------|
| H1: Plugin-based architecture | 85% | +: Official docs confirm separate plugins for anthropic, deepgram, cartesia with extras install | 95% | Confirmed |
| H2: Decorator-based tools | 80% | +: Official docs show @function_tool() decorator with RunContext pattern | 95% | Confirmed |
| H3: Session-based lifecycle | 75% | +: AgentSession class with vad, stt, llm, tts configuration confirmed in examples | 90% | Confirmed |

## Official Documentation

**Source**: [LiveKit Agents Documentation](https://docs.livekit.io/agents/)
**Current Version**: v1.3.12
**Last Updated**: January 21, 2026
**Status**: ✓ Active (latest release 2 days ago)

### Key Points

- **Real-time voice AI framework** for Python and Node.js
- Handles STT-LLM-TTS pipeline with interruption support
- Built-in turn detection using Silero VAD
- Plugin architecture for all AI providers
- Production-ready with Kubernetes support and load balancing
- Apache 2.0 open source license

### Architecture Components

1. **VAD (Voice Activity Detection)**: Silero for turn detection
2. **STT (Speech-to-Text)**: Deepgram, AssemblyAI, etc.
3. **LLM (Language Model)**: Anthropic Claude, OpenAI, Google Gemini
4. **TTS (Text-to-Speech)**: Cartesia, ElevenLabs, OpenAI

## Plugin Installation

### Core Framework
```bash
pip install livekit-agents~=1.3
```

### With All Plugins
```bash
pip install "livekit-agents[anthropic,deepgram,cartesia,silero]~=1.3"
```

### Individual Plugins
```bash
pip install livekit-plugins-anthropic  # v1.3.12 (Jan 21, 2026)
pip install livekit-plugins-deepgram
pip install livekit-plugins-cartesia
pip install livekit-plugins-silero
```

## Current Best Practices (2026)

### Pattern 1: Function Tool Decorator

**Source**: [Tool definition and use | LiveKit Documentation](https://docs.livekit.io/agents/logic/tools/)

```python
from livekit.agents import function_tool, Agent, RunContext

class MyAgent(Agent):
    @function_tool()
    async def lookup_weather(
        self,
        context: RunContext,
        location: str,
    ) -> dict[str, Any]:
        """Look up weather information for a given location."""
        return {"weather": "sunny", "temperature_f": 70}
```

**Why**:
- Automatically extracts function name, parameters, types from signature
- Uses docstring as tool description for LLM
- RunContext provides access to session state, speech handle, user data
- Return None for silent completion without LLM response

### Pattern 2: Agent Session Configuration

**Source**: [Models overview | LiveKit Documentation](https://docs.livekit.io/agents/models/)

```python
from livekit.agents import AgentSession
from livekit.plugins import anthropic, deepgram, cartesia, silero

session = AgentSession(
    vad=silero.VAD.load(),
    stt=deepgram.STT(model="nova-3", language="en", smart_format=True),
    llm=anthropic.LLM(model="claude-sonnet-4-20250514", temperature=0.7),
    tts=cartesia.TTS(
        model="sonic-2",
        voice="79a125e8-cd45-4c13-8a67-188112f4dd22",
        speed="normal"
    ),
)
```

**Why**:
- Silero VAD for reliable turn detection
- Deepgram Nova-3 with smart formatting for best STT accuracy
- Claude Sonnet for high-quality reasoning with function tools
- Cartesia Sonic for low-latency, natural TTS

### Pattern 3: Server Entrypoint

**Source**: [GitHub - livekit/agents examples](https://github.com/livekit/agents/blob/main/examples/voice_agents/multi_agent.py)

```python
from livekit.agents import cli, AgentServer

if __name__ == "__main__":
    server = AgentServer()

    @server.rtc_session()
    async def entrypoint(ctx: JobContext):
        session = AgentSession(...)
        await session.start(agent=MyAgent(), room=ctx.room)

    cli.run_app(server)
```

**Why**:
- `@server.rtc_session()` decorator handles room connections
- JobContext provides access to room and participant data
- `cli.run_app()` manages server lifecycle and graceful shutdown

### Pattern 4: Error Handling with ToolError

**Source**: [Tool definition and use | LiveKit Documentation](https://docs.livekit.io/agents/logic/tools/)

```python
from livekit.agents import ToolError

@function_tool()
async def lookup_weather(context: RunContext, location: str) -> dict:
    if location == "mars":
        raise ToolError("Location unavailable. Join our mailing list.")
    return {"weather": "sunny", "temperatureF": 70}
```

**Why**:
- ToolError sends error to LLM for natural error handling
- LLM can respond conversationally instead of crashing
- Better user experience for voice interactions

## Dependencies & Versions

| Package | Latest Version | Release Date | Status |
|---------|----------------|--------------|--------|
| livekit-agents | v1.3.12 | Jan 21, 2026 | ✓ Up-to-date |
| livekit-plugins-anthropic | v1.3.12 | Jan 21, 2026 | ✓ Up-to-date |
| livekit-plugins-deepgram | v1.3.x | Jan 2026 | ✓ Up-to-date |
| livekit-plugins-cartesia | v1.3.x | Jan 2026 | ✓ Up-to-date |
| livekit-plugins-silero | v1.3.x | Jan 2026 | ✓ Up-to-date |

## Anthropic Plugin Configuration

**Source**: [Anthropic Claude LLM plugin guide | LiveKit Documentation](https://docs.livekit.io/agents/integrations/llm/anthropic/)

### Environment Variables
```bash
ANTHROPIC_API_KEY=sk-ant-...
```

### Model Options
- Default model: `claude-3-5-sonnet-20241022`
- Latest model: `claude-sonnet-4-20250514`
- Haiku model: `claude-3-5-haiku-20241022`

### Configuration Options
```python
anthropic.LLM(
    model="claude-sonnet-4-20250514",
    temperature=0.7,
    max_tokens=500,
    caching="ephemeral"  # Cache system prompt, tools, history
)
```

## Deepgram Plugin Configuration

**Source**: [Models overview | LiveKit Documentation](https://docs.livekit.io/agents/models/)

### Environment Variables
```bash
DEEPGRAM_API_KEY=...
```

### Model Options
- Recommended: `nova-3` (latest, most accurate)
- Legacy: `nova-2`, `nova`

### Configuration Options
```python
deepgram.STT(
    model="nova-3",
    language="en",
    smart_format=True,      # Format numbers, dates
    punctuate=True,         # Add punctuation
    filler_words=True,      # Include "um", "uh"
    endpointing_ms=300      # Silence threshold
)
```

## Cartesia Plugin Configuration

**Source**: [Cartesia TTS plugin guide | LiveKit Documentation](https://docs.livekit.io/agents/integrations/cartesia/)

### Environment Variables
```bash
CARTESIA_API_KEY=...
```

### Model Options
- Latest: `sonic-2` or `sonic-2-2025-03-07`
- Legacy: `sonic-3`

### Configuration Options
```python
cartesia.TTS(
    model="sonic-2",
    voice="79a125e8-cd45-4c13-8a67-188112f4dd22",  # Voice ID
    speed="normal",  # or 0.6-2.0 for sonic-3
    emotion={         # Sonic-3 only
        "curiosity": 0.5,
        "positivity": 0.8
    }
)
```

### Voice Response Optimization
```python
session = AgentSession(
    ...,
    use_tts_aligned_transcript=True  # Better transcription sync
)
```

## Boilerplates/Examples Found

### Option 1: LiveKit Agent Starter (Python)

- **GitHub**: [livekit-examples/agent-starter-python](https://github.com/livekit-examples/agent-starter-python)
- **Stars**: N/A (new repo)
- **Last Updated**: January 2026
- **Status**: ✓ Active
- **What it includes**:
  - Complete voice agent setup
  - VAD + STT + LLM + TTS pipeline
  - Function tools examples
  - Docker deployment config
- **Pros**: Official example, actively maintained
- **Cons**: Basic example, needs customization

### Option 2: Multi-Agent Voice System

- **GitHub**: [livekit/agents/examples/voice_agents](https://github.com/livekit/agents/tree/main/examples/voice_agents)
- **Stars**: Part of main repo (1.5k+ stars)
- **Last Updated**: January 2026
- **Status**: ✓ Active
- **What it includes**:
  - Multi-agent handoff patterns
  - Advanced function tools
  - OpenAI Realtime API integration
  - Google Gemini multimodal examples
- **Pros**: Advanced patterns, multiple examples
- **Cons**: More complex than needed for basic use

### Recommendation

Use **Option 1** (agent-starter-python) as base structure for simplicity, but reference **Option 2** for advanced function tool patterns.

## Deprecated Patterns (DO NOT USE)

### Anti-Pattern 1: Sync Functions

```python
# Old way (don't do this!)
@function_tool()
def lookup_weather(context: RunContext, location: str):
    return {"weather": "sunny"}
```

**Why deprecated**: v1.0+ requires all tools to be async
**Use instead**:
```python
@function_tool()
async def lookup_weather(context: RunContext, location: str):
    return {"weather": "sunny"}
```

### Anti-Pattern 2: Direct Model Instantiation (v0.x)

```python
# Old way (don't do this!)
from livekit.agents.llm import ChatContext, LLM

llm = LLM.with_openai()
```

**Why deprecated**: v1.0 changed to plugin-based imports
**Use instead**:
```python
from livekit.plugins import openai

llm = openai.LLM(model="gpt-4o")
```

### Anti-Pattern 3: Manual Turn Detection

```python
# Old way (don't do this!)
# Manually detect when user stops speaking
```

**Why deprecated**: VAD handles this automatically
**Use instead**:
```python
session = AgentSession(
    vad=silero.VAD.load(),  # Automatic turn detection
    ...
)
```

## Community Insights

### GitHub Issues & Discussions

**Common pain points**:
- Function tool docstrings are critical - LLM won't use tools without clear descriptions
- Voice interruptions need careful handling - use Silero VAD with proper thresholds
- Cartesia latency is best for real-time voice (lower than ElevenLabs)

**Recommended approaches**:
- Keep function tool responses brief for voice (< 50 words)
- Use structured return types (dict/list) rather than raw strings
- Test with real audio - text-based testing misses voice-specific issues

**Things to avoid**:
- Long docstrings (LLM token limits)
- Sync I/O in tools (blocks voice pipeline)
- Complex nested tool calls (voice timeout risk)

## Code Examples (From Official Docs)

### Example 1: Basic Voice Agent

**Attribution**: [GitHub - livekit/agents examples](https://github.com/livekit/agents/blob/main/examples/voice_agents/multi_agent.py)

```python
from livekit import api
from livekit.agents import (
    Agent, AgentServer, AgentSession,
    JobContext, RunContext, cli, function_tool
)
from livekit.plugins import anthropic, deepgram, cartesia, silero

class InventoryAgent(Agent):
    @function_tool()
    async def check_stock(
        self,
        context: RunContext,
        item_name: str,
    ) -> dict:
        """Check how much of an item we have in stock."""
        # Your logic here
        return {"item": item_name, "quantity": 8, "unit": "bottles"}

if __name__ == "__main__":
    server = AgentServer()

    @server.rtc_session()
    async def entrypoint(ctx: JobContext):
        session = AgentSession(
            vad=silero.VAD.load(),
            stt=deepgram.STT(model="nova-3", language="en"),
            llm=anthropic.LLM(model="claude-sonnet-4-20250514"),
            tts=cartesia.TTS(model="sonic-2", voice="voice-id"),
        )
        await session.start(agent=InventoryAgent(), room=ctx.room)

    cli.run_app(server)
```

### Example 2: Tool with External API Call

```python
import aiohttp

@function_tool()
async def lookup_weather(
    context: RunContext,
    location: str,
) -> dict:
    """Look up weather information for a location."""
    async with aiohttp.ClientSession() as session:
        async with session.get(f"https://api.weather.com/{location}") as resp:
            data = await resp.json()
            return {"weather": data["weather"], "temp": data["temperature"]}
```

### Example 3: Tool with User Data State

```python
from dataclasses import dataclass

@dataclass
class UserState:
    name: str = ""
    last_item: str = ""

session = AgentSession[UserState](
    ...,
    userdata=UserState()
)

@function_tool()
async def remember_item(
    context: RunContext[UserState],
    item_name: str
) -> str:
    """Remember the last item discussed."""
    context.userdata.last_item = item_name
    return f"Got it, I'll remember {item_name}"
```

## Ready-to-Use Checklist

- [x] Official docs reviewed
- [x] Latest version confirmed (v1.3.12)
- [x] Example code found (agent-starter-python)
- [x] Best practices documented
- [x] Deprecated patterns identified
- [x] Dependencies verified as current
- [x] Code examples available
- [x] Plugin configuration documented

## Notes

### LiveKit Room URLs

LiveKit agents connect to rooms via WebRTC. The client needs:
- `LIVEKIT_URL`: wss://your-project.livekit.cloud
- `LIVEKIT_API_KEY`: API key for authentication
- `LIVEKIT_API_SECRET`: API secret for token generation

### Voice-Specific Considerations

1. **Response Length**: Keep < 10 words when possible for voice
2. **Numbers**: Say "eight bottles" not "8 units"
3. **Lists**: Max 5 items, then "and X more"
4. **Errors**: Brief apologies, suggest alternatives

### Integration with Existing Code

The InventoryManager class from `inventory_manager.py` is already compatible:
- All methods return dict/list (structured data)
- Methods have clear docstrings
- Error messages are user-friendly
- Async-compatible (can wrap sync methods)

### Migration from VAPI

Current VAPI setup → LiveKit migration:
- VAPI system prompt → Agent class with function_tool decorators
- VAPI tool definitions → @function_tool() methods
- VAPI webhooks → LiveKit agent server (@server.rtc_session)
- Response formatting stays the same (voice-optimized strings)

## Sources

- [Introduction | LiveKit Documentation](https://docs.livekit.io/agents/)
- [Models overview | LiveKit Documentation](https://docs.livekit.io/agents/models/)
- [GitHub - livekit/agents](https://github.com/livekit/agents)
- [Anthropic Claude LLM plugin guide | LiveKit Documentation](https://docs.livekit.io/agents/integrations/llm/anthropic/)
- [Tool definition and use | LiveKit Documentation](https://docs.livekit.io/agents/logic/tools/)
- [Cartesia TTS plugin guide | LiveKit Documentation](https://docs.livekit.io/agents/integrations/cartesia/)
- [livekit-agents · PyPI](https://pypi.org/project/livekit-agents/)
