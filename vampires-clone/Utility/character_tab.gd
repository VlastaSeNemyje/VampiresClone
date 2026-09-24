extends Control

signal tab_selected(index)

@export var index: int = 0
@export var character_name: String = "???"
@export var portrait_texture: Texture2D

@onready var portrait: TextureRect = $Portrait
@onready var name_label: Label = $lbl_name
@onready var lock_label: Label = $lbl_locked
@onready var selection_border: ColorRect = $SelectionBorder

var unlocked := false


func _ready() -> void:
	GameProgress.connect("progress_changed", Callable(self, "refresh"))
	portrait.texture = portrait_texture
	refresh()


func refresh() -> void:
	unlocked = GameProgress.is_unlocked(index)

	if unlocked:
		portrait.modulate = Color(1, 1, 1, 1)
		name_label.modulate = Color(1, 1, 1, 1)
		lock_label.visible = false
		name_label.text = character_name
	else:
		# Cheap silhouette: multiplying any texture by black keeps its
		# shape/alpha but flattens all color, no separate art needed.
		portrait.modulate = Color(0, 0, 0, 1)
		# Text gets its own, independent tint — dimmed grey rather than
		# pure black, so "???" stays legible against the dark portrait.
		name_label.modulate = Color(0.6, 0.6, 0.6, 1)
		lock_label.visible = true
		name_label.text = "???"

	set_selected(GameProgress.selected_index == index)


func set_selected(is_selected: bool) -> void:
	selection_border.visible = is_selected and unlocked


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if unlocked:
			emit_signal("tab_selected", index)
