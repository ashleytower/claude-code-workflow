# Deployment Checklist

Before deploying to Railway/Vercel/Cloud:

1. **Trace dependencies** - `grep -r "os\.getenv\|os\.environ" *.py`
2. **Check imports** - Each module may need env vars
3. **Research docs** - WebSearch/WebFetch before deploying
4. **Document env vars** - List ALL required variables
5. **Validate target** - Ensure vars set in deployment platform

Never deploy incrementally fixing errors one at a time.
