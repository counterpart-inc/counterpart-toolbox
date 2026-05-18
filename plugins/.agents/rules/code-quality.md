---
name: Code Quality Standards
description: Avoid over-engineering, keep solutions minimal and focused
alwaysApply: true
---

Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.

Do not add features, refactor code, or make improvements beyond what was asked.

Only add comments where the logic isn't self-evident.

Do not add error handling, fallbacks, or validation for scenarios that can't happen.

Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs).

Do not create helpers, utilities, or abstractions for one-time operations.

Do not design for hypothetical future requirements.
