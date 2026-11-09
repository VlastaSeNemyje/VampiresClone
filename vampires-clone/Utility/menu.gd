extends Control

@onready var tabs: Array = [
	$CharacterTabs/Tab1,
	$CharacterTabs/Tab2,
	$CharacterTabs/Tab3,
]


const FOREST_AMBIENCE := preload("res://Sounds/Music/Forest_Ambience.wav")
const AMBIENCE_HOLD_TIME := 6.0   # seconds ambience keeps playing after Play
const AMBIENCE_FADE_TIME := 3.0   # seconds to fade the ambience out
const LEVEL_MUSIC_FADE_IN := 3.0  # seconds for level music to reach full volume

var ambience: AudioStreamPlayer

@export_group("Flicker")
## Peak darkness of a flicker (0 = none, 1 = black). Keep low for subtle.
@export_range(0.0, 1.0, 0.005) var flicker_strength: float = 0.14
## Shortest / longest pause between flickers, in seconds.
@export var flicker_interval_min: float = 6.0
@export var flicker_interval_max: float = 10.0
## Duration of one dip (seconds).
@export_range(0.02, 1.0, 0.01) var flicker_duration: float = 0.18
## Chance that a flicker is a quick double-blink.
@export_range(0.0, 1.0, 0.05) var flicker_double_chance: float = 0.4

@onready var flicker_rect: ColorRect = $Flicker


func _ready() -> void:
	_start_ambience()
	_flicker_loop()
	for tab in tabs:
		tab.connect("tab_selected", Callable(self, "_on_tab_selected"))
		tab.refresh()
	if OS.is_debug_build():
		_build_debug_tools()


func _flicker_loop() -> void:
	while is_inside_tree():
		await get_tree().create_timer(randf_range(flicker_interval_min, flicker_interval_max)).timeout
		if not is_inside_tree():
			return
		var blinks := 2 if randf() < flicker_double_chance else 1
		for i in blinks:
			var tw := create_tween()
			tw.tween_property(flicker_rect, "modulate:a", flicker_strength, flicker_duration * 0.3)
			tw.tween_property(flicker_rect, "modulate:a", 0.0, flicker_duration * 0.7)
			await tw.finished


func _on_tab_selected(index: int) -> void:
	GameProgress.select(index)
	for tab in tabs:
		tab.set_selected(tab.index == index)
		
func _build_debug_tools() -> void:
	var debug_btn := Button.new()
	debug_btn.text = "🛠"
	debug_btn.custom_minimum_size = Vector2(15, 15)
	debug_btn.position = Vector2(580, 4)
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


func _start_ambience() -> void:
	ambience = AudioStreamPlayer.new()
	ambience.stream = FOREST_AMBIENCE
	ambience.volume_db = 20
	ambience.bus = &"MenuMusic"
	ambience.finished.connect(ambience.play) # fallback loop if import loop is off
	add_child(ambience) 
	ambience.play()


func _on_btn_play_click_end() -> void:
	# Hand the ambience over to the scene tree root so it survives the scene change,
	# keep it playing for a while, then fade it out.
	if is_instance_valid(ambience):
		ambience.reparent(get_tree().root)
		var tw := ambience.create_tween()
		tw.tween_interval(AMBIENCE_HOLD_TIME)
		tw.tween_property(ambience, "volume_db", -80.0, AMBIENCE_FADE_TIME)
		tw.tween_callback(ambience.queue_free)
	# Tell the level music to wait the same hold time, then fade in.
	Engine.set_meta("level_music_delay", AMBIENCE_HOLD_TIME)
	Engine.set_meta("level_music_fade_in", LEVEL_MUSIC_FADE_IN)
	get_tree().change_scene_to_file(GameProgress.get_selected_world_scene())


func _on_btn_exit_click_end() -> void:
	get_tree().quit()
