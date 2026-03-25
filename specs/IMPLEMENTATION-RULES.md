---
title: Implementation Rules
type: rules
status: active
completion: 100
priority: critical
authority: primary
intent-scope: implementation,debugging,review,maintenance,refactor
phase: phase-1
last-reviewed: 2026-03-10
current-focus: enforce mode-aware, status-aware, WordPress-safe implementation behavior
next-focus: standardize implementation completion output and validation discipline
ide-context-token-estimate: 4102
token-estimate-method: approx-chars-div-4
session-notes: >
  Updated to align with README-FIRST.md, STATUS.md checks, workspace setup concerns, and restricted customer hosting assumptions.
related-files:
  - ../README-FIRST.md
  - ./CODESTYLE-RULES.md
  - ./FILE-SAFETY-RULES.md
  - ./VALIDATION-STACK.md
  - ./ARCHITECTURE-MAP.md
---

# Implementation Rules

## Purpose

This file defines mandatory implementation behavior for any AI model modifying code in this repository.

It applies to:
- GPT coding models
- Codex models
- Copilot-assisted generation
- builder agents

The objective is:

safe incremental implementation inside a production-oriented WordPress plugin codebase.

---

# Mandatory Read Order

Before implementation, the model should read:

- README-FIRST.md
- target feature STATUS.md
- target feature feature-status.json
- target feature tasks.md
- target feature architecture.md

Then read as needed:
- CODESTYLE-RULES.md
- FILE-SAFETY-RULES.md
- VALIDATION-STACK.md
- DATA-SOURCE-AUTHORITY-PROTOCOL.md
- SECURITY-VALIDATION-PROTOCOL.md
- TESTING-PROTOCOL.md
- TERMINAL-RULES.md
- ARCHITECTURE-MAP.md

---

# Scope Rule

Implement only the active task or clearly isolated subtask.

Do not silently broaden scope.

Do not work on unrelated features.

---

# Zero-Guessing Rule

Implementation must be evidence-first.

Do not guess or fabricate:

- release URLs
- credentials
- endpoint availability
- version/tag mapping
- runtime outcomes

Before claiming completion or readiness, verify through one or more of:

- canonical repository docs
- local file/state inspection
- deterministic command/runtime checks
- authoritative API responses

If certainty is still missing, report as unverified/inconclusive and continue investigation.

---

# User Intervention Rule

AI should perform all executable developer work directly in-session.

Do not ask the user to perform commands, uploads/downloads, or script execution that AI can perform.

User action may be requested only when blocked by unavailable business/admin authority or inaccessible external systems.

When requesting user action:

- ask only for the minimum required action
- state why AI cannot complete that step directly
- resume autonomous execution immediately once input is provided

---

# Status Awareness Rule

If the feature is marked:
- stable
- maintenance
- completed

then default behavior should be:
- bugfix
- maintenance
- compatibility
- safe extension

not redesign.

---

# Workspace Reality Rule

Implementation may use richer local tooling, but shipped behavior must remain realistic for the client runtime, which may be:

- low resource
- restricted
- no SSH
- no WP-CLI

Do not build core feature behavior around local-only assumptions unless clearly marked as dev-only tooling.

---

# Existing Diagnostics Rule

If the plugin already has diagnostics or environment-awareness features relevant to the task, implementation should consider them.

Do not duplicate environment capability logic unnecessarily.

---

# Allowed Scope

Modify only files directly related to the active task.

Every result should list changed files.

---

# Small-Step Rule

Never implement a whole large feature in one pass.

Implement:
- one task
or
- one clearly isolated subtask

at a time.

---

# WordPress Mandatory Rules

Always respect:
- hooks
- actions
- filters
- capabilities
- nonce checks
- sanitization
- escaping

REST handlers must include:
- permission_callback
- validation / authorization clarity
- sanitized input handling
- standardized JSON responses

---

# Shared Hosting Compatibility Rule

Assume many customers do not have:
- SSH
- WP-CLI
- strong server resources
- stable cron
- broad filesystem access

Avoid unrealistic assumptions in shipped logic.

---

# Client-Side Storage Prohibition Rule

`localStorage`, `sessionStorage`, cookies, and all other browser-side or machine-local storage mechanisms are **forbidden as primary data stores** by default.

This is a prohibition, not a permission model. Do not default to client-side storage and then look for reasons it is acceptable.

## Allowed exceptions (narrow and explicit)

Client-side storage is permitted **only** when ALL of the following are true:

1. The user has explicitly named it in the task description as a requirement, OR
2. The data is mechanically impossible to persist to DB from the current execution context (e.g., an unload-time `sendBeacon` buffer that must survive a JS crash within the same tab life), OR
3. The storage is a pure read-through hydration cache that is always invalidated on next DB read and never used as a write target or source of truth

## Required waiver marker

Any permitted use must include an inline waiver comment at the usage site:

