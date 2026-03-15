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
last-reviewed: 2026-03-16
related-files:
  - ./README-FIRST.md
  - ./WORKSPACE-SETUP.md
  - ./foundation/README.md
---

# DevOps Tech Stack

## Shared Baseline

The reusable baseline lives in imported shared layers:

- `foundation/core`
- `foundation/wp`

## Default Local Baseline

- Git Bash is the default shell
- PowerShell is used for Windows-specific work
- one host Python 3 interpreter is the repository script baseline
- Docker Desktop is the default local runtime baseline for WordPress sandbox work
- root `scripts/` remains the active execution surface for app-local bootstrap and sync wrappers

## App-Local Deviations Rule

Keep deviations explicit in this file rather than editing shared-layer docs for one product-only need.