# Docs Verification: Twilio SMS Service Stack (2026-02-18)

Context7 MCP documentation audit for Cloudflare Tunnel, Twilio SDK, Express.js, and Vapi.

## Cloudflare Tunnel (cloudflared)

**Config file:** `config/cloudflared-config.yml`

- Ingress rule syntax is correct (hostname, path regex, service)
- Catch-all `http_status:404` is correct and required
- QUIC protocol recommended: add `protocol: quic` to top of config
- h2mux deprecated since 2023.2.2
- Available but unused options: `originRequest.connectTimeout`, `loglevel`, `logDirectory`

## Twilio Node.js SDK (v5.x)

**File:** `skills/twilio-sms/src/utils/validation.js`

- `validateRequest(authToken, signature, url, params)` usage is correct
- Alternative: `validateExpressRequest(req, authToken, { protocol, host })` handles URL construction internally -- better behind reverse proxy
- New feature: PKCV (Public Key Client Validation) for asymmetric auth
- No deprecations in v5.x

## Express.js Security

**File:** `skills/twilio-sms/src/index.js`

Missing from our app:
1. `helmet()` - sets security headers (CSP, HSTS, X-Content-Type-Options, etc.)
2. `app.set('trust proxy', true)` - needed behind Cloudflare Tunnel for correct IP detection
3. `express-rate-limit` - per-endpoint rate limiting
4. `cors` - restrict browser access to approval UI only

Not needed: gzip compression (Cloudflare handles at edge)

## Vapi Server-Side Tools

**File:** `skills/twilio-sms/src/routes/vapiTools.js`

**CONFLICT:** Our memory says `name` is required in responses, but current Vapi docs (2026) say format is `{ toolCallId, result }` only. The `name` field may be ignored. Keeping it for now since it was empirically verified to fix muting issues.

Required response format per docs:
```json
{ "results": [{ "toolCallId": "X", "result": "Y" }] }
```

Rules: HTTP 200 always, single-line strings, string types only for result/error.

Authentication: `x-vapi-secret` header. New config format: `server: { url, secret, timeout }` replaces deprecated `serverUrl`/`serverUrlSecret`.

Gap: We allow requests without secret header. Should reject when VAPI_SERVER_SECRET is configured.
