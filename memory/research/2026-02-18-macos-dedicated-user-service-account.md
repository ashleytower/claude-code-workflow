### 2026-02-18 - macOS Dedicated User Account for AI Agent Services

[research] Comprehensive research on creating a dedicated macOS user ("max") to run AI agent services in isolation from the primary admin user.

---

## 1. Creating a Standard (Non-Admin) macOS User via CLI

**Command (sysadminctl -- the modern, recommended approach):**

```bash
# Run as admin user. Omit -admin flag to create standard user.
sudo sysadminctl -addUser max \
  -fullName "Max AI" \
  -password "<password>" \
  -home /Users/max \
  -shell /bin/zsh
```

**Key facts:**
- sysadminctl automatically provisions the home directory (no separate `createhomedir` step needed)
- Must be run from an admin account (cannot use root/sudo alone per Apple HT208171)
- Use `-` instead of password to get interactive prompt: `-password -`
- `-roleAccount` creates a UID 200-400 hidden service account (name must start with `_`)
- For a hidden-but-functional user, use `dscl . -create /Users/max IsHidden 1` after creation
- UID convention: <500 = hidden from login screen; 501+ = regular visible user

**To verify:**
```bash
dscl . -read /Users/max
id max
ls -la /Users/max/
```

---

## 2. Auto-Login for Non-Admin User (or Run Without Login)

**Option A: Auto-login (requires disabling FileVault)**
```
System Settings > Users & Groups > Login Options > Automatic login > select "max"
```
- Requires admin password to configure
- FileVault MUST be off (auto-login is blocked when FileVault is enabled)
- Disables Touch ID and removes Apple Pay cards
- Works on reboot but not on manual logout

**Option B: LaunchDaemon with UserName key (no login required -- RECOMMENDED)**
- Place plist in `/Library/LaunchDaemons/`
- Add `<key>UserName</key><string>max</string>` to run as that user at boot
- No GUI session, no login screen interaction
- This is the correct approach for headless services

**Option C: SSH auto-login + LaunchAgents**
- Configure SSH key-based auth for the max user
- Use `launchctl bootstrap gui/$(id -u max)` after SSH login
- More complex, less reliable

---

## 3. LaunchDaemons vs LaunchAgents

| Property | LaunchDaemon | LaunchAgent |
|----------|-------------|-------------|
| Location | `/Library/LaunchDaemons/` | `~/Library/LaunchAgents/` or `/Library/LaunchAgents/` |
| Runs at | System boot (before login) | User login |
| Runs as | root (default) or specified UserName | Logged-in user |
| GUI access | NO | YES |
| Owner/Perms | root:wheel, 644 | user:staff, 644 |
| Requires login | NO | YES |
| UserName key | YES (honored) | IGNORED |

**Recommendation for the "max" service account:**
- Use `/Library/LaunchDaemons/` with `UserName=max` for services that must run at boot (openclaw-node, Ollama)
- Use `/Users/max/Library/LaunchAgents/` for services that only need to run when max is logged in (less useful for headless)

**Example LaunchDaemon:**
```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>ai.max.openclaw-node</string>
    <key>ProgramArguments</key>
    <array>
        <string>/Users/max/.local/bin/openclaw-node</string>
    </array>
    <key>UserName</key>
    <string>max</string>
    <key>GroupName</key>
    <string>staff</string>
    <key>WorkingDirectory</key>
    <string>/Users/max</string>
    <key>EnvironmentVariables</key>
    <dict>
        <key>HOME</key>
        <string>/Users/max</string>
        <key>PATH</key>
        <string>/Users/max/.local/bin:/opt/homebrew/bin:/usr/local/bin:/usr/bin:/bin</string>
    </dict>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/Users/max/logs/openclaw-node.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/max/logs/openclaw-node.stderr.log</string>
</dict>
</plist>
```

**Loading:**
```bash
sudo cp ai.max.openclaw-node.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/ai.max.openclaw-node.plist
sudo chmod 644 /Library/LaunchDaemons/ai.max.openclaw-node.plist
sudo launchctl bootstrap system /Library/LaunchDaemons/ai.max.openclaw-node.plist
```

---

## 4. ACL-Based File Sharing (max reads ashleytower's git repo)

**Grant read-only access with inheritance:**
```bash
# Grant max read access to the git repo (recursive + inheriting)
sudo chmod -R +a "max allow read,readattr,readextattr,readsecurity,list,search,execute,file_inherit,directory_inherit" \
  /Users/ashleytower/Documents/GitHub/max-ai-employee

# Verify
ls -le /Users/ashleytower/Documents/GitHub/max-ai-employee
```

**Breakdown of ACL permissions:**
- `read` -- read file contents
- `readattr` -- read file attributes
- `readextattr` -- read extended attributes
- `readsecurity` -- read ACL
- `list` -- list directory contents
- `search` -- traverse directory
- `execute` -- execute files
- `file_inherit` -- new files inherit this ACE
- `directory_inherit` -- new subdirectories inherit this ACE

