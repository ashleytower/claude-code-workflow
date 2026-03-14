# Client Portal - Cocktail Menu & Image Generation

### 2026-02-09 - Frosted glass library comparison
[research] Compared `liquid-glass-react`, `shadcn-glass-ui`, and manual CSS for frosted cocktail cards.
- `shadcn-glass-ui` CSS uses Tailwind v4 `@layer properties` syntax -- incompatible with TW3+Turbopack. Must use inline styles instead of importing their CSS.
- `liquid-glass-react` renders ~780px of SVG filter overlay divs above content, breaking flex centering. Needs absolute positioning with negative top offset to compensate.
- Manual CSS (radial gradients for lighting + backdrop-filter blur) gave the most reliable and controllable result.

### 2026-02-09 - kie.ai prompt engineering for cocktail photos
[pattern] Proven prompt structure for cocktail photography with frosted card overlay:
- Camera field must include "Dead-on straight, perfectly flat front-facing angle, zero perspective distortion, no tilt, no rotation" to prevent diagonal cards.
- Card overlay must specify "card is perfectly vertical and parallel to the image plane with absolutely no angle or diagonal".
- Text readability: ~55% opacity card, bold dark charcoal (#2a2a2a) text.
- Model: `gpt-image/1.5-text-to-image`, aspect `3:2`, quality `high`.

### 2026-02-09 - Moscow Mule recipe correction
[gotcha] MTL uses ginger SYRUP + soda, NOT ginger beer for Moscow Mule. Updated in menu data and all prompts.

### 2026-02-09 - 1.21 Gigawatts recipe correction
[gotcha] Real recipe: mezcal, beet, ginger, lime, bitters. NOT blue curacao/vodka/lemon/dry ice.

### 2026-02-09 - Menu finalized at 35 cocktails across 7 categories
[decision] Full menu recovered from session transcript. Categories: Tequila (7), Gin (6), Vodka (4), Rum (5), Whiskey (3), Holiday (5), Other Classics (5).
Key cocktails that were missing from initial recovery: La Vie en Rose, Cactus Pear Margarita, Blood Orange Margarita, Lavender Fizz (not Collins), Emma's Garden, Summer Vibes, Clover Club, Smokey Colada, Holiday Old Fashioned, Chrismukkah, Best Summer Sangria EVER.
Glass assignments: everything rocks unless specified -- highball: Paloma, 1.21 Gigawatts, Lavender Fizz, Summer Vibes, Moscow Mule, Mojito, Dark n Stormy, Cousin Eddie. Martini: Cosmo, Espresso Martini, Porn Star Martini, Dirty Martinis. Wine glass: Aperol Spritz, Pear Spritz (stemless).
Cousin Eddie is tequila-based (spiced syrup, pear, lime, bitters, tequila, soda), NOT bourbon.
Best Eggnog Ever is rum + brandy, NOT bourbon.
Smokey Colada garnish: umbrella.

### 2026-02-10 - kie.ai API details
[config] API key: `fa220bc2a5143d219a94ce9efe7b777d`
- Endpoint: `POST https://api.kie.ai/api/v1/jobs/createTask`
- Auth: `Authorization: Bearer <key>`
- Poll results: `GET https://api.kie.ai/api/v1/jobs/recordInfo?taskId=<id>`
- Result field: `data.resultJson` (JSON string) -> `resultUrls[0]`
- Image download: needs `User-Agent: Mozilla/5.0` header (403 without it)
- Best model for cocktail photos: `nano-banana-pro` (4K, 1:1, ~$0.12/image)
- Best model for logo/text work: `gpt-image/1.5-text-to-image`
- Available models: `flux-2/pro-text-to-image`, `seedream/4.5-text-to-image`, `google/imagen4`, `midjourney` (see docs.kie.ai/llms.txt for full list)
- Payload structure: `{"model": "...", "input": {"prompt": "...", "aspect_ratio": "1:1", "resolution": "4K", "output_format": "png"}}`

### 2026-02-10 - Image compression for web
[pattern] 4K PNGs (~16MB each) -> 1200px WebP quality 82 (~40KB each) = 99.7% reduction.
Used ImageMagick: `magick input.png -resize 1200x1200 -quality 82 output.webp`
Also generated JPG fallbacks at quality 85 (~100KB each).

### 2026-02-10 - 3D puffy logo generation
[decision] Used kie.ai nano-banana-pro model to generate 3D inflated/puffy version of MTL logo.
Also tried gpt-image/1.5 and flux-2/pro. Nano-banana was closest to original logo layout.
File: `/Users/ashleytower/Desktop/Cocktail Menu /logos/logo-3d-nano-banana.png`
