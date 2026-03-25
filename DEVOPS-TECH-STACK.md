---
title: DevOps Tech Stack
type: root-guidance
status: active
completion: 100
priority: critical
authority: primary
intent-scope: workspace-setup,implementation,debugging,maintenance
phase: setup
current-focus: keep the app-local runtime summary aligned with shared core guidance and WordPress overlay assumptions
last-reviewed: 2026-03-25
related-files:
  - ./README-FIRST.md
  - ./WORKSPACE-SETUP.md
  - ./foundation/README.md
  - ./foundation/wp/docs/WP-LOCAL-OPS.md
  - ./foundation/wp/docs/WP-OVERLAY-README.md
  - ./docker-compose.yml
  - ./.env.example
---

# DevOps Tech Stack

## Shared Baseline

The reusable baseline lives in imported shared layers:

- `foundation/core` — workflow, AI-context, validation, handover
- `foundation/wp` — Docker patterns, WP-CLI, plugin packaging, licensing templates

## Host Requirements

| Tool | Minimum Version | Purpose |
|---|---|---|
| Git (Git Bash on Windows) | 2.40+ | VCS, subtree sync |
| Docker Desktop | 4.x | Local WordPress runtime |
| Python 3 | 3.10+ | Repo scripts (context budget, JSON checks, validation) |
| Node.js | 18+ | Optional — only if the plugin uses JS tooling |
| shellcheck | any | Shell script linting |
| shfmt | any | Shell script formatting |

> Install `tiktoken` and `beautifulsoup4` via `pip install tiktoken beautifulsoup4` for full IDE context budget reporting.

## Default Development Shell

- **Git Bash** is the default shell for all repository work on Windows
- **PowerShell** is used only for Windows-specific tasks (service installation, etc.)
- Use one shared Git Bash terminal session; do not spawn extra bash shells for short commands
- Use one shared host Python 3 interpreter; do not create a repo-local `.venv` unless the project explicitly needs isolated packages

## WordPress Runtime — Standard Two-Plugin Setup

Every project in this stack uses a **two-plugin pattern**:

| Plugin | Role | Example |
|---|---|---|
| **App/User plugin** | Customer-facing features, UI, AI, product logic | `my-product/` |
| **Control-plane plugin** | Licensing, billing, allowances, reporting via FluentCart | `my-product-cp/` |

Both plugins are mounted into the same local WordPress container and activated together during development.

### Default WP/PHP baseline

| Component | Version | Notes |
|---|---|---|
| WordPress | **6.5** (minimum supported) | `wordpress:6.5-php8.1-apache` Docker image |
| PHP | **8.1** | Minimum declared in plugin headers |
| MySQL | 8.0 | MySQL or MariaDB 10.6+ both supported |

The local Docker lane uses the **lowest WordPress version the plugin advertises support for** (WP 6.5). This catches compatibility issues early. A second beta/prerelease lane can be added by duplicating the service block in `docker-compose.yml` with a newer image.

### Ports (default — override via `.env`)

| Service | Default Port |
|---|---|
| WordPress | `8080` |
| phpMyAdmin | `8081` |

## Docker Architecture

```
docker-compose.yml
  ├── db          — MySQL 8.0, stores WordPress data
  ├── wordpress   — Custom image (foundation/wp/docker/Dockerfile)
  │     mounts: plugin/ and cp-plugin/ (two-plugin pattern)
  └── phpmyadmin  — DB admin UI on :8081
```

The `Dockerfile` is maintained in `foundation/wp/docker/Dockerfile`. It:
- Accepts a `WORDPRESS_BASE_IMAGE` build arg (e.g. `wordpress:6.5-php8.1-apache`)
- Installs WP-CLI, Apache rewrite module, dev tools
- Sets `AllowOverride All` for clean permalink support

The `php-sharedhost.ini` in `foundation/wp/docker/` disables dangerous PHP functions to simulate real shared-hosting constraints.

## Plugin Packaging & Release

- Build release ZIP: `./scripts/build-release-zip.sh --plugin <plugin-folder> --version <x.y.z>`
- Bump version: `./scripts/bump-version.sh --plugin <plugin-folder> --to <x.y.z>`
- Full release: `./scripts/release-plugin.sh --plugin <plugin-folder> --version <x.y.z>`
- Security pre-flight: `./scripts/security-validate-changed.sh --staged` (run before every commit)

## Licensing & Control Plane

All projects use a shared billing architecture:
- **FluentCart Pro** on the billing/control-plane WordPress site
- **Control-plane plugin** (`my-product-cp`) — REST API for activations + entitlement resolution
- **Customer plugin** — license API client, site fingerprint, local state store

See `foundation/wp/docs/licensing/BILLING-LICENSING-ARCHITECTURE.md` for the complete architecture reference.
See `foundation/wp/templates/licensing/` for copy-ready PHP class templates.

## Local AI — Ollama + GitHub Copilot

All projects in this stack use the same local AI setup:
- **Ollama** running locally with Qwen models (GPU-accelerated)
- **Nothink proxy** — strips `<think>` blocks to reduce latency and token usage
- **GitHub Copilot** in VS Code configured to route through the local models when available

See `foundation/ollama/` (after `bootstrap-foundation.sh`) for model setup, proxy service, and VS Code integration docs.

## Source Control & Foundation Sync

- Bootstrap foundation layers once: `./scripts/bootstrap-foundation.sh`
- Sync updates from upstream: `./scripts/sync-foundation.sh --apply`
- Upstream remotes (registered by bootstrap):
  - `master-core` → `https://github.com/esfih/master-core`
  - `wp-overlay` → `https://github.com/esfih/wp-overlay`
- one host Python 3 interpreter is the repository script baseline
- Docker Desktop is the default local runtime baseline for WordPress sandbox work
- root `scripts/` remains the active execution surface for app-local bootstrap and sync wrappers

## App-Local Deviations Rule

Keep deviations explicit in this file rather than editing shared-layer docs for one product-only need.