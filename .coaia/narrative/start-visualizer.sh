#!/usr/bin/env bash
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
export COAIAN_MF="$HERE/coaia-agent-memory.jsonl"
export COAIAV_AUDIO_DIR="$HERE/audio"
export COAIAV_PORT="${COAIAV_PORT:-4422}"

# coaia-visualizer@1.6.0 currently attempts xdg-open even when --no-open is documented.
# Put a no-op opener first when running headless.
NOOP_BIN="${TMPDIR:-/tmp}/coaia-noop-bin"
mkdir -p "$NOOP_BIN"
printf '#!/usr/bin/env bash\nexit 0\n' > "$NOOP_BIN/xdg-open"
chmod +x "$NOOP_BIN/xdg-open"
export PATH="$NOOP_BIN:$PATH"

exec coaia-visualizer --live -M "$COAIAN_MF" -p "$COAIAV_PORT" "$@"
