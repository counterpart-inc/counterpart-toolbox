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

---

## Available Plugin Capabilities

The following skills and agents are installed and ready to use. **Proactively suggest the relevant one** when the user's request matches the trigger — don't wait for them to ask explicitly. Mention the slash command they can type or offer to invoke it directly.

### Planning & Implementation

| Skill | Command | When to suggest |
|-------|---------|-----------------|
| **Plan** | `/cmpd-plan` | User wants to design a feature, needs architecture guidance, or asks "how should I implement X?" — creates a structured plan and optionally a Linear ticket |
| **Work** | `/cmpd-work` | User is ready to implement and has a Linear ticket or plan — handles the full ticket-to-PR workflow |
| **Plan Review** | `/cmpd-plan-review` | User has written a plan and wants expert validation before starting — runs multiple specialist agents in parallel |

### Code Review & Quality

| Skill | Command | When to suggest |
|-------|---------|-----------------|
| **Review** | `/cmpd-review` | User finished a feature or asks "can you review this?" — runs parallel specialized reviewers (security, TypeScript, Django, React, performance) |
| **Fix PR** | `/cmpd-fix-pr` | User has PR review comments to address — analyzes each comment, categorizes it (valid/debatable/incorrect), and implements fixes |
| **Resolve Parallel** | `/cmpd-resolve-parallel` | Multiple TODOs, PR comments, or code review findings need addressing at once — resolves them in parallel |
| **React Best Practices** | `/react-best-practices` | User is writing or reviewing React code — applies performance rules across rendering, re-renders, async, and bundle size |
| **Tailwind Best Practices** | `/tailwind-best-practices` | User is writing Tailwind or CSS Modules — enforces consistent, scalable styling patterns |
| **Web Design Guidelines** | `/web-design-guidelines` | User wants a UI audit — checks accessibility, design consistency, and interface best practices |

### Bug Investigation & Production Issues

| Skill | Command | When to suggest |
|-------|---------|-----------------|
| **Bug Finder** | `/cmpd-bug-finder` | User reports a bug or has a Linear bug ticket — investigates with Sentry data and parallel research agents |
| **Sentry Triage** | `/cmpd-sentry-triage` | User is investigating a production error from Sentry — systematic analysis of error patterns, frequency, and impact |

### Pull Requests & Shipping

| Skill | Command | When to suggest |
|-------|---------|-----------------|
| **Create PR** | `/cmpd-create-pr` | User is ready to ship — creates a high-quality PR with zombie code audit, Linear ticket context, and quality checks |
| **Changelog** | `/cmpd-changelog` | User is preparing a release or wants to summarize what shipped — generates a Slack-ready changelog from git history |

### Issue Tracking (Linear)

| Skill | Command | When to suggest |
|-------|---------|-----------------|
| **Linear** | `/cmpd-linear` | User wants to create a bug report, feature request, or improvement ticket — creates well-structured Linear issues with proper priority and acceptance criteria |
| **Triage** | `/cmpd-triage` | User has a batch of findings (audit, review, tech debt) — categorizes them one by one for Linear ticket creation |

### Framework-Specific Guidance

| Skill | Command | When to suggest |
|-------|---------|-----------------|
| **React Query** | `/react-query` | User is implementing data fetching or mutations — applies TanStack Query patterns with type safety and caching strategy |
| **Django + Vite** | `/django-vite-integration` | User is adding a React component to a Django template or troubleshooting HMR — applies integration patterns |
| **Celery** | `/celery-man` | User is writing a background task or Celery job — enforces idempotency, failure handling, and reliable task patterns |
| **Frontend Design** | `/frontend-design` | User is building UI from scratch — produces production-grade, distinctive interfaces (not generic AI-looking ones) |

### Workflow & Session Management

| Skill | Command | When to suggest |
|-------|---------|-----------------|
| **Compound** | `/cmpd-compound` | End of a productive session — reflects on learnings and updates CLAUDE.md, README, or project docs so future sessions benefit |
| **Git Worktree** | `/cmpd-git-worktree` | User wants to work on multiple branches simultaneously or review a PR in isolation |
| **File Todos** | `/cmpd-file-todos` | User has a complex multi-step task with dependencies — creates tracked work items in `todos/` directory |

### How to invoke
- User can type the slash command directly (e.g. `/cmpd-review`)
- Or ask naturally: "review my code", "create a PR", "I have a bug in production" — you should recognize the intent and offer the skill
