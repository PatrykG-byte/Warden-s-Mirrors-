### Architecture overview (snippet-only)

This repo is a sanitized “tech extract”. It contains a minimal, coherent slice of the runtime architecture:

```
   (offline / build-time)                 (runtime)
┌─────────────────────────┐     ┌───────────────────────────────┐
│ SQLite content (private)│     │ JSON cache (sanitized sample)  │
│  - rooms table          │     │  - rooms_sample.json           │
│  - sanity_rules table   │ ─→  │  - sanity_rules_sample.json    │
└───────────┬─────────────┘     └──────────────┬────────────────┘
            │ export/build cache                 │ load
            ▼                                    ▼
     DataLoaderSQLiteToJson                 DataRepository
            │                                    │
            ▼                                    ▼
       RoomController  ───────────────→  DialogueView
            │                                  │
            │ emits/binds signals               │ builds UI
            ▼                                  ▼
         EventBus  ←───────────────  ChoicePanel (choice_pressed)
            │
            ▼
       SanitySystem ──→ TextMutator (sanity-driven mutation hooks)
```

### Core responsibilities

- `DataRepository`: reads JSON cache, provides typed-ish accessors
- `RoomController`: loads room state, filters actions, applies effects/costs, routes to next room
- `DialogueView`: displays mutated dialogue lines, forwards choices to the controller
- `ChoicePanel`: renders choice buttons, emits `choice_pressed(choice_id)`
- `SanitySystem`: maintains sanity value (0–100) and band mapping; can evaluate simple rules
- `TextMutator`: deterministic transformation for “unstable/broken/collapse” bands



