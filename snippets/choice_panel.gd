# Role: UI component responsible for presenting a list of choices to the player.
# Inputs: Array of choice dictionaries, typically: [{id:String, label:String}, ...].
# Outputs: Emits `choice_pressed(choice_id)` when a choice is selected.
# Key invariants: Choice IDs must be non-empty strings; empty list hides/clears choices.
# Dependencies: Pure GDScript node; in a full UI it would create Buttons (omitted here).
# Redactions/TODO: Production styling, animations, accessibility, and input focus handling removed.
# Spoiler policy: Labels are placeholders; no story content is present.
# Failure behavior: Invalid items are skipped safely; signal is only emitted for valid IDs.
# Integration: DialogueView owns/wires this panel; RoomController consumes the emitted choice IDs.
# Testing note: You can call `simulate_press("id")` to test flow without UI nodes.
# Godot note: Written to compile without requiring a scene tree.

extends Node
class_name ChoicePanel

signal choice_pressed(choice_id: String)

var _choices: Array[Dictionary] = []

func build_choices(items: Array) -> void:
	_choices.clear()
	for item in items:
		if item is Dictionary:
			var id := DataContracts.safe_string(item.get("id"))
			var label := DataContracts.safe_string(item.get("label"))
			if id == "":
				continue
			_choices.append({"id": id, "label": label})

func get_choices() -> Array[Dictionary]:
	return _choices.duplicate(true)

func simulate_press(choice_id: String) -> void:
	# For snippet-only demo/testing.
	if choice_id == "":
		return
	for c in _choices:
		if c.get("id", "") == choice_id:
			choice_pressed.emit(choice_id)
			return




