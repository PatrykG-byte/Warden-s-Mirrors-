# Role: Demonstrates a SQLite → JSON cache export pipeline used for data-driven content.
# Inputs: A SQLite connection/path (private in production) and an output cache path.
# Outputs: JSON cache files (rooms/actions/rules) consumable at runtime by DataRepository.
# Key invariants: Export must be deterministic, stable field names, and schema-versioned.
# Dependencies: In production this uses a SQLite addon (e.g., a GDNative/GDExtension wrapper).
# Redactions/TODO: This public extract does NOT ship a DB, schema, or SQLite dependency.
#                 The DB query layer is stubbed; only mapping logic + cache lifecycle is shown.
# Security: No internal DB paths, no real IDs, and no narrative content; this is illustrative only.
# Failure behavior: Export functions return error codes; callers should surface errors in tooling.
# Integration: Runtime uses JSON only (see DataRepository); exporter is build-time tooling.
# Testing note: Export can be tested against synthetic rows (see _synthetic_rows_for_demo()).
# Spoiler policy: Any text fields must be placeholders; never export story content here.

extends Node
class_name DataLoaderSQLiteToJson

const SCHEMA_VERSION := 1

func export_all_to_cache(output_dir: String) -> int:
	# In a real tool script, `output_dir` would be something like: "res://cache/generated/"
	# Here we keep it simple and show the shape of outputs.
	var rooms_json := _export_rooms_json()
	var rules_json := _export_sanity_rules_json()

	var err := _write_json(output_dir.path_join("rooms_cache.v%d.json" % SCHEMA_VERSION), rooms_json)
	if err != OK:
		return err
	err = _write_json(output_dir.path_join("sanity_rules_cache.v%d.json" % SCHEMA_VERSION), rules_json)
	return err

func _export_rooms_json() -> Dictionary:
	# TODO: Replace `_synthetic_rows_for_demo()` with real SQL queries:
	# - SELECT * FROM rooms;
	# - SELECT * FROM actions WHERE room_id = ?;
	var rows := _synthetic_rows_for_demo()

	var by_room: Dictionary = {}
	for row in rows:
		var room_id := str(row.get("room_id", ""))
		if room_id == "":
			continue
		if not by_room.has(room_id):
			by_room[room_id] = {
				"id": room_id,
				"entry_text_by_sanity": {},
				"ambient_by_sanity": {},
				"actions": []
			}

		var room := by_room[room_id] as Dictionary

		# Map “entry variants” (sanity-banded) into entry_text_by_sanity
		var band_key := str(row.get("band_key", "90-100"))
		var entry_text := str(row.get("entry_text", "TEXT_PLACEHOLDER"))
		(room["entry_text_by_sanity"] as Dictionary)[band_key] = entry_text

		# Optionally map ambient snippets per band
		var ambient := str(row.get("ambient_text", ""))
		if ambient != "":
			var amb_by := room["ambient_by_sanity"] as Dictionary
			if not amb_by.has(band_key):
				amb_by[band_key] = []
			(amb_by[band_key] as Array).append(ambient)

		# Actions are separate rows in production; kept inline here for demonstration.
		if row.has("action_id"):
			(room["actions"] as Array).append(_map_action_row(row))

	var locations: Array = []
	for room_id in by_room.keys():
		locations.append(by_room[room_id])
	return {"schema_version": SCHEMA_VERSION, "locations": locations}

func _export_sanity_rules_json() -> Dictionary:
	# TODO: Real query: SELECT * FROM sanity_rules;
	return {
		"schema_version": SCHEMA_VERSION,
		"rules": [
			{"id": "rule_example", "when": {"sanity_lte": 49}, "then": {"emit_event": "sanity_band_changed"}}
		]
	}

func _map_action_row(row: Dictionary) -> Dictionary:
	return {
		"id": str(row.get("action_id", "action_placeholder")),
		"label_preview": str(row.get("label_preview", "CHOICE_PLACEHOLDER")),
		"result_text": str(row.get("result_text", "")),
		"costs": {"sanity": int(row.get("cost_sanity", 0)), "items": {}},
		"effects": {"goto": row.get("goto", null), "items_add": {}, "flags": []},
		"sanity_constraints": str(row.get("sanity_constraints", "any")),
		"visibility_rules": []
	}

func _write_json(path: String, data: Dictionary) -> int:
	var json_text := JSON.stringify(data, "  ")
	var f := FileAccess.open(path, FileAccess.WRITE)
	if f == null:
		return ERR_CANT_CREATE
	f.store_string(json_text)
	f.close()
	return OK

func _synthetic_rows_for_demo() -> Array:
	# Synthetic “joined” rows resembling a denormalized SQL result.
	return [
		{
			"room_id": "room_alpha",
			"band_key": "90-100",
			"entry_text": "TEXT_PLACEHOLDER: exported entry.",
			"ambient_text": "TEXT_PLACEHOLDER: exported ambient.",
			"action_id": "go_to_corridor",
			"label_preview": "Go to corridor",
			"result_text": "",
			"goto": "corridor_01",
			"cost_sanity": 1,
			"sanity_constraints": "any"
		}
	]




