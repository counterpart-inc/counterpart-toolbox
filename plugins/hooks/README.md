# Hooks

Pre-commit and CI hook scripts for repo adoption. Each hook is optional — repos decide whether to wire them up.

## Available Hooks

### `check-context-lock`

Pre-commit hook that warns when `context/` files are staged but `context.lock` is stale.

**Never blocks commits** — warning only. Skippable via `SKIP_CONTEXT_CHECK=1`.

**Adoption** (add to `.pre-commit-config.yaml`):
```yaml
repos:
  - repo: local
    hooks:
      - id: check-context-lock
        name: Check context.lock
        entry: bash .git/hooks/check-context-lock
        language: system
        pass_filenames: false
```

Or install directly:
```bash
cp hooks/check-context-lock .git/hooks/check-context-lock
chmod +x .git/hooks/check-context-lock
```

## CI Script

`ci/check-context-lock.sh` (in counterpart-toolbox) compares `context.lock` on the PR branch vs `main`.

**Warn mode** (default): exits 0, prints warning.
**Hard mode**: `CONTEXT_LOCK_HARD=1 bash ci/check-context-lock.sh` exits 1.

**GitHub Actions adoption**:
```yaml
- name: Check context.lock
  run: bash "${TOOLBOX_DIR}/ci/check-context-lock.sh"
  env:
    CONTEXT_LOCK_HARD: "0"
```
