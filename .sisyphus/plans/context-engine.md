# Context Engine

## TL;DR

> **Quick Summary**: Transform `counterpart-toolbox` from a Claude Code wrapper into an agent-agnostic installer + syncer that distributes company skills, rules, and agents to every dev's AI tool — regardless of which one they use. Layer on top a knowledge system (`context/` + `context.lock`) that captures and enforces codebase conventions organically as PRs flow.
>
> **Deliverables**:
> - `yourcounterpart` CLI (renamed, no longer a wrapper — installer/syncer)
> - Sync engine: reads canonical `.agents/` hierarchy, writes to each detected agent's native format
> - `counterpart-plugins` restructured to `.agents/` format (agents, rules, skills, MCP)
> - `context.lock` mechanism + CI check script (for repos to adopt)
> - Hook script implementations in `counterpart-plugins` (for repos to adopt)
> - Reference implementation in `counterpart` repo
>
> **Estimated Effort**: XL
> **Parallel Execution**: YES — 4 waves
> **Critical Path**: T1 (rename/restructure) → T4 (sync engine) → T8 (plugins restructure) → T13 (reference impl)

---

## Context

### Original Request
Build an end-to-end system that transfers codebase knowledge between 40+ devs using different AI agents. Agent-agnostic. Conventions captured at implementation time. Enforced via lock file + CI.

### Architecture Decisions

**Toolbox is NOT a wrapper** — it's an installer + syncer.
- Old model: `yourclaude` wraps `claude`, intercepts every session
- New model: `yourcounterpart setup/update` installs company defaults into whatever agents the dev uses. Dev opens their agent directly — it already has the right context.

**Hierarchy (global → repo):**
```
~/.agents/               ← toolbox installs here (company defaults)
  agents/                ← default agent (company guidelines)
  rules/                 ← company-wide rules
  skills/                ← company skills
  mcp.json               ← company MCP servers

{repo}/.agents/          ← repo-specific extensions (layered on top)
  agents/
  rules/
  skills/

{repo}/context/          ← knowledge layer (owned by repo)
  project-summaries/
  stories/
  index.md               ← entry point for AI discovery

{repo}/context.lock      ← SHA256 hash of all context/ files
```

**Sync model (borrowed from Agentloom):**
- `syncFromCanonical` reads `~/.agents/` (global) + `{cwd}/.agents/` (local)
- Merges (local extends global — never overrides)
- Writes to each detected agent's native format:
  - Claude Code → `~/.claude/CLAUDE.md` (global) + `AGENTS.md` in repo (local)
  - Cursor → `~/.cursor/rules/` (global) + `.cursor/rules/` in repo (local)
  - OpenCode → `~/.config/opencode/AGENTS.md` (global) + `AGENTS.md` in repo (local)
  - Copilot → `~/.copilot/copilot-instructions.md` (global) + `.github/copilot-instructions.md` (local)
  - Pi → `~/.pi/` (global)

**Enforcement is repo-owned:**
- Pre-commit hooks: repos adopt from `counterpart-plugins` if they want
- CI checks: repos adopt from `counterpart-plugins` if they want
- Toolbox provides the implementations, not the enforcement

**New dev flow (ideal):**
1. Get AI provider accounts + clone repos (standard)
2. Install toolbox: `curl ... | bash`
3. `yourcounterpart setup`: detects installed agents, syncs company defaults
4. Open any agent — it already has the right context + skills
5. Work normally

### Research Findings
- Agentloom (`farnoodma/agentloom`) solved the multi-agent sync problem with `.agents/` canonical structure + `syncFromCanonical`. We borrow the architecture, not the tool.
- `AGENTS.md` is the de facto universal standard (Linux Foundation, 25+ agents). Use it as the primary output format.
- Managed blocks pattern: inject company rules into agent instruction files without replacing hand-written content.
- Skills: `SKILL.md` + `references/` + `assets/` — portable across agents.

### Metis Review
**Identified Gaps** (addressed):
- context.lock determinism: SHA256 of sorted file paths + contents
- Escape hatch: hooks are repo-owned — each repo decides enforcement
- Lock flaw: lock + doc-check skill are complementary enforcement mechanisms
- Tech stack: TypeScript for sync engine (bash insufficient for YAML frontmatter, manifest tracking, provider logic)

---

## Work Objectives

### Core Objective
An agent-agnostic toolbox that any dev can install once and have company-standard context, skills, and rules in whatever AI tool they use — without changing their workflow.

### Concrete Deliverables

**counterpart-toolbox:**
- `yourcounterpart` CLI (replaces `yourclaude`)
- `lib/sync/` — TypeScript sync engine (ported from Agentloom pattern)
- `lib/setup.sh` + `lib/update.sh` — setup/update commands
- `templates/agents/` — default agent template
- `templates/context/` — hierarchy layer templates (repo, scope, module)
- `templates/plugin-manifest.json` — plugin manifest schema

