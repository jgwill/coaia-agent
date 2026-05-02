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

mkdir -p "$COAIA_HOME/bin" "$HOME/.local/bin"

cat > "$COAIA_HOME/compose.yml" <<'COMPOSE_EOF'
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
ENV_EOF
else
  # Keep existing secrets/config, but make sure required keys exist.
  grep -q '^COMPOSE_PROJECT_NAME=' "$COAIA_HOME/.env" || printf '\nCOMPOSE_PROJECT_NAME=coaia-agent\n' >> "$COAIA_HOME/.env"
  grep -q '^COAIA_HOME=' "$COAIA_HOME/.env" || printf 'COAIA_HOME=%s\n' "$COAIA_HOME" >> "$COAIA_HOME/.env"
  grep -q '^COAIA_REPO=' "$COAIA_HOME/.env" || printf 'COAIA_REPO=%s\n' "$COAIA_REPO" >> "$COAIA_HOME/.env"
  grep -q '^HERMES_UID=' "$COAIA_HOME/.env" || printf 'HERMES_UID=%s\n' "$HERMES_UID" >> "$COAIA_HOME/.env"
  grep -q '^HERMES_GID=' "$COAIA_HOME/.env" || printf 'HERMES_GID=%s\n' "$HERMES_GID" >> "$COAIA_HOME/.env"
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
  tui)
    shift || true
    compose exec --user hermes "$SERVICE" hermes --tui --provider openai-codex "$@"
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

The compose file intentionally lives outside the repo so normal upstream pulls
do not conflict with local container workflow files.

## Commands

```bash
coaia-hermes up
coaia-hermes auth add openai-codex
coaia-hermes tui
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
