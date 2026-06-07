#!/usr/bin/env bash
set -u

codex_read_input() {
    CODEX_HOOK_INPUT="$(cat -)"
    if ! printf '%s' "$CODEX_HOOK_INPUT" | jq -e . >/dev/null 2>&1; then
        exit 0
    fi
    CODEX_CAPTURED_AT="$(date -Iseconds)"
    CODEX_HOOK_JSON="$(
        printf '%s' "$CODEX_HOOK_INPUT" |
            jq -c --arg captured_at "$CODEX_CAPTURED_AT" \
                '. + {captured_at: $captured_at, captured_by: "codex_hooks"}' 2>/dev/null
    )"
}

codex_json_value() {
    printf '%s' "$CODEX_HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null
}

codex_json_compact() {
    local query="$1"
    printf '%s' "$CODEX_HOOK_INPUT" | jq -c "$query // {}" 2>/dev/null || printf '{}'
}

codex_init_session() {
    CODEX_SESSION_ID="$(codex_json_value '.session_id')"
    if [ -z "$CODEX_SESSION_ID" ] || [ "$CODEX_SESSION_ID" = "null" ]; then
        CODEX_SESSION_ID="unknown-session"
    fi

    CODEX_SESSIONDATA_ROOT="${CODEX_SESSIONDATA_ROOT:-/workspace/coaia-agent/.asterion/sessions}"
    CODEX_SESSION_DIR="$CODEX_SESSIONDATA_ROOT/$CODEX_SESSION_ID"
    mkdir -p "$CODEX_SESSION_DIR" "$CODEX_SESSIONDATA_ROOT/data"
}

codex_write_jsonl() {
    local file="$1"
    printf '%s\n' "$CODEX_HOOK_JSON" >> "$file"
}

codex_write_json() {
    local file="$1"
    printf '%s\n' "$CODEX_HOOK_JSON" > "$file"
}

codex_record_event() {
    local event_name="$1"
    codex_write_jsonl "$CODEX_SESSION_DIR/_codex_${event_name}.jsonl"
    codex_write_json "$CODEX_SESSION_DIR/last_codex_${event_name}.json"
    codex_write_jsonl "$CODEX_SESSION_DIR/_codex_hooks_all.jsonl"
}

codex_record_alias() {
    local stream_name="$1"
    codex_write_jsonl "$CODEX_SESSION_DIR/_codex_${stream_name}.jsonl"
    codex_write_json "$CODEX_SESSION_DIR/last_codex_${stream_name}.json"
}

codex_trace() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*" >> "$CODEX_SESSION_DIR/trace.log"
}

codex_safe_name() {
    tr -c 'A-Za-z0-9._-' '_' | sed 's/^_*//; s/_*$//'
}

codex_capture_transcript() {
    local transcript_path
    transcript_path="$(codex_json_value '.transcript_path')"
    if [ -z "$transcript_path" ] || [ ! -f "$transcript_path" ]; then
        return 0
    fi

    cp -f "$transcript_path" "$CODEX_SESSION_DIR/_codex_transcript_latest.jsonl" 2>/dev/null || true

    if jq -c '
        select(
            (.type == "event_msg" and .payload.type == "agent_message") or
            (.type == "response_item" and .payload.type == "message" and (.payload.role // "") == "assistant")
        )
    ' "$transcript_path" > "$CODEX_SESSION_DIR/_codex_responses_progressive.jsonl.tmp" 2>/dev/null; then
        mv "$CODEX_SESSION_DIR/_codex_responses_progressive.jsonl.tmp" "$CODEX_SESSION_DIR/_codex_responses_progressive.jsonl"
        cp -f "$CODEX_SESSION_DIR/_codex_responses_progressive.jsonl" "$CODEX_SESSION_DIR/_responses_progressive.jsonl" 2>/dev/null || true
    else
        rm -f "$CODEX_SESSION_DIR/_codex_responses_progressive.jsonl.tmp"
    fi
}

codex_capture_last_assistant() {
    local last_msg
    last_msg="$(codex_json_value '.last_assistant_message')"
    if [ -n "$last_msg" ]; then
        codex_record_alias "AssistantResponse"
    fi
}

codex_capture_tool_artifacts() {
    local tool_name tool_use_id safe_id proposed_dir timestamp
    tool_name="$(codex_json_value '.tool_name')"
    tool_use_id="$(codex_json_value '.tool_use_id')"
    timestamp="$(date +"%y%m%d%H%M%S")"
    safe_id="$(printf '%s' "${tool_use_id:-$timestamp}" | codex_safe_name)"

    case "$tool_name" in
        Bash)
            jq -c --arg captured_at "$CODEX_CAPTURED_AT" '{
                session_id,
                hook_event_name,
                tool_name,
                tool_use_id,
                command: (.tool_input.command // empty),
                captured_at: $captured_at
            }' <<< "$CODEX_HOOK_INPUT" >> "$CODEX_SESSION_DIR/_codex_bash_commands.jsonl" 2>/dev/null || true
            ;;
        apply_patch|Edit|Write)
            proposed_dir="$CODEX_SESSION_DIR/proposed"
            mkdir -p "$proposed_dir"
            jq -r '
                (.tool_input.command? // .tool_input.patch? // .tool_input.content? // .tool_input // empty) |
                if type == "string" then . else tojson end
            ' <<< "$CODEX_HOOK_INPUT" > "$proposed_dir/${safe_id:-$timestamp}.patch" 2>/dev/null || true
            codex_trace "Saved proposed Codex edit artifact for ${tool_name:-unknown} as proposed/${safe_id:-$timestamp}.patch"
            ;;
        ExitPlanMode)
            local plan_content plans_dir plan_file
            plan_content="$(codex_json_value '.tool_input.plan')"
            if [ -n "$plan_content" ]; then
                plans_dir="$CODEX_SESSION_DIR/plans"
                mkdir -p "$plans_dir"
                plan_file="$plans_dir/session_${CODEX_SESSION_ID}_${timestamp}.md"
                {
                    printf '%s\n' '---'
                    printf 'session_id: %s\n' "$CODEX_SESSION_ID"
                    printf 'timestamp: %s\n' "$(date -Iseconds)"
                    printf 'source: codex\n'
                    printf '%s\n\n' '---'
                    printf '%s\n' "$plan_content"
                } > "$plan_file"
                codex_trace "Saved Codex plan content as $plan_file"
            fi
            ;;
    esac
}

codex_latest_tool_json() {
    local stream_file="$1"
    if [ -f "$stream_file" ]; then
        tail -n 1 "$stream_file" 2>/dev/null
    fi
}
