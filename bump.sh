#!/usr/bin/env bash
# Usage: ./bump.sh 66
# Atomically updates ALL places that hold the current build number, then
# mirrors index.html → app.html. Failing to update any one of them used to
# break the auto-update path and strand users on the old build.

set -euo pipefail

if [ "$#" -ne 1 ] || ! [[ "$1" =~ ^[0-9]+$ ]]; then
  echo "usage: $0 <new-version-number>"
  echo "example: $0 66"
  exit 1
fi

NEW="$1"
HERE="$(cd "$(dirname "$0")" && pwd)"
cd "$HERE"

echo "Bumping to v$NEW..."

# 1. version.json — what the server reports to clients
echo "{\"v\":$NEW}" > docs/version.json

# 2. MY_VERSION in the HTML gate
sed -i.bak -E "s/var MY_VERSION=[0-9]+;/var MY_VERSION=$NEW;/" docs/index.html

# 3. #appVersionLabel "build NN" text
sed -i.bak -E "s/build [0-9]+/build $NEW/" docs/index.html

# 4. Cache-bust on manifest link
sed -i.bak -E "s#manifest\.json\?v=[0-9]+#manifest.json?v=$NEW#" docs/index.html

# 5. Cache-bust on config.js and db.js script tags
sed -i.bak -E "s#supabase/config\.js\?v=[0-9]+#supabase/config.js?v=$NEW#" docs/index.html
sed -i.bak -E "s#supabase/db\.js\?v=[0-9]+#supabase/db.js?v=$NEW#" docs/index.html

# 6. start_url in manifest so iOS PWA re-fetches on next launch
sed -i.bak -E "s#\"start_url\": \"\./app\.html\?v=[0-9]+\"#\"start_url\": \"./app.html?v=$NEW\"#" docs/manifest.json

# Clean up sed backup files
rm -f docs/index.html.bak docs/manifest.json.bak

# 7. Mirror index.html to app.html (Pages serves both routes)
cp docs/index.html docs/app.html

# Sanity check: every place that should say the new version now does
echo ""
echo "Verifying all 7 places are in sync with $NEW..."
grep -c "\"v\":$NEW" docs/version.json            > /dev/null && echo "  ✓ version.json"
grep -c "MY_VERSION=$NEW" docs/index.html         > /dev/null && echo "  ✓ MY_VERSION"
grep -c "build $NEW" docs/index.html              > /dev/null && echo "  ✓ build label"
grep -c "manifest.json?v=$NEW" docs/index.html    > /dev/null && echo "  ✓ manifest cache-bust"
grep -c "config.js?v=$NEW" docs/index.html        > /dev/null && echo "  ✓ config.js cache-bust"
grep -c "db.js?v=$NEW" docs/index.html            > /dev/null && echo "  ✓ db.js cache-bust"
grep -c "app.html?v=$NEW" docs/manifest.json      > /dev/null && echo "  ✓ manifest start_url"

diff -q docs/index.html docs/app.html > /dev/null && echo "  ✓ app.html mirrors index.html"

echo ""
echo "Done. Next: git add -A && git commit -m 'v$NEW: <what changed>' && ./push.sh"
