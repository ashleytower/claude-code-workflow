### 2026-03-12 - VAPI Real-Time Transcript During Active Calls

[research] Deep dive into how to get real-time conversation data from VAPI outbound calls.

## Question 1: Does GET /call/{id} return messages during an active call?

**NO.** The `messages` array and `artifact.transcript` on the call object are **only populated after the call ends**. Polling GET `/call/{id}` during an active call will NOT give you transcript data. This is confirmed by VAPI community discussions and support threads.

- The call object has: `messages` (array of UserMessage, BotMessage, SystemMessage, ToolCallMessage, ToolCallResultMessage), `artifact.transcript`, `artifact.messagesOpenAIFormatted`
- These fields are empty/null during an active call
- Only `status`, `monitor.listenUrl`, `monitor.controlUrl` are available during active calls

## Question 2: monitor.listenUrl WebSocket

The `listenUrl` is a WebSocket URL returned in the call object's `monitor` field. It provides:
- **Raw PCM audio stream** (binary frames) - NOT transcript text
- Some JSON text messages alongside the binary audio
- Audio format: raw PCM (not MP3/WAV)
- URL expires when the call ends
- You would need to run your own STT (speech-to-text) on the audio to get transcripts

```javascript
const ws = new WebSocket(call.monitor.listenUrl);
ws.on('message', (data, isBinary) => {
  if (isBinary) {
    // Raw PCM audio data
    pcmBuffer = Buffer.concat([pcmBuffer, data]);
  } else {
    // JSON text messages (limited metadata)
    console.log(JSON.parse(data.toString()));
  }
});
```

**Verdict:** listenUrl is audio-only, not a transcript stream. You'd have to pipe it through Deepgram/Whisper yourself.

## Question 3: serverUrl Webhook (BEST APPROACH)

Configure a `serverUrl` on the assistant. VAPI POSTs events to this URL in real-time during the call.

### Key Real-Time Events:

**`transcript` event** - Fired for every utterance:
```json
{
  "message": {
    "type": "transcript",
    "role": "user|assistant",
    "transcriptType": "partial|final",
    "transcript": "the spoken text",
    "isFiltered": false,
    "detectedThreats": [],
    "originalTranscript": "unfiltered text"
  }
}
```

**`conversation-update` event** - Full conversation state on each update:
```json
{
  "message": {
    "type": "conversation-update",
    "messages": [
      { "role": "assistant", "message": "Hello..." },
      { "role": "user", "message": "Hi..." }
    ],
    "messagesOpenAIFormatted": [
      { "role": "assistant", "content": "Hello..." },
      { "role": "user", "content": "Hi..." }
    ]
  }
}
```

**`speech-update` event** - Who is speaking:
```json
{
  "message": {
    "type": "speech-update",
    "status": "started|stopped",
    "role": "assistant|user",
    "turn": 1
  }
}
```

**`status-update` event** - Call lifecycle:
```json
{
  "message": {
    "type": "status-update",
    "status": "scheduled|queued|ringing|in-progress|forwarding|ended"
  }
}
```

**`end-of-call-report` event** - Final summary:
```json
{
  "message": {
    "type": "end-of-call-report",
    "endedReason": "hangup",
    "artifact": {
      "transcript": "full conversation text",
      "messages": [{ "role": "assistant", "message": "..." }]
    }
  }
}
```

### Configuring Which Events Are Sent

On the assistant object, set `serverMessages` array to control which events are POSTed:

Default serverMessages: `conversation-update`, `end-of-call-report`, `function-call`, `hang`, `speech-update`, `status-update`, `tool-calls`, `transfer-destination-request`, `handoff-destination-request`, `user-interrupted`, `assistant.started`

For transcript, explicitly add `"transcript"` to serverMessages if not already there.

### clientMessages vs serverMessages

- `clientMessages` - sent to client SDKs (browser/mobile via WebSocket)
- `serverMessages` - sent to your backend server URL via HTTP POST

Default clientMessages include: `conversation-update`, `transcript`, `speech-update`, `status-update`, `model-output`, etc.

## Question 4: Best Architecture for Real-Time Transcript Display

**Recommended approach: serverUrl webhook -> your server -> WebSocket/SSE to client**

1. Set `serverUrl` on the VAPI assistant pointing to your backend
2. Ensure `serverMessages` includes `["transcript", "conversation-update", "status-update", "speech-update"]`
3. Backend receives POSTs from VAPI in real-time during the call
4. Backend forwards transcript data to your frontend via WebSocket or Server-Sent Events
5. Frontend renders the live conversation

**Alternative: Client SDK approach**
- If using VAPI's web SDK, set `clientMessages` to include `transcript` and `conversation-update`
- Listen for events directly on the VAPI client instance
- Simpler but only works for web calls, not outbound phone calls where user watches a dashboard

**For outbound phone calls specifically:**
The serverUrl webhook is the only reliable way. The user isn't on the VAPI client - they're watching a dashboard while the AI talks to someone on the phone. So the data flow is:

```
VAPI call -> serverUrl POST (transcript events) -> Your backend -> WebSocket -> User's dashboard
```
