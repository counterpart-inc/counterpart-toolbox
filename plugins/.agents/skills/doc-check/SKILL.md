# Skill: Doc Check

**Trigger**: Before opening a PR, or when asked to verify that docs are current after a code change.

**Description**: Compare the PR diff against the knowledge hierarchy docs to identify stale or missing documentation.

## Steps

1. **Get the diff** — run:
   ```bash
   git diff main...HEAD --name-only
   ```

2. **For each changed file**, walk up the directory tree to find `.context.md` files:
   ```bash
   # Example for apps/notifications/emails/base.py
   # Check: apps/notifications/emails/.context.md
   # Check: apps/notifications/.context.md
   # Check: apps/.context.md
   # Check: context/index.md (always)
   ```

3. **Read each `.context.md` found** in the affected hierarchy

4. **For each convention in the docs**, reason:
   - Does the diff introduce a new pattern that this convention should document?
   - Does the diff change an existing pattern that this convention describes?
   - Is the convention still accurate given the changes?

5. **Output structured findings** — one line per doc:
   ```
   [STALE] apps/notifications/emails/.context.md — opt-in flag convention needs updating (added recovery_enabled field to EmailBase)
   [OK] apps/notifications/.context.md — no relevant changes
   [MISSING] apps/quote/.context.md — no docs exist for this module but 3 files were changed
   ```

6. **For each STALE or MISSING finding**, offer to:
   - Draft the updated/new convention using the capture skill
   - Or let the dev handle it manually

## Output Format

Structured output — one line per finding:
- `[OK]` — doc exists and is current
- `[STALE]` — doc exists but may need updating (with reason)
- `[MISSING]` — no doc exists for a touched module

Always end with a summary count: `N OK, M STALE, P MISSING`.

## Rules

- Scope analysis to CHANGED files only — do not scan the full repo
- Skip binary files, migrations, test fixtures
- Do NOT auto-update docs — surface findings only, let the human decide
