#!/usr/bin/env bash
set -u

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=codex_hooks/lib.sh
. "$SCRIPT_DIR/lib.sh"

codex_read_input
codex_init_session
codex_capture_last_assistant
codex_capture_transcript
codex_record_event "Stop"

exit 0
