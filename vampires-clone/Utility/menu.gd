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


func _on_tab_selected(index: int) -> void:
	GameProgress.select(index)
	for tab in tabs:
		tab.set_selected(tab.index == index)


func _on_btn_play_click_end() -> void:
	get_tree().change_scene_to_file(GameProgress.get_selected_world_scene())


func _on_btn_exit_click_end() -> void:
	get_tree().quit()
