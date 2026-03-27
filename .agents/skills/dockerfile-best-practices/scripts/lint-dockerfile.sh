#!/usr/bin/env bash
#
# lint-dockerfile.sh — Lint a Dockerfile using hadolint via Docker
#
# Usage:
#   ./lint-dockerfile.sh <path-to-Dockerfile>
#   ./lint-dockerfile.sh Dockerfile
#   ./lint-dockerfile.sh --local Dockerfile   # use locally installed hadolint

set -euo pipefail

USE_LOCAL=false
if [ "${1:-}" = "--local" ]; then
  USE_LOCAL=true
  shift
fi

DOCKERFILE="${1:?Usage: $0 [--local] <Dockerfile>}"

if [ ! -f "$DOCKERFILE" ]; then
  echo "ERROR: File not found: $DOCKERFILE" >&2
  exit 1
fi

# Rules to enforce (subset of hadolint defaults, plus extras)
# DL3007: Do not use latest tag
# DL3008: Pin versions in apt-get install
# DL3018: Pin versions in apk add
# DL3025: Use JSON notation for CMD/ENTRYPOINT
# DL3059: Multiple consecutive RUN instructions (consolidate)
# DL4006: Set SHELL option -o pipefail before piping

if [ "$USE_LOCAL" = true ]; then
  if ! command -v hadolint &>/dev/null; then
    echo "ERROR: hadolint not found locally. Run without --local to use Docker." >&2
    exit 1
  fi
  hadolint "$DOCKERFILE"
else
  if ! command -v docker &>/dev/null; then
    echo "ERROR: Docker is not installed or not in PATH." >&2
    exit 1
  fi
  docker run --rm -i hadolint/hadolint < "$DOCKERFILE"
fi

exit_code=$?

if [ $exit_code -eq 0 ]; then
  echo "Dockerfile lint passed."
else
  echo ""
  echo "See hadolint wiki for rule details: https://github.com/hadolint/hadolint#rules"
fi

exit $exit_code
