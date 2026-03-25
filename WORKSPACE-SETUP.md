---
title: Workspace Setup Guide
type: root-guidance
status: active
completion: 100
priority: critical
authority: primary
intent-scope: workspace-setup
phase: setup
current-focus: full setup guide for new workspaces and new computers
last-reviewed: 2026-03-25
related-files:
  - ./README-FIRST.md
  - ./DEVOPS-TECH-STACK.md
  - ./foundation/README.md
  - ./scripts/bootstrap-foundation.sh
  - ./scripts/bootstrap-foundation.ps1
  - ./foundation/wp/docs/WP-LOCAL-OPS.md
  - ./foundation/wp/docs/WP-OVERLAY-README.md
  - ./docker-compose.yml
  - ./.env.example
---

# Workspace Setup

## Purpose

Step-by-step guide to set up this repository from scratch on a new computer or in a new workspace.

## Quick Bootstrap (new machine)

```bash
# 1. Clone the repository
git clone https://github.com/<your-org>/<your-repo>.git
cd <your-repo>

# 2. Pull foundation layers (master-core + wp-overlay as git subtrees)
./scripts/bootstrap-foundation.sh

# 3. Copy env template and fill in your values
cp .env.example .env
# edit .env: set COMPOSE_PROJECT_NAME, DB passwords, WP admin creds, ports

# 4. Start the WordPress container
docker compose up -d

# 5. Install WordPress
./scripts/wp.sh wp core install \
  --url="http://localhost:8080" \
  --title="My Plugin Dev Site" \
  --admin_user=admin \
  --admin_password=admin \
  --admin_email=dev@local.test \
  --skip-email

# 6. Activate both plugins (two-plugin pattern)
./scripts/wp.sh wp plugin activate <your-plugin> <your-cp-plugin>

# 7. Verify
./scripts/check-prereqs.sh
./scripts/check-local-wp.sh
```

## Detailed Setup Routing

### Shared core setup guidance

Use `foundation/core/docs/` for reusable setup, IDE-context, workflow, validation, and handover guidance.

Upstream: `https://github.com/esfih/master-core`

Key files available after `bootstrap-foundation.sh`:
- `foundation/core/docs/TERMINAL-RULES.md` — shell discipline
- `foundation/core/docs/VALIDATION-STACK.md` — linting, security, JSON checks
- `foundation/core/docs/SECURITY-VALIDATION-PROTOCOL.md` — pre-commit scanning
- `foundation/core/docs/APP-FEATURES-README.md` — feature packaging patterns
- `foundation/core/docs/SHARED-LAYER-MODUS-OPERANDI.md` — how subtrees work

### WordPress overlay setup guidance

Use `foundation/wp/` for WordPress runtime, plugin packaging, and licensing.

Upstream: `https://github.com/esfih/wp-overlay`

Key files available after bootstrap:
- `foundation/wp/docs/WP-LOCAL-OPS.md` — canonical WP-CLI, DB, PHP eval, debug log patterns
- `foundation/wp/docs/WP-OVERLAY-README.md` — Docker pattern, two-plugin setup
- `foundation/wp/docs/licensing/BILLING-LICENSING-ARCHITECTURE.md` — FluentCart control-plane pattern
- `foundation/wp/templates/licensing/` — PHP class templates (copy + adapt for new product)

### Local AI setup guidance

Use `foundation/ollama/` for Ollama local model setup, nothink proxy, and VS Code integration.

Key files available after bootstrap:
- `foundation/ollama/docs/LOCAL-LLM-SETUP.md` — Ollama install and Qwen model setup
- `foundation/ollama/docs/NO-THINK-PROXY.md` — nothink proxy to reduce latency
- `foundation/ollama/docs/IDE-COPILOT-INTEGRATION.md` — VS Code + Copilot + local model routing

### App-local setup truth

Keep these decisions local to this repository:

- plugin/product identity and slug
- active ports and Docker service names (in `docker-compose.yml`)
- actual product code folder names
- current feature inventory (`specs/app-features/feature-inventory.json`)
- `.env` overrides

## Host Requirements

Install these before the bootstrap. Run `./scripts/check-prereqs.sh` to verify.

| Tool | Install | Notes |
|---|---|---|
| Git + Git Bash | https://git-scm.com/downloads | Required on Windows |
| Docker Desktop | https://www.docker.com/products/docker-desktop | Required |
| Python 3 | https://www.python.org/downloads/ | `python` must be on PATH |
| shellcheck | https://www.shellcheck.net/ | Shell lint |
| shfmt | https://github.com/mvdan/sh | Shell formatting |
| tiktoken (pip) | `pip install tiktoken beautifulsoup4` | IDE context budget |

## WordPress Version Baseline

This project stack targets **WordPress 6.5 minimum** (PHP 8.1 minimum). The local Docker lane uses
`wordpress:6.5-php8.1-apache` by default so development catches compatibility issues against the
declared minimum. Override with `WP_IMAGE=wordpress:6.9.4-php8.2-apache` in `.env` if needed.

## Two-Plugin Standard Pattern

All projects in this stack follow a two-plugin development model:

1. **App plugin** — the product/customer-facing plugin (e.g. `plugin/`)
2. **Control-plane plugin** — the billing-site licensing/allowances plugin (e.g. `cp-plugin/`)

Both are mounted into the local WordPress Docker container. See `docker-compose.yml` for mount paths,
and `foundation/wp/docs/licensing/BILLING-LICENSING-ARCHITECTURE.md` for the full architecture.

## Updating Foundation Layers

Pull the latest reusable tooling from upstream remotes:

```bash
./scripts/sync-foundation.sh --apply
```

## App-Local Checklist (before feature work)

1. Verify workspace path and branch/worktree role
2. Confirm host tools: `./scripts/check-prereqs.sh`
3. Verify Docker and WordPress: `./scripts/check-local-wp.sh`
4. Review feature inventory: `specs/app-features/feature-inventory.json`
5. Read the relevant feature `STATUS.md` before starting work
6. Run pre-commit security check before every commit: `./scripts/security-validate-changed.sh --staged`