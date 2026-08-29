#!/bin/bash
# tests/run_tests.sh - Run novim-dev test suite
# Part of novim custom derivative
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd -P)"

MODE="${1:-all}"

if [[ "$MODE" == "--smoke" || "$MODE" == "-s" || "$MODE" == "smoke" ]]; then
  exec "$SCRIPT_DIR/run_smoke_tests.sh"
fi

echo "Running tests using: $PROJECT_ROOT/bin/novim-dev"
echo "=== Running Diff Workbench & Project Browser Test Suite ==="
"$PROJECT_ROOT/bin/novim-dev" --headless -u "$PROJECT_ROOT/config/nvim/init.lua" -l "$PROJECT_ROOT/tests/test_workbench.lua"

if [[ "$MODE" == "--all" || "$MODE" == "-a" || "$MODE" == "all" ]]; then
  echo ""
  "$SCRIPT_DIR/run_smoke_tests.sh"
fi
