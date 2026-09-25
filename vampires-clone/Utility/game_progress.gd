extends Node

# --- Slot 0 = starting Dryad/forest world, always unlocked ---
# --- Slot 1 & 2 = unlocked by finishing the previous world     ---
var unlocked: Array[bool] = [true, false, false]
var selected_index: int = 0

# Fill in the real paths once you've duplicated world.tscn for the
# two new worlds (see INTEGRATION_NOTES.md).
const WORLD_SCENES := [
	"res://Scenes/world.tscn",
	"res://Scenes/world_2.tscn",
	"res://Scenes/world_3.tscn",
]

const SAVE_PATH := "user://progress.cfg"

signal progress_changed


func _ready() -> void:
	load_progress()


func is_unlocked(index: int) -> bool:
	if index < 0 or index >= unlocked.size():
		return false
	return unlocked[index]


func unlock(index: int) -> void:
	if index >= 0 and index < unlocked.size() and not unlocked[index]:
		unlocked[index] = true
		save_progress()
		emit_signal("progress_changed")


# Call this when a world is completed (win state) to open the next slot.
func unlock_next(current_index: int) -> void:
	unlock(current_index + 1)


func select(index: int) -> void:
	if is_unlocked(index):
		selected_index = index
		emit_signal("progress_changed")


func get_selected_world_scene() -> String:
	if selected_index < 0 or selected_index >= WORLD_SCENES.size():
		return WORLD_SCENES[0]
	return WORLD_SCENES[selected_index]


func save_progress() -> void:
	var cfg = ConfigFile.new()
	cfg.set_value("progress", "unlocked", unlocked)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg = ConfigFile.new()
	var err = cfg.load(SAVE_PATH)
	if err == OK:
		var loaded = cfg.get_value("progress", "unlocked", unlocked)
		if loaded is Array and loaded.size() == unlocked.size():
			unlocked = loaded
			
func toggle_lock(index: int) -> void:
	if index >= 0 and index < unlocked.size():
		if index == 0:
			return # starting world stays unlocked always
		unlocked[index] = not unlocked[index]
		save_progress()
		emit_signal("progress_changed")

func reset_progress() -> void:
	unlocked = [true, false, false]
	selected_index = 0
	save_progress()
	emit_signal("progress_changed")
