---
name: No Code Duplication
description: Search before creating — always check if something already exists
alwaysApply: true
---

Search before creating. Before writing any new function, class, service, serializer, component, or utility — search the codebase to check if it already exists or if something equivalent is available.

Check these locations specifically:
- Backend: `common/`, `apps/core/`, and any app that logically owns the concept
- Frontend: `src/components/`, `src/utils/`, `src/services/`, `uas_frontend/src/`

Extend or reuse existing code rather than creating a parallel implementation.

If something similar exists but doesn't quite fit, flag it to the user and discuss whether to extend it or create a new one — do not silently create a duplicate.

This applies to: utility functions, base classes, mixins, API clients, type definitions, constants, test fixtures, and test factories.
