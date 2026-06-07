#!/usr/bin/env bash
set -u

# Find Git Root or default to CWD
GIT_ROOT=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
HOOKS_DIR="$GIT_ROOT/.github/hooks"
HOOKS_FILE="$HOOKS_DIR/hooks.json"
TEMPLATE="/a/src/scripts/copilot_hooks/hooks.json"

mkdir -p "$HOOKS_DIR"

if [ ! -f "$HOOKS_FILE" ]; then
    cp "$TEMPLATE" "$HOOKS_FILE"
    echo "Initialized $HOOKS_FILE from template."
else
    # Check if we should update it or if it's already what we want
    # For now, just report it.
    echo "$HOOKS_FILE already exists. Skipping initialization."
fi

if [ "$GIT_ROOT" != "$PWD" ]; then
    echo "NOTE: Git Root detected at $GIT_ROOT. Hooks placed there."
fi

echo ""
echo "NOTE: To enable repo hooks in non-interactive mode (-p), you must set:"
echo "export GITHUB_COPILOT_PROMPT_MODE_REPO_HOOKS=true"
