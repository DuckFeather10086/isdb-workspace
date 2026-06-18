#!/usr/bin/env bash
#
# bootstrap.sh — set up / build the ferrite stack.
#
#   ./bootstrap.sh           # ensure submodules, then build everything
#   ./bootstrap.sh init      # only sync + checkout submodules
#   ./bootstrap.sh build     # only build (assumes submodules present)
#   ./bootstrap.sh status    # show pinned commit + branch of each submodule
#
set -euo pipefail
cd "$(dirname "$0")"

step() { printf '\n\033[1;36m==> %s\033[0m\n' "$*"; }
have() { command -v "$1" >/dev/null 2>&1; }

ensure_submodules() {
  step "Syncing submodules"
  git submodule sync --recursive
  git submodule update --init --recursive
}

build() {
  if ! have cargo; then echo "error: cargo not found on PATH" >&2; exit 1; fi
  if ! have go;    then echo "error: go not found on PATH"    >&2; exit 1; fi

  step "Building Rust engines: libaribb24 + dvbr (root workspace)"
  cargo build --release

  step "Building Rust engine: b25 (inner workspace)"
  cargo build --release --manifest-path libaribb25-rs/Cargo.toml

  step "Building Go daemon: isdb-hub"
  ( cd isdb-hub && go build ./... )

  step "Done"
  echo "  dvbr   : $(pwd)/target/release/dvb-rs"
  echo "  b25    : $(pwd)/libaribb25-rs/target/release/b25-rs"
  echo "  isdbd  : build with 'cd isdb-hub && go build -o isdb-hub ./cmd/isdbd'"
}

status() {
  step "Submodule status (pinned commit / tracked branch)"
  git submodule status
  echo
  git config -f .gitmodules --get-regexp 'submodule\..*\.branch' || true
}

case "${1:-all}" in
  init)   ensure_submodules ;;
  build)  build ;;
  status) status ;;
  all)    ensure_submodules; build ;;
  *)      echo "usage: $0 [init|build|status|all]" >&2; exit 2 ;;
esac
