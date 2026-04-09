#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

MODE="${1:-default}"

run_all() {
  dart test -r expanded --chain-stack-traces
}

case "$MODE" in
  default)
    run_all
    ;;
  live)
    if [[ -f ".env" ]]; then
      set -a
      # shellcheck disable=SC1091
      source .env
      set +a
    fi
    export RUN_LIVE_API_TESTS=true
    run_all
    ;;
  file)
    if [[ "${2:-}" == "" ]]; then
      echo "Usage: ./scripts/run_tests.sh file <test_file_path>"
      exit 1
    fi
    dart test "$2" -r expanded --chain-stack-traces
    ;;
  watch)
    dart test --watch -r expanded --chain-stack-traces
    ;;
  *)
    echo "Usage: ./scripts/run_tests.sh [default|live|file <path>|watch]"
    exit 1
    ;;
esac
