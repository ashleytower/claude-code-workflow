# Cloudflare

### 2026-02-18 - Cloudflare Tunnel Setup for mtlcraft.com
[gotcha] `cloudflared tunnel login` requires a domain (zone) to already exist in the Cloudflare account. If the zone table is empty on the auth page, the CLI will timeout after ~7 minutes with "context deadline exceeded". Must add domain first via dashboard.

[gotcha] `cloudflared tunnel login` has a ~8 minute timeout. The browser auth must complete within that window or the cert won't be written. Failed 3 times before getting the timing right.

[gotcha] When `cloudflared tunnel login` reports "Failed to write the certificate", the browser side may have succeeded but the CLI failed to fetch it. Re-run the login command and authorize quickly.

[pattern] User-space cloudflared setup (no sudo needed):
- Config: `~/.cloudflared/config.yml` (not /etc/cloudflared/)
- Cert: `~/.cloudflared/cert.pem`
- Credentials: `~/.cloudflared/<UUID>.json`
- Launchd plist: `~/Library/LaunchAgents/com.cloudflare.cloudflared.plist`
- Use `--config ~/.cloudflared/config.yml` flag

[config] letsaskmax.com Cloudflare account:
- Account: Ash.cocktails@gmail.com
- Zone ID: 68dd31722e3ede6dbb1ccb0754ce852d
- Tunnel name: max-ai
- Tunnel UUID: 4ba9452d-3777-4923-a201-900cdbcc4366
- Domain: letsaskmax.com (purchased from Network Solutions, $12.19/yr)
- Assigned nameservers: mark.ns.cloudflare.com, roxy.ns.cloudflare.com
- Registrar: Network Solutions
- Tunnel CNAME: letsaskmax.com -> 4ba9452d-3777-4923-a201-900cdbcc4366.cfargotunnel.com

[gotcha] mtlcraft.com was originally planned but Ashley doesn't own it. Pivoted to letsaskmax.com mid-setup. Had to re-run `cloudflared tunnel login` for the new zone (cert.pem is zone-specific).

[gotcha] When adding a new domain to Cloudflare, the DNS scan picks up parking A records (208.91.197.27). These must be deleted before `cloudflared tunnel route dns` can add the CNAME for the tunnel.

[gotcha] `cloudflared tunnel route dns` uses the zone from cert.pem. If cert.pem is for zone A but you try to add a route for zone B, it creates the CNAME under zone A (e.g., "letsaskmax.com.mtlcraft.com"). Must re-login with the correct zone first.

[decision] Using caffeinate launchd service instead of `sudo pmset` for sleep prevention. No sudo required, same result for system sleep (not display sleep).

### 2026-02-18 - SSL Certificate Provisioning
[gotcha] Cloudflare Universal SSL "Pending Validation (TXT)" does NOT auto-add ACME challenge TXT records to DNS, despite dashboard banner saying "Cloudflare will validate the certificate on your behalf. No action is required." Must manually add both `_acme-challenge` TXT records from the Edge Certificates page to the DNS zone. Cert issued within 2 minutes after adding them.

[gotcha] SSL/TLS encryption mode "Full (Strict)" works fine with Cloudflare Tunnel. The mode controls browser-to-Cloudflare-edge encryption. Tunnel transport uses QUIC independently.

[pattern] SSL cert validation steps for new Cloudflare domain:
1. Go to SSL/TLS > Edge Certificates
2. Expand Universal cert row to see TXT validation values
3. Go to DNS > Records
4. Add TXT records: Name=`_acme-challenge`, Value=each validation string
5. Cert issues within 1-3 minutes
6. Records can be removed after issuance (Cloudflare manages renewals)

### 2026-02-18 - Migration Complete
[config] Railway-to-Mac migration for twilio-sms:
- All webhooks now route through: https://letsaskmax.com
- SSL cert: Let's Encrypt via Cloudflare, expires 2026-05-19
- Services: com.max.twilio-sms (port 5050), com.cloudflare.cloudflared, com.max.caffeinate
- Twilio webhooks updated: Voice=/voice, SMS=/incoming, Status=/status
- HTTP and HTTPS both functional through tunnel
