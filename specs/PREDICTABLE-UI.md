# Predictable UI Practices (for AI-assisted development)

This document captures the recommended practices for building user interfaces that are **predictable**, **testable**, and **easy for an AI assistant to reason about and modify**.

## Goals

- Make UI changes deterministic and repeatable.
- Allow the AI agent to reason about UI structure and apply changes without guessing.
- Reduce the likelihood of visual drift, layout bugs, or state mismatch.

## 1) Treat UI as an explicit API surface

### a) Design a UI contract

For each major UI area (e.g., Floating Panel), define:

- a set of **CSS/DOM anchors** (IDs/classes) that are stable and intended for programmatic access
- a small set of **public APIs** (JS methods, data attributes, event hooks) for modifying UI state
- a set of **static/immutable regions** vs **dynamic/managed regions**

### b) Use data-driven rendering

Prefer rendering UI from a structured model (JSON/state object) rather than manual DOM mutations.

- Controlled components: store UI state in a single source of truth and render based on that.
- Provide a clear mapping between model fields and DOM output.

### c) Avoid fragile DOM traversal

Instead of "find the nth child of the third `.card` and modify it", prefer:

- `document.querySelector('[data-ui="action-button"]')`
- `document.getElementById('wmos-panel-body')`

Use explicit selectors rather than relative traversal.

## 2) Make layout predictable

### a) Use layout frameworks / patterns

Prefer layout systems that are predictable and composable:

- CSS Grid for 2D layouts
- CSS Flexbox for linear layouts
- CSS custom properties (`--wmos-...`) for theme values

Avoid brittle positioning hacks (e.g., absolute positioning without a stable container).

### b) Use utility classes / design tokens

Define a small set of shared spacing/color/typography tokens, e.g.:

- `--wmos-space-2`, `--wmos-space-4`
- `--wmos-text-small`, `--wmos-text-body`
- `--wmos-color-bg`, `--wmos-color-foreground`

When the AI is asked to make a UI change, have it use these tokens rather than raw values.

## 3) Explicitly separate static vs dynamic content

### a) Static (immutable) regions

Elements that should never be altered by runtime logic (e.g., core panel chrome) must be clearly marked.

Example:

```html
<div id="wmos-panel" data-ui="panel">
  <header data-ui="panel-header">...</header>
  <div data-ui="panel-body" data-ui-static>
    <!-- static content -->
  </div>
</div>
```

### b) Dynamic regions

Dynamic widgets should live in distinct containers and have a clear contract for insertion/removal.
Use a registry/renderer pattern:

```js
const panelSlots = {
  header: document.querySelector('[data-ui="panel-header"]'),
  body: document.querySelector('[data-ui="panel-body"]'),
};

function renderSlot(name, content) {
  panelSlots[name].innerHTML = content;
}
```

## 4) Make UI modifications idempotent and reversible

When the AI generates DOM changes (injected HTML / CSS modifications), ensure they are:

- Scoped (use identifiers / namespacing)
- Reversible (keep a “cleanup” or “reset” path)
- Composable (avoid overwriting unrelated pieces)

Example: use a single root class for AI-generated styles:

```css
.wmos-ai-modified {
  outline: 2px dashed #0af;
}
```

And remove it when done.

## 5) Use the toolkit’s capture/validation tooling as the source of truth

When the AI needs to debug UI rendering:

1. Run `./scripts/ai-toolkit.sh --ui ...` (it will capture and validate automatically)
2. Read the generated `fix-suggestions.json` / `selector-insights.json`
3. Apply changes that address the exact hint (e.g., z-index overlap, contrast ratio)

By keeping the AI workflow tied to these tools, we ensure the AI never has to guess or rely on vague “it looks wrong” messages.
## 6) Debugging: element not appearing

When a UI element (button, section, badge) is expected but does not appear, follow this diagnostic tree **in strict order**. Do not skip steps or jump to hypotheses based on recent changes.

### Step 1 — Confirm the render function ran

Add a single temporary log at the top of the `.then()` callback or render function that should produce the missing element. If the log never fires, the problem is upstream (fetch failure, wrong event handler, wrong entry point).

If the log **does** fire, proceed to Step 2.

### Step 2 — Read `children.length` as a definitive signal

```js
console.log('container children:', container.children.length, Array.from(container.children).map(c => c.tagName));
```

If the count equals only the structural children (a wrapper DIV, a header row) and no action elements are present, the interpretation is unambiguous: **all conditional branches evaluated to false and the function exited without appending anything**. This is not caused by:

- a missing variable declaration
- a Promise timing issue
- a fetch race condition

It is always caused by **branch exhaustion**. Proceed to Step 3.

### Step 3 — Enumerate the full model state space

List every possible value of the state variable that gates rendering. Verify that the code has an explicit branch for each one:

| State value | Expected elements | Branch exists? |
|-------------|-------------------|----------------|
| `draft`     | Publish button    | ?              |
| `published` | Re-publish + Un-publish buttons | ?  |
| `disabled`  | Publish button    | ?              |

Any row with `? = no` is the bug. The state currently being tested will always be in an uncovered row.

### Step 4 — Add the missing branch

Add an `else` (or additional `else if`) block for the uncovered state. Remove all temporary debug logs **in the same change**. Do not defer log cleanup to a separate task — shipping debug logs is incomplete work.

### Anti-patterns that waste iterations

- **Adding `var isXxx` declarations** — variable scope is almost never the cause when the render function ran but produced zero children.
- **Wrapping fetches in `Promise.all`** — fetch timing does not explain children-count = structural-only.
- **Iterating more than twice on the same hypothesis** — if the same fix attempt has been tried twice, stop and enumerate the state space instead.
- **Treating "console log never fired" as inconclusive** — if a log inside the `.then()` block fires and only one structural DIV is present, branch exhaustion is the diagnosis. No other investigation is needed first.