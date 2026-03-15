---
title: Repository Context Router
type: root-guidance
status: active
completion: 100
priority: critical
authority: primary
intent-scope: all
phase: setup
current-focus: route AI sessions through the app-local adapter and shared foundation layers
last-reviewed: 2026-03-16
next-focus: keep root guidance thin while reusable logic lives in shared repositories
related-files:
  - ./WORKSPACE-SETUP.md
  - ./DEVOPS-TECH-STACK.md
  - ./foundation/README.md
  - ./specs/app-features/feature-inventory.json
---

# README FIRST

## Purpose

This is the first file an IDE AI should read before doing meaningful work in this repository.

This repository is an app-local plugin/product repo.

## Routing Layers

Use the repository in this order:

1. this root adapter for local product context
2. `foundation/core` for reusable process and AI-context guidance
3. `foundation/wp` when the task requires WordPress runtime or packaging context
4. local `specs` and `specs/app-features` for app-local product truth

## Always-On Runtime Rules

- Git Bash is the default shell for repository work
- use one shared Git Bash terminal session for normal repository work
- PowerShell is for Windows-specific tasks only
- use one host Python 3 interpreter for repository scripts
- do not create or prefer a repo-local `.venv` unless the repository later explicitly requires it

## Shared-Layer Rule

Treat `foundation/core` and `foundation/wp` as imported shared layers.

- improve reusable workflow or IDE-context assets upstream first
- improve reusable WordPress scaffolding upstream first
- keep product identity, feature specs, and plugin code local to this repo

## Canonical Product Truth

For this repository, app-local product truth belongs in:

- `specs/`
- `specs/app-features/`
- product code folders such as `plugin/`, `private-plugins/`, or equivalent

Do not treat `foundation/` as product truth.