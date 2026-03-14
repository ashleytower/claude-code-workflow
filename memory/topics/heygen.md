# HeyGen API Notes

### 2026-02-14 - Free plan resolution limit
[gotcha] Free/trial HeyGen API plan is limited to 720p resolution. Requesting 1080x1920 (or 1920x1080) returns `RESOLUTION_NOT_ALLOWED` error with message "subscribe to higher plan". Use 720x1280 for 9:16 vertical and 1280x720 for 16:9 horizontal.

### 2026-02-14 - Audio URL must be publicly accessible
[gotcha] HeyGen `audio_url` in video generation must be a publicly accessible URL. Local file paths won't work. Use catbox.moe (`curl -F "reqtype=fileupload" -F "fileToUpload=@file.mp3" https://catbox.moe/user/api.php`) for quick temp hosting. tmpfiles.org also works but may be blocked by some services.

### 2026-02-14 - Error object not stringified
[debug] HeyGen `data.data.error` in poll response can be an object (not a string). Must JSON.stringify it in error handling or you get `[object Object]`. Fixed in `src/lib/heygen/client.ts`.

### 2026-02-14 - API key format
[pattern] HeyGen API key is base64-encoded. Format: `{uuid}-{timestamp}` when decoded. Key stored in `~/.secrets` as `HEYGEN_API_KEY`.

### 2026-02-14 - Casual male avatars
[research] 343 casual male avatars available. Good picks for UGC-style: `Armando_Casual_Front_public`, `August_Casual_Front_public`, `Artur_sitting_sofacasual_front`. Full list via `scripts/find-heygen-avatar.ts`.
