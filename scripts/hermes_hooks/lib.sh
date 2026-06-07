#!/usr/bin/env bash
set -u

hermes_read_input() {
    HERMES_HOOK_INPUT="$(cat -)"
    if ! printf '%s' "$HERMES_HOOK_INPUT" | jq -e . >/dev/null 2>&1; then
        # If not JSON, just wrap it in a JSON object
        HERMES_HOOK_JSON="$(jq -n --arg raw "$HERMES_HOOK_INPUT" '{raw: $raw}')"
    else
        HERMES_HOOK_JSON="$HERMES_HOOK_INPUT"
    fi
    HERMES_CAPTURED_AT="$(date -Iseconds)"
    HERMES_HOOK_JSON="$(
        printf '%s' "$HERMES_HOOK_JSON" |
            jq -c --arg captured_at "$HERMES_CAPTURED_AT" \
                '. + {captured_at: $captured_at, captured_by: "hermes_hooks"}' 2>/dev/null
    )"
}

hermes_json_value() {
    printf '%s' "$HERMES_HOOK_JSON" | jq -r "$1 // empty" 2>/dev/null
}

hermes_init_session() {
    # Hermes usually provides session_id or similar in context
    if [ -z "${HERMES_SESSION_ID:-}" ]; then
        HERMES_SESSION_ID="$(hermes_json_value '.session_id')"
    fi
    if [ -z "$HERMES_SESSION_ID" ] || [ "$HERMES_SESSION_ID" = "null" ]; then
        # Try to find it in nested context or other common fields
        HERMES_SESSION_ID="$(hermes_json_value '.context.session_id')"
    fi
    if [ -z "$HERMES_SESSION_ID" ] || [ "$HERMES_SESSION_ID" = "null" ]; then
        HERMES_SESSION_ID="unknown-hermes-session"
    fi

    HERMES_SESSIONDATA_ROOT="${HERMES_SESSIONDATA_ROOT:-/src/_sessiondata}"
    HERMES_SESSION_DIR="$HERMES_SESSIONDATA_ROOT/$HERMES_SESSION_ID"
    mkdir -p "$HERMES_SESSION_DIR" "$HERMES_SESSIONDATA_ROOT/data"
}

hermes_write_jsonl() {
    local file="$1"
    printf '%s\n' "$HERMES_HOOK_JSON" >> "$file"
}

hermes_write_json() {
    local file="$1"
    printf '%s\n' "$HERMES_HOOK_JSON" > "$file"
}

hermes_record_event() {
    local event_name="$1"
    hermes_write_jsonl "$HERMES_SESSION_DIR/_hermes_${event_name}.jsonl"
    hermes_write_json "$HERMES_SESSION_DIR/last_hermes_${event_name}.json"
    hermes_write_jsonl "$HERMES_SESSION_DIR/_hermes_hooks_all.jsonl"
    # Also record to global ledger
    hermes_write_jsonl "$HERMES_SESSIONDATA_ROOT/data/hermes_hooks_all.jsonl"
}

hermes_trace() {
    printf '[%s] %s\n' "$(date -Iseconds)" "$*" >> "$HERMES_SESSION_DIR/trace.log"
}
