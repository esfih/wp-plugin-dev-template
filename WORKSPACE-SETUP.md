---
title: Workspace Setup Guide
type: root-guidance
status: active
completion: 100
priority: critical
authority: primary
intent-scope: workspace-setup
phase: setup
current-focus: route setup work through app-local entrypoints and shared layers
last-reviewed: 2026-03-16
related-files:
  - ./README-FIRST.md
  - ./DEVOPS-TECH-STACK.md
  - ./foundation/README.md
  - ./scripts/bootstrap-foundation.sh
  - ./scripts/bootstrap-foundation.ps1
---

# Workspace Setup

## Purpose

This is the app-local workspace setup adapter.

## Setup Routing

### Shared core setup guidance

Use `foundation/core/docs/` for reusable setup, IDE-context, workflow, validation, and handover guidance.

### WordPress overlay setup guidance

Use `foundation/wp/` when setup involves local WordPress runtime, plugin packaging, or WordPress-specific validation.

### App-local setup truth

Keep these decisions local to this repository:

- plugin/product identity
- active ports and Docker wiring
- actual product code folders
- current feature inventory and roadmap truth

## Bootstrap Checklist

1. verify the repository root and branch role
2. run the foundation bootstrap script to pull `foundation/core` and `foundation/wp`
3. verify root scripts are available
4. verify root adapter docs still reflect the current product
5. initialize local product feature packages in `specs/app-features`