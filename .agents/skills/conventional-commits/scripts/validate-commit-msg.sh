#!/usr/bin/env bash
#
# validate-commit-msg.sh — Conventional Commits commit-msg hook
#
# Usage:
#   As a git hook:  cp this file to .git/hooks/commit-msg && chmod +x .git/hooks/commit-msg
#   Standalone:     ./validate-commit-msg.sh <commit-msg-file>
#   Pipe:           echo "feat: add thing" | ./validate-commit-msg.sh /dev/stdin

set -euo pipefail

COMMIT_MSG_FILE="${1:?Usage: $0 <commit-msg-file>}"

# Read only the first line (subject) and full message
subject=$(head -n 1 "$COMMIT_MSG_FILE")
full_msg=$(cat "$COMMIT_MSG_FILE")

# Strip comment lines (git default comments start with #)
subject=$(echo "$subject" | grep -v '^#' || true)
full_msg=$(echo "$full_msg" | grep -v '^#')

if [ -z "$subject" ]; then
  echo "ERROR: Commit message is empty." >&2
  exit 1
fi

# Allowed types
types="feat|fix|docs|style|refactor|perf|test|build|ci|chore"

# Reject ! breaking change syntax before general validation (clearer error)
if echo "$subject" | grep -Eq "^($types)(\([a-z0-9_-]+\))?!:"; then
  echo "ERROR: Use 'BREAKING CHANGE:' footer instead of '!' syntax." >&2
  echo "  $subject" >&2
  exit 1
fi

# Pattern: type(optional-scope): description
pattern="^($types)(\([a-z0-9_-]+\))?: .+"

if ! echo "$subject" | grep -Eq "$pattern"; then
  echo "ERROR: Invalid commit message format." >&2
  echo "" >&2
  echo "  Expected: <type>(<optional scope>): <description>" >&2
  echo "  Types:    feat, fix, docs, style, refactor, perf, test, build, ci, chore" >&2
  echo "  Got:      $subject" >&2
  echo "" >&2
  echo "  Examples:" >&2
  echo "    feat: add user authentication" >&2
  echo "    fix(parser): handle empty input" >&2
  exit 1
fi

# Check subject line length (max 72 chars)
subject_len=${#subject}
if [ "$subject_len" -gt 72 ]; then
  echo "ERROR: Subject line is $subject_len chars (max 72)." >&2
  echo "  $subject" >&2
  exit 1
fi

# Check subject does not end with a period
if echo "$subject" | grep -Eq '\.$'; then
  echo "ERROR: Subject line must not end with a period." >&2
  echo "  $subject" >&2
  exit 1
fi

# Check subject description starts with lowercase
desc=$(echo "$subject" | sed -E "s/^($types)(\([a-z0-9_-]+\))?: //")
if echo "$desc" | grep -Eq '^[A-Z]'; then
  echo "ERROR: Description must start with lowercase." >&2
  echo "  $subject" >&2
  exit 1
fi

# If there is a body, ensure blank line separates subject from body
line_count=$(echo "$full_msg" | wc -l)
if [ "$line_count" -gt 1 ]; then
  second_line=$(echo "$full_msg" | sed -n '2p')
  if [ -n "$second_line" ]; then
    echo "ERROR: Second line must be blank (separates subject from body)." >&2
    exit 1
  fi
fi

echo "Commit message is valid."
