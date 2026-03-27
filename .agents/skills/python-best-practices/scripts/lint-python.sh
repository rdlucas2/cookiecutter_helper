#!/usr/bin/env bash
#
# lint-python.sh — Lint Python files using ruff and optionally mypy
#
# Usage:
#   ./lint-python.sh [path]          # defaults to current directory
#   ./lint-python.sh src/main.py     # lint a specific file
#   ./lint-python.sh --fix [path]    # auto-fix what ruff can
#   ./lint-python.sh --mypy [path]   # also run mypy type checking

set -euo pipefail

FIX=false
MYPY=false
TARGET="."

while [ $# -gt 0 ]; do
  case "$1" in
    --fix)  FIX=true; shift ;;
    --mypy) MYPY=true; shift ;;
    *)      TARGET="$1"; shift ;;
  esac
done

errors=0

# --- ruff (linting + formatting) ---
if command -v ruff &>/dev/null; then
  echo "=== ruff lint ==="
  if [ "$FIX" = true ]; then
    ruff check --fix "$TARGET" || errors=$((errors + 1))
    echo ""
    echo "=== ruff format ==="
    ruff format "$TARGET" || errors=$((errors + 1))
  else
    ruff check "$TARGET" || errors=$((errors + 1))
    echo ""
    echo "=== ruff format (check) ==="
    ruff format --check "$TARGET" || errors=$((errors + 1))
  fi
elif command -v pip &>/dev/null; then
  echo "ruff not found. Install with: pip install ruff" >&2
  errors=$((errors + 1))
fi

# --- mypy (type checking, optional) ---
if [ "$MYPY" = true ]; then
  echo ""
  echo "=== mypy ==="
  if command -v mypy &>/dev/null; then
    mypy "$TARGET" || errors=$((errors + 1))
  else
    echo "mypy not found. Install with: pip install mypy" >&2
    errors=$((errors + 1))
  fi
fi

echo ""
if [ $errors -eq 0 ]; then
  echo "All checks passed."
else
  echo "$errors check(s) failed."
  exit 1
fi