```js
// BROWSER_STORAGE_WAIVER: <reason> | expires: <condition or task reference>
```

Waivers without a reason and expiry condition are not valid.

## What this prevents

- AI defaulting to `localStorage` to avoid implementing a REST endpoint
- session-lost data after browser restart or incognito use
- multi-device inconsistency for operator-visible state
- invisible state divergence between client and DB

---

# DB-First State Rule

For App data and runtime state, default to DB-first behavior.

Any state that must survive a page reload, browser close, or device switch must live in the database. No exceptions without an explicit `BROWSER_STORAGE_WAIVER` marker.

For WebmasterOS-specific visual workflows such as CSS Mixer and queued changes, the displayed state must come from the DB or from cache layers that are invalidated systematically enough to preserve reliable live preview.

---

# New Data Schema Design Gate

Before writing any code that stores new data, stop and answer all five questions below. Do not proceed to implementation until each question has a concrete written answer.

This gate applies whenever a task introduces:
- a new option key in `wp_options`
- a new post meta key
- a new custom table
- a new column on an existing table
- a new JSON blob stored in any field

## Mandatory schema questions

**Q1 — Exact storage target**
What is the precise storage location? Name the table, column, option key, or meta key. Do not describe the shape without naming the location.

**Q2 — New table justification**
If a new table is proposed: justify why the existing schema cannot accommodate the data without fragility. If no new table is proposed: confirm that storing in the existing structure does not require unindexed JSON field scanning to query any individual field.

A blob or JSON column is acceptable only when:
- the field set is genuinely schema-less and will never be queried field-by-field
- OR an explicit waiver `DATA_SCHEMA_WAIVER: <reason>` is documented inline

Silently serializing structured relational data into a `meta_value` blob is **not acceptable** without this waiver.

**Q3 — WP Admin manageability**
How will a WordPress Admin monitor, edit, search, and delete this data? Name the concrete mechanism:
- phpMyAdmin / direct DB (dev-only — not acceptable as the sole admin path unless the data is dev-only)
- custom admin page with `WP_List_Table` or settings API
- existing WMOS admin panel
- WP core list table (e.g., post list, user list)

**Q4 — Operator and end-user surface**
How will the site operator or site user see or interact with this data in the front end or WP admin? If neither surface needs it, state that explicitly as a constraint.

**Q5 — Query pattern**
What are the expected read and write query patterns (e.g., "read all rows for user X", "read latest N by date", "write once on activation")? Confirm that the proposed schema supports those patterns with indexed lookups where volume warrants it.

## Where to record answers

Record answers in the active feature `architecture.md` under the **Data Storage Design** section (see template). Do not skip this section and use placeholders.

---

# Data Source Authority Rule

Do not hardcode mutable runtime variable data in production code paths.

Before adding or changing runtime variable behavior:

- identify the authoritative storage source
- wire read path and write or sync path explicitly
- document fallback behavior and stale-data detection

For temporary exceptions, use an explicit waiver marker and rationale as defined in DATA-SOURCE-AUTHORITY-PROTOCOL.md.

---

# UI Wiring Completeness Rule

A UI task is **not complete** and must not be marked done until the full wiring chain from CTA to DB is implemented and named.

## Required wiring chain

For every task that introduces or modifies UI elements with actions (buttons, forms, toggles, links that trigger state changes):

```
CTA / form element
  → JS event handler  (file path, function name)
    → REST or AJAX call  (URL, method, nonce source)
      → PHP callback  (hook name, class::method)
        → DB operation  (table/option/key, read/write)
```

Every link in this chain must exist as real code, not a stub or placeholder comment.

## What counts as incomplete

- A button that has no JS click listener
- A JS handler that calls `console.log` or shows a notice but makes no HTTP request
- A REST endpoint that is registered but not connected to any DB read or write
- A PHP handler that calls `wp_send_json_success()` with hardcoded or empty data
- A form whose submit action posts to `#` or is not wired to a nonce-protected handler

## Completion output extension

The **Completion Output Format** section already requires Changed Files and Acceptance Criteria. For any task involving UI actions, also include:

```
## Wiring Chain
- [CTA element]  →  [JS handler: file::function]  →  [endpoint: METHOD /path]  →  [PHP: class::method]  →  [DB: table/key]
```

If any link is genuinely deferred to a future task, name it explicitly as deferred with a task reference. Do not omit or skip it silently.

---

# No Hidden Architecture Drift

Do not silently:
- rename architecture layers
- move major files
- change namespaces
- introduce framework-like abstractions

unless the task or architecture explicitly requires it.

---

# File Safety Rule

Respect FILE-SAFETY-RULES.md.

Prefer:
- minimal patch
- validated staged replacement
- no broad delete-and-recreate flow

---

# Validation Rule

Respect VALIDATION-STACK.md.

A task is not complete until relevant validation is done or the missing validation capability is explicitly reported.