**counterpart-plugins (restructured):**
- `.agents/agents/default.md` — company default agent
- `.agents/rules/` — company rules (from existing guidelines.md)
- `.agents/skills/` — company skills (capture, doc-check, pr-create, etc.)
- `.agents/mcp.json` — company MCP servers
- `hooks/check-context-lock` — pre-commit hook script (repos adopt)
- `hooks/doc-check` — doc-check hook script (repos adopt)
- `ci/check-context-lock.sh` — CI check script (repos adopt)

**counterpart repo (reference implementation):**
- `.agents/` — repo-specific extensions
- `context/` — project-summaries/, stories/, index.md
- `context.lock`
- `AGENTS.md` (generated by sync)

### Definition of Done
- [ ] `yourcounterpart setup` runs on a fresh machine, detects Claude Code + Cursor, writes to both
- [ ] `yourcounterpart update` pulls latest plugins and re-syncs
- [ ] Dev opens Cursor after setup — sees company rules in `.cursor/rules/`
- [ ] Dev opens Claude Code — sees company rules in `CLAUDE.md`
- [ ] Repo `.agents/rules/` extend (not replace) global rules
- [ ] `context.lock` is byte-identical across two fresh clones of the same repo
- [ ] CI check exits non-zero when lock is behind main
- [ ] Capture skill drafts a `.context.md` file in the correct location

### Must Have
- Agent-agnostic — works for Claude Code, Cursor, Copilot, OpenCode, Pi, Gemini
- Non-destructive sync — managed blocks, never replaces hand-written content
- Hierarchy: global defaults always apply, repo extends, never overrides global
- `context.lock` is deterministic (SHA256, sorted paths + contents)
- New dev: one install command → everything works

### Must NOT Have
- No launch wrapping — toolbox does NOT intercept agent sessions
- No automatic convention detection — skill drafts, human approves
- No global enforcement of pre-commit/CI — that's repo-owned
- No public skills registry — `counterpart-plugins` is the only source
- No agent-specific permanent files generated outside of sync (sync owns what it writes)

---

## Verification Strategy

### Test Decision
- **Infrastructure**: TypeScript + bun test for sync engine
- **Automated tests**: unit tests for sync logic, integration tests for agent output
- **Shell scripts**: manual verification via test fixtures

### QA Policy
Every task verified by direct execution. Evidence saved to `.sisyphus/evidence/`.

---

## Execution Strategy

### Parallel Execution Waves

```
Wave 1 (Foundation — no dependencies, all parallel):
├── T1: Rename + restructure toolbox (yourclaude → yourcounterpart, remove wrapper logic)
├── T2: Define knowledge hierarchy spec + context/ templates
└── T3: Plugin manifest schema + .agents/ structure standard

Wave 2 (Sync engine — depends on T1, T3):
├── T4: TypeScript sync engine (syncFromCanonical, provider-paths, managed blocks)
├── T5: yourcounterpart setup command (detect agents, initial global sync)
├── T6: yourcounterpart update command (pull plugins, re-sync)
└── T7: context.lock mechanism (generate, validate, CI check script)

Wave 3 (Plugins restructure — depends on T2, T3):
├── T8: Restructure counterpart-plugins to .agents/ format
├── T9: Default agent + company rules (migrate from guidelines.md)
├── T10: Capture skill
├── T11: Doc-check skill
└── T12: Hook + CI scripts (check-context-lock, doc-check)

Wave 4 (Reference implementation — depends on all above):
└── T13: Apply to counterpart repo

Wave FINAL:
├── F1: Plan compliance audit (oracle)
├── F2: End-to-end functional QA (unspecified-high)
└── F3: Scope fidelity check (deep)
```

### Dependency Matrix
- T4, T5, T6: depends on T1, T3
- T7: depends on T1
- T8, T9: depends on T3
- T10, T11, T12: depends on T2, T3
- T13: depends on T4, T5, T7, T8, T9

### Agent Dispatch Summary
- **Wave 1**: T1 `unspecified-high`, T2 `writing`, T3 `quick`
- **Wave 2**: T4 `deep`, T5/T6 `unspecified-high`, T7 `unspecified-high`
- **Wave 3**: T8 `unspecified-high`, T9 `writing`, T10/T11 `unspecified-high`, T12 `quick`
- **Wave 4**: T13 `deep`
- **Final**: `oracle`, `unspecified-high`, `deep`

---

## TODOs

