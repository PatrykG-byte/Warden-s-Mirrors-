# Role: Orchestrates room routing/state transitions in a data-driven narrative loop.
# Inputs: room_id to load, choice_id from UI, and current game state (flags/items/sanity).
# Outputs: Calls DialogueView to show text/ambient and build visible choices; updates game state.
# Key invariants: Never crash on missing data; always apply fallbacks. State updates follow:
#                 sanity_delta → costs → effects → result_text → goto/refresh.
# Dependencies: DataRepository (JSON cache), SanitySystem, TextMutator, DialogueView, EventBus.
# Redactions/TODO: Visual state, audio, localization keys, and richer rules removed for public repo.
# Spoiler policy: Text is placeholder-only; IDs are synthetic (room_alpha, etc.).
# Failure behavior: Unknown room/action results in warnings and safe no-op; clamps sanity to 0..100.
# Integration: In the original project this lives in `controllers/room/RoomController.gd` and reads
#              a large rooms JSON; this extract replaces it with `samples/rooms_sample.json`.
# Security: No assets loaded; no absolute paths; no internal content or DB references.

extends Node
class_name RoomController

const DEFAULT_START_ROOM := "room_alpha"

class DataRepository:
	# Minimal runtime repository that loads the JSON cache (rooms/actions) and provides safe access.
	# Kept local to this snippet to avoid adding extra files beyond the requested export set.
	var _db: Dictionary = {}

	func load_rooms_from_json_path(json_path: String) -> bool:
		var f := FileAccess.open(json_path, FileAccess.READ)
		if f == null:
			return false
		var text := f.get_as_text()
		f.close()
		var parsed = JSON.parse_string(text)
		if not (parsed is Dictionary):
			return false
		_db = parsed
		return true

	func get_room(room_id: String) -> Dictionary:
		var locations_val = _db.get("locations", null)
		if not (locations_val is Array):
			return {}
		for loc in locations_val:
			if loc is Dictionary and str(loc.get("id", "")) == room_id:
				return loc
		return {}

	func pick_banded_text(entry_by_sanity, band_key: String) -> String:
		if entry_by_sanity is Dictionary and entry_by_sanity.has(band_key):
			return str(entry_by_sanity[band_key])
		# Fallback: first available string
		if entry_by_sanity is Dictionary:
			for k in entry_by_sanity.keys():
				if entry_by_sanity[k] is String:
					return str(entry_by_sanity[k])
		return ""

	func pick_banded_ambient(ambient_by_sanity, band_key: String) -> String:
		if ambient_by_sanity is Dictionary and ambient_by_sanity.has(band_key):
			var arr = ambient_by_sanity[band_key]
			if arr is Array and arr.size() > 0:
				return str(arr[0])
		return ""

var repo: DataRepository
var view: DialogueView
var bus: EventBus
var sanity: SanitySystem

var flags: Dictionary = {}
var items: Dictionary = {}

var _current_room_id: String = ""
var _current_room: Dictionary = {}

func configure(repository: DataRepository, dialogue_view: DialogueView, event_bus: EventBus, sanity_system: SanitySystem) -> void:
	repo = repository
	view = dialogue_view
	bus = event_bus
	sanity = sanity_system

func set_initial_state(initial_flags: Dictionary, initial_items: Dictionary, initial_sanity: int = 100) -> void:
	flags = initial_flags if initial_flags is Dictionary else {}
	items = initial_items if initial_items is Dictionary else {}
	sanity.set_sanity(initial_sanity)

func load_room(room_id: String) -> void:
	var room := repo.get_room(room_id)
	if room.is_empty():
		push_warning("RoomController.load_room: unknown room_id='%s'" % room_id)
		return

	_current_room_id = room_id
	_current_room = room

	# Apply optional room-level sanity delta
	var room_delta := DataContracts.safe_int(room.get("sanity_delta"), 0)
	if room_delta != 0:
		sanity.apply_delta(room_delta)

	# Select banded entry/ambient
	var band_key := DataContracts.band_key_from_sanity(sanity.get_sanity())
	var entry := repo.pick_banded_text(room.get("entry_text_by_sanity", {}), band_key)
	var ambient := repo.pick_banded_ambient(room.get("ambient_by_sanity", {}), band_key)

	# Mutate entry text based on sanity band
	entry = TextMutator.mutate_text_for_sanity(entry, sanity.get_sanity())

	view.show_line(entry)
	if ambient != "":
		view.show_ambient(ambient)

	view.build_choices(_build_visible_choices(room.get("actions", [])))

