# Google Sheets Learnings

## Notes

### 2026-02-06 - Seeded from existing skills
[pattern] See ~/.claude/skills/google-sheets-service-account.md for service account setup. Notes below capture quick gotchas not in the skill file.

### 2026-02-07 - Lead Pipeline Google Sheet
[config] "MTL Craft - Lead Pipeline" spreadsheet ID: 1G3tGOSQ4sVEdE8ibzMkrgXwGbLnIvR--BQ_463-svPw. Three tabs: "CRM & Solopreneur Leads" (sheetId 0), "Bars & Restaurants" (sheetId 1879904038), "Events & Venues" (sheetId 2055973834). Connected via ash.cocktails@gmail.com Rube connection. Set LEAD_SHEET_ID env var to the spreadsheet ID.

### 2026-02-15 - Rube MCP session for batch processing
[config] Rube session ID for Google Sheets batch processing: `gulf`. Used with GOOGLESHEETS_BATCH_GET and GOOGLESHEETS_UPSERT_ROWS tools. Range: `'CRM & Solopreneur Leads'!A1:Z1000`.
