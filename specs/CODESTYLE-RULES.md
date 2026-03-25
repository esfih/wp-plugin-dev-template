---
title: Code Style Rules
type: rules
status: active
completion: 100
priority: high
authority: primary
intent-scope: implementation,review,maintenance,refactor
phase: phase-1
last-reviewed: 2026-03-10
current-focus: keep code patches small, readable, WordPress-compatible, and review-friendly
next-focus: align code examples and file-level structure advice with active plugin patterns
ide-context-token-estimate: 2572
token-estimate-method: approx-chars-div-4
session-notes: >
	This file defines style expectations separately from terminal, file-safety, and validation behavior.
related-files:
	- ../README-FIRST.md
	- ./IMPLEMENTATION-RULES.md
	- ./FILE-SAFETY-RULES.md
	- ./VALIDATION-STACK.md
---

# Code Style Rules

## Purpose

This document defines the coding style expectations for all human and AI-generated code in this repository.

Its purpose is to keep the codebase:

- readable
- stable
- predictable
- easy to review
- easy to patch safely
- compatible with WordPress conventions

This file covers style and structure only.

Operational safety, terminal behavior, file replacement rules, and validation tooling are defined in separate repository documents.

---

This file should generally be read in:
- implementation mode
- review mode
- maintenance mode
- refactor mode

It should not be one of the first files loaded in planning-only or workspace-setup-only tasks unless code style is directly relevant.


# General Principles

Code in this repository must favor:

- clarity over cleverness
- explicitness over hidden magic
- small safe changes over broad rewrites
- WordPress compatibility over fashionable patterns
- maintainability over brevity

Avoid writing code that looks impressive but is harder to debug later.

---

# Cross-Language Rules

## Keep logic visible

Prefer straightforward logic with readable intermediate variables when useful.

Avoid collapsing too much behavior into one expression.

---

## Prefer small functions and methods

Functions and methods should ideally do one clear job.

If a block grows large, split it.

---

## Minimize nesting

Avoid deeply nested conditionals when guard clauses can simplify the flow.

---

## Name things clearly

Names must communicate intent.

Good names should tell:

- what the thing is
- what it does
- what scope it belongs to

Avoid vague names like:

- data
- stuff
- temp
- helper
- manager
- util

unless the purpose is genuinely generic.

---

## Do not introduce abstraction too early

Do not create extra layers just because they look architecturally elegant.

Only abstract repeated or clearly reusable behavior.

---

## Prefer patching over rewriting

When editing existing code:

- change the minimum necessary lines
- preserve surrounding style
- do not reformat unrelated sections
- do not rename unrelated variables
- do not reorder code without reason

---

## Comments explain why, not obvious syntax

Use comments to explain:

- non-obvious decisions
- constraints
- WordPress-specific caveats
- hosting limitations
- safety assumptions

Do not comment trivial syntax.

---

# File-Level Rules

## One clear responsibility per file

A file should have a strong primary purpose.

Avoid files that mix:

- UI rendering
- API transport
- business logic
- persistence logic
- diagnostics

unless the file is intentionally tiny and tightly scoped.

---

## Keep file headers clean

Avoid banner comments unless required.

Do not add noisy generated metadata.

---

## Preserve existing encoding and line-ending policy

Do not introduce accidental BOM, mixed line endings, or trailing whitespace.

---

# PHP Rules

## Follow WordPress conventions first

This repository is WordPress-oriented.

PHP should remain compatible with WordPress plugin development patterns.

---

## PHP opening tags

Use full opening tags:

<?php

Never use short open tags.

---

## One class per file when practical

If using classes, prefer one main class per file.

File name and class purpose should align clearly.

---

## Clear class responsibilities

Classes should not become dumping grounds.

Good examples of responsibilities:

- controller
- service
- rest handler
- settings registry
- logger
- capability helper

Bad examples:

- giant multi-purpose manager
- generic toolkit with feature-specific logic

---

## Methods should stay focused

A method should ideally represent one operation.

If a method does multiple stages, use private helper methods.

---

## Guard clauses preferred

Prefer early returns for invalid state, missing capability, empty input, or unsupported context.

This keeps methods flatter and easier to read.

---

## Arrays should be readable

For larger arrays:

- one key per line
- trailing commas when style already uses them
- align structure for reviewability, not decoration

---

## String style

Prefer single quotes for simple literal strings.

Use double quotes only when interpolation or special characters make it clearly better.

---

## Sanitization and escaping are mandatory

All input must be sanitized appropriately.

All output must be escaped appropriately.

This is not optional style; it is part of code correctness.

