### 2026-03-12 - VAPI Outbound Calling Research

[research] Deep dive into VAPI outbound phone calling patterns.

## firstMessageMode

Three options:
1. `assistant-speaks-first` - Uses the static `firstMessage` string. The message cannot be interrupted and is guaranteed to be spoken.
2. `assistant-waits-for-user` - Waits for the human to speak first, then responds.
3. `assistant-speaks-first-with-model-generated-message` - Ignores `firstMessage`. Instead, the LLM generates the opening message based on `model.messages` (system prompt). Useful when you want dynamic, context-aware greetings. Originally designed for squad transfers where conversation history carries over.

## assistantOverrides (POST /call)

Two approaches to customize per-call:

### Approach A: assistantId + assistantOverrides
```json
{
  "assistantId": "saved-assistant-id",
  "phoneNumberId": "phone-id",
  "customer": { "number": "+1234567890" },
  "assistantOverrides": {
    "firstMessage": "Hi John, this is...",
    "firstMessageMode": "assistant-speaks-first-with-model-generated-message",
    "variableValues": { "name": "John", "company": "Acme" },
    "model": { ... }  // can override entire model config
  }
}
```

### Approach B: Inline/Transient assistant (full config per call)
```json
{
  "assistant": {
    "model": {
      "provider": "openai",
      "model": "gpt-4o",
      "messages": [{ "role": "system", "content": "You are..." }]
    },
    "voice": { "provider": "11labs", "voiceId": "sarah" },
    "firstMessage": "Hi, this is...",
    "firstMessageMode": "assistant-speaks-first"
  },
  "phoneNumberId": "phone-id",
  "customer": { "number": "+1234567890" }
}
```

[gotcha] The `model` field in assistantOverrides accepts the full model config including `messages` array. This is how you override the system prompt per-call without using dynamic variables.

[gotcha] Dynamic variables (`{{name}}`) only work in system prompts and dashboard messages. Passed via `assistantOverrides.variableValues`.

## Overridable Fields (35 total from Rust SDK)
transcriber, model, voice, first_message, first_message_mode, first_message_interruptions_enabled, voicemail_detection, client_messages, server_messages, silence_timeout_seconds, max_duration_seconds, background_sound, background_denoising_enabled, model_output_in_messages_enabled, transport_configurations, observability_plan, credentials, hooks, variable_values, name, voicemail_message, end_call_message, end_call_phrases, compliance_plan, metadata, background_speech_denoising_plan, analysis_plan, artifact_plan, message_plan, start_speaking_plan, stop_speaking_plan, monitor_plan, credential_ids, server, keypad_input_plan

## Sync Tool Calls (serverUrl webhook)

### Request format (tool-calls event):
```json
{
  "message": {
    "type": "tool-calls",
    "toolCallList": [
      { "id": "toolu_01DTP...", "name": "check_with_user", "arguments": { ... } }
    ],
    "toolWithToolCallList": [ ... ],
    "call": { "id": "call-uuid" }
  }
}
```

### Response format (MUST return HTTP 200):
```json
{
  "results": [
    {
      "toolCallId": "toolu_01DTP...",
      "result": "Approved by user"
    }
  ]
}
```

[gotcha] toolCallId MUST be camelCase and MUST exactly match the id from request.
[gotcha] result and error fields MUST be strings (not objects/arrays).
[gotcha] Use single-line strings only - line breaks cause parsing errors.
[gotcha] Always return HTTP 200, even for errors. Other status codes are silently ignored.
[gotcha] For errors, use `"error": "message"` instead of `"result"`.
[gotcha] Default is sync (`async: false`) - the conversation PAUSES waiting for your response.
