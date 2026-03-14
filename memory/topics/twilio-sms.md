
### 2026-02-18 - Railway to Mac Migration
[gotcha] Node.js on this Mac is at `/usr/local/bin/node`, NOT `/opt/homebrew/bin/node`. Homebrew formula installs to /usr/local/bin on this ARM Mac with Node v24.
[gotcha] macOS AirPlay Receiver uses port 5000. twilio-sms must use port 5050 to avoid conflict.
[gotcha] `cloudflared tunnel login` requires interactive browser auth. Cannot be automated.
[pattern] launchd plist with real secrets goes to ~/Library/LaunchAgents/. Repo template uses REPLACE_ME placeholders.
[config] VAPI_PHONE_NUMBER is +14385447557 (dedicated Vapi AI number, "Max Personal (Ashley)"). Business number +14382557557 is separate.
[config] Twilio phone number SID: PNbfdd7b682977e10ca9ea272b110a1145
[pattern] Quick tunnel: `cloudflared tunnel --url http://localhost:5050` gives temporary trycloudflare.com URL. Good for testing, not production.
[decision] MTL_API_BASE_URL/MTL_API_SECRET not set locally. Non-critical website sync feature. Warning is expected.
[pattern] finish-migration.sh automates: Cloudflare auth, tunnel creation, DNS routing, firewall, Twilio webhook API update. One-shot script.
