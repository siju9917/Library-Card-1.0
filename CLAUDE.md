# Library Card — Working with this repo

## MANDATORY: push to BOTH `main` AND the feature branch

This repo intentionally keeps feature branches around (we don't delete them
after merge), but we don't want confusion about which branch is "current".
Every push therefore needs to land in two places:

1. The feature branch for the current session (e.g. `claude/review-session-bugs-VflTp`)
2. `main`

Do this by updating the local `main` to match the feature tip and pushing
both refs in one command:

```bash
git push -u origin <feature-branch>
git push origin <feature-branch>:main
```

Or, equivalently, after committing on the feature branch:

```bash
git push origin HEAD:<feature-branch> HEAD:main
```

Never push to just one of them. If `main` push is rejected (fast-forward
failure), pull/rebase `main` first, then push both again.

## Web app layout

- `docs/index.html` is the production web app (3800+ lines, HTML+CSS+JS inline).
- `docs/app.html` is a byte-identical copy of `index.html` (served at both routes). Any edit to one MUST be mirrored to the other.
- `docs/supabase/db.js` is the cloud data layer. `docs/supabase/config.js` holds the URL + anon key (gitignored per-env).
- `docs/supabase/schema.sql` is the full Postgres schema including RLS + realtime + RPCs. Safe to re-run.
- `docs/version.json` stores the current build number; `index.html` mirrors it in `#appVersionLabel`.

## Bump the version on every release

When shipping a change, bump the `v` in `docs/version.json` AND the `build NN` string in `docs/index.html` (the `#appVersionLabel` div).

## Session / data safety

- Cloud is the source of truth for all user data (sessions, drinks, friendships, weekend plans).
- Live session state is mirrored to `localStorage` under `lc_live_session` and a pending-ops queue under `lc_pending_ops` as a safety net. On page load, cloud is checked first; local is only used to recover sessions whose cloud insert never landed.
- Never silently swallow an error on a data-write path. `catch {}` is banned — always `console.error` at minimum, and surface to the user when it's something they can act on.
