#!/usr/bin/env bash
set -u

gemini_read_input() {
    GEMINI_HOOK_INPUT="$(cat -)"
    if ! printf '%s' "$GEMINI_HOOK_INPUT" | jq -e . >/dev/null 2>&1; then
        exit 0
    fi
    GEMINI_CAPTURED_AT="$(date -Iseconds)"
    GEMINI_HOOK_JSON="$(
        printf '%s' "$GEMINI_HOOK_INPUT" |
            jq -c --arg captured_at "$GEMINI_CAPTURED_AT" \
                '. + {captured_at: $captured_at, captured_by: "gemini_hooks"}' 2>/dev/null
    )"
}

gemini_json_value() {
    printf '%s' "$GEMINI_HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null
}

gemini_init_session() {
    # Use GEMINI_SESSION_ID from env if available, otherwise from input JSON
    if [ -z "${GEMINI_SESSION_ID:-}" ]; then
        GEMINI_SESSION_ID="$(gemini_json_value '.session_id')"
    fi
    if [ -z "$GEMINI_SESSION_ID" ] || [ "$GEMINI_SESSION_ID" = "null" ]; then
        GEMINI_SESSION_ID="unknown-session"
    fi

    GEMINI_SESSIONDATA_ROOT="${GEMINI_SESSIONDATA_ROOT:-/src/_sessiondata}"
    GEMINI_SESSION_DIR="$GEMINI_SESSIONDATA_ROOT/$GEMINI_SESSION_ID"
    mkdir -p "$GEMINI_SESSION_DIR" "$GEMINI_SESSIONDATA_ROOT/data"
}

gemini_write_jsonl() {
    local file="$1"
    printf '%s\n' "$GEMINI_HOOK_JSON" >> "$file"
}

gemini_write_json() {
    local file="$1"
    printf '%s\n' "$GEMINI_HOOK_JSON" > "$file"
}

gemini_record_event() {
    local event_name="$1"
    gemini_write_jsonl "$GEMINI_SESSION_DIR/_gemini_${event_name}.jsonl"
    gemini_write_json "$GEMINI_SESSION_DIR/last_gemini_${event_name}.json"
    gemini_write_jsonl "$GEMINI_SESSION_DIR/_gemini_hooks_all.jsonl"
}

gemini_record_alias() {
    local stream_name="$1"
    gemini_write_jsonl "$GEMINI_SESSION_DIR/_gemini_${stream_name}.jsonl"
    gemini_write_json "$GEMINI_SESSION_DIR/last_gemini_${stream_name}.json"
}

gemini_trace() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*" >> "$GEMINI_SESSION_DIR/trace.log"
}

gemini_capture_transcript() {
    local transcript_path
    transcript_path="$(gemini_json_value '.transcript_path')"
    if [ -n "$transcript_path" ] && [ -f "$transcript_path" ]; then
        cp -f "$transcript_path" "$GEMINI_SESSION_DIR/_gemini_transcript_latest.jsonl" 2>/dev/null || true
    fi
}
