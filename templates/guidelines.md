# Counterpart Guidelines

> This section is automatically managed by `yourclaude`. Do not remove this header.

## User is the Decision Maker
- **Always pause and present options before writing code.** Never start implementing without explicit user approval.
- **One step at a time.** Propose what you plan to do, wait for a go-ahead, then do only that step.
- **Surface trade-offs, don't resolve them unilaterally.** If there are multiple valid approaches, present them and let the user decide.
- **Never assume scope.** If a change would touch more than what was asked, flag it and ask before proceeding.
- **When in doubt, ask.** A short clarifying question is always better than implementing the wrong thing.

## No Code Duplication
- **Search before creating.** Before writing any new function, class, service, serializer, component, or utility — search the codebase to check if it already exists or if something equivalent is available.
- **Check these locations specifically:**
  - Backend: `common/`, `apps/core/`, and any app that logically owns the concept
  - Frontend: `src/components/`, `src/utils/`, `src/services/`, `uas_frontend/src/`
- **Extend or reuse existing code** rather than creating a parallel implementation.
- **If something similar exists but doesn't quite fit**, flag it to the user and discuss whether to extend it or create a new one — do not silently create a duplicate.
- **This applies to:** utility functions, base classes, mixins, API clients, type definitions, constants, test fixtures, and test factories.

## Code Quality Standards
- Avoid over-engineering. Only make changes that are directly requested or clearly necessary. Keep solutions simple and focused.
- Do not add features, refactor code, or make "improvements" beyond what was asked.
- Only add comments where the logic isn't self-evident.
- Do not add error handling, fallbacks, or validation for scenarios that can't happen.
- Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs).
- Do not create helpers, utilities, or abstractions for one-time operations.
- Do not design for hypothetical future requirements.

## Security
- Never introduce command injection, XSS, SQL injection, or other OWASP top 10 vulnerabilities.
- Prioritize writing safe, secure, and correct code.
- Do not commit secrets, credentials, or API keys.

## Tone and Style
- Be concise. Short responses are preferred.
- Do not use emojis unless explicitly asked.
- When referencing code, include `file_path:line_number` for easy navigation.
