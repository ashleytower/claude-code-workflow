#!/bin/bash

# Phase 2: Score Instagram Posts
# Uses Claude Haiku (with Ollama fallback) to score posts for engagement opportunity (1-10).
# Identifies hooks for comment drafting context.

# ============================================================================
# Score Instagram Posts
# ============================================================================

score_instagram_posts() {
    local posts_json="$1"
    local campaign="$2"

    log "Phase 2: Score Instagram Posts"
    log "=============================="

    if [[ "$posts_json" == "[]" || -z "$posts_json" ]]; then
        log "No posts to score."
        echo "[]"
        return 0
    fi

    local total
    total=$(echo "$posts_json" | jq 'length')
    log "Scoring $total posts for campaign: $campaign"

    local scored="[]"
    local i=0

    while [[ $i -lt $total ]]; do
        local post
        post=$(echo "$posts_json" | jq -c ".[$i]")
        local author
        author=$(echo "$post" | jq -r '.author')
        local caption
        caption=$(echo "$post" | jq -r '.caption')
        local media_type
        media_type=$(echo "$post" | jq -r '.media_type')
        local like_count
        like_count=$(echo "$post" | jq -r '.like_count')
        local comment_count
        comment_count=$(echo "$post" | jq -r '.comment_count')

        # Truncate long captions for scoring
        local caption_for_scoring
        caption_for_scoring=$(echo "$caption" | head -c 1000)

        log "Scoring [$((i + 1))/$total]: @${author} (${media_type}, ${like_count} likes)"

        local campaign_context=""
        case "$campaign" in
            event-leads)
                campaign_context="We're looking for wedding/event posts where we can share bartending/cocktail expertise naturally. High opportunity = posts about event planning, venue setups, party drinks, wedding details where cocktail/bar knowledge adds value."
                ;;
            managed-bar)
                campaign_context="We're looking for bar/restaurant content where cocktail/service expertise adds value. High opportunity = posts about new menus, drink photos, bar setups, venue launches where professional cocktail knowledge would be appreciated."
                ;;
            voice-crm)
                campaign_context="We're looking for solopreneur content about business tools, booking, or client management. High opportunity = posts about business struggles, tool recommendations, productivity tips, or client management where we can share practical experience."
                ;;
            *)
                campaign_context="We're looking for posts where a genuine, knowledgeable comment about cocktails, events, bar service, or solopreneur business tools would add value and feel natural."
                ;;
        esac

        local system_prompt="You are scoring Instagram posts for engagement opportunity. Score 1-10 based on how natural and valuable a comment would be.

${campaign_context}

Evaluate:
- Does the caption invite conversation or ask a question?
- Is the content relevant to our expertise (cocktails/events/solopreneur tools)?
- Is the post getting engagement (likes/comments suggest active audience)?
- Would a thoughtful comment feel natural and welcome, not forced?

Score guide:
1-3: Generic content, a comment would feel random or forced
4-5: Somewhat relevant but no natural opening for conversation
6-7: Good opportunity - relevant content with a natural comment angle
8-10: Great opportunity - caption invites discussion, content is directly relevant, comment would add clear value

Respond in EXACTLY this JSON format:
{\"engagement_score\": N, \"hook\": \"what makes this post worth engaging with\"}"

        local user_prompt="Score this Instagram post:

Account: @${author}
Media type: ${media_type}
Likes: ${like_count} | Comments: ${comment_count}
Caption: ${caption_for_scoring}"

        if [[ "$DRY_RUN" == "true" ]]; then
            local scored_post
            scored_post=$(echo "$post" | jq '.engagement_score = 5 | .hook = "dry-run"')
            scored=$(echo "$scored" | jq --argjson p "$scored_post" '. + [$p]')
            i=$((i + 1))
            continue
        fi

        local response
        response=$(call_ollama "$system_prompt" "$user_prompt" 150)

        # Parse score - try JSON first, fallback to regex
        local engagement_score=0
        local hook=""

        if echo "$response" | jq -e '.engagement_score' > /dev/null 2>&1; then
            engagement_score=$(echo "$response" | jq -r '.engagement_score')
            hook=$(echo "$response" | jq -r '.hook // ""')
        else
            # Regex fallback
            engagement_score=$(echo "$response" | grep -oE '"engagement_score"[[:space:]]*:[[:space:]]*([0-9]+)' | grep -oE '[0-9]+' | head -1)
            hook=$(echo "$response" | grep -oE '"hook"[[:space:]]*:[[:space:]]*"([^"]*)"' | sed 's/.*: *"//;s/"$//' | head -1)

            if [[ -z "$engagement_score" ]]; then
                engagement_score=$(echo "$response" | grep -oE '[0-9]+/10' | grep -oE '^[0-9]+' | head -1)
            fi

            [[ -z "$engagement_score" ]] && engagement_score=0
        fi

        log "  Score: ${engagement_score}/10 | Hook: ${hook:-none}"

        local scored_post
        scored_post=$(echo "$post" | jq \
            --argjson score "$engagement_score" \
            --arg hook "$hook" \
            '.engagement_score = $score | .hook = $hook')

        scored=$(echo "$scored" | jq --argjson p "$scored_post" '. + [$p]')

        i=$((i + 1))

        # Small delay between API calls
        [[ $i -lt $total ]] && sleep 1
    done

    # Sort by engagement score descending
    scored=$(echo "$scored" | jq 'sort_by(-.engagement_score)')

    # Summary stats
    local hot
    hot=$(echo "$scored" | jq '[.[] | select(.engagement_score >= 8)] | length')
    local warm
    warm=$(echo "$scored" | jq '[.[] | select(.engagement_score >= 6 and .engagement_score < 8)] | length')
    local cold
    cold=$(echo "$scored" | jq '[.[] | select(.engagement_score < 6)] | length')

    log "Scoring complete: HOT=$hot WARM=$warm COLD=$cold"

    # Save scored output
    local output_file="${OUTPUT_DIR}/ig-scored-${campaign}-${RUN_DATE}.json"
    echo "$scored" | jq '.' > "$output_file"
    log "Saved scored posts to: $output_file"

    echo "$scored"
}
