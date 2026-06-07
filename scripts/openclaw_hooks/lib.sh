#!/usr/bin/env bash
set -u

openclaw_read_input() {
    OPENCLAW_HOOK_INPUT="$(cat -)"
    if ! printf '%s' "$OPENCLAW_HOOK_INPUT" | jq -e . >/dev/null 2>&1; then
        exit 0
    fi
    OPENCLAW_CAPTURED_AT="$(date -Iseconds)"
    OPENCLAW_HOOK_JSON="$(
        printf '%s' "$OPENCLAW_HOOK_INPUT" |
            jq -c --arg captured_at "$OPENCLAW_CAPTURED_AT" \
                '. + {captured_at: $captured_at, captured_by: "openclaw_hooks"}' 2>/dev/null
    )"
}

openclaw_json_value() {
    printf '%s' "$OPENCLAW_HOOK_INPUT" | jq -r "$1 // empty" 2>/dev/null
}

openclaw_init_session() {
    # OpenClaw specific session identification
    if [ -z "${OPENCLAW_SESSION_ID:-}" ]; then
        OPENCLAW_SESSION_ID="$(openclaw_json_value '.session_id')"
    fi
    if [ -z "$OPENCLAW_SESSION_ID" ] || [ "$OPENCLAW_SESSION_ID" = "null" ]; then
        OPENCLAW_SESSION_ID="unknown-openclaw-session"
    fi

    OPENCLAW_SESSIONDATA_ROOT="${OPENCLAW_SESSIONDATA_ROOT:-/workspace/coaia-agent/.hch/sessions}"
    OPENCLAW_SESSION_DIR="$OPENCLAW_SESSIONDATA_ROOT/$OPENCLAW_SESSION_ID"
    mkdir -p "$OPENCLAW_SESSION_DIR" "$OPENCLAW_SESSIONDATA_ROOT/data"
}

openclaw_write_jsonl() {
    local file="$1"
    printf '%s\n' "$OPENCLAW_HOOK_JSON" >> "$file"
}

openclaw_write_json() {
    local file="$1"
    printf '%s\n' "$OPENCLAW_HOOK_JSON" > "$file"
}

openclaw_record_event() {
    local event_name="$1"
    openclaw_write_jsonl "$OPENCLAW_SESSION_DIR/_openclaw_${event_name}.jsonl"
    openclaw_write_json "$OPENCLAW_SESSION_DIR/last_openclaw_${event_name}.json"
    openclaw_write_jsonl "$OPENCLAW_SESSION_DIR/_openclaw_hooks_all.jsonl"
}

openclaw_trace() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*" >> "$OPENCLAW_SESSION_DIR/trace.log"
}
