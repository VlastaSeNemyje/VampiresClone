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


# Optional SideL/SideR ornaments light up while the button is hovered.
func _update_sides() -> void:
	var tint := SIDE_BRIGHT if is_hovered() else SIDE_DIM
	for side in ["SideL", "SideR"]:
		if has_node(side):
			get_node(side).modulate = tint
