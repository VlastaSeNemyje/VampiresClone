extends AudioStreamPlayer

var _dead := false


func _ready() -> void:
	# If we came from the menu, wait for the forest ambience, then fade in.
	if Engine.has_meta("level_music_delay"):
		var delay: float = Engine.get_meta("level_music_delay")
		var fade_in: float = Engine.get_meta("level_music_fade_in", 3.0)
		Engine.remove_meta("level_music_delay")
		Engine.remove_meta("level_music_fade_in")
		var target_db := volume_db
		volume_db = -50.0
		stop() # cancel autoplay (may have already started)
		await get_tree().process_frame
		stop()
		await get_tree().create_timer(delay).timeout
		if _dead or not is_inside_tree():
			return
		play()
		create_tween().tween_property(self, "volume_db", target_db, fade_in)


func _on_player_playerdeath():
	_dead = true
	playing = false
