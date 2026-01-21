### Sanity system (bands + mutation hooks)

Sanity is a deterministic state machine that drives **presentation + gating**, not “random horror effects”.
It’s designed to be **debuggable** and **data-driven**.

#### Core rules
- Sanity is clamped to **0–100**
- Sanity maps to a **band** (discrete state)
- Band is the single source of truth for:
  - UI/text mutation intensity
  - action availability (constraints)
  - optional rule evaluation (data-driven modifiers)

#### Bands used in snippets
- `clean`: 90–100
- `mild`: 70–89
- `unstable`: 50–69
- `broken`: 30–49
- `collapse`: 0–29

#### Why bands (instead of raw value everywhere)
- keeps logic readable (`band == broken`) vs magic numbers
- enables content authoring by designers (rules per band)
- prevents “micro-flapping” when sanity changes by small deltas

#### Mutation hooks (integration points)
- `RoomController` passes text through `TextMutator.mutate_text_for_sanity(text, sanity)`
- `ChoicePanel` can optionally filter/label actions via sanity constraints (band thresholds)

#### Determinism (important)
Mutation is deterministic (no RNG) so:
- the same input state produces the same UI output
- bugs are reproducible
- automated tests / snapshot comparisons are feasible

#### Data-driven extension (full project pattern)
In the full project, `samples/sanity_rules_sample.json` represents the pattern:
rules can be attached per band to modify:
- text mutation parameters
- action constraints
- ambient selection