func on_choice_pressed(choice_id: String) -> void:
	if _current_room.is_empty():
		return

	var action := _find_action(_current_room.get("actions", []), choice_id)
	if action.is_empty():
		push_warning("RoomController.on_choice_pressed: unknown choice_id='%s'" % choice_id)
		return

	# Pipeline: sanity_delta (action) → costs → effects → result_text → goto/refresh
	var action_delta := DataContracts.safe_int(action.get("sanity_delta"), 0)
	if action_delta != 0:
		sanity.apply_delta(action_delta)

	_apply_costs(action.get("costs", {}))
	var goto_room := _apply_effects(action.get("effects", {}))

	var result_text := DataContracts.safe_string(action.get("result_text"))
	if result_text != "":
		view.show_line(TextMutator.mutate_text_for_sanity(result_text, sanity.get_sanity()))

	# Allow sanity rules to react after state changes
	sanity.evaluate_rules(flags, items)

	if goto_room == "":
		# Refresh current room actions based on new state
		view.build_choices(_build_visible_choices(_current_room.get("actions", [])))
		return

	load_room(goto_room)

func _build_visible_choices(actions_raw) -> Array:
	var out: Array = []
	for a in DataContracts.safe_array(actions_raw):
		if not (a is Dictionary):
			continue
		if not _passes_sanity_constraints(a):
			continue
		if not _passes_visibility_rules(a):
			continue
		if not _can_afford_costs(a.get("costs", {})):
			continue
		out.append({
			"id": DataContracts.safe_string(a.get("id")),
			"label": DataContracts.safe_string(a.get("label_preview"))
		})
	return out

func _passes_sanity_constraints(action: Dictionary) -> bool:
	var c := DataContracts.safe_string(action.get("sanity_constraints", "any"))
	if c == "" or c == "any":
		return true
	var n := sanity.get_sanity()
	if "-" in c:
		var parts := c.split("-")
		if parts.size() == 2:
			return n >= int(parts[0]) and n <= int(parts[1])
	if c.begins_with(">="):
		return n >= int(c.substr(2))
	if c.begins_with("<="):
		return n <= int(c.substr(2))
	if c.begins_with(">"):
		return n > int(c.substr(1))
	if c.begins_with("<"):
		return n < int(c.substr(1))
	return true

func _passes_visibility_rules(action: Dictionary) -> bool:
	var rules := DataContracts.safe_array(action.get("visibility_rules", []))
	for r in rules:
		if not (r is Dictionary):
			continue
		if r.has("flag"):
			var f := DataContracts.safe_string(r.get("flag"))
			var want := bool(r.get("value", true))
			var op := DataContracts.safe_string(r.get("op", "=="))
			var have := bool(flags.get(f, false))
			if op == "==" and have != want:
				return false
			if op == "!=" and have == want:
				return false
		if r.has("item"):
			var item_id := DataContracts.safe_string(r.get("item"))
			var want_n := DataContracts.safe_int(r.get("value"), 0)
			var op2 := DataContracts.safe_string(r.get("op", ">="))
			var have_n := int(items.get(item_id, 0))
			if op2 == ">=" and have_n < want_n:
				return false
			if op2 == ">" and have_n <= want_n:
				return false
			if op2 == "==" and have_n != want_n:
				return false
			if op2 == "<=" and have_n > want_n:
				return false
			if op2 == "<" and have_n >= want_n:
				return false
			if op2 == "!=" and have_n == want_n:
				return false
	return true

func _can_afford_costs(costs) -> bool:
	if not (costs is Dictionary):
		return true
	var cost_items := DataContracts.safe_dict(costs.get("items", {}))
	for k in cost_items.keys():
		var need := int(cost_items.get(k, 0))
		if int(items.get(k, 0)) < need:
			return false
	return true

func _apply_costs(costs) -> void:
	if not (costs is Dictionary):
		return
	var cost_sanity := DataContracts.safe_int(costs.get("sanity"), 0)
	if cost_sanity != 0:
		sanity.apply_delta(-cost_sanity)

	var cost_items := DataContracts.safe_dict(costs.get("items", {}))
	for k in cost_items.keys():
		var need := int(cost_items.get(k, 0))
		if need <= 0:
			continue
		var have := int(items.get(k, 0))
		items[k] = max(0, have - need)

func _apply_effects(effects) -> String:
	if not (effects is Dictionary):
		return ""
	# effects: goto, items_add, flags, sanity_delta (optional)
	var sd := DataContracts.safe_int(effects.get("sanity_delta"), 0)
	if sd != 0:
		sanity.apply_delta(sd)

	var items_add := DataContracts.safe_dict(effects.get("items_add", {}))
	for k in items_add.keys():
		var add := int(items_add.get(k, 0))
		if add <= 0:
			continue
		items[k] = int(items.get(k, 0)) + add

	var flag_list := DataContracts.safe_array(effects.get("flags", []))
	for f in flag_list:
		if f is String and f != "":
			flags[f] = true

	var goto_val = effects.get("goto", null)
	if goto_val is String:
		return goto_val
	return ""

func _find_action(actions_raw, action_id: String) -> Dictionary:
	for a in DataContracts.safe_array(actions_raw):
		if a is Dictionary and DataContracts.safe_string(a.get("id")) == action_id:
			return a
	return {}



