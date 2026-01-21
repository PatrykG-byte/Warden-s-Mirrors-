# Samples (synthetic data)

This folder contains **synthetic JSON files** used only to demonstrate the data contracts expected by the runtime code in `snippets/`.

These files are **not production content** (no real story text, no internal IDs, no exports).

## Files

- `rooms_sample.json`
  - Minimal room/location dataset used to show routing + UI rendering.
  - Focus: `locations[]`, `actions[]`, and sanity-dependent text fields.

- `sanity_rules_sample.json`
  - Minimal rule dataset used to demonstrate sanity evaluation patterns.
  - Focus: `rules[]` with simple `when` → `then` effects (deterministic).

- `flags_items_sample.json`
  - Minimal bootstrapping state for flags and inventory/items.
  - Focus: initial defaults + basic constraints for rule checks.

## Notes

- JSON shapes here should match what the extract expects.
- If you want to reproduce the system, replace placeholders carefully and keep the schema consistent.

