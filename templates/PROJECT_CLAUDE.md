# Project: [PROJECT_NAME]

## Tech Stack
- Framework:
- Language:
- Database:
- Deployment:

## Structure
```
src/
├── components/    # UI components
├── lib/           # Utilities
├── app/           # Routes/pages
└── types/         # TypeScript types
```

## Patterns
- [Add project-specific patterns here]
- [e.g., "Use server actions for mutations"]
- [e.g., "Components use cn() for classNames"]

## Commands
```bash
npm run dev      # Start dev server
npm run build    # Production build
npm run test     # Run tests
npm run lint     # Lint code
```

## Environment
Required env vars (see .env.example):
- `DATABASE_URL`
- `API_KEY`

## Key Files
- `src/lib/db.ts` - Database client
- `src/lib/auth.ts` - Auth helpers
- `src/app/api/` - API routes

## Testing
- Unit tests: `__tests__/`
- E2E tests: `e2e/`
- Run before commit: `npm run test`

## Notes
- [Add gotchas, quirks, or important context]
- [e.g., "Auth uses cookies, not JWT"]
- [e.g., "Legacy API at /v1 - don't modify"]
