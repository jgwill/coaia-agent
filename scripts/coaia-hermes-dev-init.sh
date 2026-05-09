#!/usr/bin/env bash
# Initialize the local COAIA Hermes dev-container workflow.
#
# This script intentionally writes compose/runtime files outside the repo under
# ~/.coaia-agent so the upstream docker-compose.yml can stay untouched.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
DEFAULT_REPO="$(cd "$SCRIPT_DIR/.." && pwd -P)"

COAIA_REPO="${COAIA_REPO:-$DEFAULT_REPO}"
COAIA_HOME="${COAIA_HOME:-$HOME/.coaia-agent}"
HERMES_UID="${HERMES_UID:-$(id -u)}"
HERMES_GID="${HERMES_GID:-$(id -g)}"
COAIA_VISUALIZER_HOST_PORT="${COAIA_VISUALIZER_HOST_PORT:-4421}"
COAIA_VISUALIZER_PORT="${COAIA_VISUALIZER_PORT:-4422}"
COAIA_VISUALIZER_MEMORY="${COAIA_VISUALIZER_MEMORY:-/opt/data/memory.jsonl}"
COAIA_VISUALIZER_AUDIO_DIR="${COAIA_VISUALIZER_AUDIO_DIR:-/opt/data/audio}"

START=0
LOGIN=0
TUI=0

usage() {
  cat <<'EOF'
Usage: scripts/coaia-hermes-dev-init.sh [options]

Creates a local Docker Compose dev setup for this checkout.

Options:
  --start      Build/start the background container after writing files
  --login      Run OpenAI Codex auth after starting the container
  --tui        Launch the TUI after starting the container
  -h, --help   Show this help

Environment overrides:
  COAIA_HOME   Host state/control dir (default: ~/.coaia-agent)
  COAIA_REPO   Repo to mount (default: parent of this script)
  HERMES_UID   Host UID to map to container hermes user
  HERMES_GID   Host GID to map to container hermes group
  COAIA_TUI_MOUSE  TUI mouse tracking default: off|on (default: off)
  COAIA_VISUALIZER_HOST_PORT  Host port for visualizer default route (default: 4421)
  COAIA_VISUALIZER_PORT       Live visualizer port inside/outside container (default: 4422)
  COAIA_VISUALIZER_MEMORY     Container JSONL memory path (default: /opt/data/memory.jsonl)
  COAIA_VISUALIZER_AUDIO_DIR  Container narrative audio dir (default: /opt/data/audio)
EOF
}

while [ $# -gt 0 ]; do
  case "$1" in
    --start)
      START=1
      ;;
    --login)
      START=1
      LOGIN=1
      ;;
    --tui)
      START=1
      TUI=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      usage >&2
      exit 2
      ;;
  esac
  shift
done

mkdir -p "$COAIA_HOME/bin" "$HOME/.local/bin" "$COAIA_HOME/audio"
touch "$COAIA_HOME/memory.jsonl"

write_optional_mounts() {
  for mount_spec in \
    "/opt/binscripts:/opt/binscripts" \
    "/a/src:/src" \
    "/a/src:/a/src" \
    "/workspace:/workspace" \
    "/srv/miadi:/srv/miadi" \
    "/var/lib/miadi:/var/lib/miadi" \
    "/var/log/miadi:/var/log/miadi"; do
    host_path="${mount_spec%%:*}"
    container_path="${mount_spec#*:}"
    if [ -e "$host_path" ]; then
      printf '      - %s:%s\n' "$host_path" "$container_path"
    fi
  done
}

cat > "$COAIA_HOME/compose.yml" <<COMPOSE_EOF
name: coaia-agent

services:
  hermes-dev:
    build:
      context: ${COAIA_REPO}
      dockerfile: Dockerfile
    image: coaia-hermes-agent:dev
    container_name: coaia-hermes-dev
    restart: unless-stopped
    working_dir: /workspace/coaia-agent
    volumes:
      - ${COAIA_REPO}:/workspace/coaia-agent
      - ${COAIA_HOME}:/opt/data
$(write_optional_mounts)
    ports:
      - "${COAIA_VISUALIZER_HOST_PORT}:4321"
      - "${COAIA_VISUALIZER_PORT}:${COAIA_VISUALIZER_PORT}"
    environment:
      HERMES_UID: ${HERMES_UID}
      HERMES_GID: ${HERMES_GID}
      HERMES_HOME: /opt/data
      HOME: /opt/data/home
      HERMES_CWD: /workspace/coaia-agent
      TERMINAL_CWD: /workspace/coaia-agent
      HERMES_PYTHON: /opt/hermes/.venv/bin/python
      HERMES_PYTHON_SRC_ROOT: /workspace/coaia-agent
      HERMES_TUI_DIR: /opt/hermes/ui-tui
      PYTHONPATH: /workspace/coaia-agent
      VIRTUAL_ENV: /opt/hermes/.venv
      COAIAN_MF: ${COAIA_VISUALIZER_MEMORY}
      COAIAV_PORT: ${COAIA_VISUALIZER_PORT}
      COAIAV_AUDIO_DIR: ${COAIA_VISUALIZER_AUDIO_DIR}
      PATH: /opt/hermes/.venv/bin:/opt/data/.local/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
    command: ["sleep", "infinity"]
