# AI Marketing Agent Landscape Research
## 2026-02-06

### Purpose
Research for building proactive AI marketing capabilities into Max AI Employee system for a solo founder running a mobile cocktail bar in Montreal.

### Key Findings

#### 1. TikTok/Social Scanning - Real Tools
- **Apify TikTok Trends Scraper**: MCP-compatible, scrapes trending hashtags, songs, creators, videos. Direct Claude integration possible.
- **Apify TikTok Trending Songs Scraper**: Specific trending audio data with MCP server support.
- **Virlo**: Tracks 21.3K+ creators across TikTok, YouTube Shorts, Instagram Reels. AI-powered trend alerts.
- **ViralScope**: Analyzes WHY content performed well across 35+ patterns. Monitors competitors continuously.
- **Instagram Competitive Insights** (Nov 2025): Native tool, compare up to 10 accounts.

#### 2. Community Prospecting - Real Tools
- **Devi AI** ($25/mo): Monitors Facebook groups (public AND private), LinkedIn, Reddit, Twitter. 26 buyer-intent expressions. 50-60 leads/day reported.
- **Leado** (Dec 2025): AI Reddit agent, monitors subreddits 24/7, detects buying intent, drafts replies. Alerts via Slack/Discord/webhook.
- **Intently.ai** ($49/mo): AI social listening across Reddit, X, LinkedIn. Real-time buying signal detection.
- **Clay.com**: 150+ data sources, Claygent AI agent, 500K research tasks/day across users.
- **Redreach**: AI-powered Reddit lead generation.

#### 3. Content Generation - Real Tools
- **Videotok**: AI agents for video ads, UGC. 100+ videos in minutes. Script to final cut automated.
- **HeyGen** ($29/mo): 1,100+ AI avatars, UGC ad generation, multilingual. Export for TikTok/Reels/YouTube.
- **Arcads**: AI-generated UGC video ads.
- **AdCreative.AI**: Platform-specific ad copy for Facebook, Google, TikTok.

#### 4. Landing Page AI - Real Tools
- **v0.dev**: React components from prompts, excellent design quality, Vercel integration.
- **Framer AI**: Wireframer tool generates responsive layouts from prompts. $2B valuation.
- Both can be orchestrated by an AI agent via API.

#### 5. Knowledge-Grounded Marketing - Real Examples
- **Custom GPTs**: "$100M Leads Guide" GPT, "Alex Hormozi $100M Offer Generator" GPT exist on GPT Store.
- **StoryBrand AI**: Launched Jan 2025 alongside Building a StoryBrand 2.0.
- **RAG approach**: Store marketing frameworks in Supabase vector store, retrieve during content generation.

#### 6. Orchestration - Real Platforms
- **n8n**: Multi-agent marketing team workflows. CMO agent delegates to specialists.
- **Claude Flow**: 175+ MCP tools, multi-agent swarms, RAG integration.
- **Composio MCP**: Integrations for Klaviyo, Meta Ads, Canva, ActiveCampaign.

### Technical Feasibility for Max AI Employee (Claude + MCP + Supabase)
- HIGH: TikTok scanning via Apify MCP servers
- HIGH: Reddit/community monitoring via Leado API or direct Reddit API
- HIGH: Content script generation via Claude with marketing framework RAG
- MEDIUM: Landing page generation via v0 Platform API
- MEDIUM: Video ad creation via HeyGen/Videotok APIs
- LOW: Facebook private group monitoring (ToS concerns)

### Tags
[research] [decision] AI marketing agent landscape for mobile cocktail bar business
