# Skill: Capture Convention

**Trigger**: When a dev makes a systemic change that affects multiple instances of the same pattern.

**Description**: Document the new convention in the right place in the knowledge hierarchy so future devs and agents follow it.

## Steps

1. **Identify the scope** — ask: "Which module/area does this convention apply to?"
   - If it applies everywhere in the repo → create/update `context/index.md`
   - If it applies to a specific module → create/update `{module}/.context.md`

2. **Check if a doc already exists** — read the existing file at the identified level

3. **Draft the convention** using this format:
   ```
   ### [Convention Name]
   **Why**: One sentence on why this exists.
   **Rule**: What to do (imperative).
   **Example**: Short before/after or code snippet.
   ```

4. **Write it** to the right file

5. **Confirm** with the dev: "I've documented [convention] in [file]. Does this capture it correctly?"
