#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

gemini_read_input
gemini_init_session
gemini_record_event "BeforeAgent"
gemini_record_alias "user_inputs"
gemini_capture_transcript

exit 0