**Alternative: Shared group approach:**
```bash
# Create a shared group
sudo dseditgroup -o create -n . maxshare
sudo dseditgroup -o edit -a ashleytower -t user maxshare
sudo dseditgroup -o edit -a max -t user maxshare

# Set group on repo
sudo chgrp -R maxshare /Users/ashleytower/Documents/GitHub/max-ai-employee
sudo chmod -R g+rX /Users/ashleytower/Documents/GitHub/max-ai-employee
```

**Gotcha:** ACL inheritance only applies to NEW files created after setting the ACL. For existing files, the `-R` (recursive) flag handles current contents. Git operations (checkout, pull) create new files, which will inherit if `file_inherit` and `directory_inherit` are set.

**Gotcha:** Never run recursive chmod/ACL changes on `/Users/ashleytower/` itself -- system-created folders have hidden ACLs that can break.

---

## 5. Homebrew Packages Shared Between Users

**Homebrew is NOT designed for multi-user use.** Three approaches, ranked:

### Approach A: Shared /opt/homebrew via group permissions (simplest, semi-supported)
```bash
# On Apple Silicon, Homebrew lives at /opt/homebrew
# The admin group already has read+execute. Add write:
sudo chmod -R g+w /opt/homebrew
# Ensure max is in the admin group (or staff):
sudo dseditgroup -o edit -a max -t user admin

# Both users can now read binaries. Only admin user should run brew update/install.
```

### Approach B: Symlink individual binaries (surgical)
```bash
# After admin installs packages:
sudo ln -s /opt/homebrew/bin/cloudflared /usr/local/bin/cloudflared
sudo ln -s /opt/homebrew/bin/node /usr/local/bin/node
```

### Approach C: Dedicated brew user (cleanest for teams)
```bash
# Create hidden brew user
sudo sysadminctl -addUser _brew -fullName "Homebrew" -password - -home /var/brew -roleAccount
sudo chown -R _brew:admin /opt/homebrew
# Grant brew group access via sudoers for package management
```

