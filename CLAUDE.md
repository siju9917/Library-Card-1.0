# Library Card — Working with this repo

## MANDATORY: push to `main` AND the feature branch AND the Pages branch

This repo has an UNUSUAL setup that has bitten us hard before:

1. The feature branch for the current session (e.g. `claude/review-session-bugs-VflTp`).
2. `main` — kept in sync so it reflects the current tip.
3. **`claude/wallet-tracking-app-plan-48P2f`** — THIS is what GitHub Pages
   actually deploys from (Settings → Pages → Source). If you push to
   `main` but not this branch, the live site stays on the OLD build
   forever and every user stays stuck.

**Just run `./push.sh` from the repo root.** It handles all three. If
you're pushing manually, the three commands are:

```bash
git push -u origin <feature-branch>
git push origin HEAD:main
git push origin HEAD:claude/wallet-tracking-app-plan-48P2f
```

If the Pages source branch ever changes in the GitHub UI, update
`PAGES_BRANCH` in `push.sh` or the live site will silently stop updating.

## Web app layout

- `docs/index.html` is the production web app (3800+ lines, HTML+CSS+JS inline).
- `docs/app.html` is a byte-identical copy of `index.html` (served at both routes). Any edit to one MUST be mirrored to the other.
- `docs/supabase/db.js` is the cloud data layer. `docs/supabase/config.js` holds the URL + anon key (gitignored per-env).
- `docs/supabase/schema.sql` is the full Postgres schema including RLS + realtime + RPCs. Safe to re-run.
- `docs/version.json` stores the current build number; `index.html` mirrors it in `#appVersionLabel`.

## Version bumps — use `./bump.sh NN`

Run `./bump.sh 67` (or whatever the next number is) from the repo root.
It updates all the places listed below in one go, then mirrors
`index.html` to `app.html`, then verifies they're all in sync.

If you absolutely need to edit by hand, these are ALL the places:

## Bump the version on every release — ALL FIVE places

Missing any ONE of these breaks the auto-update path and users get stuck
on the old build. Every release, bump the number in ALL of:

1. `docs/version.json` — the `v` field.
2. `docs/index.html` — `var MY_VERSION=NN;` in the `<head>` version gate script.
3. `docs/index.html` — the `build NN` string in `#appVersionLabel` (Profile screen).
4. `docs/index.html` — `manifest.json?v=NN` on the `<link rel="manifest">` tag.
5. `docs/index.html` — `supabase/config.js?v=NN` and `supabase/db.js?v=NN` on the two `<script>` tags.

Then `cp docs/index.html docs/app.html` so the two served routes stay identical.

**Why it matters:** The gate at the top of `<head>` compares `MY_VERSION`
against `version.json`. If they don't match after a reload, users get
stuck in a redirect loop OR never see the new build at all. The `?v=NN`
cache-busts on sub-resources so the browser actually re-fetches them.

## Self-healing update path

`docs/index.html`'s `<head>` has a bulletproof version gate that runs
BEFORE any CDN script. When a new version is detected it:
- Unregisters every service worker
- Deletes every Cache Storage cache
- Hard-reloads with `?_v=NN&t=NOW`

A manual "Force Refresh" button lives in Profile so users can pull
the latest build even if the auto-check is confused.

## Session / data safety

- Cloud is the source of truth for all user data (sessions, drinks, friendships, weekend plans).
- Live session state is mirrored to `localStorage` under `lc_live_session` and a pending-ops queue under `lc_pending_ops` as a safety net. On page load, cloud is checked first; local is only used to recover sessions whose cloud insert never landed.
- Never silently swallow an error on a data-write path. `catch {}` is banned — always `console.error` at minimum, and surface to the user when it's something they can act on.
