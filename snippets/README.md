### Security / sanitization notes

- **No proprietary content**: story text, narrative assets, and spoiler strings are removed or replaced with `"TEXT_PLACEHOLDER"`.
- **No production IDs**: real room IDs, action IDs, item IDs, flags, and internal naming are replaced with synthetic placeholders (e.g., `"room_alpha"`, `"FLAG_EXAMPLE"`).
- **No internal data dumps**: large JSON/DB exports are not included; only minimal synthetic samples exist under `samples/`.
- **No local machine traces**: no absolute paths, usernames, or environment-specific references.
- **No assets or exports**: images/audio/fonts/imports and build artifacts are intentionally excluded.

### Redactions / TODOs

- The `snippets/data_loader_sqlite_to_json.gd` shows the intended **SQLite→JSON cache** pattern but does **not** ship a real DB or schema. The DB layer is stubbed and marked TODO.