**Recommendation:** Approach A is sufficient. The max user only needs to READ and EXECUTE brew-installed binaries, not manage Homebrew itself. The admin (ashleytower) manages installations. Adding max to `admin` group gives execute access to /opt/homebrew/bin/*.

**Key binaries needed by max:** node, cloudflared, ollama, git, jq, curl

---

## 6. Claude Code CLI for Non-Admin User

**Native installer (recommended, no Node.js required):**
```bash
# Run AS the max user (or su - max):
su - max
curl -fsSL https://claude.ai/install.sh | bash
```

This installs to `~/.local/bin/claude` and `~/.local/share/claude` -- entirely within the user's home directory. No sudo needed. No Node.js dependency.

**NPM method (deprecated but works):**
```bash
su - max
mkdir -p ~/.npm-global
npm config set prefix '~/.npm-global'
echo 'export PATH=~/.npm-global/bin:$PATH' >> ~/.zshrc
source ~/.zshrc
npm install -g @anthropic-ai/claude-code
```

**Authentication:** The max user will need its own Claude authentication. Run `claude` and complete the OAuth flow, or set `ANTHROPIC_API_KEY` in the environment.

**Configuration:** Claude Code stores config in `~/.claude/` -- completely isolated per user.

---

## 7. Security Isolation: What Standard Users CANNOT Access

| Resource | Accessible? | Notes |
|----------|------------|-------|
| Other users' home dirs | NO | Default 700 permissions on /Users/*/ |
| Other users' Keychain | NO | ~/Library/Keychains/ encrypted per-user |
| Other users' SSH keys | NO | ~/.ssh/ is 700 |
| Other users' browser data | NO | ~/Library/Application Support/Google/ etc |
| System Keychain | READ only | /Library/Keychains/System.keychain |
| /etc/sudoers | NO | Only viewable by root |
| Homebrew binaries | YES | /opt/homebrew/bin/* is world-readable |
| System Preferences (network, printers) | NO | Requires admin password |
| Install to /Applications | NO | Requires admin auth |
| /tmp, /var/tmp | YES | World-writable |
| Shared folders (/Users/Shared/) | YES | Default world-readable |

**Key isolation guarantees:**
- Keychain is AES-256-GCM encrypted, locked to user's login password
- SSH keys in ~/.ssh/ are protected by Unix permissions (700/600)
- Browser profiles, cookies, saved passwords -- all in ~/Library/, inaccessible
- Environment variables from one user's shell are NOT visible to another
- Processes run by max cannot read ashleytower's memory (separate address spaces)

---

## 8. Running Ollama Accessible to Both Users

**Problem:** Ollama GUI app doesn't read shell environment variables. Setting OLLAMA_HOST in .zshrc won't work.

**Solution: LaunchDaemon that runs Ollama at boot, bound to localhost:**

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN"
  "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.ollama.serve</string>
    <key>ProgramArguments</key>
    <array>
        <string>/opt/homebrew/bin/ollama</string>
        <string>serve</string>
    </array>
    <key>EnvironmentVariables</key>
    <dict>
        <key>OLLAMA_HOST</key>
        <string>127.0.0.1:11434</string>
        <key>HOME</key>
        <string>/Users/ashleytower</string>
    </dict>
    <key>UserName</key>
    <string>ashleytower</string>
    <key>GroupName</key>
    <string>staff</string>
    <key>RunAtLoad</key>
    <true/>
    <key>KeepAlive</key>
    <true/>
    <key>StandardOutPath</key>
    <string>/var/log/ollama.stdout.log</string>
    <key>StandardErrorPath</key>
    <string>/var/log/ollama.stderr.log</string>
</dict>
</plist>
```

```bash
# Install
sudo cp com.ollama.serve.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.ollama.serve.plist
sudo chmod 644 /Library/LaunchDaemons/com.ollama.serve.plist

# Disable Ollama's built-in LaunchAgent to avoid conflicts
launchctl unload ~/Library/LaunchAgents/com.ollama.plist 2>/dev/null

# Load the daemon
sudo launchctl bootstrap system /Library/LaunchDaemons/com.ollama.serve.plist
```

**Why localhost (127.0.0.1) works for both users:** TCP sockets bound to localhost are accessible by ANY local process regardless of user. The max user can `curl http://localhost:11434/api/generate` just fine.

**Model storage:** Models live in ~/.ollama/models/. If Ollama runs as ashleytower, models are at /Users/ashleytower/.ollama/models/. The max user doesn't need direct file access -- it accesses via HTTP API.

**No authentication:** Ollama has no built-in auth. Keep it bound to 127.0.0.1 (not 0.0.0.0) to prevent network exposure.

---

## 9. Gotchas: macOS Permissions, TCC, and Non-Admin LaunchDaemons

### TCC (Transparency, Consent, and Control)
- **TCC blocks access** to Documents, Desktop, Downloads, Camera, Microphone, etc.
- LaunchDaemons/scripts do NOT get TCC dialog prompts -- they just fail silently
- Full Disk Access must be granted manually via System Settings > Privacy & Security > Full Disk Access
- **Only admin users** can grant FDA (the Privacy pane requires admin auth)
- The system TCC database (`/Library/Application Support/com.apple.TCC/TCC.db`) is SIP-protected
- User TCC database (`~/Library/Application Support/com.apple.TCC/TCC.db`) is per-user
- `tccutil` CLI can only RESET permissions, not grant them
- **Workaround:** Grant FDA to `/bin/bash` or the specific binary that needs it, via System Settings GUI

### LaunchDaemon Gotchas
- plist must be owned by root:wheel with 644 permissions or launchd refuses to load it
- `sudo launchctl load` is deprecated; use `sudo launchctl bootstrap system <path>`
- LaunchDaemons do NOT source .zshrc, .bash_profile, or any shell config
- PATH in LaunchDaemons is minimal (/usr/bin:/bin:/usr/sbin:/sbin) -- always set PATH in EnvironmentVariables
- HOME is not set by default -- must be explicitly specified in EnvironmentVariables
- The UserName key in LaunchDaemons is IGNORED in LaunchAgents
- If a LaunchDaemon's program doesn't exist at the specified path, it fails silently

### Non-Admin User Gotchas
- Cannot modify /Library/ (need admin for installing LaunchDaemons)
- Cannot install .pkg files system-wide
- Cannot change network settings or add printers
- CAN create cron jobs for themselves (`crontab -e`)
- CAN run their own LaunchAgents in ~/Library/LaunchAgents/ (if logged in)
- CAN access any localhost TCP service (important for Ollama, Supabase local)
- Cannot use `sudo` unless explicitly added to sudoers

### File Access Gotchas
- /Users/ashleytower/ is 700 by default -- max user cannot even `ls` it without ACL changes
- Git operations create new files that may not inherit ACLs if not configured with file_inherit
- Symlinks are followed as the ACCESSING user, not the owner -- ACLs must be on the target
- `.git/` directory contains pack files that also need read access
- `git clone` to max's home is cleaner than ACL-sharing ashleytower's repo

### Recommended Architecture
For the cleanest setup:
1. Create max as standard user with sysadminctl
2. Use LaunchDaemons (in /Library/LaunchDaemons/) with UserName=max for boot-time services
3. Clone/mirror the git repo into /Users/max/ (avoid cross-user ACL complexity)
4. Install Claude Code natively in max's home via the installer script
5. Run Ollama as a system LaunchDaemon bound to localhost -- accessible by all users
6. Keep Homebrew owned by ashleytower; max uses the binaries via PATH
7. Grant FDA to specific binaries (not the user) via System Settings GUI
