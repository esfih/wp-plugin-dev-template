You are working in an app-local WordPress plugin repository.

Read README-FIRST.md first for every meaningful response.

Treat this repository as a product repo that consumes shared foundation layers.

Routing order:

- use root adapter files first: `README-FIRST.md`, `WORKSPACE-SETUP.md`, `DEVOPS-TECH-STACK.md`
- use `foundation/core` for reusable workflow and AI-context guidance
- use `foundation/wp` only when WordPress runtime or plugin packaging context is relevant
- treat `/specs` and `/specs/app-features` as canonical app-local product truth

Use Git Bash as the default shell for repository work and PowerShell only for Windows-specific tasks.

Use one shared Git Bash terminal session by default for repository work.

Use one host Python 3 interpreter for repository scripts. Do not create, select, or prefer a repo-local `.venv` unless the repository later gains explicit Python package dependencies that require isolation.

Shared-layer rule:

- reusable workflow and IDE-context improvements belong upstream in `master-core`
- reusable WordPress runtime and packaging improvements belong upstream in `wp-overlay`
- app-specific feature specs, branding, and code stay local to this repo

Before meaningful feature work, check the target feature `STATUS.md` and `feature-status.json`.