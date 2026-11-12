extends Button

signal click_end()

func _on_mouse_entered():
	$snd_hover.play()

func _on_pressed():
	$snd_click.play()


func _on_snd_click_finished():
	emit_signal("click_end")


const SIDE_DIM := Color(0.5, 0.1, 0.12, 1)
const SIDE_BRIGHT := Color(1, 0.3, 0.3, 1)


func _ready() -> void:
	mouse_entered.connect(_update_sides)
	mouse_exited.connect(_update_sides)
	focus_entered.connect(_update_sides)
	focus_exited.connect(_update_sides)
	# Mouse and keyboard share one cursor: hovering a button also selects it
	mouse_entered.connect(grab_focus)


# Keyboard navigation uses the built-in focus: arrows move it, Enter / Space press the button.
# Links the buttons top to bottom (wrapping around) and keeps the cursor inside the group.
static func link_focus(buttons: Array) -> void:
	for i in buttons.size():
		var btn: Control = buttons[i]
		btn.focus_neighbor_top = btn.get_path_to(buttons[i - 1])
		btn.focus_neighbor_bottom = btn.get_path_to(buttons[(i + 1) % buttons.size()])
		btn.focus_neighbor_left = NodePath(".")
		btn.focus_neighbor_right = NodePath(".")
		btn.focus_previous = btn.focus_neighbor_top
		btn.focus_next = btn.focus_neighbor_bottom


# W / S move the cursor too, like in the upgrade selection.
func _gui_input(event: InputEvent) -> void:
	if not (event is InputEventKey and event.pressed and not event.echo):
		return
	var target: Control = null
	match event.keycode:
		KEY_W:
			target = find_valid_focus_neighbor(SIDE_TOP)
		KEY_S:
			target = find_valid_focus_neighbor(SIDE_BOTTOM)
		_:
			return
	if target != null:
		target.grab_focus()
	accept_event()


# Optional SideL/SideR ornaments light up while the button is hovered or selected with the keyboard.
func _update_sides() -> void:
	var tint := SIDE_BRIGHT if is_hovered() or has_focus() else SIDE_DIM
	for side in ["SideL", "SideR"]:
		if has_node(side):
			get_node(side).modulate = tint
