### UI system (signals/events flow)

UI is state-driven. `RoomController` owns the game state, UI nodes render a projection of that state.
An optional “event bus” keeps wiring explicit and prevents hidden dependencies.

[ChoicePanel] -- emits --> choice_pressed(choice_id)
| |
v v
renders choices[] [DialogueView]
(id, label, enabled) updates text + choice list
| |
+----------- notify -------+
|
v
[RoomController]
validates action (sanity/band/flags)
applies effects (sanity/flags/items)
computes next state + next room
pushes updated view-model to UI


### Event contract (extract)
- `choice_pressed(choice_id: String)` — user intent
- `room_loaded(room_id: String)` — controller lifecycle (optional)
- `state_changed(snapshot: Dictionary)` — UI refresh trigger (optional)

> This repo keeps event wiring explicit in `snippets/event_bus_or_signals.gd`.
> In a full project this can be direct signals or an autoload.

### Ownership rules (important)
- **RoomController is the single source of truth** (sanity, flags/items, current room).
- UI nodes do not mutate state directly; they emit intent and render output.

### Text flow
- `DialogueView` displays text provided by controller.
- Controller may pass text through `TextMutator` before rendering (sanity-driven mutation).