---

# Security-First Implementation Rule

Every implementation slice must include an explicit security pass at design time and before final completion.

Minimum security questions per slice:

- what new data entry points are introduced (public or authenticated)
- what trust boundaries are crossed (browser to REST, plugin to control plane, admin to backend)
- what credentials/tokens/secrets are stored, logged, transmitted, or exposed
- what authorization/capability checks enforce access to each action

---

# Attack Surface Checklist Rule

For each new or changed feature path, identify and review attack surfaces including:

- public forms and anonymous endpoints
- authenticated user actions and nonce-protected forms
- REST/AJAX endpoints and permission callbacks
- file upload/download/import/export paths
- remote request and webhook handlers
- debug logs and diagnostics surfaces that may leak sensitive values

Document high-risk surfaces in feature docs (`spec.md`, `tasks.md`, `testing.md`, or `progress.md`) when relevant.

---

# WordPress Incident Vectors Rule

Pay special attention to common WordPress compromise vectors:

- credential exposure in code, logs, debug output, or docs
- brute-force amplification through weak auth/rate controls
- SQL injection through unsanitized query inputs
- XSS through unescaped output or unsafe HTML rendering
- CSRF through missing nonce checks in state-changing actions
- privilege escalation through missing capability enforcement
- unsafe deserialization/file handling and path traversal risks

Where applicable, include concrete mitigations in the same task slice.

---

# Testing Readiness Gate Rule

Before meaningful feature implementation, confirm the testing readiness gate defined in TESTING-PROTOCOL.md.

Minimum requirements:

- target test environments identified
- required access credentials captured in canonical feature docs
- required role accounts and plan/license test assets identified
- success and failure oracles defined for the task being implemented

If the gate is not satisfied, only scaffold or preparatory implementation should proceed, and the gap must be documented in the feature package.

---

# Success Oracle Rule

Implementation validation must check semantic outcomes, not just transport outcomes.

Do not treat HTTP 200 or a rendered success notice alone as proof.

Validation should include:

- expected contract/state fields
- expected counters/limits/activation transitions
- expected negative-path enforcement behavior

---

# Debug Log UX Rule

For feature pages that expose debug tooling, use a standardized two-tab debug pattern:

- tab 1: feature/page WMOS logs
- tab 2: last 50 lines of wp debug log

Show debug tooling only when WordPress debug logging is enabled and access capability is appropriate.

---

# Existing File Respect Rule

When editing an existing file:
- preserve nearby style
- preserve stable logic
- avoid broad formatting churn
- do not rewrite whole files casually

---

# Completion Output Format

Always return:

## Completed Task
[TASK ID]

## Changed Files
- file 1
- file 2

## Acceptance Criteria Check
- item 1 ✅
- item 2 ✅

## Wiring Chain (required for any task with UI actions)
- [CTA element] → [JS handler: file::function] → [endpoint: METHOD /path] → [PHP: class::method] → [DB: table/key]
- If a link is deferred: state "DEFERRED: <reason> — see task [ID]"

## Validation
- [what was checked]
- [what could not be checked]

## Risks
- if any

---

# Forbidden Behaviors

- no speculative refactor
- no hidden dependency injection layers
- no unnecessary abstractions
- no broad stable-code rewrite for style only
- no new libraries unless justified
- no pretending missing validation passed

---

# Conditional Branch Exhaustion Rule

When a UI element (button, section, badge) does not appear and console/DOM inspection confirms the rendering code ran but produced no output, the first diagnosis must be **branch exhaustion** — not a missing variable.

**Mandatory check before any other debugging step:**

1. List every possible model state values (e.g., `status: 'draft' | 'published' | 'disabled'`).
2. Verify that the rendering code has an explicit code branch or `else` for **each** state value.
3. If a state value has no branch, that is the bug. Add the branch. Stop.

**Why AI models get stuck here:**

The iterative console-log debugging pattern hides branch exhaustion bugs. When a `console.log` is added to check variable values, the absence of log output is misread as "the code never reached this point" rather than "all conditions evaluated to false and fell through silently." This leads to repeated `var` declaration fixes, Promise refactors, and fetch-timing investigations — none of which fix a missing `else` branch.

**Correct debugging sequence for "button/section not appearing" reports:**

1. Confirm the containing `.then()` callback ran: look for any log inside that callback.
2. Map every `if / else if` guard in the rendering block to the full set of possible state values.
3. Identify which state value is **not covered**.
4. Add the missing branch.
5. Remove all temporary debug logs in the same fix.

**Console log hygiene (mandatory):**

Temporary `console.log` statements added during debugging are a deliverable blocker. They must be removed in the **same commit** that contains the fix — not deferred to a cleanup task. A fix that ships debug logs is not done.

---

# Final Principle

Implementations in this repository must be:

small  
safe  
status-aware  
WordPress-realistic  
reviewable  

---

# End