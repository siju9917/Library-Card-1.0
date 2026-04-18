#!/usr/bin/env bash
# Usage: ./push.sh
# Pushes HEAD to THREE places:
#   1. The current feature branch
#   2. main (kept in sync so there's no confusion about "current")
#   3. claude/wallet-tracking-app-plan-48P2f — THIS IS THE BRANCH GITHUB PAGES
#      DEPLOYS FROM (Settings → Pages → Source). If this branch is not
#      updated, the live site stays on whatever old build was last pushed
#      here, and every user sees a stale version forever.
#
# If you change the Pages source in the GitHub UI, UPDATE THE PAGES_BRANCH
# variable below, otherwise the live site will silently stop updating.

set -euo pipefail

PAGES_BRANCH="claude/wallet-tracking-app-plan-48P2f"

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

BR="$(git symbolic-ref --short HEAD)"
echo "Pushing HEAD ($(git rev-parse --short HEAD)) to:"

if [ "$BR" = "main" ]; then
  git push -u origin main
  echo "  ✓ main"
else
  git push -u origin "$BR"
  echo "  ✓ $BR"
  git push origin "HEAD:main"
  echo "  ✓ main (fast-forward)"
fi

# Pages deploy branch — critical. Must be a fast-forward from the current
# HEAD. If this fails, the live site does NOT update.
if git push origin "HEAD:$PAGES_BRANCH"; then
  echo "  ✓ $PAGES_BRANCH (Pages source — site will redeploy in 1–2 min)"
else
  echo ""
  echo "!!! PAGES PUSH FAILED !!!"
  echo "The live site will stay on whatever was last on $PAGES_BRANCH."
  echo "Either fix the push, or go to Settings → Pages and change the"
  echo "source branch to 'main', then update PAGES_BRANCH in this script."
  exit 1
fi
