### Data pipeline (SQLite → JSON cache lifecycle)

This extract demonstrates the pattern used for data-driven content:

- **Authoring source**: SQLite database (private; not included here)
- **Export**: a build-time script produces JSON cache(s)
- **Runtime**: the game loads JSON only (fast, deterministic, easy to patch)

```
SQLite (private) ── export ──> JSON cache ── load ──> DataRepository API
```

### Runtime expectations (this repo)

- `samples/rooms_sample.json` contains `locations[]` with minimal fields:
  - `id`, `entry_text_by_sanity`, `ambient_by_sanity`, `actions[]`
- `samples/sanity_rules_sample.json` contains simple rule objects used by `SanitySystem`.
- `samples/flags_items_sample.json` contains initial flags/items for bootstrapping a run.

### Redactions / TODO

- `snippets/data_loader_sqlite_to_json.gd` stubs the SQLite query layer. The goal is to show:
  - how rows are mapped into JSON structures
  - how cache versioning/invalidation could work