COMPOSE_EOF

if [ ! -f "$COAIA_HOME/.env" ]; then
  cat > "$COAIA_HOME/.env" <<ENV_EOF
COMPOSE_PROJECT_NAME=coaia-agent
COAIA_HOME=$COAIA_HOME
COAIA_REPO=$COAIA_REPO
HERMES_UID=$HERMES_UID
HERMES_GID=$HERMES_GID

# This file is also mounted into the container as /opt/data/.env.
# You can add Hermes/API secrets here later if you use API-key providers.
#
# COAIA_TUI_MOUSE defaults to off so terminal selection, right-click copy,
# and middle-click paste keep working in coaia-hermes tui.
COAIA_TUI_MOUSE=off
COAIA_VISUALIZER_HOST_PORT=$COAIA_VISUALIZER_HOST_PORT
COAIA_VISUALIZER_PORT=$COAIA_VISUALIZER_PORT
COAIA_VISUALIZER_MEMORY=$COAIA_VISUALIZER_MEMORY
COAIA_VISUALIZER_AUDIO_DIR=$COAIA_VISUALIZER_AUDIO_DIR
ENV_EOF
else
  # Keep existing secrets/config, but make sure required keys exist.
  grep -q '^COMPOSE_PROJECT_NAME=' "$COAIA_HOME/.env" || printf '\nCOMPOSE_PROJECT_NAME=coaia-agent\n' >> "$COAIA_HOME/.env"
  grep -q '^COAIA_HOME=' "$COAIA_HOME/.env" || printf 'COAIA_HOME=%s\n' "$COAIA_HOME" >> "$COAIA_HOME/.env"
  grep -q '^COAIA_REPO=' "$COAIA_HOME/.env" || printf 'COAIA_REPO=%s\n' "$COAIA_REPO" >> "$COAIA_HOME/.env"
  grep -q '^HERMES_UID=' "$COAIA_HOME/.env" || printf 'HERMES_UID=%s\n' "$HERMES_UID" >> "$COAIA_HOME/.env"
  grep -q '^HERMES_GID=' "$COAIA_HOME/.env" || printf 'HERMES_GID=%s\n' "$HERMES_GID" >> "$COAIA_HOME/.env"
  grep -q '^COAIA_TUI_MOUSE=' "$COAIA_HOME/.env" || printf 'COAIA_TUI_MOUSE=off\n' >> "$COAIA_HOME/.env"
  grep -q '^COAIA_VISUALIZER_HOST_PORT=' "$COAIA_HOME/.env" || printf 'COAIA_VISUALIZER_HOST_PORT=%s\n' "$COAIA_VISUALIZER_HOST_PORT" >> "$COAIA_HOME/.env"
  grep -q '^COAIA_VISUALIZER_PORT=' "$COAIA_HOME/.env" || printf 'COAIA_VISUALIZER_PORT=%s\n' "$COAIA_VISUALIZER_PORT" >> "$COAIA_HOME/.env"
  grep -q '^COAIA_VISUALIZER_MEMORY=' "$COAIA_HOME/.env" || printf 'COAIA_VISUALIZER_MEMORY=%s\n' "$COAIA_VISUALIZER_MEMORY" >> "$COAIA_HOME/.env"
  grep -q '^COAIA_VISUALIZER_AUDIO_DIR=' "$COAIA_HOME/.env" || printf 'COAIA_VISUALIZER_AUDIO_DIR=%s\n' "$COAIA_VISUALIZER_AUDIO_DIR" >> "$COAIA_HOME/.env"
fi

cat > "$COAIA_HOME/bin/coaia-hermes" <<'LAUNCHER_EOF'
#!/usr/bin/env bash
set -euo pipefail

COAIA_HOME="${COAIA_HOME:-$HOME/.coaia-agent}"
COMPOSE_FILE="${COAIA_COMPOSE_FILE:-$COAIA_HOME/compose.yml}"
SERVICE="${COAIA_SERVICE:-hermes-dev}"

compose() {
  docker compose --env-file "$COAIA_HOME/.env" -f "$COMPOSE_FILE" "$@"
}

load_local_env_default() {
  local key="$1"
  local current="${!key-}"
  local line
  if [ -n "$current" ] || [ ! -f "$COAIA_HOME/.env" ]; then
    return
  fi
  line="$(grep -E "^${key}=" "$COAIA_HOME/.env" | tail -n 1 || true)"
  if [ -n "$line" ]; then
    printf -v "$key" '%s' "${line#*=}"
    export "$key"
  fi
}

