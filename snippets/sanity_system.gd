# Role: Central sanity state (0–100) + band mapping + lightweight rule evaluation hook.
# Inputs: Deltas (apply_delta), absolute set (set_sanity), and optional rule sets (Array[Dict]).
# Outputs: Current sanity value + band; emits signals on change for UI/mutation hooks.
# Key invariants: Sanity is clamped to 0..100. Band mapping must be consistent across code.
# Dependencies: Pure GDScript; optional EventBus for broadcasting changes; DataContracts helpers.
# Redactions/TODO: Production rules engine supports more conditions/actions; this extract shows a
#                 minimal “when/then” evaluator for demonstration only.
# Spoiler policy: No narrative text; rules operate on numeric state and synthetic IDs only.
# Failure behavior: Invalid rules are ignored safely (no crash).
# Integration: RoomController owns/uses SanitySystem; DialogueView listens for changes.
# Testing note: Deterministic and side-effect free except for emitted signals.
# Security: No persistence, telemetry, or remote calls in this extract.

extends Node
class_name SanitySystem

signal sanity_changed(new_value: int, new_band: String)

var _value: int = 100
var _rules: Array = []
var _bus: EventBus = null

func configure(event_bus: EventBus, rules: Array = []) -> void:
	_bus = event_bus
	_rules = rules if rules is Array else []

func get_sanity() -> int:
	return _value

func set_sanity(value: int) -> void:
	_apply_new_value(DataContracts.safe_int(value, 100))

func apply_delta(delta: int) -> void:
	_apply_new_value(_value + DataContracts.safe_int(delta, 0))

func get_band() -> String:
	return _band_from_value(_value)

func evaluate_rules(game_flags: Dictionary, game_items: Dictionary) -> void:
	# Minimal “when/then” pattern:
	# when: sanity_lte / flag_is_true / item_lte {id,value}
	# then: sanity_delta / emit_event
	for rule in _rules:
		if not (rule is Dictionary):
			continue
		if not _rule_matches(rule.get("when", {}), game_flags, game_items):
			continue
		_apply_rule_then(rule.get("then", {}))

func _apply_new_value(v: int) -> void:
	var clamped := clampi(v, 0, 100)
	if clamped == _value:
		return
	_value = clamped
	var band := get_band()
	sanity_changed.emit(_value, band)
	if _bus != null:
		_bus.emit_sanity(_value, band)

func _band_from_value(v: int) -> String:
	if v >= 90:
		return "clean"
	if v >= 70:
		return "mild"
	if v >= 50:
		return "unstable"
	if v >= 30:
		return "broken"
	return "collapse"

func _rule_matches(when_clause, flags: Dictionary, items: Dictionary) -> bool:
	if not (when_clause is Dictionary):
		return false
	if when_clause.has("sanity_lte"):
		return _value <= DataContracts.safe_int(when_clause.get("sanity_lte"), 100)
	if when_clause.has("flag_is_true"):
		var f := DataContracts.safe_string(when_clause.get("flag_is_true"))
		return f != "" and bool(flags.get(f, false)) == true
	if when_clause.has("item_lte"):
		var spec = when_clause.get("item_lte")
		if not (spec is Dictionary):
			return false
		var item_id := DataContracts.safe_string(spec.get("id"))
		var limit := DataContracts.safe_int(spec.get("value"), 0)
		return int(items.get(item_id, 0)) <= limit
	return false

func _apply_rule_then(then_clause) -> void:
	if not (then_clause is Dictionary):
		return
	if then_clause.has("sanity_delta"):
		apply_delta(DataContracts.safe_int(then_clause.get("sanity_delta"), 0))
	if then_clause.has("emit_event") and _bus != null:
		var ev := DataContracts.safe_string(then_clause.get("emit_event"))
		if ev != "":
			_bus.emit_event(ev, {"sanity": _value, "band": get_band()})




