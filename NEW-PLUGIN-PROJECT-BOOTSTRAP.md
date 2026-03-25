---
title: New Plugin Project Bootstrap Guide
type: root-guidance
status: active
completion: 100
priority: critical
authority: primary
intent-scope: workspace-setup
phase: setup
last-reviewed: 2026-03-25
related-files:
  - ./WORKSPACE-SETUP.md
  - ./DEVOPS-TECH-STACK.md
  - ./docker-compose.yml
  - ./.env.example
  - ./foundation/wp/docs/licensing/BILLING-LICENSING-ARCHITECTURE.md
  - ./foundation/wp/templates/licensing/
---

# New Plugin Project Bootstrap

## Overview

This guide walks you through creating a new WordPress plugin project from scratch
using this template repository. Every project in this stack follows the **two-plugin pattern**:

1. **App plugin** — customer-facing features, UI, product logic
2. **Control-plane plugin** — billing, licensing, plan allowances via FluentCart

Both plugins develop together in the same local WordPress Docker environment.

---

## Step 1 — Create Your Repository from This Template

On GitHub, click **Use this template** → **Create a new repository**.
Name it after your product (e.g. `my-saas`).

Clone locally:
```bash
git clone https://github.com/<your-org>/my-saas.git
cd my-saas
```

---

## Step 2 — Pull Foundation Layers

```bash
./scripts/bootstrap-foundation.sh
```

This pulls:
- `foundation/core` from `https://github.com/esfih/master-core` (devops, AI context, validation)
- `foundation/wp` from `https://github.com/esfih/wp-overlay` (Docker, WP-CLI, licensing templates)
- `foundation/ollama` from `https://github.com/esfih/master-core` (local AI setup)

---

## Step 3 — Scaffold Your Plugin Folders

```bash
mkdir -p plugin cp-plugin
```

### App plugin stub (`plugin/`)

Copy the start structure:
```
plugin/
├── my-saas.php              # Plugin header + bootstrap
├── includes/
│   ├── Core/Autoloader.php  # PSR-4 autoloader
│   ├── Licensing/           # Copy from foundation/wp/templates/licensing/customer-plugin/
│   └── API/                 # REST endpoints
├── assets/
├── readme.txt
└── uninstall.php
```

### Control-plane plugin (`cp-plugin/`)

Copy from the billing/licensing templates:
```bash
cp -r foundation/wp/templates/licensing/control-plane/ cp-plugin/
```

Then adapt:
- Rename class namespaces to match your product
- Update `PlanRegistry.php` with your FluentCart product IDs and plan slugs
- Update `BillingAllowanceRepository.php` with your allowance option keys
- Update plugin header in `cp-plugin-main.php.template` → rename to `my-saas-cp.php`

See `foundation/wp/docs/licensing/BILLING-LICENSING-ARCHITECTURE.md` for the complete
auth flow, FluentCart setup, allowance schema, and security rationale.

---

## Step 4 — Configure Environment

```bash
cp .env.example .env
```

Edit `.env`:
```bash
COMPOSE_PROJECT_NAME=my_saas_dev
WP_IMAGE=wordpress:6.5-php8.1-apache   # Use your minimum supported WP version
DB_NAME=wordpress
DB_USER=wp_user
DB_PASSWORD=wp_pass_dev
WP_PORT=8080
PMA_PORT=8081
PLUGIN_SLUG=my-saas
CP_PLUGIN_SLUG=my-saas-cp
```

---

## Step 5 — Update `docker-compose.yml`

Edit `docker-compose.yml` to use your actual plugin folder names:

```yaml
volumes:
  - ./plugin:/var/www/html/wp-content/plugins/my-saas
  - ./cp-plugin:/var/www/html/wp-content/plugins/my-saas-cp
```

---

## Step 6 — Start WordPress

```bash
docker compose up -d

# Install WordPress
./scripts/wp.sh wp core install \
  --url="http://localhost:8080" \
  --title="My SaaS Dev" \
  --admin_user=admin \
  --admin_password=admin \
  --admin_email=dev@local.test \
  --skip-email

# Set pretty permalinks (required for REST API)
./scripts/wp.sh wp rewrite structure '/%postname%/' --hard

# Activate both plugins
./scripts/wp.sh wp plugin activate my-saas my-saas-cp

# Verify
./scripts/check-local-wp.sh
```

---

## Step 7 — Initialize Product Specs

```bash
# Create your product feature inventory
cp foundation/core/templates/README-FIRST.template.md README-FIRST.md
# Edit README-FIRST.md with your product name and context

# Initialize feature inventory
# Edit specs/app-features/feature-inventory.json with your first features
```

---

## Step 8 — Set Up GitHub Copilot Instructions

```bash
cp foundation/core/templates/copilot-instructions.template.md .github/copilot-instructions.md
```

Edit it to:
- Replace `<PRODUCT_NAME>` with your product name
- Replace `<PRODUCT_REPO>` with your GitHub repo URL
- Add any product-specific routing rules

---

## Step 9 — Release Workflow

Before each release:
```bash
# Run security validation
./scripts/security-validate-changed.sh --staged

# Bump plugin version
./scripts/bump-version.sh --plugin plugin --to 0.1.1
./scripts/bump-version.sh --plugin cp-plugin --to 0.1.1

# Commit (single-line only — multi-line -m hangs Git Bash on Windows)
git add plugin cp-plugin
git commit -m "feat(release): bump both plugins to 0.1.1"

# Build release ZIP
./scripts/build-release-zip.sh --plugin plugin --version 0.1.1
./scripts/build-release-zip.sh --plugin cp-plugin --version 0.1.1
```

---

## Architecture Reference

| Pattern | Reference |
|---|---|
| Two-plugin billing architecture | `foundation/wp/docs/licensing/BILLING-LICENSING-ARCHITECTURE.md` |
| PHP class templates (control-plane) | `foundation/wp/templates/licensing/control-plane/` |
| PHP class templates (customer plugin) | `foundation/wp/templates/licensing/customer-plugin/` |
| WP-CLI / Docker operations | `foundation/wp/docs/WP-LOCAL-OPS.md` |
| Docker image patterns | `foundation/wp/docs/WP-OVERLAY-README.md` |
| Local AI setup | `foundation/ollama/docs/LOCAL-LLM-SETUP.md` |
| Implementation rules | `foundation/core/docs/IMPLEMENTATION-RULES.md` |
| Security protocol | `foundation/core/docs/SECURITY-VALIDATION-PROTOCOL.md` |
