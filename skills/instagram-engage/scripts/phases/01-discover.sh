#!/bin/bash

# Phase 1: Discover Instagram Posts
# Fetches posts from target accounts via Rube MCP (Instagram API).
# Normalizes results, deduplicates, and filters already-engaged posts.
# Supports auto mode (config-driven) and manual mode (MANUAL_POSTS env var).

# ============================================================================
# Discover Instagram Posts for a Campaign
# ============================================================================

discover_instagram_posts() {
    local campaign="$1"

    log "Phase 1: Discover Instagram Posts"
    log "================================="
    log "Campaign: $campaign"

    # Read campaign config from targets.json
    local config
    config=$(jq -r --arg c "$campaign" '.[$c]' "$CONFIG_DIR/targets.json")

    if [[ -z "$config" || "$config" == "null" ]]; then
        error "No config found for campaign: $campaign"
        echo "[]"
        return 0
    fi

    local target_accounts
    target_accounts=$(echo "$config" | jq -r '.target_accounts')
    local posts_per_account
    posts_per_account=$(echo "$config" | jq -r '.posts_per_account // 10')
    local max_post_age_days
    max_post_age_days=$(echo "$config" | jq -r '.max_post_age_days // 14')

    log "Target accounts: $(echo "$target_accounts" | jq -r 'join(", ")')"
    log "Posts per account: $posts_per_account | Max age: ${max_post_age_days} days"

    if [[ "$DRY_RUN" == "true" ]]; then
        log "[DRY RUN] Would fetch Instagram posts for campaign: $campaign"
        echo "[]"
        return 0
    fi

    local all_results="[]"
    local account_count
    account_count=$(echo "$target_accounts" | jq 'length')
    local a=0

    while [[ $a -lt $account_count ]]; do
        local account
        account=$(echo "$target_accounts" | jq -r ".[$a]")
        [[ -z "$account" || "$account" == "null" ]] && { a=$((a + 1)); continue; }

        log "Fetching posts from @${account}..."

        local args
        args=$(jq -n \
            --arg ig_user_id "$account" \
            --argjson limit "$posts_per_account" \
            '{
                ig_user_id: $ig_user_id,
                limit: $limit
            }')

        local response
        response=$(rube_execute "INSTAGRAM_GET_IG_USER_MEDIA" "$args" "Get media for @${account}")

        if [[ $? -ne 0 || -z "$response" ]]; then
            error "Instagram API failed for @${account}"
            a=$((a + 1))
            continue
        fi

        # Extract posts from response (Rube returns data array or nested structure)
        local posts
        posts=$(echo "$response" | jq '.data // .media // .posts // []' 2>/dev/null)

        if [[ -z "$posts" || "$posts" == "null" || "$posts" == "[]" ]]; then
            log "No posts found for @${account}"
            a=$((a + 1))
            continue
        fi

        # Filter by age
        local cutoff_ts
        cutoff_ts=$(date -v-${max_post_age_days}d +%s 2>/dev/null || date -d "${max_post_age_days} days ago" +%s 2>/dev/null)

        local filtered_posts
        filtered_posts=$(echo "$posts" | jq --argjson cutoff "$cutoff_ts" '[
            .[] | select(
                ((.created_time // .timestamp // "") |
                    if . == "" then true
                    elif test("^[0-9]+$") then (. | tonumber) >= $cutoff
                    else (. | sub("\\+00:00$"; "Z") | fromdateiso8601) >= $cutoff
                    end
                )
            )
        ]')

        local before_count
        before_count=$(echo "$posts" | jq 'length')
        local after_count
        after_count=$(echo "$filtered_posts" | jq 'length')

        if [[ "$before_count" != "$after_count" ]]; then
            log "Age filter for @${account}: $before_count -> $after_count posts"
        fi

        # Normalize to standard shape
        local normalized
        normalized=$(echo "$filtered_posts" | jq --arg campaign "$campaign" --arg account "$account" '[
            .[] | {
                source: "instagram",
                source_id: (.id // ""),
                author: $account,
                caption: (.caption // ""),
                post_url: (
                    if (.shortcode // .code // "") | length > 0 then
                        ("https://www.instagram.com/p/" + (.shortcode // .code))
                    elif (.permalink // "") | length > 0 then
                        .permalink
                    else
                        ""
                    end
                ),
                media_type: (.media_type // "IMAGE"),
                like_count: (.like_count // .likes // 0),
                comment_count: (.comment_count // .comments // 0),
                campaign: $campaign,
                engagement_score: 0,
                hook: ""
            }
        ] // []')

        if [[ -n "$normalized" && "$normalized" != "[]" ]]; then
            all_results=$(echo "$all_results" "$normalized" | jq -s '.[0] + .[1]')
        fi

        log "Found $after_count posts from @${account}"

        a=$((a + 1))

        # Small delay between API calls
        [[ $a -lt $account_count ]] && sleep 2
    done

    # Dedup by source_id
    local deduped
    deduped=$(echo "$all_results" | jq '[group_by(.source_id) | .[] | .[0]]')

    local before_count
    before_count=$(echo "$all_results" | jq 'length')
    local after_count
    after_count=$(echo "$deduped" | jq 'length')

    if [[ "$before_count" != "$after_count" ]]; then
        log "Deduped: $before_count -> $after_count posts"
    fi

    # Filter out already-engaged posts (check audit_log)
    # Fail-open: if Supabase is unreachable, keep the post
    local filtered="[]"
    local skipped_count=0
    local post_count
    post_count=$(echo "$deduped" | jq 'length')
    local i=0

    while [[ $i -lt $post_count ]]; do
        local post
        post=$(echo "$deduped" | jq -c ".[$i]")
        local source_id
        source_id=$(echo "$post" | jq -r '.source_id')

        # Check if we already commented on this post
        local existing
        existing=$(supabase_query "audit_log?action=eq.instagram_comment&details->>source_id=eq.${source_id}&select=id&limit=1" "GET")

        # Fail-open: only skip if we got a valid JSON array with actual results
        if echo "$existing" | jq -e 'type == "array" and length > 0' > /dev/null 2>&1; then
            log "Skipping already-engaged post: $source_id"
            skipped_count=$((skipped_count + 1))
        else
            filtered=$(echo "$filtered" | jq --argjson post "$post" '. + [$post]')
        fi

        i=$((i + 1))
    done

    if [[ $skipped_count -gt 0 ]]; then
        log "Skipped $skipped_count previously-engaged posts"
    fi

    local filtered_count
    filtered_count=$(echo "$filtered" | jq 'length')
    log "After dedup+filter: $filtered_count posts for $campaign"

    # Save discovered posts
    local output_file="${OUTPUT_DIR}/ig-posts-${campaign}-${RUN_DATE}.json"
    echo "$filtered" | jq '.' > "$output_file"
    log "Saved discovered posts to: $output_file"

    echo "$filtered"
}

# ============================================================================
# Discover Manual Posts (MANUAL_POSTS env var)
# ============================================================================

discover_manual_posts() {
    local posts_csv="$1"

    log "Discovering manual posts: $posts_csv"

    local results="[]"

    IFS=',' read -ra entries <<< "$posts_csv"

    for entry in "${entries[@]}"; do
        entry=$(echo "$entry" | xargs) # trim whitespace
        [[ -z "$entry" ]] && continue

        if [[ "$entry" == @* ]]; then
            # Username: fetch recent posts
            local username="${entry#@}"
            log "Manual: fetching posts from @${username}"

            local args
            args=$(jq -n \
                --arg ig_user_id "$username" \
                --argjson limit 5 \
                '{
                    ig_user_id: $ig_user_id,
                    limit: $limit
                }')

            local response
            response=$(rube_execute "INSTAGRAM_GET_IG_USER_MEDIA" "$args" "Get media for @${username}")

            if [[ $? -ne 0 || -z "$response" ]]; then
                error "Failed to fetch posts for @${username}"
                continue
            fi

            local posts
            posts=$(echo "$response" | jq '.data // .media // .posts // []' 2>/dev/null)

            local normalized
            normalized=$(echo "$posts" | jq --arg account "$username" '[
                .[] | {
                    source: "instagram",
                    source_id: (.id // ""),
                    author: $account,
                    caption: (.caption // ""),
                    post_url: (
                        if (.shortcode // .code // "") | length > 0 then
                            ("https://www.instagram.com/p/" + (.shortcode // .code))
                        elif (.permalink // "") | length > 0 then
                            .permalink
                        else
                            ""
                        end
                    ),
                    media_type: (.media_type // "IMAGE"),
                    like_count: (.like_count // .likes // 0),
                    comment_count: (.comment_count // .comments // 0),
                    campaign: "manual",
                    engagement_score: 0,
                    hook: ""
                }
            ] // []')

            if [[ -n "$normalized" && "$normalized" != "[]" ]]; then
                results=$(echo "$results" "$normalized" | jq -s '.[0] + .[1]')
            fi

        elif [[ "$entry" == *instagram.com* ]]; then
            # URL: extract shortcode
            local shortcode
            shortcode=$(echo "$entry" | grep -oE '/p/([A-Za-z0-9_-]+)' | sed 's|/p/||')

            if [[ -z "$shortcode" ]]; then
                # Try /reel/ pattern
                shortcode=$(echo "$entry" | grep -oE '/reel/([A-Za-z0-9_-]+)' | sed 's|/reel/||')
            fi

            if [[ -z "$shortcode" ]]; then
                error "Could not extract shortcode from URL: $entry"
                continue
            fi

            log "Manual: adding post with shortcode $shortcode"

            local post_obj
            post_obj=$(jq -n \
                --arg shortcode "$shortcode" \
                --arg url "$entry" \
                '{
                    source: "instagram",
                    source_id: $shortcode,
                    author: "unknown",
                    caption: "",
                    post_url: $url,
                    media_type: "UNKNOWN",
                    like_count: 0,
                    comment_count: 0,
                    campaign: "manual",
                    engagement_score: 0,
                    hook: ""
                }')

            results=$(echo "$results" | jq --argjson post "$post_obj" '. + [$post]')
        else
            error "Unrecognized manual entry (expected @username or URL): $entry"
        fi
    done

    local count
    count=$(echo "$results" | jq 'length')
    log "Manual discovery: $count posts"

    echo "$results"
}
