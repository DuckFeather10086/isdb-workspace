#!/usr/bin/env bash
#
# bootstrap.sh — check out the ferrite stack and build it.
#
# RETIRED. This repo is a wrapper around one submodule and its pin is no longer
# moved; clone ferrite directly instead. See README.md.
#
#   ./bootstrap.sh           # ensure submodules, then build everything
#   ./bootstrap.sh init      # only sync + checkout submodules
#   ./bootstrap.sh build     # only build (assumes submodules present)
#   ./bootstrap.sh status    # show pinned commit + branch of each submodule
#
# The build is ferrite's own — its Makefile builds the Rust engines it carries
# as submodules, the web UI, and the daemon, into the paths its config names.
# There is nothing to build at this level: this repo holds one submodule.
#
set -euo pipefail
cd "$(dirname "$0")"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
note() { printf '\033[1;33m%s\033[0m\n' "$*" >&2; }

note "isdb-workspace is retired — the ferrite pin here is a snapshot, not a release."
note "  git clone --recursive https://github.com/DuckFeather10086/ferrite.git"

have() { command -v "$1" >/dev/null 2>&1; }

ensure_submodules() {
  step "Syncing submodules"
  git submodule sync --recursive
  # --recursive: ferrite carries the four Rust engines as submodules of its own.
  git submodule update --init --recursive
}

build() {
  for tool in cargo go bun make; do
    if ! have "$tool"; then echo "error: $tool not found on PATH" >&2; exit 1; fi
  done

  step "Building ferrite (Rust engines, web UI, daemon)"
  make -C ferrite build
}

status() {
  step "Submodule status (pinned commit / tracked branch)"
  git submodule status --recursive
  echo
  git config -f .gitmodules --get-regexp 'submodule\..*\.branch' || true
  git config -f ferrite/.gitmodules --get-regexp 'submodule\..*\.branch' || true
}

case "${1:-all}" in
  init)   ensure_submodules ;;
  build)  build ;;
  status) status ;;
  all)    ensure_submodules; build ;;
  *)      echo "usage: $0 [init|build|status|all]" >&2; exit 2 ;;
esac
