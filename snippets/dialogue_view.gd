# Role: UI-facing “view” that displays dialogue/ambient text and hosts the ChoicePanel.
# Inputs: show_line(text), show_ambient(text), build_choices([{id,label}]).
# Outputs: Emits/forwards selection events to EventBus or directly to RoomController.
# Key invariants: View must never mutate game state directly; it only forwards intent.
# Dependencies: ChoicePanel (child/owned), optional EventBus for publishing UI events.
# Redactions/TODO: Real UI nodes (RichTextLabel/Buttons/animations) removed; only logic remains.
# Spoiler policy: Displayed strings should be placeholders; no story content is shipped here.
# Failure behavior: Null/empty strings are handled safely; choices can be rebuilt at any time.
# Integration: RoomController calls view methods; view forwards choice presses to controller/bus.
# Testing note: Works without a scene tree; inspect `last_line` / `last_ambient`.
# Godot note: This is a minimal logic facade, not a full scene implementation.

extends Node
class_name DialogueView

var last_line: String = ""
var last_ambient: String = ""

var choice_panel: ChoicePanel
var event_bus: EventBus = null
var room_controller: RoomController = null

func configure(bus: EventBus, controller: RoomController) -> void:
	event_bus = bus
	room_controller = controller

	if choice_panel == null:
		choice_panel = ChoicePanel.new()
		add_child(choice_panel)
	choice_panel.choice_pressed.connect(_on_choice_pressed)

func show_line(text: String) -> void:
	last_line = text if text != null else ""

func show_ambient(text: String) -> void:
	last_ambient = text if text != null else ""

func build_choices(items: Array) -> void:
	if choice_panel == null:
		choice_panel = ChoicePanel.new()
		add_child(choice_panel)
		choice_panel.choice_pressed.connect(_on_choice_pressed)
	choice_panel.build_choices(items)

func _on_choice_pressed(choice_id: String) -> void:
	if event_bus != null:
		event_bus.emit_choice(choice_id)
	if room_controller != null:
		room_controller.on_choice_pressed(choice_id)




