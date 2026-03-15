# WordPress Plugin Dev Template

Thin bootstrap repository for starting a new WordPress plugin project that uses shared development layers.

This repository is intentionally not the long-term home of the reusable framework itself.

Use it to create a new app-local plugin repository, then pull shared layers into:

- `foundation/core` from `master-core`
- `foundation/wp` from `wp-overlay`

The template owns:

- root adapter docs
- IDE AI entry instructions
- workspace bootstrap and sync scripts
- minimal product-spec scaffolding
- VS Code workspace helpers

The shared repositories own:

- reusable AI-context and workflow rules
- reusable validation and handover scripts
- reusable WordPress runtime and packaging assets

## Bootstrap Order

1. Create a new repository from this template.
2. Set your product/plugin name in the root adapters.
3. Add `master-core` and `wp-overlay` remotes.
4. Pull `foundation/core` and `foundation/wp` using subtree.
5. Keep app truth in root `specs/` and product code folders.

## Shared-Layer Rule

Improve reusable process, IDE context, and runtime scaffolding upstream first.

Then pull those improvements into each plugin project.