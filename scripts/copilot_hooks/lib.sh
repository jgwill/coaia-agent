#!/usr/bin/env bash
set -u

copilot_read_input() {
    COPILOT_HOOK_INPUT="$(cat)"
    if [ -z "$COPILOT_HOOK_INPUT" ]; then
        exit 0
    fi
    if ! jq -e . <<< "$COPILOT_HOOK_INPUT" >/dev/null 2>&1; then
        exit 0
    fi
    COPILOT_CAPTURED_AT="$(date -Iseconds)"
    COPILOT_HOOK_JSON="$(
        jq -c --arg captured_at "$COPILOT_CAPTURED_AT" \
            '. + {captured_at: $captured_at, captured_by: "copilot_hooks"}' <<< "$COPILOT_HOOK_INPUT" 2>/dev/null
    )"
}

copilot_json_value() {
    printf '%s' "$COPILOT_HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null
}

copilot_init_session() {
    # Use COPILOT_SESSION_ID from env if available, otherwise from input JSON
    if [ -z "${COPILOT_SESSION_ID:-}" ]; then
        COPILOT_SESSION_ID="$(copilot_json_value '.sessionId')"
    fi
    if [ -z "$COPILOT_SESSION_ID" ] || [ "$COPILOT_SESSION_ID" = "null" ]; then
        COPILOT_SESSION_ID="$(copilot_json_value '.session_id')"
    fi
    if [ -z "$COPILOT_SESSION_ID" ] || [ "$COPILOT_SESSION_ID" = "null" ]; then
        COPILOT_SESSION_ID="unknown-session"
    fi

    COPILOT_SESSIONDATA_ROOT="${COPILOT_SESSIONDATA_ROOT:-/workspace/coaia-agent/.hch/sessions}"
    COPILOT_SESSION_DIR="$COPILOT_SESSIONDATA_ROOT/$COPILOT_SESSION_ID"
    mkdir -p "$COPILOT_SESSION_DIR" "$COPILOT_SESSIONDATA_ROOT/data"
}

copilot_write_jsonl() {
    local file="$1"
    printf '%s\n' "$COPILOT_HOOK_JSON" >> "$file"
}

copilot_write_json() {
    local file="$1"
    printf '%s\n' "$COPILOT_HOOK_JSON" > "$file"
}

copilot_record_event() {
    local event_name="$1"
    copilot_write_jsonl "$COPILOT_SESSION_DIR/_copilot_${event_name}.jsonl"
    copilot_write_json "$COPILOT_SESSION_DIR/last_copilot_${event_name}.json"
    copilot_write_jsonl "$COPILOT_SESSION_DIR/_copilot_hooks_all.jsonl"
}

copilot_record_alias() {
    local stream_name="$1"
    copilot_write_jsonl "$COPILOT_SESSION_DIR/_copilot_${stream_name}.jsonl"
    copilot_write_json "$COPILOT_SESSION_DIR/last_copilot_${stream_name}.json"
}

copilot_trace() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*" >> "$COPILOT_SESSION_DIR/trace.log"
}
