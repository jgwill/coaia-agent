#!/usr/bin/env bash
set -u
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
. "$SCRIPT_DIR/lib.sh"

openclaw_read_input
openclaw_init_session
openclaw_record_event "SessionStart"
openclaw_write_jsonl "$OPENCLAW_SESSIONDATA_ROOT/data/openclaw_session_starts_all.jsonl"

exit 0
