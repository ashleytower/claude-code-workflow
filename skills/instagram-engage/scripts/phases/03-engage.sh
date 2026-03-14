#!/bin/bash

# Phase 3: Engage Instagram Posts
# Drafts comments, sends to Telegram for approval, posts via API or browser fallback.
# Mirrors reddit-engage/03-engage.sh with Instagram-specific adaptations.

# Safety limits
MAX_COMMENTS_PER_DAY=10
COMMENT_DELAY=120    # 120s base between comments
COMMENT_JITTER=60    # 0-60s random jitter = 120-180s total
APPROVAL_TIMEOUT=3600  # 1 hour to respond

# Source correction library
SHARED_LIB_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../shared/lib" && pwd)"
if [[ -f "${SHARED_LIB_DIR}/corrections.sh" ]]; then
    source "${SHARED_LIB_DIR}/corrections.sh"
    CORRECTIONS_AVAILABLE=true
else
    CORRECTIONS_AVAILABLE=false
fi

# ============================================================================
# Draft Instagram Comment with Claude
# ============================================================================

draft_instagram_comment() {
    local caption="$1"
    local campaign="$2"
    local author="$3"
    local hook="$4"
    local engagement_score="$5"
    local media_type="$6"

    local campaign_context=""
    local campaign_voice=""
    case "$campaign" in
        event-leads)
            campaign_context="Ashley runs MTL Craft Cocktails, a mobile bartending / cocktail catering service in Montreal. She personally bartends events and provides full bar service (cocktails, setup, staff). She's done weddings, corporate events, private parties."
            campaign_voice="Event lover voice: warm, celebratory, genuinely excited about people's events. Like a friend who loves throwing parties."
            ;;
        managed-bar)
            campaign_context="Ashley runs MTL Craft, which makes handmade cocktail syrups and provides bar consulting for restaurants and bars. She helps venues build consistent cocktail programs without needing a full-time mixologist."
            campaign_voice="Cocktail nerd voice: enthusiastic, specific about techniques and ingredients. Like a fellow bartender geeking out."
            ;;
        voice-crm)
            campaign_context="Ashley is a wedding vendor and solopreneur who was frustrated with Dubsado and other CRMs. She ended up building her own AI-powered system that handles bookings, follow-ups, and even takes phone calls."
            campaign_voice="Fellow solopreneur voice: empathetic, practical, sharing what actually works. Like a business friend who gets it."
            ;;
    esac

    local correction_rules=""
    if [[ "$CORRECTIONS_AVAILABLE" == "true" ]]; then
        correction_rules=$(get_correction_rules "$caption" 5 2>/dev/null || true)
    fi

    local correction_block=""
    if [[ -n "$correction_rules" ]]; then
        correction_block="
CORRECTION RULES (learned from past edits -- follow strictly):
${correction_rules}
"
    fi

    local system_prompt="You are drafting an Instagram comment for Ashley. She's a real person engaging authentically with accounts she follows.

RULES - non-negotiable:
1. MAX 300 CHARACTERS. Aim for 100-200. Instagram enforces this hard limit.
2. 1-3 sentences max. Keep it tight.
3. Be warm and visual-reactive - reference what's in the photo/video if the caption hints at it.
4. Sound like a real person on Instagram: genuine, enthusiastic but not fake, supportive.
5. NEVER include links. NEVER say \"DM me\" or anything promotional.
6. NEVER use marketing language: \"solution\", \"leverage\", \"optimize\", \"seamless\".
7. NEVER use em dashes or en dashes (-- or -). Use commas or periods instead.
8. If you can engage without mentioning Ashley's business at all, do that.
9. Match the energy of the post - celebratory posts get excitement, thoughtful posts get reflection.
10. No hashtags in comments. No emojis at the start of the comment.

${campaign_context}
${campaign_voice}
${correction_block}

GOOD Instagram comment examples:
- \"This setup is gorgeous! The color palette with those garnishes is so well thought out.\"
- \"Honestly this is the kind of bar program more places need. Consistency is so underrated.\"
- \"I felt this so hard. Switched up my whole booking flow last year and it changed everything.\"

BAD examples (never write these):
- \"Love this! Check out our page for more!\" (promotional)
- \"As a professional in the industry...\" (too formal)
- \"DM us for details!\" (spam)"

    local user_prompt="Draft an Instagram comment for this post.

Account: @${author}
Media type: ${media_type}
Engagement hook: ${hook}
Engagement score: ${engagement_score}/10

Caption:
\"${caption}\"

