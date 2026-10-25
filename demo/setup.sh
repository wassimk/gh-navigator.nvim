#!/usr/bin/env bash
#
# Prepares /tmp/gh-navigator-demo for recording the README demo (see demo/gh-navigator.tape).
#
# The demo needs a real GitHub repo for gh to look up, so it uses a fresh clone of this
# public repo on main. The plugin code itself is loaded from this checkout.

set -euo pipefail

DEMO_DIR=/tmp/gh-navigator-demo
REPO_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)

# Ignore personal git config (aliases, hooks) for the clone
export GIT_CONFIG_GLOBAL=/dev/null
export GIT_CONFIG_NOSYSTEM=1

rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR"
git clone -q https://github.com/wassimk/gh-navigator.nvim "$DEMO_DIR/gh-navigator.nvim"

# Environment for the demo shell. gh keeps its own auth config, so only git is isolated.
cat >"$DEMO_DIR/env.sh" <<ENV
export GIT_CONFIG_GLOBAL=/dev/null GIT_CONFIG_NOSYSTEM=1
export XDG_DATA_HOME=$DEMO_DIR/data
export DEMO_INIT=$REPO_DIR/demo/init.lua
ENV
