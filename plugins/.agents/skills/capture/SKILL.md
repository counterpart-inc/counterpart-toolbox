# Skill: Capture Convention

**Trigger**: When a dev makes a systemic change that affects multiple instances of the same pattern (e.g. added a flag to a base class, changed how all emails work, established a new pattern across N files).

**Description**: Document the new convention in the right place in the knowledge hierarchy so future devs and agents follow it.

## Steps

1. **Identify the scope** — ask: "Which module/area does this convention apply to?"
   - If it applies everywhere in the repo → create/update `context/index.md`
   - If it applies to a domain (e.g. all emails) → create/update `apps/notifications/emails/.context.md`
   - If it applies to a specific module → create/update `{module}/.context.md`

2. **Check if a doc already exists** — read the `.context.md` at the identified level if it exists

3. **Draft the convention** using this format:
   ```
   ### [Convention Name]
   **Why**: One sentence on why this exists.
   **Rule**: What to do (imperative).
   **Example**: Short code snippet showing correct usage.
   **Counter-example** (optional): What NOT to do.
   ```

4. **Place the file** — write to the correct location:
   - New file: use the module template from `templates/context/module.md`
   - Existing file: append the new `###` block to the `## Conventions` section

5. **Update the lock** — run:
   ```bash
   yourcounterpart context sync
   ```

6. **Include in your PR** — the `.context.md` change and `context.lock` update ship in the same PR as the code change

## Output

A `.context.md` file at the correct hierarchy level containing the documented convention, and an updated `context.lock`.

## References

- See `references/templates/` for the context template files
- See `references/hierarchy.md` for the layer decision guide