Write ONLY the comment text. Nothing else. Max 300 characters."

    local draft
    draft=$(call_claude_api "$system_prompt" "$user_prompt" 300)

    # Strip em/en dashes (AI tells)
    draft=$(echo "$draft" | sed 's/—/-/g; s/–/-/g')

    # Strip surrounding quotes if present
    draft=$(echo "$draft" | sed 's/^"//;s/"$//')

    # Hard enforce 300 char limit
    draft="${draft:0:300}"

    echo "$draft"
}

# ============================================================================
# Send Draft to Telegram for Approval
# ============================================================================

send_ig_comment_for_approval() {
    local caption="$1"
    local draft_comment="$2"
    local author="$3"
    local post_url="$4"
    local campaign="$5"
    local comment_index="$6"

    local snippet
    snippet=$(echo "$caption" | head -c 200)

    local message="IG COMMENT DRAFT [${comment_index}]

Account: @${author}
Campaign: ${campaign}
Caption: \"${snippet}...\"

Draft:
\"${draft_comment}\"

Reply with:
  IG OK ${comment_index} - Post as-is
  IG EDIT ${comment_index} <your version> - Post your edit
  IG SKIP ${comment_index} - Don't comment

Link: ${post_url}"

    send_telegram_message "$message"
}

# ============================================================================
# Check for Telegram Approval
# ============================================================================

check_ig_approval() {
    local comment_index="$1"
    local timeout="${2:-$APPROVAL_TIMEOUT}"

    local start_time
    start_time=$(date +%s)

    # Get latest update_id so we don't consume other skills' messages
    local latest_updates
    latest_updates=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=-1&limit=1")
    local offset=0
    if echo "$latest_updates" | jq -e '.result[0].update_id' > /dev/null 2>&1; then
        offset=$(($(echo "$latest_updates" | jq -r '.result[0].update_id') + 1))
    fi

    while true; do
        local now
        now=$(date +%s)
        local elapsed=$((now - start_time))

        if [[ $elapsed -ge $timeout ]]; then
            log "Approval timeout for comment ${comment_index} after ${timeout}s"
            echo "TIMEOUT"
            return 0
        fi

        local updates
        updates=$(curl -s "https://api.telegram.org/bot${TELEGRAM_BOT_TOKEN}/getUpdates?offset=${offset}&timeout=10")

        if ! echo "$updates" | jq -e '.ok' > /dev/null 2>&1; then
            sleep 5
            continue
        fi

        local result_count
        result_count=$(echo "$updates" | jq '.result | length')

        local j=0
        while [[ $j -lt $result_count ]]; do
            local update
            update=$(echo "$updates" | jq -c ".result[$j]")
            local update_id
            update_id=$(echo "$update" | jq -r '.update_id')
            local msg_text
            msg_text=$(echo "$update" | jq -r '.message.text // ""')
            local chat_id
            chat_id=$(echo "$update" | jq -r '.message.chat.id // ""')

            if [[ "$chat_id" == "$TELEGRAM_CHAT_ID" ]]; then
                local upper_msg
                upper_msg=$(echo "$msg_text" | tr '[:lower:]' '[:upper:]')

                if [[ "$upper_msg" == "IG OK ${comment_index}"* ]]; then
                    offset=$((update_id + 1))
                    echo "APPROVED"
                    return 0
                elif [[ "$upper_msg" == "IG EDIT ${comment_index}"* ]]; then
                    local edited
                    edited=$(echo "$msg_text" | sed "s/^[Ii][Gg] [Ee][Dd][Ii][Tt] ${comment_index} //")
                    offset=$((update_id + 1))
                    echo "EDITED:${edited}"
                    return 0
                elif [[ "$upper_msg" == "IG SKIP ${comment_index}"* ]]; then
                    offset=$((update_id + 1))
                    echo "SKIPPED"
                    return 0
                fi
            fi

            offset=$((update_id + 1))
            j=$((j + 1))
        done

        sleep 10
    done
}

# ============================================================================
# Post Instagram Comment (Dual Path: API first, browser fallback)
# ============================================================================

