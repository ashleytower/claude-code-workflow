# Mirror Landing

### 2026-02-13 - Initial setup: Next.js 16 + Tailwind 4 static export
[pattern] Next.js 16.1.6 with `output: 'export'` in next.config.ts generates static HTML to `out/` directory.
Must set `images: { unoptimized: true }` for static export since next/image optimization requires a server.
Tailwind 4 uses `@theme inline` blocks in CSS instead of tailwind.config.ts for custom theme values.

### 2026-02-13 - CSS custom properties for per-page accent colors
[pattern] Use `style={{ "--accent": accentColor } as React.CSSProperties}` on the page wrapper div.
Reference in Tailwind classes as `bg-[var(--accent)]` or `text-[var(--accent)]`. Works with static export.

### 2026-02-13 - Next.js 16 params are Promises
[gotcha] In Next.js 16, route params are `Promise<Params>` not `Params`. Must `await params` in both
`generateMetadata` and page components. Signature: `{ params: Promise<{ slug: string }> }`.

### 2026-02-13 - create-next-app interactive prompt for React Compiler
[gotcha] `npx create-next-app@latest` now asks "Would you like to use React Compiler?" interactively.
Pipe `No` via stdin to avoid blocking: `echo "No" | npx create-next-app@latest ...` or use heredoc.
