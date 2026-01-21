### Run notes (why snippet-only)

This repository is intentionally **not** a runnable Godot project.

### Why

- The full project contains assets, narrative content, and internal tooling that cannot be shared publicly.
- This extract focuses on showing architecture and code quality in a small, reviewable slice.

### How a demo will be added later

- Add a minimal Godot project scaffold that imports `snippets/` as scripts.
- Add a lightweight scene that instantiates:
  - `DialogueView`
  - `ChoicePanel`
  - `RoomController`
  - `SanitySystem`
  - `DataRepository` loaded from `samples/*.json`
