#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex_hooks/lib.sh
. "$SCRIPT_DIR/lib.sh"

codex_read_input
codex_init_session
codex_record_event "SessionStart"
codex_record_alias "session_starts"
codex_write_jsonl "$CODEX_SESSIONDATA_ROOT/data/codex_session_starts_all.jsonl"
codex_write_jsonl "$CODEX_SESSIONDATA_ROOT/data/session_starts_all.jsonl"
codex_capture_transcript

exit 0
