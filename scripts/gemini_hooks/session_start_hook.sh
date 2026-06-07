#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

gemini_read_input
gemini_init_session
gemini_record_event "SessionStart"
gemini_record_alias "session_starts"
gemini_write_jsonl "$GEMINI_SESSIONDATA_ROOT/data/gemini_session_starts_all.jsonl"
gemini_write_jsonl "$GEMINI_SESSIONDATA_ROOT/data/session_starts_all.jsonl"
gemini_capture_transcript

exit 0
