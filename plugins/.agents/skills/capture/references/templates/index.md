# [REQUIRED] Project Name

Brief 1-2 sentence description of what this repo does and who uses it.

## [REQUIRED] Quick Start

Prerequisites and how to run locally:

```bash
# Example commands — replace with actual project commands
make install
make run
```

Key URLs:
- Local: http://localhost:8000
- Admin: http://localhost:8000/admin

## [REQUIRED] Architecture Overview

High-level description of the system. Key apps/modules:

| Module | What it does |
|--------|-------------|
| `apps/core/` | Shared models and utilities |
| `apps/[domain]/` | [Domain description] |

Directory structure:

```
[repo-root]/
├── apps/           # Django apps / feature modules
├── common/         # Shared utilities (not Django apps)
├── settings/       # Environment-specific settings
└── context/        # This knowledge layer
    ├── index.md    # You are here
    ├── project-summaries/  # Detailed subsystem docs
    └── stories/    # User story context
```

## [REQUIRED] Key Conventions

The most important patterns a dev must know before touching this codebase:

- [Convention 1]: Brief description. See `[path/.context.md]` for details.
- [Convention 2]: Brief description.

> For module-specific conventions, read the `.context.md` file in the relevant directory.

## [OPTIONAL] Key Integrations

External services and APIs this repo depends on:

| Service | Purpose | Docs |
|---------|---------|------|
| [Service] | [What it does] | [Link or path] |

## [OPTIONAL] Domain Map

Domains in this repo with their context files:

- [`apps/[domain]/`]([path]) — [What this domain owns]

## [OPTIONAL] Tech Stack

- **Language**: [e.g. Python 3.12]
- **Framework**: [e.g. Django 4.2]
- **Database**: [e.g. PostgreSQL]
- **Task queue**: [e.g. Celery + Redis]
- **Tests**: [e.g. pytest]
