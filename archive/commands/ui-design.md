# UI Design Command

**Purpose**: Design and approve UI mockups BEFORE writing any implementation code. No code until design is approved!

**User's critical requirement**: "Get the UI right BEFORE the code is written"

## Usage

```bash
claude /ui-design "[component description]"
# Example: claude /ui-design "login screen with email/password fields and social auth buttons"
```

## Process

### Phase 1: Research UI Patterns (Automatic)

Invoke `@research-ui-patterns` subagent to search:

**YouTube**:
- "[component] React Native tutorial 2025"
- "[component] UI design tutorial"
- Filter: Recent (6 months), good engagement
- Extract: Implementation approaches, user feedback

**GitHub**:
- Search: "[component] react-native stars:>100"
- Filter: Updated in last 6 months
- Extract: Code patterns, component APIs, styling approaches

**Reddit/X**:
- r/reactnative, r/expo, r/UI_Design
- X hashtags: #ReactNative #UIDesign #MobileUI
- Extract: User pain points, what works/doesn't

**Dribbble/Behance**:
- Visual inspiration
- Current design trends 2025
- Interaction patterns
- Animation ideas

**Output**: `.claude/research/ui-[component].md` with findings

### Phase 2: Generate UI Mockup

**Option A: Google AI Studio (Gemini 2.0)**
```bash
# Use Gemini 2.0 Flash for quick mockup generation
# Describe component → Gemini generates visual mockup
```

**Option B: Stitch API**
```bash
curl -X POST "https://api.stitch.tech/v1/generate" \
  -H "Authorization: Bearer $STITCH_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Design a [component description]",
    "framework": "react-native",
    "style": "modern, minimalist, following iOS/Material Design"
  }'
# Returns: image URL + suggested component code
```

**Option C: Text Description + Code Sketch**
If no visual tools available:
1. Detailed text description of UI
2. ASCII mockup
3. Suggested component structure
4. Styling approach

### Phase 3: Present to User for Approval

Show:
- Research findings summary
- Generated mockup (image or detailed description)
- Recommended component structure
- Styling approach
- Interaction patterns

Ask:
- "Does this design look good?"
- "Any changes needed?"
- "Approve to proceed with implementation?"

### Phase 4: Iterate Until Approved

If user requests changes:
- Regenerate mockup with changes
- Show updated version
- Get approval

Repeat until user says:
- "Looks good!"
- "Approved"
- "Go ahead and implement this"

### Phase 5: Document Approved Design

Save to: `.claude/designs/[component].md`

```markdown
# [Component Name] - Approved Design

**Approved on**: [date]
**Mockup**: [image URL or description]

## Design Specifications

**Colors**:
- Primary: [color]
- Secondary: [color]
- Background: [color]
- Text: [color]

**Typography**:
- Heading: [font, size, weight]
- Body: [font, size, weight]

**Spacing**:
- Padding: [values]
- Margins: [values]
- Component spacing: [values]

**Layout**:
[Description of layout structure]

**Interactions**:
- Tap: [behavior]
- Long press: [behavior]
- Swipe: [behavior]

**States**:
- Default: [appearance]
- Hover/Pressed: [appearance]
- Disabled: [appearance]
- Loading: [appearance]
- Error: [appearance]

## Component Structure

```typescript
interface [ComponentName]Props {
  // Props based on approved design
}
```

## Implementation Notes

[Any specific implementation guidance]

## Approved By
User: [name/date]
```

### Phase 6: Ready for Implementation

**ONLY NOW** can code be written!

Frontend subagent will check:
- Is this UI code?
- Has design been approved?
- If no: STOP and run /ui-design first

## Integration with Frontend Subagent

**In @frontend agent frontmatter**:
```markdown
---
skills: [ui-design]
hooks:
  PreToolUse:
    matcher: "Write|Edit"
    hooks:
      - type: prompt
        prompt: "Before writing UI code: Has design been approved via /ui-design? If not, invoke ui-design skill first."
---
```

This prevents frontend agent from writing UI code without approval!

## Integration with Orchestrator

When orchestrator detects UI changes, it invokes @frontend agent which:
1. Checks if design was approved
2. Compares implementation to approved design
3. Reports any deviations
4. Suggests corrections if needed

## Output Example

```
🎨 UI DESIGN: Login Screen

📚 Research Complete:
- Found 12 GitHub examples
- Watched 3 YouTube tutorials
- Reviewed 15 Dribbble designs
- Community feedback: Users prefer social auth buttons above email/password

🖼️  Generated Mockup:
[Image URL or ASCII mockup]

Design includes:
- Email input field with validation
- Password input with show/hide toggle
- "Sign In" button (primary action)
- Social auth buttons (Google, Apple) below
- "Forgot password?" link
- "Create account" link

Color scheme: Modern, clean
- Background: #FFFFFF
- Primary: #007AFF (iOS blue)
- Text: #000000
- Borders: #E5E5E5

✋ APPROVAL NEEDED:
Does this design look good? Any changes?

[User: "Looks great!"]

✓ Design approved and saved to .claude/designs/login-screen.md

✅ Ready to implement!
Frontend agent can now write code following this approved design.
```

## Notes

- Never skip this step for UI features
- Research informs better designs
- User approval prevents rework
- Approved designs become documentation
- Frontend agent enforces approved designs via hooks