post_instagram_comment() {
    local media_id="$1"
    local comment="$2"
    local post_url="$3"

    # Strip em/en dashes again (safety net)
    comment=$(echo "$comment" | sed 's/—/-/g; s/–/-/g')

    # Hard enforce 300 char limit
    comment="${comment:0:300}"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would post comment on $post_url"
        log "[DRY RUN] Comment: $comment"
        return 0
    fi

    # Try API first
    log "Attempting API comment on media $media_id..."
    local args
    args=$(jq -n \
        --arg ig_media_id "$media_id" \
        --arg message "$comment" \
        '{
            ig_media_id: $ig_media_id,
            message: $message
        }')

    local response
    response=$(rube_execute "INSTAGRAM_POST_IG_MEDIA_COMMENTS" "$args" "Post comment on $media_id" 2>/dev/null)

    local success
    success=$(echo "$response" | jq -r '.successful // false' 2>/dev/null)

    if [[ "$success" == "true" ]]; then
        log "Comment posted via API successfully"
        echo "api"
        return 0
    fi

    # API failed - queue for browser fallback
    log "API comment failed, queuing for browser fallback"

    local comment_obj
    comment_obj=$(jq -n \
        --arg url "$post_url" \
        --arg text "$comment" \
        --arg ts "$(date -u +%Y-%m-%dT%H:%M:%SZ)" \
        '{post_url: $url, comment_text: $text, action: "post", status: "pending", platform: "instagram", created_at: $ts}')

    local pending_file="${OUTPUT_DIR}/pending-ig-comments-${RUN_DATE}.json"
    if [[ -f "$pending_file" ]]; then
        jq --argjson obj "$comment_obj" '. + [$obj]' "$pending_file" > "${pending_file}.tmp" && mv "${pending_file}.tmp" "$pending_file"
    else
        echo "[$comment_obj]" | jq '.' > "$pending_file"
    fi

    log "Comment queued in: $pending_file"
    echo "browser"
    return 0
}

# ============================================================================
# Log Comment to Supabase
# ============================================================================

log_ig_comment_to_supabase() {
    local post_url="$1"
    local comment_text="$2"
    local campaign="$3"
    local account="$4"
    local source_id="$5"
    local status="$6"  # posted, skipped, timeout, edited
    local method="$7"  # api, browser

    if [[ "$DRY_RUN" == "true" ]]; then
        log "DRY RUN: Would log Instagram comment to Supabase"
        return 0
    fi

    local data
    data=$(jq -n \
        --arg uid "$USER_ID" \
        --arg action "instagram_comment" \
        --arg post_url "$post_url" \
        --arg comment "$comment_text" \
        --arg campaign "$campaign" \
        --arg account "$account" \
        --arg source_id "$source_id" \
        --arg status "$status" \
        --arg method "$method" \
        --arg date "$RUN_DATE" \
        '{
            user_id: $uid,
            action: $action,
            details: {
                post_url: $post_url,
                comment_text: $comment,
                campaign: $campaign,
                account: $account,
                source_id: $source_id,
                comment_status: $status,
                method: $method,
                date: $date
            }
        }')

    supabase_query "audit_log" "POST" "$data" > /dev/null 2>&1
}

# ============================================================================
# Send Daily Summary
# ============================================================================

send_ig_summary() {
    local total_scored="$1"
    local comments_posted="$2"
    local comments_skipped="$3"
    local hot_count="$4"
    local warm_count="$5"

    local summary="Instagram Engagement Summary

Posts found & scored: ${total_scored}
HOT (8+): ${hot_count}
WARM (6-7): ${warm_count}

Comments drafted: $((comments_posted + comments_skipped))
Posted: ${comments_posted}
Skipped: ${comments_skipped}

All comments logged to audit trail."

    send_telegram_message "$summary"
}

# ============================================================================
# Main Engagement Flow
# ============================================================================

