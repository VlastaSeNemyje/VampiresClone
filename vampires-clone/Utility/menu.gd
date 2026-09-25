extends Control

@onready var tabs: Array = [
	$CharacterTabs/Tab1,
	$CharacterTabs/Tab2,
	$CharacterTabs/Tab3,
]


func _ready() -> void:
	for tab in tabs:
		tab.connect("tab_selected", Callable(self, "_on_tab_selected"))
		tab.refresh()
	if OS.is_debug_build():
		_build_debug_tools()


func _on_tab_selected(index: int) -> void:
	GameProgress.select(index)
	for tab in tabs:
		tab.set_selected(tab.index == index)
		
func _build_debug_tools() -> void:
	var debug_btn := Button.new()
	debug_btn.text = "🛠"
	debug_btn.custom_minimum_size = Vector2(28, 28)
	debug_btn.position = Vector2(644, 4)
	add_child(debug_btn)

	var panel := Panel.new()
	panel.visible = false
	panel.position = Vector2(420, 40)
	panel.custom_minimum_size = Vector2(240, 180)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.position = Vector2(10, 10)
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "DEBUG — World Unlocks"
	vbox.add_child(title)

	for i in range(GameProgress.unlocked.size()):
		var row := HBoxContainer.new()
		vbox.add_child(row)

		var lbl := Label.new()
		lbl.custom_minimum_size = Vector2(80, 0)
		lbl.text = "World %d" % i
		row.add_child(lbl)

		var toggle_btn := Button.new()
		toggle_btn.text = "Unlocked" if GameProgress.is_unlocked(i) else "Locked"
		toggle_btn.disabled = (i == 0) # world 0 always unlocked
		toggle_btn.pressed.connect(func():
			GameProgress.toggle_lock(i)
			toggle_btn.text = "Unlocked" if GameProgress.is_unlocked(i) else "Locked"
		)
		row.add_child(toggle_btn)

	var reset_btn := Button.new()
	reset_btn.text = "Delete Progress"
	reset_btn.pressed.connect(func():
		GameProgress.reset_progress()
		get_tree().reload_current_scene()
	)
	vbox.add_child(reset_btn)

	debug_btn.pressed.connect(func(): panel.visible = not panel.visible)


func _on_btn_play_click_end() -> void:
	get_tree().change_scene_to_file(GameProgress.get_selected_world_scene())


func _on_btn_exit_click_end() -> void:
	get_tree().quit()
