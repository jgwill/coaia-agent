#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

copilot_read_input
copilot_init_session
copilot_record_event "sessionStart"
copilot_record_alias "session_starts"
copilot_write_jsonl "$COPILOT_SESSIONDATA_ROOT/data/copilot_session_starts_all.jsonl"
copilot_write_jsonl "$COPILOT_SESSIONDATA_ROOT/data/session_starts_all.jsonl"

exit 0
