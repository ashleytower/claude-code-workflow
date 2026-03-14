# B-Roll Automated Pipeline Deep Dive: APIs, Remotion Integration, and Workflow Patterns
### 2026-02-18

## 1. Stock Footage API Comparison (Developer-Focused)

### Free APIs
| API | Library Size | Rate Limit | Video Formats | Attribution | Notes |
|-----|-------------|------------|---------------|-------------|-------|
| Pexels | 4.4M+ assets | 200 req/hr, 20K/mo | HD/4K | Not required | Best free option. Orientation + size filters. Max 80 per page. |
| Pixabay | 4.3M assets | 100 req/min | HD/4K | Not required | Unlimited total requests. 24hr cache required. No hotlinking. |
| Coverr | Curated library | Staging: 1K/mo; Prod: 500/min | HD/4K | Not required | Free for commercial. Must request prod key. |
| Videvo | 700K+ assets | 100 req/min | HD/4K | Varies by clip | 24hr caching required. No hotlinking. |

### Paid APIs
| API | Library Size | Rate Limit | Pricing | Notes |
|-----|-------------|------------|---------|-------|
| Storyblocks | 1.5M+ | Unlimited search/download | $24K/yr min (API) | Flat fee. Best for scale. Poor docs (Postman only). |
| Shutterstock | 500M+ | Free: 100/hr | Contact sales | Free tier = images only. Video needs Business plan. |
| Adobe Stock | 200M+ (23M video) | Unlimited | Free API, pay per license | Best docs. Visual search. Per-asset licensing. |
| Getty Images | 477M+ | Not disclosed | Contact sales | Premium quality, premium price ($200+/clip). |
| Pond5 | "World's largest" | Not disclosed | Sub + pay-as-you-go | Strong archival content. |

### Key Pexels API Details
[research]
- Endpoint: GET /videos/search?query={query}&orientation={landscape|portrait|square}&size={large|medium|small}&per_page={1-80}&page={n}
- Auth: Header `Authorization: {API_KEY}`
- Rate headers: X-Ratelimit-Remaining, X-Ratelimit-Reset
- Returns: video files array with multiple quality options (HD, SD, etc.)
- Error: 429 when limit exceeded

### Key Pixabay API Details
[research]
- Endpoint: GET /api/videos/?key={KEY}&q={query}&video_type={film|animation|all}&min_width=&min_height=&per_page={3-200}
- Free, unlimited requests
- Must cache results 24 hours
- No hotlinking -- must download

## 2. Remotion + B-Roll Integration

[research]
### How B-Roll Works in Remotion
- Use `<OffthreadVideo>` component for video overlays (preferred over `<Video>` for rendering)
- `<Sequence>` components are absolutely positioned by default = natural layering for b-roll
- Place footage in `public/` folder, reference via `staticFile()`
- Control timing with `from` and `durationInFrames` props
- Remotion Recorder has built-in b-roll support with dropdown selector

### Key Constraints (Remotion Recorder)
- If second b-roll overlays first, first must not disappear before second disappears
- B-roll must disappear before scene transition begins
- Rules enforced in: `remotion/scenes/BRoll/apply-b-roll-rules.ts`

### Code Pattern for B-Roll Overlay
```tsx
<Composition id="VideoWithBRoll" component={MyVideo} durationInFrames={300} fps={30} width={1080} height={1920}>
  {/* Main content layer */}
  <Sequence from={0} durationInFrames={300}>
    <MainContent />
  </Sequence>
  {/* B-roll overlay layer */}
  <Sequence from={60} durationInFrames={90}>
    <OffthreadVideo src={staticFile("broll-clip-1.mp4")} style={{ width: '100%', height: '100%', objectFit: 'cover' }} />
  </Sequence>
</Composition>
```

### Limitation
[gotcha] Remotion cannot import MP4s for trimming/cutting/effects. It renders FROM code. For editing existing footage, use traditional NLE or Shotstack/Creatomate APIs.

## 3. Automated B-Roll Selection Pipeline

[pattern] The standard NLP-to-b-roll pipeline:
1. Transcribe narration (Whisper API)
2. Extract keywords per sentence/segment (GPT-4 API)
3. Generate search queries from keywords
4. Query stock API (Pexels/Pixabay) with queries
5. Filter results by orientation, duration, resolution
6. Download and cache clips locally
7. Insert into timeline (Remotion/Shotstack/Creatomate)