engage_instagram_posts() {
    local scored_matches="$1"

    log "Phase 3: Engage Instagram Posts"
    log "==============================="

    if [[ "$scored_matches" == "[]" || -z "$scored_matches" ]]; then
        log "No scored matches to engage with."
        return 0
    fi

    # Only engage with posts scoring >= 6
    local engageable
    engageable=$(echo "$scored_matches" | jq '[.[] | select(.engagement_score >= 6)] | sort_by(-.engagement_score)')
    local total
    total=$(echo "$engageable" | jq 'length')

    if [[ "$total" == "0" ]]; then
        log "No posts scored high enough for engagement (need >= 6)."
        return 0
    fi

    # Cap at daily limit
    local limit="${MAX_COMMENTS_OVERRIDE:-$MAX_COMMENTS_PER_DAY}"
    local to_engage=$total
    if [[ $to_engage -gt $limit ]]; then
        to_engage=$limit
        log "Capping to $limit comments (of $total engageable)"
    fi

    log "Drafting comments for $to_engage posts..."

    local comments_posted=0
    local comments_skipped=0
    local i=0

    while [[ $i -lt $to_engage ]]; do
        local match
        match=$(echo "$engageable" | jq -c ".[$i]")
        local caption
        caption=$(echo "$match" | jq -r '.caption')
        local post_url
        post_url=$(echo "$match" | jq -r '.post_url // ""')
        local author
        author=$(echo "$match" | jq -r '.author // "unknown"')
        local campaign
        campaign=$(echo "$match" | jq -r '.campaign')
        local hook
        hook=$(echo "$match" | jq -r '.hook // ""')
        local engagement_score
        engagement_score=$(echo "$match" | jq -r '.engagement_score')
        local source_id
        source_id=$(echo "$match" | jq -r '.source_id')
        local media_type
        media_type=$(echo "$match" | jq -r '.media_type // "IMAGE"')

        local comment_num=$((i + 1))
        log "Drafting comment ${comment_num}/${to_engage} (score: ${engagement_score}/10, @${author})..."

        # Draft the comment
        local draft
        draft=$(draft_instagram_comment "$caption" "$campaign" "$author" "$hook" "$engagement_score" "$media_type")

        if [[ -z "$draft" ]]; then
            error "Failed to draft comment for post by @$author"
            i=$((i + 1))
            continue
        fi

        # Strip em/en dashes (post-processing safety)
        draft=$(echo "$draft" | sed 's/—/-/g; s/–/-/g')

        # Hard enforce 300 char limit
        draft="${draft:0:300}"

        log "Draft: $(echo "$draft" | head -c 100)..."

        # Send to Telegram for approval
        send_ig_comment_for_approval "$caption" "$draft" "$author" "$post_url" "$campaign" "$comment_num"

        # Wait for approval
        log "Waiting for approval on comment ${comment_num}..."
        local approval
        approval=$(check_ig_approval "$comment_num")

        case "$approval" in
            APPROVED)
                log "Comment ${comment_num} APPROVED"
                local method
                method=$(post_instagram_comment "$source_id" "$draft" "$post_url")
                log_ig_comment_to_supabase "$post_url" "$draft" "$campaign" "$author" "$source_id" "posted" "${method:-browser}"
                comments_posted=$((comments_posted + 1))
                ;;
            EDITED:*)
                local edited_text="${approval#EDITED:}"
                # Strip em/en dashes from edited text too
                edited_text=$(echo "$edited_text" | sed 's/—/-/g; s/–/-/g')
                edited_text="${edited_text:0:300}"
                log "Comment ${comment_num} EDITED by Ashley"
                local method
                method=$(post_instagram_comment "$source_id" "$edited_text" "$post_url")
                log_ig_comment_to_supabase "$post_url" "$edited_text" "$campaign" "$author" "$source_id" "edited" "${method:-browser}"
                comments_posted=$((comments_posted + 1))
                if [[ "$CORRECTIONS_AVAILABLE" == "true" ]]; then
                    store_correction "instagram" "edit" "$caption" "@$author" "$draft" "$edited_text" "$source_id" "audit_log" '{}' &
                fi
                ;;
            SKIPPED)
                log "Comment ${comment_num} SKIPPED"
                log_ig_comment_to_supabase "$post_url" "$draft" "$campaign" "$author" "$source_id" "skipped" "none"
                comments_skipped=$((comments_skipped + 1))
                if [[ "$CORRECTIONS_AVAILABLE" == "true" ]]; then
                    store_correction "instagram" "reject" "$caption" "@$author" "$draft" "" "$source_id" "audit_log" '{}' &
                fi
                ;;
            TIMEOUT)
                log "Comment ${comment_num} TIMED OUT - skipping"
                log_ig_comment_to_supabase "$post_url" "$draft" "$campaign" "$author" "$source_id" "timeout" "none"
                comments_skipped=$((comments_skipped + 1))
                ;;
        esac

        # Delay between comments
        if [[ $i -lt $((to_engage - 1)) && "$comments_posted" -gt 0 ]]; then
            local delay=$((COMMENT_DELAY + RANDOM % COMMENT_JITTER))
            log "Waiting ${delay}s before next comment..."
            sleep "$delay"
        fi

        i=$((i + 1))
    done

    log "Phase 3 complete. Posted: ${comments_posted}, Skipped: ${comments_skipped}"

    # Execute approved comments via browser automation if API failed for any
    local pending_file="${OUTPUT_DIR}/pending-ig-comments-${RUN_DATE}.json"
    if [[ -f "$pending_file" ]]; then
        local pending_count
        pending_count=$(jq 'length' "$pending_file" 2>/dev/null || echo "0")
        if [[ "$pending_count" -gt 0 ]]; then
            log "Handing off $pending_count comments to browser automation..."
            execute_browser_comments "$pending_file" "instagram"
        fi
    fi

    # Calculate stats for summary
    local total_scored
    total_scored=$(echo "$scored_matches" | jq 'length')
    local hot_count
    hot_count=$(echo "$scored_matches" | jq '[.[] | select(.engagement_score >= 8)] | length')
    local warm_count
    warm_count=$(echo "$scored_matches" | jq '[.[] | select(.engagement_score >= 6 and .engagement_score < 8)] | length')

    send_ig_summary "$total_scored" "$comments_posted" "$comments_skipped" "$hot_count" "$warm_count"
}
