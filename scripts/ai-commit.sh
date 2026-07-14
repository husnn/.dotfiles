#!/usr/bin/env bash
#
# ai-commit — stage changes in the current git repo and create a commit whose
# message is generated from the diff.
#
# Message style priority:
#   1. Project commit guidelines, if any are found (CONTRIBUTING, CLAUDE.md, …).
#   2. Otherwise, match the style of recent commits in this repo.
#   3. Default: one short, specific line, no author attribution.
#
# Usage:
#   ai-commit          # stage (if nothing staged), propose a message, confirm, commit
#   ai-commit -y       # skip the confirmation prompt
#
# Env:
#   AI_COMMIT_MODEL    # model passed to `claude` (default: sonnet)

set -euo pipefail

ASSUME_YES=0
[ "${1:-}" = "-y" ] && ASSUME_YES=1

MODEL="${AI_COMMIT_MODEL:-sonnet}"

# 1. Must be inside a git work tree.
if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "ai-commit: not a git repository." >&2
  exit 1
fi

ROOT=$(git rev-parse --show-toplevel)

# 2. Decide what to commit. Respect an intentional staging if one exists;
#    otherwise stage everything (tracked + untracked).
if git diff --cached --quiet; then
  git add -A
fi

if git diff --cached --quiet; then
  echo "ai-commit: no changes to commit." >&2
  exit 0
fi

# 3. Gather context for the message.
STAT=$(git diff --cached --stat)
DIFF=$(git diff --cached | head -c 60000)          # cap huge diffs
LOG=$(git log --no-merges --pretty=format:'%s' -n 20 2>/dev/null || true)

GUIDELINES=""
for f in CLAUDE.md AGENTS.md CONTRIBUTING.md CONTRIBUTING .gitmessage \
         COMMIT_CONVENTION.md docs/commits.md .github/COMMIT_CONVENTION.md; do
  if [ -f "$ROOT/$f" ]; then
    GUIDELINES+=$'\n\n--- '"$f"$' ---\n'
    GUIDELINES+=$(head -c 4000 "$ROOT/$f")
  fi
done

# 4. Build the prompt.
PROMPT="Write a git commit message for the staged changes below.

Rules:
- Output ONLY the commit message. No quotes, no code fences, no explanation.
- A single line. Short and specific: a reader should understand what changed
  without going into detail.
- No author attribution, no 'Co-authored-by', no trailing metadata.
- If project guidelines are given below, follow their style and structure.
- Otherwise match the style of the recent commit subjects below.
"

if [ -n "$GUIDELINES" ]; then
  PROMPT+="
Project guidelines:$GUIDELINES
"
fi

PROMPT+="
Recent commit subjects (style reference):
$LOG

Diff summary:
$STAT

Full diff:
$DIFF
"

# 5. Generate the message.
MSG=$(printf '%s' "$PROMPT" | claude -p --model "$MODEL" 2>/dev/null \
        | head -n1 \
        | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//' \
              -e 's/^["'\''`]//' -e 's/["'\''`]$//')

if [ -z "$MSG" ]; then
  echo "ai-commit: failed to generate a commit message." >&2
  exit 1
fi

# 6. Confirm and commit.
echo "Proposed commit message:"
echo "  $MSG"
echo

if [ "$ASSUME_YES" -ne 1 ]; then
  printf "Commit with this message? [Y/n] "
  read -r reply </dev/tty || reply=""
  case "$reply" in
    ""|y|Y|yes|YES) ;;
    *) echo "Aborted."; exit 1 ;;
  esac
fi

git commit -m "$MSG"