- [x] 1. Rename + restructure toolbox

  **What to do**:
  - Rename `yourclaude` → `yourcounterpart` throughout (script, README, install.sh, completions)
  - Remove wrapper logic: strip out `claude` CLI launch, `--append-system-prompt`, plugin installation via Claude Code marketplace
  - Remove `check_claude.sh`, `check_plugins.sh` (replaced by sync engine)
  - Keep: `check_tools.sh` (still useful), `check_mcp.sh` (still useful), install/update/setup flow skeleton
  - Add `lib/sync/` directory (empty, for T4)
  - Update README to reflect new model (installer/syncer, not wrapper)
  - Update `install.sh` to symlink `yourcounterpart`
  - Update shell completions

  **Must NOT do**:
  - Do not implement sync logic here (that's T4)
  - Do not remove the submodule setup (counterpart-plugins stays)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T4, T5, T6, T7
  - **Blocked By**: None

  **References**:
  - `yourclaude` — main script to rename/refactor
  - `lib/check_claude.sh` — delete
  - `lib/check_plugins.sh` — delete
  - `install.sh` — update symlink target
  - `completions/yourclaude.zsh`, `completions/yourclaude.bash` — rename

  **Acceptance Criteria**:
  - [ ] `yourcounterpart --help` works
  - [ ] `yourclaude` symlink removed
  - [ ] `install.sh` installs `yourcounterpart`
  - [ ] No references to `claude` CLI in the main script

  **QA Scenarios**:
  ```
  Scenario: Fresh install produces yourcounterpart
    Tool: Bash
    Steps:
      1. Run: bash install.sh from a clean directory
      2. Run: which yourcounterpart
      3. Run: yourcounterpart --help
    Expected: exits 0, shows help text with "yourcounterpart"
    Evidence: .sisyphus/evidence/task-1-install.txt

  Scenario: Old yourclaude command is gone
    Tool: Bash
    Steps:
      1. Run: which yourclaude
    Expected: exit non-zero, command not found
    Evidence: .sisyphus/evidence/task-1-rename.txt
  ```

  **Commit**: YES
  - Message: `refactor(toolbox): rename yourclaude → yourcounterpart, remove wrapper logic`

---

- [x] 2. Knowledge hierarchy spec + context/ templates

  **What to do**:
  - Write `templates/context/README.md` — the spec: what each layer is (company, repo, scope, module), what belongs at each level, ownership rules
  - Write `templates/context/repo.md` — template for repo-level context doc (what is this repo, architecture, how to run, key integrations)
  - Write `templates/context/scope.md` — template for scope/domain-level doc (what this domain does, key flows, data models)
  - Write `templates/context/module.md` — template for module-level doc (conventions, patterns, examples, counter-examples)
  - Write `templates/context/index.md` — template for the `context/index.md` entry point file
  - Required sections per layer clearly marked. Optional sections marked.
  - All templates are plain markdown, agent-agnostic

  **Must NOT do**:
  - Do not write actual Counterpart-specific content (that's T13)
  - Do not add agent-specific syntax

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T10, T11, T12
  - **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] 5 template files exist in `templates/context/`
  - [ ] Each template has clearly marked required vs optional sections
  - [ ] Spec doc explains the 4 layers and ownership model

  **QA Scenarios**:
  ```
  Scenario: Templates are complete and structured
    Tool: Bash
    Steps:
      1. Run: ls templates/context/
      2. Run: grep "Required" templates/context/repo.md
      3. Run: grep "Optional" templates/context/repo.md
    Expected: 5 files, both Required and Optional markers present
    Evidence: .sisyphus/evidence/task-2-templates.txt
  ```

  **Commit**: YES
  - Message: `docs(toolbox): add knowledge hierarchy spec and context templates`

---

- [x] 3. Plugin manifest schema + .agents/ structure standard

  **What to do**:
  - Write `templates/plugin-manifest.json` — JSON schema for a plugin manifest (name, version, description, type, skills[], rules[], agents[], mcp)
  - Write `templates/agents-structure.md` — the canonical `.agents/` directory structure spec (mirroring Agentloom's layout: agents/, commands/, rules/, skills/, mcp.json, agents.lock.json)
  - Define the skill format: `SKILL.md` + optional `references/` + `assets/`
  - Define the rule frontmatter schema: `name`, `description`, `globs`, `alwaysApply`, provider-specific overrides
  - Define the agent frontmatter schema: `name`, `description`, provider-specific blocks
  - Reference: `/tmp/agentloom/packages/cli/README.md` for schemas

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 1
  - **Blocks**: T4, T5, T6, T8, T9
  - **Blocked By**: None

  **Acceptance Criteria**:
  - [ ] `templates/plugin-manifest.json` is valid JSON with all required fields
  - [ ] `templates/agents-structure.md` documents the full `.agents/` layout

  **QA Scenarios**:
  ```
  Scenario: Manifest schema is valid JSON
    Tool: Bash
    Steps:
      1. Run: jq . templates/plugin-manifest.json
    Expected: exits 0, valid JSON output
    Evidence: .sisyphus/evidence/task-3-manifest.txt
  ```

  **Commit**: YES (groups with T1)
  - Message: `docs(toolbox): add plugin manifest schema and .agents/ structure spec`

---

- [x] 4. TypeScript sync engine

  **What to do**:
  - Init TypeScript project in `lib/sync/` (bun, tsconfig, package.json)
  - Port Agentloom's core sync architecture:
    - `provider-paths.ts` — where each agent stores its config (Claude, Cursor, Copilot, OpenCode, Pi, Gemini)
    - `sync.ts` — `syncFromCanonical(globalAgentsDir, localAgentsDir?, providers[])` function
    - `agents.ts` — parse `.agents/agents/*.md` (YAML frontmatter + body)
    - `rules.ts` — parse `.agents/rules/*.md`, render for each provider, upsert managed blocks
    - `skills.ts` — copy `.agents/skills/` to provider skill dirs
    - `mcp.ts` — read `.agents/mcp.json`, write to each provider's MCP config
    - `manifest.ts` — read/write `.sync-manifest.json` (track generated files)
    - `fs.ts` — atomic writes, ensure dirs
  - Managed blocks: inject company rules into agent files between `<!-- agentloom:managed:start -->` / `<!-- agentloom:managed:end -->` markers (or counterpart equivalent)
  - Hierarchy merge: global `.agents/` is the floor, local extends — rules are additive, agents are merged by name
  - Support providers: `claude`, `cursor`, `copilot`, `opencode`, `pi`, `gemini`

  **Must NOT do**:
  - Do not implement the setup/update CLI commands (that's T5/T6)
  - Do not build agent detection (that's T5)
  - Do not implement context.lock (that's T7)

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T5, T6, T7)
  - **Parallel Group**: Wave 2
  - **Blocks**: T5, T6, T13
  - **Blocked By**: T1, T3

  **References**:
  - `/tmp/agentloom/packages/cli/src/sync/index.ts` — core sync logic to port
  - `/tmp/agentloom/packages/cli/src/core/provider-paths.ts` — provider path resolution
  - `/tmp/agentloom/packages/cli/src/core/rules.ts` — managed blocks pattern
  - `/tmp/agentloom/packages/cli/src/core/agents.ts` — agent parsing
  - `/tmp/agentloom/packages/cli/src/types.ts` — type definitions

  **Acceptance Criteria**:
  - [ ] `bun test lib/sync/` passes
  - [ ] `syncFromCanonical` with test fixtures writes correct files for claude + cursor
  - [ ] Managed blocks: running sync twice produces identical output (idempotent)
  - [ ] Local rules extend global rules (both appear in output)

  **QA Scenarios**:
  ```
  Scenario: Sync writes to Claude and Cursor from test fixtures
    Tool: Bash
    Steps:
      1. Create test fixture: ~/.agents/rules/test-rule.md with name: "test-rule"
      2. Run: bun run lib/sync/test-sync.ts --providers claude,cursor
      3. Check: cat ~/.claude/CLAUDE.md | grep "test-rule"
      4. Check: ls ~/.cursor/rules/ | grep "test-rule"
    Expected: rule appears in both agent configs
    Evidence: .sisyphus/evidence/task-4-sync.txt

  Scenario: Sync is idempotent
    Tool: Bash
    Steps:
      1. Run sync twice on same fixtures
      2. diff output of run 1 vs run 2
    Expected: identical output, no duplicated managed blocks
    Evidence: .sisyphus/evidence/task-4-idempotent.txt
  ```

  **Commit**: YES
  - Message: `feat(toolbox): add TypeScript sync engine`

---

- [x] 5. `yourcounterpart setup` command

  **What to do**:
  - Implement `yourcounterpart setup` in the main bash script (calls into TypeScript sync engine)
  - Agent detection: check for `claude`, `cursor`, `code` (Copilot), `opencode`, `gemini` binaries + config dirs
  - Interactive: "Which agents do you use?" with detected ones pre-selected
  - Store selected providers in `~/.config/counterpart/config.json` (`providers` key)
  - Clone/pull `counterpart-plugins` to `~/.local/share/counterpart/plugins/`
  - Run `syncFromCanonical(~/.agents/, null, selectedProviders)` with plugins as source
  - Show summary: "Synced N rules, M skills to Claude Code, Cursor"
  - Idempotent: re-running is safe, re-syncs without breaking

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T6, T7)
  - **Parallel Group**: Wave 2
  - **Blocks**: T13
  - **Blocked By**: T1, T3, T4

  **Acceptance Criteria**:
  - [ ] `yourcounterpart setup` runs to completion on a test machine
  - [ ] `~/.config/counterpart/config.json` contains `providers` array
  - [ ] Company rules appear in selected agent config locations
  - [ ] Re-running setup does not duplicate content

  **QA Scenarios**:
  ```
  Scenario: Setup detects and configures Claude Code
    Tool: Bash
    Steps:
      1. Ensure claude CLI is installed
      2. Run: yourcounterpart setup --yes --providers claude
      3. Check: cat ~/.claude/CLAUDE.md | grep "Counterpart"
      4. Check: cat ~/.config/counterpart/config.json | jq .providers
    Expected: CLAUDE.md has Counterpart managed block, config has ["claude"]
    Evidence: .sisyphus/evidence/task-5-setup-claude.txt

  Scenario: Setup is idempotent
    Tool: Bash
    Steps:
      1. Run setup twice
      2. grep -c "counterpart:managed" ~/.claude/CLAUDE.md
    Expected: managed block appears exactly once
    Evidence: .sisyphus/evidence/task-5-idempotent.txt
  ```

  **Commit**: YES (groups with T6)
  - Message: `feat(toolbox): add yourcounterpart setup command`

---

- [x] 6. `yourcounterpart update` command

  **What to do**:
  - Implement `yourcounterpart update`
  - Pull latest `counterpart-plugins` (git pull on `~/.local/share/counterpart/plugins/`)
  - Re-run `syncFromCanonical` with existing providers from config
  - Pull latest toolbox itself (git pull on toolbox repo)
  - Show diff summary: "Updated N rules, added M skills"
  - Also sync any repo-local `.agents/` if CWD has one (run local sync after global)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T5, T7)
  - **Parallel Group**: Wave 2
  - **Blocks**: T13
  - **Blocked By**: T1, T3, T4

  **Acceptance Criteria**:
  - [ ] `yourcounterpart update` pulls latest plugins and re-syncs
  - [ ] After update, new rules added to plugins appear in agent configs
  - [ ] CWD with `.agents/` gets local sync applied on top of global

  **QA Scenarios**:
  ```
  Scenario: Update propagates new rule from plugins
    Tool: Bash
    Steps:
      1. Add a new rule file to counterpart-plugins .agents/rules/
      2. Run: yourcounterpart update
      3. Check rule appears in ~/.claude/CLAUDE.md
    Expected: new rule in managed block
    Evidence: .sisyphus/evidence/task-6-update.txt
  ```

  **Commit**: YES (groups with T5)
  - Message: `feat(toolbox): add yourcounterpart update command`

---

- [x] 7. context.lock mechanism

  **What to do**:
  - Implement `lib/context-lock.sh` (bash) or `lib/sync/context-lock.ts`:
    - `context-lock generate` — SHA256 hash of all files under `context/`, sorted by relative path, write to `context.lock`
    - `context-lock validate` — compare current hash vs `context.lock`, exit 0 if match, 1 if stale
    - Hash format: `sha256:<hash>  context/<path>` per line (like sha256sum output), final line: `sha256:<aggregate-hash>  .`
  - Implement `ci/check-context-lock.sh` — reads `context.lock` from PR branch and from main branch (via git), exits non-zero if different; warn mode by default (exit 0 with warning message), hard mode via `CONTEXT_LOCK_HARD=1`
  - Add `yourcounterpart context sync` — alias for `context-lock generate` + stage `context.lock`
  - Add `yourcounterpart context validate` — alias for `context-lock validate`

  **Must NOT do**:
  - Do not hash files outside `context/`
  - Do not auto-commit the lock file

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T4, T5, T6)
  - **Parallel Group**: Wave 2
  - **Blocks**: T12, T13
  - **Blocked By**: T1

  **Acceptance Criteria**:
  - [ ] `yourcounterpart context sync` generates `context.lock` in a repo with `context/`
  - [ ] Modifying any file under `context/` causes `validate` to exit 1
  - [ ] `context.lock` is byte-identical across two fresh clones of the same repo
  - [ ] CI script exits non-zero when lock differs from main

  **QA Scenarios**:
  ```
  Scenario: Lock is deterministic across clones
    Tool: Bash
    Steps:
      1. Clone repo to two directories
      2. Run context sync in both
      3. diff dir1/context.lock dir2/context.lock
    Expected: identical files
    Evidence: .sisyphus/evidence/task-7-deterministic.txt

  Scenario: Validate detects stale lock
    Tool: Bash
    Steps:
      1. Run context sync (generates lock)
      2. echo "# change" >> context/index.md
      3. Run: yourcounterpart context validate
    Expected: exit 1 with "context.lock is stale" message
    Evidence: .sisyphus/evidence/task-7-stale.txt
  ```

  **Commit**: YES
  - Message: `feat(toolbox): add context.lock mechanism`

---

- [x] 8. Restructure counterpart-plugins to .agents/ format

  **What to do**:
  - Migrate existing plugin structure to canonical `.agents/` layout:
    ```
    .agents/
      agents/
      commands/
      rules/
      skills/
      mcp.json
      agents.lock.json
    ```
  - Move existing skills to `.agents/skills/<skill-name>/SKILL.md`
  - Move existing rules/guidelines to `.agents/rules/`
  - Create `agents.lock.json` (empty initially)
  - Create `.agents/mcp.json` with existing MCP server definitions (linear, sentry, context7)
  - Update `counterpart-toolbox/.gitmodules` if paths change
  - Remove old structure (whatever was there before)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES (with T9, T10, T11, T12)
  - **Parallel Group**: Wave 3
  - **Blocks**: T13
  - **Blocked By**: T3

  **References**:
  - `/tmp/agentloom/packages/cli/README.md` — canonical layout spec
  - `counterpart-plugins/` — current structure to migrate
  - `templates/agents-structure.md` — target structure (from T3)

  **Acceptance Criteria**:
  - [ ] `.agents/` directory exists with correct subdirectories
  - [ ] All existing skills accessible under `.agents/skills/`
  - [ ] `agents.lock.json` exists (valid JSON)
  - [ ] `mcp.json` has linear, sentry, context7 server definitions

  **QA Scenarios**:
  ```
  Scenario: Skills are accessible in new structure
    Tool: Bash
    Steps:
      1. ls counterpart-plugins/.agents/skills/
      2. Verify at least 3 skills present with SKILL.md
    Expected: skills directory with SKILL.md files
    Evidence: .sisyphus/evidence/task-8-structure.txt
  ```

  **Commit**: YES
  - Message: `refactor(plugins): migrate to .agents/ canonical structure`

---

- [x] 9. Default agent + company rules

  **What to do**:
  - Write `.agents/agents/default.md` — the company default agent:
    - Frontmatter: `name: counterpart-default`, description, provider-specific overrides (claude: model, cursor: etc.)
    - Body: company-level instructions (migrate from existing `templates/guidelines.md` content)
    - Include instruction: "Always read `context/index.md` in the current repo before starting work"
  - Migrate existing rules from `templates/guidelines.md` into individual rule files under `.agents/rules/`:
    - `no-code-duplication.md`
    - `code-quality.md`
    - `security.md`
    - `user-is-decision-maker.md`
  - Each rule: proper frontmatter (`name`, `description`, `alwaysApply: true`)
  - Remove `templates/guidelines.md` (content now lives in rules + default agent)

  **Recommended Agent Profile**:
  - **Category**: `writing`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: T13
  - **Blocked By**: T3

  **References**:
  - `templates/guidelines.md` — source content to migrate
  - `/tmp/agentloom/packages/cli/README.md` — rule + agent frontmatter schema

  **Acceptance Criteria**:
  - [ ] `.agents/agents/default.md` exists with valid frontmatter
  - [ ] At least 4 rule files under `.agents/rules/`
  - [ ] Each rule has `name` and `alwaysApply: true` in frontmatter
  - [ ] "read context/index.md" instruction present in default agent body

  **QA Scenarios**:
  ```
  Scenario: Default agent has valid frontmatter
    Tool: Bash
    Steps:
      1. Run: head -20 counterpart-plugins/.agents/agents/default.md
      2. Check YAML frontmatter is parseable
    Expected: valid YAML between --- markers with name field
    Evidence: .sisyphus/evidence/task-9-agent.txt
  ```

  **Commit**: YES (groups with T8)
  - Message: `feat(plugins): add default agent and company rules`

---

- [x] 10. Capture skill

  **What to do**:
  - Write `.agents/skills/capture/SKILL.md` — skill that helps a dev document a new convention
  - Skill behavior:
    1. Ask: "What module/area does this convention apply to?" → determines hierarchy level
    2. Ask: "Describe the pattern" → draft the convention
    3. Read existing `.context.md` at that level if it exists
    4. Draft new entry using the module template (from T2)
    5. Place file at correct location in the repo
    6. Run `yourcounterpart context sync` to update context.lock
  - Format: plain markdown, agent-agnostic (no Claude-specific syntax)
  - Include `references/` with the context templates (symlink or copy from T2)

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocks**: T13
  - **Blocked By**: T2, T3

  **Acceptance Criteria**:
  - [ ] `SKILL.md` exists with clear step-by-step workflow
  - [ ] Skill correctly identifies the right hierarchy level from file path
  - [ ] Skill references the correct template for the identified level

  **QA Scenarios**:
  ```
  Scenario: Capture skill drafts a module-level convention
    Tool: Bash (agent execution)
    Steps:
      1. Open agent in a repo with apps/notifications/emails/
      2. Invoke capture skill
      3. Input: module = "apps/notifications/emails", pattern = "opt-in flag"
      4. Verify: apps/notifications/emails/.context.md created
    Expected: .context.md file with correct template structure at module level
    Evidence: .sisyphus/evidence/task-10-capture.txt
  ```

  **Commit**: YES (groups with T11)
  - Message: `feat(plugins): add capture and doc-check skills`

---

- [x] 11. Doc-check skill

  **What to do**:
  - Write `.agents/skills/doc-check/SKILL.md` — skill that compares PR diff against docs hierarchy
  - Skill behavior:
    1. Get diff: `git diff main...HEAD --name-only`
    2. For each changed file, walk up directory tree to find `.context.md` files
    3. Read each `.context.md` in the affected hierarchy
    4. For each convention/rule in the docs, reason: "does this diff violate or require updating this rule?"
    5. Output structured findings: `[STALE] apps/notifications/emails/.context.md — opt-in flag convention may need updating`
    6. Output: `[OK]` for docs that are current
  - Output must be structured (parseable), not prose
  - Scope: only changed files, not full repo scan

  **Recommended Agent Profile**:
  - **Category**: `unspecified-high`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocked By**: T2, T3

  **Acceptance Criteria**:
  - [ ] Skill produces structured output (STALE/OK per doc)
  - [ ] Correctly identifies stale doc when diff touches a module with a known convention
  - [ ] Correctly outputs OK when diff is doc-only

  **QA Scenarios**:
  ```
  Scenario: Detects stale doc when module changed without doc update
    Tool: Bash (agent execution)
    Steps:
      1. Create .context.md with a convention at apps/notifications/emails/
      2. Modify apps/notifications/emails/base.py
      3. Do NOT update .context.md
      4. Run doc-check skill
    Expected: output contains [STALE] apps/notifications/emails/.context.md
    Evidence: .sisyphus/evidence/task-11-stale.txt

  Scenario: OK on doc-only PR
    Tool: Bash
    Steps:
      1. Only modify a .context.md file
      2. Run doc-check skill
    Expected: no STALE findings
    Evidence: .sisyphus/evidence/task-11-ok.txt
  ```

  **Commit**: YES (groups with T10)

---

- [x] 12. Hook + CI scripts

  **What to do**:
  - Write `hooks/check-context-lock` — pre-commit hook script:
    - Checks if any files under `context/` were staged
    - If yes: runs `yourcounterpart context validate`
    - If stale: prints warning with instructions to run `yourcounterpart context sync`
    - Never exits non-zero (prompt only, never blocks)
    - Skippable via `SKIP_CONTEXT_CHECK=1`
  - Write `ci/check-context-lock.sh` — CI script:
    - Compares `context.lock` on current branch vs `main`
    - Warn mode (default): exits 0, prints warning
    - Hard mode (`CONTEXT_LOCK_HARD=1`): exits 1
  - Write `hooks/doc-check` — pre-commit hook that invokes doc-check skill
  - Include `README.md` in `hooks/` explaining how repos adopt these

  **Recommended Agent Profile**:
  - **Category**: `quick`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: YES
  - **Parallel Group**: Wave 3
  - **Blocked By**: T2, T3, T7

  **Acceptance Criteria**:
  - [ ] `hooks/check-context-lock` is executable, never exits non-zero
  - [ ] `ci/check-context-lock.sh` exits 1 in hard mode when lock differs
  - [ ] `SKIP_CONTEXT_CHECK=1` bypasses the hook
  - [ ] `hooks/README.md` explains adoption

  **QA Scenarios**:
  ```
  Scenario: Pre-commit hook warns but does not block
    Tool: Bash
    Steps:
      1. Stage a change to context/index.md without running context sync
      2. Run: bash hooks/check-context-lock
    Expected: exit 0 with warning message
    Evidence: .sisyphus/evidence/task-12-hook.txt

  Scenario: CI script exits 1 in hard mode
    Tool: Bash
    Steps:
      1. Modify context/index.md, do NOT run context sync
      2. Run: CONTEXT_LOCK_HARD=1 bash ci/check-context-lock.sh
    Expected: exit 1
    Evidence: .sisyphus/evidence/task-12-ci.txt
  ```

  **Commit**: YES
  - Message: `feat(plugins): add hook and CI scripts for context.lock enforcement`

---

- [x] 13. Reference implementation in counterpart repo

  **What to do**:
  - Create `context/index.md` using the index template (from T2) — Counterpart-specific content
  - Create `context/project-summaries/` with at least one summary (overall system, email system)
  - Create `context/stories/` (empty dir with `.gitkeep` — populated organically over time)
  - Run `yourcounterpart context sync` → generates `context.lock`
  - Create `.agents/` with repo-specific extensions:
    - `.agents/rules/counterpart-conventions.md` — repo-specific rules (from existing `.agent-rules/` content)
    - `.agents/agents.lock.json` (empty)
  - Create `AGENTS.md` at repo root by running `yourcounterpart update` in the repo
  - Deprecate/remove: `.agent-rules/`, `.cursor/rules/` (Cursor-specific), `.github/instructions/` (content migrated to `.agents/rules/`)
  - Add `context.lock` to `.gitignore`? No — commit it. It should be versioned.
  - Wire up CI: add `ci/check-context-lock.sh` call to existing pipeline (warn mode)
  - Wire up pre-commit: add `hooks/check-context-lock` to `.pre-commit-config.yaml`

  **Recommended Agent Profile**:
  - **Category**: `deep`
  - **Skills**: []

  **Parallelization**:
  - **Can Run In Parallel**: NO
  - **Parallel Group**: Wave 4 (sequential, after all above)
  - **Blocked By**: T4, T5, T7, T8, T9

  **References**:
  - `counterpart/.agent-rules/` — content to migrate
  - `counterpart/.github/instructions/` — content to migrate
  - `counterpart/.cursor/rules/` — content to migrate (if any)
  - `templates/context/` — templates to use (from T2)
  - `templates/context/index.md` — index template

  **Acceptance Criteria**:
  - [ ] `context/index.md` exists with Counterpart-specific content
  - [ ] `context.lock` exists and validates
  - [ ] `.agents/rules/counterpart-conventions.md` has migrated content
  - [ ] `AGENTS.md` exists at repo root (generated by sync)
  - [ ] Old `.agent-rules/` removed or deprecated
  - [ ] CI pipeline includes context lock check
  - [ ] `yourcounterpart update` in counterpart repo produces valid output

  **QA Scenarios**:
  ```
  Scenario: Full setup works end-to-end in counterpart repo
    Tool: Bash
    Steps:
      1. Run: yourcounterpart setup in counterpart repo
      2. Check: AGENTS.md exists at repo root
      3. Check: context.lock exists
      4. Run: yourcounterpart context validate
      5. Open Claude Code — verify context/index.md instruction is present
    Expected: all checks pass, AGENTS.md has counterpart managed block
    Evidence: .sisyphus/evidence/task-13-e2e.txt

  Scenario: context.lock CI check passes on fresh clone
    Tool: Bash
    Steps:
      1. Clone counterpart to a temp dir
      2. Run: bash ci/check-context-lock.sh
    Expected: exit 0 (lock is current)
    Evidence: .sisyphus/evidence/task-13-ci.txt
  ```

  **Commit**: YES
  - Message: `feat(counterpart): add context layer and .agents/ reference implementation`

---

## Final Verification Wave

- [ ] F1. **Plan Compliance Audit** — `oracle`
  Read plan end-to-end. Verify each Must Have is implemented. Search for any Must NOT Have violations. Check evidence files exist. Output: `APPROVE/REJECT`.

- [ ] F2. **End-to-End Functional QA** — `unspecified-high`
  Fresh machine simulation: run `yourcounterpart setup`, verify Claude Code + Cursor both get company rules. Run `yourcounterpart update`, verify new rule propagates. Open counterpart repo, run `context validate`. Output: `APPROVE/REJECT` per scenario.

- [ ] F3. **Scope Fidelity Check** — `deep`
  Compare each task's spec against actual diff. Verify 1:1. Flag unaccounted changes. Output: `APPROVE/REJECT`.

---

## Commit Strategy
- Wave 1: `refactor(toolbox): rename yourclaude → yourcounterpart, remove wrapper logic`
- Wave 2: `feat(toolbox): add sync engine, setup/update commands, context.lock`
- Wave 3: `feat(plugins): migrate to .agents/ format, add default agent, skills, hooks`
- Wave 4: `feat(counterpart): add context layer and .agents/ reference implementation`

## Success Criteria

```bash
yourcounterpart setup                # Expected: syncs to detected agents
yourcounterpart update               # Expected: pulls plugins, re-syncs
yourcounterpart context sync         # Expected: generates context.lock
yourcounterpart context validate     # Expected: "in sync" or "stale"
cat ~/.claude/CLAUDE.md              # Expected: counterpart managed block present
cat .cursor/rules/counterpart-*.mdc  # Expected: company rules present
bash ci/check-context-lock.sh        # Expected: exit 0 on fresh clone
```

### Final Checklist
- [ ] All Must Have present
- [ ] All Must NOT Have absent
- [ ] `yourcounterpart setup` works on Claude Code + Cursor
- [ ] context.lock is deterministic
- [ ] Company rules appear in both agent configs after setup
- [ ] Sync is idempotent (run twice = same output)
- [ ] counterpart repo has context/, .agents/, AGENTS.md, context.lock