### How OpusClip Does It
- NLP on speech + audio for keywords, topics, emotional tone
- ML model trained on thousands of successful social media videos
- Ranks potential b-roll by relevance AND viewer engagement potential
- Auto-detects moments needing visual enhancement

### How Submagic Does It
- Auto-transcribes with near-perfect accuracy
- Detects themes, objects, people, locations, emotions
- Creates b-roll "prompt list"
- Generates or sources relevant footage
- Places b-roll synchronized with captions/subtitles

### Submagic API Specifics
[research]
- POST https://api.submagic.co/v1/projects
- Auth: x-api-key header (sk-*)
- Rate limit: 500 req/hr
- Key params: magicBrolls (boolean), magicBrollsPercentage (0-100%)
- AI b-roll items: type "ai-broll", startTime, endTime (max 12s), prompt (1-2500 chars)
- User media items: type "user-media", startTime, endTime, userMediaId
- Formats: MP4, MOV. Max 2GB, 2hr duration
- Webhook callback on completion with downloadUrl

## 4. B-Roll Best Practices (Automated Video)

[research]
### Duration Per Clip
- Short-form (TikTok/Reels/Shorts): 0.8-2.0 seconds per clip
- Standard video: 2-5 seconds per clip
- Documentary/slower pace: 5-10 seconds
- Rule of thumb: one cut every 2-4 seconds for high retention

### Avoiding Repetition
- Maintain a "used clips" registry per video and per campaign
- Mix shot types: wide establishing, medium, close-up, macro
- Alternate between: motion shots (pans/tilts), static shots, POV shots
- Use Pexels orientation filter to vary landscape/portrait/square

### Mood Matching
- Map narration sentiment (positive/negative/neutral) to visual tone
- GPT-4 can classify segment mood and generate appropriate search terms
- Use warm/cool color grading as secondary mood signal

### Transitions
- Cut (most common, cleanest for fast-paced)
- Cross-dissolve (for mood/time changes)
- Avoid wipes/fancy transitions in short-form
- Cut on the beat if music is present

## 5. Ready-Made Pipeline Templates

[research]
### n8n Workflows (Open Source)
1. "Reddit threads to vertical videos" - Pexels b-roll + Shotstack rendering + TTS
2. "AI videos from prompts" - OpenAI script + TTS + Pexels b-roll + SRT subtitles
3. "Short-form with Creatomate" - ElevenLabs TTS + Pexels stock + Creatomate render
4. "Faceless videos" - Gemini + ElevenLabs + Leonardo AI + Shotstack

### Video Rendering APIs
| API | What It Does | Pricing |
|-----|-------------|---------|
| Shotstack | JSON-to-video rendering, overlays, transitions | Free tier available |
| Creatomate | Template-based video generation | From $24/mo |
| Plainly | After Effects template rendering in cloud | Contact sales |

## 6. Hybrid AI + Stock Approach

[decision]
### When to Use Stock B-Roll
- Shots featuring people (AI still uncanny)
- Recognizable locations
- Specific branded products
- Complex human interactions
- Cooking/food close-ups
- Hand-object interactions

### When to Use AI-Generated
- Abstract concepts (growth, innovation, technology)
- Environmental/atmospheric shots
- Stylized sequences
- Product close-ups without people
- Custom scenes not available in stock libraries

### Recommended Hybrid Stack
1. Primary: Pexels API (free) for 70% of b-roll needs
2. Fallback: Pixabay API (free) for variety
3. AI Generation: Runway/Kling for custom scenes (10-20% of clips)
4. Premium: Storyblocks API for high-volume production ($24K/yr)

## 7. Free/Open-Source Video Libraries

[research]
- Pexels: Free, no attribution, commercial use, 4K
- Pixabay: Free, no attribution, commercial use, 4K
- Coverr: Free, no attribution, commercial use, curated for marketing
- Videezy: Free tier with CC attribution, paid tier available
- Mixkit: Free, trendy clips, good for social media
- Prelinger Archives: 2000+ public domain videos (archival/vintage)
- Wikimedia Commons: Public domain educational media
- Videvo: Free tier (attribution required for some clips)