tui_mouse_enabled() {
  load_local_env_default COAIA_TUI_MOUSE
  case "${COAIA_TUI_MOUSE:-off}" in
    1|true|TRUE|yes|YES|on|ON|enable|ENABLE|enabled|ENABLED)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

set_tui_mouse_config() {
  local value="$1"
  compose exec -T --user hermes "$SERVICE" hermes config set display.mouse_tracking "$value" >/dev/null
}

load_visualizer_defaults() {
  load_local_env_default COAIA_VISUALIZER_MEMORY
  load_local_env_default COAIA_VISUALIZER_PORT
  load_local_env_default COAIA_VISUALIZER_AUDIO_DIR
  export COAIAN_MF="${COAIAN_MF:-${COAIA_VISUALIZER_MEMORY:-/opt/data/memory.jsonl}}"
  export COAIAV_PORT="${COAIAV_PORT:-${COAIA_VISUALIZER_PORT:-4422}}"
  export COAIAV_AUDIO_DIR="${COAIAV_AUDIO_DIR:-${COAIA_VISUALIZER_AUDIO_DIR:-/opt/data/audio}}"
}

run_tui() {
  if tui_mouse_enabled; then
    set_tui_mouse_config true
    compose exec --user hermes "$SERVICE" hermes --tui --provider openai-codex "$@"
  else
    set_tui_mouse_config false
    compose exec --user hermes -e HERMES_TUI_DISABLE_MOUSE=1 "$SERVICE" hermes --tui --provider openai-codex "$@"
  fi
}

ensure_env() {
  mkdir -p "$COAIA_HOME"
  if [ ! -f "$COAIA_HOME/.env" ]; then
    cat > "$COAIA_HOME/.env" <<EOF
COMPOSE_PROJECT_NAME=coaia-agent
COAIA_HOME=$COAIA_HOME
COAIA_REPO=/src/coaia-agent
HERMES_UID=$(id -u)
HERMES_GID=$(id -g)

# This file is also mounted into the container as /opt/data/.env.
# You can add Hermes/API secrets here later if you use API-key providers.
EOF
  fi
}

case "${1:-help}" in
  up|start)
    ensure_env
    shift || true
    compose up -d --build "$SERVICE" "$@"
    ;;
  stop)
    shift || true
    compose stop "$SERVICE" "$@"
    ;;
  down)
    shift || true
    compose down "$@"
    ;;
  restart)
    shift || true
    compose restart "$SERVICE" "$@"
    ;;
  rebuild)
    shift || true
    compose build --no-cache "$SERVICE" "$@"
    compose up -d "$SERVICE"
    ;;
  ps)
    shift || true
    compose ps "$@"
    ;;
  logs)
    shift || true
    compose logs -f "$SERVICE" "$@"
    ;;
  shell|bash)
    shift || true
    compose exec --user hermes "$SERVICE" bash "$@"
    ;;
  auth)
    shift || true
    compose exec --user hermes "$SERVICE" hermes auth "$@"
    ;;
  login)
    shift || true
    compose exec --user hermes "$SERVICE" hermes auth add openai-codex "$@"
    ;;
  model)
    shift || true
    compose exec --user hermes "$SERVICE" hermes model "$@"
    ;;
  visualizer)
    shift || true
    load_visualizer_defaults
    compose exec --user hermes \
      -e COAIAN_MF="$COAIAN_MF" \
      -e COAIAV_PORT="$COAIAV_PORT" \
      -e COAIAV_AUDIO_DIR="$COAIAV_AUDIO_DIR" \
      "$SERVICE" coaia-visualizer --no-open --live -M "$COAIAN_MF" -p "$COAIAV_PORT" "$@"
    ;;
  visualizer-start)
    shift || true
    load_visualizer_defaults
    compose exec -d --user hermes \
      -e COAIAN_MF="$COAIAN_MF" \
      -e COAIAV_PORT="$COAIAV_PORT" \
      -e COAIAV_AUDIO_DIR="$COAIAV_AUDIO_DIR" \
      "$SERVICE" coaia-visualizer --no-open --live -M "$COAIAN_MF" -p "$COAIAV_PORT" "$@"
    ;;
  narrative)
    shift || true
    compose exec --user hermes "$SERVICE" coaia-narrative "$@"
    ;;
  tui)
    shift || true
    run_tui "$@"
    ;;
  hermes)
    shift || true
    compose exec --user hermes "$SERVICE" hermes "$@"
    ;;
  exec)
    shift || true
    compose exec --user hermes "$SERVICE" "$@"
    ;;
  root)
    shift || true
    compose exec "$SERVICE" bash "$@"
    ;;
  config)
    shift || true
    compose config "$@"
    ;;
  help|-h|--help)
    cat <<'EOF'
