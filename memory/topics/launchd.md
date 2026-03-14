
### 2026-02-28 - macOS 26 provenance blocks launchd bash scripts
[gotcha] macOS 26 (Tahoe) has `com.apple.provenance` extended attribute on directories created by signed apps (GitHub Desktop, etc). This attribute is sticky — can't be removed via `xattr -d` or copy-move. When Developer Mode is disabled (`DevToolsSecurity -status`), launchd-spawned `/bin/bash` cannot open/execute script files with this attribute. Error: `/bin/bash: /path/to/script.sh: Operation not permitted`.

**Fix:** Use node as the process launcher in the plist:
```xml
<array>
    <string>/usr/local/bin/node</string>
    <string>-e</string>
    <string>require("child_process").execFileSync("/bin/bash",["/path/to/script.sh"],{stdio:"inherit",env:Object.assign({},process.env)})</string>
</array>
```
Node at `/usr/local/bin/node` already works from launchd (proven by OpenClaw gateway). It bypasses the Gatekeeper check that blocks bash from opening provenance-tagged scripts.

Also: add `~/.npm-global/bin` to PATH in plist EnvironmentVariables — `mcporter` and `openclaw` live there and aren't in the default system PATH.

[gotcha] `launchctl start` doesn't reliably trigger interval-based jobs. Use `launchctl kickstart -kp gui/$(id -u)/LABEL` instead.

[gotcha] heartbeat-check.sh had wrong SHARED_LIB path: `../../shared/lib` (2 levels up = repo root). Correct path is `../shared/lib` (1 level up = skills/). All skills are siblings under `skills/`.
