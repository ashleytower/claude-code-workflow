# Facebook Group Monitoring Research - 2026-02-06

## Summary
Deep research into how Facebook group monitoring tools work, competitive landscape, and architecture for building Max's own version using claude-in-chrome.

### 2026-02-06 - How Devi AI Works
[research] Chrome extension that uses your existing browser session cookies. Navigates group feeds in background tabs. Reads DOM content, keyword matches locally. Data never leaves your machine. Patent pending on this approach. Scans every 2 hours, 25 group limit, $49/mo.

### 2026-02-06 - Groups Watcher (Better Alternative)
[research] Three tiers: Chrome extension (3-7 min scans, unlimited groups, $29/mo), Professional (their accounts, cloud servers, under 60s alerts, $99/mo), Local Business (auto-comments within 60s, A/B tested strategies, $149/mo). Webhooks to Slack/Discord/n8n/Zapier.

### 2026-02-06 - Meta API Changes August 2024
[gotcha] Meta killed most Facebook group monitoring tools by cutting API access. Only browser-extension-based tools survived because they read the rendered page like a human, not via API. This validates our claude-in-chrome approach.

### 2026-02-06 - PhantomBuster
[research] $69/mo, cloud-based scraping. Extracts member lists and profiles, not real-time monitoring. Higher ban risk from Meta. Different use case - data extraction vs lead monitoring.

### 2026-02-06 - Max's Architecture for Facebook Monitoring
[decision] Build using claude-in-chrome MCP tools through Mac node. Four phases:
1. Group Discovery - automated Facebook search for relevant groups
2. Group Joining - semi-automated, 3-5/day max, draft screening question answers
3. Monitoring - configurable frequency, bilingual FR/EN keywords, Claude-powered intent scoring
4. Engagement - brand-voice-aware reply drafts, approval flow via Telegram

### 2026-02-06 - Competitive Advantages Over Devi/Groups Watcher
[decision] Bilingual FR/EN (competitors are English only), automated group discovery (competitors require manual), Claude-powered contextual intent scoring (vs simple keyword match), $0 cost (own infrastructure), full data ownership in Supabase, unlimited groups.

### 2026-02-06 - Voice CRM Product Direction
[decision] Ashley plans to launch a voice CRM business. Facebook group monitoring becomes a sellable feature: automated discovery + managed monitoring + bilingual support + voice follow-up via Twilio + lead pipeline dashboard. Target price: $200+/mo per client.

### 2026-02-06 - Three Campaign Strategy
[decision] Three separate group monitoring campaigns, same system:

**Campaign 1: MTL Craft Cocktails (event leads - Montreal local)**
- Target groups: Montreal wedding planning, event planning Quebec, Montreal foodies, local party/social groups
- Keywords (EN): "bartender", "mobile bar", "cocktail service", "recommend bartender", "wedding drinks"
- Keywords (FR): "bar mobile", "service de cocktails", "bartender mariage", "cherche un bartender", "traiteur"
- Goal: Book events. Hot leads get Telegram alert + drafted reply for Ashley to approve.
- Estimated groups needed: 10-15 well-targeted Montreal groups

**Campaign 2: Managed Bar Program (B2B - owners without craft bartenders)**
- The gap: Cocktail bar-quality drinks that anybody can make. Owners overwhelmed managing their bar.
- MTL Craft provides: syrups, garnishes, easy recipes, consistency. Eventually AI inventory system.
- Target: OWNERS not bartenders. Restaurants where drinks are an afterthought, new bar owners, high-volume spots, catering companies, hotels, cafes, seasonal/pop-up venues.
- Target groups: Restaurant owner FB groups, new bar owner groups (Bar Principles), catering groups, hotel F&B, cafe owners, r/restaurateur, r/BarOwners
- AVOID: Craft bartender communities (they make their own), mixology groups
- Keywords: "can't find a bartender", "staff turnover", "drinks are inconsistent", "cocktail menu help", "bar program from scratch", "training new bar staff"
- Geographic scope: Canada-wide, US possible. Syrups ship.
- Competitors: WithCo Cocktails, Wandering Barman, Bartesian. MTL Craft differentiator: handmade not premade, kosher, bilingual, full package.

**Campaign 3: Voice CRM / AI Tools (product-led growth)**
- Target: NON-TECHNICAL solopreneurs who use ChatGPT but don't know AI can do more. NOT AI builders.
- Target groups: Dubsado Users, HoneyBook Community, AI Simplified, LifeStarr Solopreneur, wedding vendor support, freelancer groups
- Keywords: "frustrated with CRM", "looking for alternative", "anyone switched from Dubsado", "too many tools", "manually tracking"
- Approach: Empathy-first. "I had the same problem as a wedding vendor, here's what I built."
- Ashley is leaving Dubsado and building a replacement. Positions as fellow user who solved own pain, not vendor.
- Goal: Early adopters for voice CRM product.

### 2026-02-06 - Group Targeting Principles
[pattern] Don't need 200 groups. 10-15 well-chosen groups per campaign is enough. A 5,000-member Montreal wedding group is worth more than a 50,000-member generic wedding group. Quality over quantity. Pace joining at 3-5 per day to avoid Facebook flags.

### 2026-02-06 - Key Facebook Group Types for MTL Craft
[research] Target groups by customer type:
- Brides: "Montreal Brides 2026", "Mariages Quebec", "Montreal Wedding Planning"
- Corporate: "Montreal Event Planners", "Corporate Events Quebec"
- Party hosts: "Montreal Foodies", "Montreal Social Events", "Things to Do Montreal"
- Venue managers: "Montreal Venue Owners", "Quebec Hospitality Industry"
- Local biz: "Montreal Entrepreneurs", "Small Business Montreal"

### 2026-02-06 - Key Facebook Group Types for Voice CRM
[research] Target: NON-TECHNICAL solopreneurs who use ChatGPT but don't know AI can do more. NOT AI builders.
- CRM users: "Dubsado Users Group", "HoneyBook Community", "CRM for Small Business"
- Solopreneurs: "AI Simplified" (small biz owners learning ChatGPT), "LifeStarr Solopreneur Community", "Solopreneur Nation", "One Person Business"
- Wedding vendors: "Wedding Vendor Support", "Wedding Pros Who Tech"
- Freelancers: "Freelancers Union", "Small Business Owners" (various large groups), "Women Entrepreneurs"
- ChatGPT users: "ChatGPT for Business" type groups, "Side Hustle" groups
- AVOID: AI Agents, Claude Code, Vibe Coding groups (too technical, not the target)
