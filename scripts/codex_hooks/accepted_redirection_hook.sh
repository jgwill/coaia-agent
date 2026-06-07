#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex_hooks/lib.sh
. "$SCRIPT_DIR/lib.sh"

codex_read_input
codex_init_session

prompt="$(codex_json_value '.prompt')"
if [ -z "$prompt" ]; then
    exit 0
fi

if ! printf '%s' "$prompt" | grep -Eiq '^(yes|yep|ok|okay|go ahead|continue|approved|do it|please proceed)\b'; then
    exit 0
fi

latest_tool="$(codex_latest_tool_json "$CODEX_SESSION_DIR/_codex_PostToolUse.jsonl")"
tool_use_id="$(printf '%s' "$latest_tool" | jq -r '.tool_use_id // empty' 2>/dev/null)"
tool_name="$(printf '%s' "$latest_tool" | jq -r '.tool_name // "unknown"' 2>/dev/null)"
tool_input="$(printf '%s' "$latest_tool" | jq -c '.tool_input // {}' 2>/dev/null || printf '{}')"
timestamp="$(date -Iseconds)"

redirection="$(
    jq -n \
        --arg session_id "$CODEX_SESSION_ID" \
        --arg hook_event_name "AcceptedRedirection" \
        --arg accepted_tool_use_id "$tool_use_id" \
        --arg accepted_tool_name "$tool_name" \
        --argjson accepted_tool_input "$tool_input" \
        --arg followup_instruction "$prompt" \
        --arg timestamp "$timestamp" \
        '{
            session_id: $session_id,
            hook_event_name: $hook_event_name,
            accepted_tool_use_id: $accepted_tool_use_id,
            accepted_tool_name: $accepted_tool_name,
            accepted_tool_input: $accepted_tool_input,
            followup_instruction: $followup_instruction,
            timestamp: $timestamp,
            source: "codex_user_prompt_submit_best_effort"
        }'
)"

printf '%s\n' "$redirection" >> "$CODEX_SESSION_DIR/_codex_AcceptedRedirection.jsonl"
printf '%s\n' "$redirection" > "$CODEX_SESSION_DIR/last_codex_AcceptedRedirection.json"
printf '%s\n' "$redirection" >> "$CODEX_SESSION_DIR/_codex_user_inputs.jsonl"
codex_trace "Captured best-effort Codex accepted redirection for ${tool_name:-unknown} (${tool_use_id:-no-tool-id})"

exit 0
