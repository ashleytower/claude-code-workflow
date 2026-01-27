---
name: telegram-bot
category: integration
frameworks: [nodejs, python]
last_updated: 2026-01-22
version: telegraf 4.16.3
---

# Telegram Bot Integration

## Quick Start

Use `telegraf` for Node.js (TypeScript-friendly, webhook support).

## Installation

```bash
# Node.js
npm install telegraf

# Python
pip install python-telegram-bot
```

## Environment Variables

```env
TELEGRAM_BOT_TOKEN=your_bot_token_from_botfather
```

## Bot Creation (via @BotFather)

1. Message @BotFather on Telegram
2. Send `/newbot`
3. Choose name and username
4. Copy the token

## Setup Code (Node.js with Telegraf)

```typescript
import { Telegraf } from "telegraf";
import { message } from "telegraf/filters";
import { Update } from "telegraf/types";

const BOT_TOKEN = process.env.TELEGRAM_BOT_TOKEN;

let bot: Telegraf | null = null;
let handlersInitialized = false;

/**
 * Get or create the Telegraf bot instance
 */
export function getTelegramBot(): Telegraf | null {
  if (!BOT_TOKEN) {
    console.log("[Telegram] No TELEGRAM_BOT_TOKEN set, bot disabled");
    return null;
  }

  if (!bot) {
    bot = new Telegraf(BOT_TOKEN);
  }

  return bot;
}

/**
 * Set up all bot handlers (called once)
 */
function setupBotHandlers(bot: Telegraf) {
  if (handlersInitialized) return;
  handlersInitialized = true;

  // /start command
  bot.start(async (ctx) => {
    const telegramId = ctx.from.id.toString();
    await ctx.reply(`Hello! Your Telegram ID is: ${telegramId}`);
  });

  // Handle photo messages
  bot.on(message("photo"), async (ctx) => {
    await ctx.reply("Processing your photo...");

    // Get the largest photo
    const photos = ctx.message.photo;
    const largestPhoto = photos[photos.length - 1];
    const fileId = largestPhoto.file_id;

    // Get file URL from Telegram
    const file = await ctx.telegram.getFile(fileId);
    const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${file.file_path}`;

    // Download the file
    const fileRes = await fetch(fileUrl);
    const fileBuffer = Buffer.from(await fileRes.arrayBuffer());

    // Process the image...
    await ctx.reply("Photo received!");
  });

  // Handle document messages (PDFs)
  bot.on(message("document"), async (ctx) => {
    const doc = ctx.message.document;
    const mimeType = doc.mime_type || "";

    if (!mimeType.includes("pdf") && !mimeType.includes("image")) {
      await ctx.reply("Please send a PDF or image file.");
      return;
    }

    // Get file URL
    const file = await ctx.telegram.getFile(doc.file_id);
    const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${file.file_path}`;

    // Process...
  });

  // Handle text messages
  bot.on(message("text"), async (ctx) => {
    if (ctx.message.text.startsWith("/")) return; // Skip commands

    const text = ctx.message.text;
    await ctx.reply(`You said: ${text}`);
  });
}
```

## Webhook Handler (for Vercel/Serverless)

```typescript
/**
 * Handle incoming webhook update from Telegram
 */
export async function handleTelegramWebhook(update: Update): Promise<void> {
  const telegramBot = getTelegramBot();
  if (!telegramBot) return;

  setupBotHandlers(telegramBot);

  try {
    await telegramBot.handleUpdate(update);
  } catch (error) {
    console.error("[Telegram] Error handling webhook update:", error);
    throw error;
  }
}

// API Route (Express/Fastify)
app.post("/api/telegram/webhook", async (req, res) => {
  try {
    await handleTelegramWebhook(req.body);
    res.status(200).json({ ok: true });
  } catch (error) {
    res.status(500).json({ error: "Webhook handling failed" });
  }
});
```

## Set Webhook URL

```bash
# Set webhook (production)
curl -X POST "https://api.telegram.org/bot<TOKEN>/setWebhook" \
  -H "Content-Type: application/json" \
  -d '{"url": "https://your-domain.com/api/telegram/webhook"}'

# Delete webhook (for local dev with polling)
curl -X POST "https://api.telegram.org/bot<TOKEN>/deleteWebhook"

# Check webhook status
curl "https://api.telegram.org/bot<TOKEN>/getWebhookInfo"
```

## Long-Polling (Local Development)

```typescript
export function startTelegramBot() {
  const telegramBot = getTelegramBot();
  if (!telegramBot) return;

  setupBotHandlers(telegramBot);

  telegramBot.launch()
    .then(() => console.log("[Telegram] Bot started (polling mode)"))
    .catch((error) => console.error("[Telegram] Failed to start:", error));

  // Graceful shutdown
  process.once("SIGINT", () => telegramBot?.stop("SIGINT"));
  process.once("SIGTERM", () => telegramBot?.stop("SIGTERM"));
}
```

## Common Use Cases

### Inline Keyboards (Buttons)

```typescript
import { Markup } from "telegraf";

await ctx.reply("Choose an option:",
  Markup.inlineKeyboard([
    [Markup.button.callback("Option 1", "action_1")],
    [Markup.button.callback("Option 2", "action_2")],
  ])
);

// Handle button press
bot.action("action_1", async (ctx) => {
  await ctx.answerCbQuery("You chose Option 1!");
  await ctx.editMessageText("Selected: Option 1");
});
```

### Reply Keyboard (Persistent Buttons)

```typescript
await ctx.reply("Quick actions:",
  Markup.keyboard([
    ["Check Inventory", "Low Stock"],
    ["Pickup List", "Settings"]
  ]).resize()
);
```

### Caption from Photos

```typescript
bot.on(message("photo"), async (ctx) => {
  const caption = ctx.message.caption || "";
  // Use caption for context
});
```

### Send Photos Back

```typescript
await ctx.replyWithPhoto({ source: buffer });
// or
await ctx.replyWithPhoto({ url: "https://example.com/image.jpg" });
```

## Gotchas

1. **Webhook vs Polling**: Can't use both simultaneously. Delete webhook for local polling.

2. **File Downloads**: Telegram file URLs expire. Download immediately or store the file_id.

3. **Handler Initialization**: Only call `setupBotHandlers` once to avoid duplicate handlers.

4. **Message Size**: Telegram has 4096 character limit per message. Split long responses.

5. **Rate Limits**: ~30 messages/second to same chat. Use queue for bulk operations.

6. **Photo Sizes**: `ctx.message.photo` is an array of sizes. Last element is largest.

7. **Serverless Cold Starts**: First request may timeout. Keep handlers lightweight.

8. **User Linking**: Store `ctx.from.id` (Telegram user ID) to link with your app's users.

## Testing

```typescript
// Mock the context for testing
const mockCtx = {
  from: { id: 12345 },
  message: { text: "test message" },
  reply: vi.fn(),
};
```

## Python Alternative

```python
from telegram import Update
from telegram.ext import Application, CommandHandler, MessageHandler, filters

BOT_TOKEN = os.environ.get("TELEGRAM_BOT_TOKEN")

async def start(update: Update, context):
    await update.message.reply_text(f"Hello! Your ID: {update.effective_user.id}")

async def handle_photo(update: Update, context):
    photo = update.message.photo[-1]  # Largest size
    file = await photo.get_file()
    await file.download_to_drive("photo.jpg")
    await update.message.reply_text("Photo received!")

app = Application.builder().token(BOT_TOKEN).build()
app.add_handler(CommandHandler("start", start))
app.add_handler(MessageHandler(filters.PHOTO, handle_photo))
app.run_polling()
```

## Integration with External APIs

```typescript
// Example: Process photo with external API
bot.on(message("photo"), async (ctx) => {
  const file = await ctx.telegram.getFile(ctx.message.photo.pop().file_id);
  const fileUrl = `https://api.telegram.org/file/bot${BOT_TOKEN}/${file.file_path}`;

  // Send to your API
  const response = await fetch("https://your-api.com/process", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ imageUrl: fileUrl })
  });

  const result = await response.json();
  await ctx.reply(`Result: ${JSON.stringify(result)}`);
});
```

---

**Key Takeaway**: Use webhooks for production (serverless-friendly), polling for local dev. Store telegram user ID to link accounts. Handle photos by getting file URL, downloading, then processing.