---

## Nonce and capability checks must be obvious

Security checks should be easy to spot in the code.

Do not bury them far away from the action they protect.

---

## Avoid hidden globals

Do not rely on global state unless WordPress conventions make it necessary.

When globals are needed, keep usage minimal and obvious.

---

## Prefer explicit return values

Methods should return predictable values.

Avoid returning mixed shapes unless clearly documented.

---

## Docblocks only when useful

Use docblocks when they add real value:

- parameter types not obvious
- array shape expectations
- return contract
- WordPress hook context
- important side effects

Do not add decorative docblocks to every tiny method.

---

# WordPress-Specific PHP Conventions

## Hooks must be easy to trace

When registering actions and filters, keep callback mapping readable.

Avoid hook registration that is overly dynamic unless it adds real value.

---

## REST handlers must stay thin

REST endpoint methods should:

- validate
- authorize
- sanitize
- delegate to a service
- return standardized responses

They should not contain deep business logic when avoidable.

---

## Admin page code must stay separate from core logic

Rendering logic should not become the main home of business rules.

---

## Option keys and meta keys must be stable

Use clear prefixes and consistent naming.

Avoid casually renaming keys once introduced.

---

# JavaScript Rules

## Prefer simple modular JavaScript

Use modular files and small functions.

Avoid heavy framework-style complexity unless the feature truly needs it.

---

## Keep DOM logic separate from transport logic

As much as practical:

- DOM selection / event binding
- request sending
- response normalization
- UI update rendering

should remain conceptually separated.

---

## Defensive DOM access

Check that expected elements exist before acting on them.

Do not assume markup is always present.

---

## Avoid global pollution

Do not create unnecessary globals.

Use scoped modules or clearly namespaced objects when needed.

---

## Keep async flows readable

Use async/await when available in the project style.

Handle failure paths explicitly.

Do not ignore rejected promises.

---

## Standardize response handling

API responses should be normalized before UI logic depends on them.

Avoid spreading ad hoc response-shape assumptions everywhere.

---

## Avoid inline magic strings

For repeated selectors, actions, event names, or response keys, define stable constants where it improves clarity.

---

# CSS Rules

## Scope styles tightly

Never write styles that may accidentally leak into unrelated wp-admin or theme areas.

Use clear wrappers or feature-specific class prefixes.

---

## Prefer feature-local selectors

Selectors should reflect the feature scope.

Avoid broad selectors like:

- .button
- .panel
- div span
- .active

without feature namespacing.

---

## Avoid unnecessary specificity wars

Keep selectors as simple as possible while still safely scoped.

---

## Keep layout and skin readable

Where practical, separate:

- structural layout choices
- visual skin choices
- state styles

---

## Do not style by fragile DOM assumptions

Avoid selectors that depend on brittle nesting unless necessary.

---

# Naming Rules

## PHP class names

Use descriptive, stable names aligned with repository architecture.

Examples:

- WebmasterOS_Recovery_Service
- WebmasterOS_Element_Picker_Controller
- WebmasterOS_Remote_Bridge_REST_Controller

---

## Function and method names

Use verb-oriented names for actions.

Examples:

- register_routes
- enqueue_assets
- get_feature_state
- validate_request
- render_panel

---

## JavaScript names

Prefer descriptive camelCase names.

Examples:

- selectedElement
- sendPreviewRequest
- applyPanelState
- normalizeApiResponse

---

## CSS class names

Prefer feature-prefixed class names.

Examples:

- wmos-panel
- wmos-panel__header
- wmos-picker-overlay
- wmos-designer-control

---

# Formatting Rules

## Respect repository formatter output

If formatter rules exist, follow them.

Do not manually fight the formatter.

---

## No trailing whitespace

---

## End files with a newline

---

## Keep diffs clean

Do not mix formatting-only edits with logic edits unless explicitly requested.

---

# Diff Hygiene Rules

## One concern per change when possible

Do not combine:

- syntax repair
- architecture refactor
- feature implementation
- formatting sweep

in one patch if it can be avoided.

---

## Preserve blame usefulness

Avoid giant style-only rewrites that make history harder to inspect.

---

# AI-Specific Style Behavior

AI must:

- preserve nearby coding style
- avoid broad reformatting
- avoid renaming stable symbols casually
- prefer minimal patch size
- keep acceptance criteria visible in implementation choices
- not invent new architectural patterns unless required by spec

---

# Final Principle

This repository values code that is:

clear  
safe  
traceable  
reviewable  
WordPress-aware  

Style exists to support stability, not aesthetics alone.

---

# End