Usage: coaia-hermes <command> [args]

Commands:
  up          Build/start the background dev container
  tui         Launch Hermes TUI in /workspace/coaia-agent
  auth ...    Manage Hermes credentials inside the isolated container state
  login       Alias for: auth add openai-codex
  model       Open Hermes model picker
  visualizer  Run coaia-visualizer in the foreground (default port 4422)
  visualizer-start  Start coaia-visualizer in the background (default port 4422)
  narrative   Run coaia-narrative inside the container
  shell       Open a non-root shell as the hermes user
  hermes ...  Run any hermes command as the hermes user
  exec ...    Run any command as the hermes user
  root        Open a root shell for container maintenance
  logs        Follow container logs
  ps          Show compose status
  restart     Restart the dev container
  stop        Stop the dev container
  down        Remove the dev container/network
  rebuild     Rebuild image from scratch and restart
  config      Print resolved compose config

Files:
  compose: ~/.coaia-agent/compose.yml
  state:   ~/.coaia-agent/  mounted as /opt/data
  repo:    COAIA_REPO from ~/.coaia-agent/.env mounted as /workspace/coaia-agent

TUI mouse:
  default: off, so terminal selection/copy and middle-click paste work
  enable:  COAIA_TUI_MOUSE=on coaia-hermes tui

COAIA tools:
  visualizer packages are installed in the image with npm -g
  host ports: 4421->4321 for the visualizer default port, 4422->4422 for live runs
  run:       coaia-hermes visualizer
  background: coaia-hermes visualizer-start
EOF
    ;;
  *)
    exec "$0" hermes "$@"
    ;;
esac
LAUNCHER_EOF

chmod +x "$COAIA_HOME/bin/coaia-hermes"
ln -sf "$COAIA_HOME/bin/coaia-hermes" "$HOME/.local/bin/coaia-hermes"

cat > "$COAIA_HOME/README.md" <<'README_EOF'
# COAIA Hermes Dev Container

This is a local-only Docker Compose setup for developing a Hermes fork inside a
container without using or modifying the existing `~/.hermes` installation.

## Layout

- Host repo: set by `COAIA_REPO` in `~/.coaia-agent/.env`
- Container repo: `/workspace/coaia-agent`
- Host Hermes state: `~/.coaia-agent`
- Container Hermes state: `/opt/data`
- Container subprocess home: `/opt/data/home`
- TUI mouse tracking: off by default, so terminal selection/copy and
  middle-click paste keep working
- COAIA visualizer: installed in the image with coaia-narrative; host ports
  4421→4321 and 4422→4422 are exposed for local chart access
- Optional Gaia mounts: existing host paths from /opt/binscripts, /a/src,
  /workspace, /srv/miadi, /var/lib/miadi, and /var/log/miadi are mounted when present

The compose file intentionally lives outside the repo so normal upstream pulls
do not conflict with local container workflow files.

## Commands

```bash
coaia-hermes up
coaia-hermes auth add openai-codex
coaia-hermes tui
coaia-hermes visualizer-start
```

To temporarily enable TUI mouse/wheel tracking:

```bash
COAIA_TUI_MOUSE=on coaia-hermes tui
```

General shell:

```bash
coaia-hermes shell
```

Run any Hermes command:

```bash
coaia-hermes hermes doctor
coaia-hermes hermes --tui --provider openai-codex
```

Run the COAIA visualizer against the isolated memory JSONL:

```bash
coaia-hermes visualizer
# or keep it running in the background
coaia-hermes visualizer-start
```

Override the visualizer memory/port/audio paths with either ~/.coaia-agent/.env
or one-shot environment variables:

```bash
COAIAN_MF=/opt/data/memory.jsonl COAIAV_PORT=4422 coaia-hermes visualizer
```
README_EOF

docker compose --env-file "$COAIA_HOME/.env" -f "$COAIA_HOME/compose.yml" config >/dev/null

cat <<EOF
COAIA Hermes dev setup is ready.

Control dir: $COAIA_HOME
Repo mount:  $COAIA_REPO
Launcher:    $COAIA_HOME/bin/coaia-hermes
Symlink:     $HOME/.local/bin/coaia-hermes

Next:
  coaia-hermes up
  coaia-hermes auth add openai-codex
  coaia-hermes tui
  coaia-hermes visualizer-start
EOF

if [ "$START" = 1 ]; then
  "$COAIA_HOME/bin/coaia-hermes" up
fi
if [ "$LOGIN" = 1 ]; then
  "$COAIA_HOME/bin/coaia-hermes" auth add openai-codex
fi
if [ "$TUI" = 1 ]; then
  "$COAIA_HOME/bin/coaia-hermes" tui
fi
