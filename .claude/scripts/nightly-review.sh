#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="/home/user/DA-Leclerc"
LOG_DIR="$REPO_DIR/.claude/review-logs"
LOG_FILE="$LOG_DIR/review-$(date +%Y-%m-%d).md"

mkdir -p "$LOG_DIR"

cd "$REPO_DIR"

# Collect commits from the last 24 hours
COMMITS=$(git log --since="24 hours ago" --oneline 2>/dev/null)

if [ -z "$COMMITS" ]; then
  echo "# Nightly Review — $(date '+%Y-%m-%d')" > "$LOG_FILE"
  echo "" >> "$LOG_FILE"
  echo "No commits in the last 24 hours. Nothing to review." >> "$LOG_FILE"
  exit 0
fi

# Build the full diff for all commits in the last 24 hours
DIFF=$(git log --since="24 hours ago" -p --stat 2>/dev/null | head -2000)

PROMPT="You are doing a nightly code review of all commits pushed to this repository in the last 24 hours.

Commits:
$COMMITS

Diff (truncated to 2000 lines if large):
$DIFF

Please provide a concise review covering:
1. **Summary** – what changed and why (inferred from commit messages + diff)
2. **Code quality** – any obvious issues, anti-patterns, or improvements
3. **Security** – any potential vulnerabilities introduced
4. **Risks** – anything that looks risky or needs a closer look tomorrow

Keep the review practical and actionable. Output in Markdown."

# Run claude and save output
echo "# Nightly Code Review — $(date '+%Y-%m-%d %H:%M')" > "$LOG_FILE"
echo "" >> "$LOG_FILE"
/opt/node22/bin/claude --print "$PROMPT" >> "$LOG_FILE" 2>&1 || {
  echo "claude CLI invocation failed — check PATH and API key." >> "$LOG_FILE"
  exit 1
}
