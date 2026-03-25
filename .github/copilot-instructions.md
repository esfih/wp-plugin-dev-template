You are working in an app-local WordPress plugin repository.

Read README-FIRST.md first for every meaningful response.

Treat this repository as a product repo that consumes shared foundation layers.

## Routing Order

- use root adapter files first: `README-FIRST.md`, `WORKSPACE-SETUP.md`, `DEVOPS-TECH-STACK.md`
- use `foundation/core` for reusable workflow and AI-context guidance
- use `foundation/wp` only when WordPress runtime or plugin packaging context is relevant
- treat `/specs` and `/specs/app-features` as canonical app-local product truth

## Terminal Discipline

Use Git Bash as the default shell for repository work and PowerShell only for Windows-specific tasks.

Use one shared Git Bash terminal session by default for repository work.

Do not open multiple extra Git Bash terminals for one-off inspection commands, retries, or prompt recovery.

Use a separate background terminal only for genuinely long-running processes such as servers, watchers, or streaming logs.

## Python

Use one host Python 3 interpreter for repository scripts. Do not create, select, or prefer a repo-local `.venv` unless the repository later gains explicit Python package dependencies that require isolation.

## Shared-Layer Rule

- reusable workflow and IDE-context improvements belong upstream in `master-core`
- reusable WordPress runtime and packaging improvements belong upstream in `wp-overlay`
- app-specific feature specs, branding, and code stay local to this repo

## Default Upstreams

- `https://github.com/esfih/master-core`
- `https://github.com/esfih/wp-overlay`

## Commit Messages — Single-Line Only

Never use multi-line `-m` flags. Git Bash on Windows opens continuation prompts and the commit hangs indefinitely.

Use **only**:
```bash
git commit -m "type(scope): single-line description"
```

Always verify the commit landed immediately after:
```bash
git log --oneline -1
```

## Security Pre-Flight — Required Before Every Commit

Run before any commit attempt:
```bash
./scripts/security-validate-changed.sh --staged
```

Must print `Security validation passed`. Fix all FAIL items first.

## Storage Rules

**Client-side storage is forbidden by default.** `localStorage`, `sessionStorage`, and cookies must not be used as primary data stores. All App state must go to the database. Any exception requires a `BROWSER_STORAGE_WAIVER: <reason>` inline comment.

**New data always requires a schema design gate.** Before writing any code that creates a new option key, meta key, column, or table, answer the five mandatory schema questions in `specs/IMPLEMENTATION-RULES.md`.

## UI Wiring Completeness

A UI task is not done until the full wiring chain exists: JS handler → REST/AJAX endpoint → PHP callback → DB operation. A visually correct but unwired CTA is incomplete work.

## Two-Plugin Pattern

This project uses the standard two-plugin dev pattern:
- App plugin: `plugin/` — product features, UI, AI, REST
- Control-plane plugin: `cp-plugin/` — licensing, billing, allowances, reporting

See `foundation/wp/docs/licensing/BILLING-LICENSING-ARCHITECTURE.md` for the architecture.

## Feature Work

Before meaningful feature work, check the target feature `STATUS.md` and `feature-status.json`.

## Docker / WordPress

For any `docker exec`, `wp`, `mysql`, or PHP CLI command against the local WordPress instance, follow patterns in `foundation/wp/docs/WP-LOCAL-OPS.md`. Use `./scripts/wp.sh` as the preferred entry point.

Always set `MSYS_NO_PATHCONV=1` before docker exec commands that use Linux absolute paths.

Credential safety is mandatory: never change, reset, rotate, create, delete, reveal, or test any credential whatsoever without explicit user confirmation in the current conversation.