#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

gemini_read_input
gemini_init_session
gemini_record_event "AfterAgent"
gemini_capture_transcript

# Capture assistant response if available in payload
# Gemini CLI uses prompt_response for AfterAgent
last_msg=$(gemini_json_value '.prompt_response // .last_assistant_message')
if [ -n "$last_msg" ]; then
    gemini_record_alias "AssistantResponse"
fi

exit 0
