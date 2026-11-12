extends Control

signal tab_selected(index)

@export var index: int = 0
@export var character_name: String = "???"
@export var portrait_texture: Texture2D

@onready var portrait: TextureRect = $Portrait
@onready var name_label: Label = $lbl_name
@onready var lock_label: Label = $lbl_locked
@onready var selection_border: Panel = $SelectionBorder

var unlocked := false
var selected := false
var hovered := false

const TEX_FRAME := preload("res://Textures/Sprites/Menu/Frame.png")
const TEX_FRAME_SELECTED := preload("res://Textures/Sprites/Menu/Frame selected.png")

# Art rects placed so each sprite's border line lands exactly on the 100x140 card.
const RECT_FRAME := Rect2(-7.4, -12.2, 115.8, 167.4)
const RECT_SELECTED := Rect2(-6.4, -12.9, 112.4, 162.8)

const TINT_BASE := Color(0.5, 0.1, 0.12, 1)
const TINT_HOVER := Color(1, 0.3, 0.3, 1)
const TINT_SELECTED := Color(1, 0.3, 0.3, 1)

@onready var frame_art: TextureRect = $FrameArt

var _style_base := _make_style(Color(0.04, 0.02, 0.02, 1), 0)
var _style_hover := _make_style(Color(0.04, 0.02, 0.02, 1), 8)
var _style_selected := _make_style(Color(0.33, 0.03, 0.05, 1), 10)


func _make_style(bg: Color, glow: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	if glow > 0:
		s.shadow_color = Color(1, 0.1, 0.1, 0.4)
		s.shadow_size = glow
	return s


func _update_frame() -> void:
	if selected:
		selection_border.add_theme_stylebox_override("panel", _style_selected)
		frame_art.texture = TEX_FRAME_SELECTED
		_place_art(RECT_SELECTED)
		frame_art.modulate = TINT_SELECTED
	elif (hovered or has_focus()) and unlocked:   # browsed, not confirmed yet
		selection_border.add_theme_stylebox_override("panel", _style_hover)
		frame_art.texture = TEX_FRAME
		_place_art(RECT_FRAME)
		frame_art.modulate = TINT_HOVER
	else:
		selection_border.add_theme_stylebox_override("panel", _style_base)
		frame_art.texture = TEX_FRAME
		_place_art(RECT_FRAME)
		frame_art.modulate = TINT_BASE



func _ready() -> void:
	GameProgress.connect("progress_changed", Callable(self, "refresh"))
	mouse_entered.connect(func(): hovered = true; _update_frame())
	mouse_exited.connect(func(): hovered = false; _update_frame())
	# Keyboard cursor = focus. Mouse and keyboard share it: hovering a tab also moves the cursor there.
	focus_entered.connect(_update_frame)
	focus_exited.connect(_update_frame)
	mouse_entered.connect(func(): if unlocked: grab_focus())
	portrait.texture = portrait_texture
	refresh()


func refresh() -> void:
	unlocked = GameProgress.is_unlocked(index)
	focus_mode = Control.FOCUS_ALL if unlocked else Control.FOCUS_NONE   # the cursor skips locked characters

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
	selected = is_selected and unlocked
	_update_frame()
	_set_portrait_animating(selected)


# Animated portraits only play while this tab is the selected one; otherwise
# they rest on their first frame.
func _set_portrait_animating(animating: bool) -> void:
	var anim := portrait_texture as AnimatedTexture
	if anim == null:
		return
	anim.pause = not animating
	if not animating:
		anim.current_frame = 0


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if unlocked:
			emit_signal("tab_selected", index)
		return
	# Keyboard: left / right (A / D) browse the characters, Enter / Space confirm the browsed one,
	# W / S leave the row (the arrow keys do that through the focus neighbours set by the menu).
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	match event.keycode:
		KEY_LEFT, KEY_A:
			_browse(-1)
		KEY_RIGHT, KEY_D:
			_browse(1)
		KEY_ENTER, KEY_KP_ENTER, KEY_SPACE:
			if unlocked:
				emit_signal("tab_selected", index)
		KEY_W:
			_focus_neighbor(SIDE_TOP)
		KEY_S:
			_focus_neighbor(SIDE_BOTTOM)
		_:
			return
	accept_event()


# Moves the cursor to the next unlocked character in the given direction, wrapping around.
func _browse(step: int) -> void:
	var siblings := get_parent().get_children()
	for i in range(1, siblings.size()):
		var tab = siblings[wrapi(get_index() + step * i, 0, siblings.size())]
		if tab.get("unlocked"):
			tab.grab_focus()
			return


func _focus_neighbor(side: Side) -> void:
	var target := find_valid_focus_neighbor(side)
	if target != null:
		target.grab_focus()


func _place_art(rect: Rect2) -> void:
	frame_art.position = rect.position
	frame_art.size = rect.size
