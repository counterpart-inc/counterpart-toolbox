# How context.lock Works

`context.lock` is a SHA256 hash file that tracks the state of a repo's `context/` directory. It ensures AI agents always operate with up-to-date project knowledge.

---

## What it hashes

Every file under `context/` is hashed individually. An aggregate hash covers the entire directory. Both are stored in `context.lock`:

```
sha256:<hash>  context/index.md
sha256:<hash>  context/stories/foo.md
...
sha256:<aggregate>  .
```

---

## The two CI checks

**Check 1 — lock is current on this branch**

Regenerates the lock from the branch's `context/` files and compares against the committed `context.lock`. Fails if they differ — the author changed a story but forgot to run `make context-generate`.

**Check 2 — branch is not behind main (merge-base aware)**

Uses `git merge-base` to find the exact commit where the branch diverged from main. Then computes what changed on main *after* that point:

- New story added to main → PR must have it
- Story updated on main → PR must have main's exact hash (even if PR also edited it — rebase required)
- Story deleted on PR → only flagged if main also changed it after the branch point

The merge-base approach is critical. Without it, the check can't distinguish between "this file was already different before the PR was created" and "this file changed on main after the PR was created."

---

## Regenerating the lock

```bash
make context-generate   # regenerate
make context-validate   # check if stale
make context-check      # run both CI checks locally
```
