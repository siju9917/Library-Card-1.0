#!/usr/bin/env bash
# Usage: ./push.sh
# Pushes HEAD to BOTH the current feature branch AND main. The repo
# intentionally keeps feature branches around after merge, but we never
# want main to lag — otherwise Pages serves stale code and users get
# stuck on the old build.

set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

BR="$(git symbolic-ref --short HEAD)"
if [ "$BR" = "main" ]; then
  git push -u origin main
else
  git push -u origin "$BR"
  git push origin "HEAD:main"
fi

echo ""
echo "Pushed to:"
echo "  - $BR"
[ "$BR" != "main" ] && echo "  - main (fast-forward)"
