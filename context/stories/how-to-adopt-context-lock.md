# How to Adopt context.lock in Another Repo

`context.lock` enforces that AI context is always up to date — both locally (lock matches current files) and in PRs (branch isn't missing context that landed on main).

No dependency on `yourcounterpart`. The script is self-contained.

---

## Setup (one time)

**1. Copy the script into your repo:**
```bash
cp path/to/counterpart-toolbox/scripts/context-lock.sh scripts/context-lock.sh
git add scripts/context-lock.sh
```

**2. Create your `context/` directory and add content:**
```bash
mkdir -p context
# add context/index.md, context/stories/*.md etc.
```

**3. Generate the initial lock:**
```bash
bash scripts/context-lock.sh generate
git add context.lock
git commit -m "chore: add context.lock"
```

**4. Copy the GitHub Actions workflow:**
```bash
mkdir -p .github/workflows
cp path/to/counterpart-toolbox/.github/workflows/context-lock.yml .github/workflows/context-lock.yml
git add .github/workflows/context-lock.yml
git commit -m "ci: add context-lock check"
```

---

## Daily workflow

After editing any file under `context/`, regenerate the lock before pushing:

```bash
bash scripts/context-lock.sh generate
git add context.lock
git commit -m "docs: update context"
```

Or check first if it's stale:
```bash
bash scripts/context-lock.sh validate
```

---

## What CI enforces

The workflow runs on every PR targeting `main`. Two checks:

**Check 1 — lock is current on this branch**
Regenerates the lock from the branch's `context/` files and diffs against the committed `context.lock`. Fails if they differ — the author changed stories but didn't run `generate`.

**Check 2 — branch is not behind main's context**
For every entry in `main`'s `context.lock`, verifies the same hash exists in the PR's lock. Fails if any entry is missing — a story was merged to `main` after this branch was created. Fix: rebase and regenerate.

---

## Environment variables

| Variable | Default | Effect |
|----------|---------|--------|
| `CONTEXT_DIR` | `context` | Directory to hash |
| `CONTEXT_LOCK_FILE` | `context.lock` | Lock file path |
| `CONTEXT_LOCK_BASE_BRANCH` | `main` | Base branch for Check 2 |
| `CONTEXT_LOCK_HARD` | `1` in ci-check | `1` = fail, `0` = warn only |

---

## Keeping the script up to date

When a new version of `scripts/context-lock.sh` is released in the toolbox, copy it again:

```bash
cp path/to/counterpart-toolbox/scripts/context-lock.sh scripts/context-lock.sh
```

`yourcounterpart update` does NOT copy this script automatically — it's a one-time manual adoption.
