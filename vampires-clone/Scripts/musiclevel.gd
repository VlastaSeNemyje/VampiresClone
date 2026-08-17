extends Node

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()

func _ready() -> void:
	add_child(player)
	player.bus = "Master"  # optional, if you have a Music bus

func play_track(stream: AudioStream, from_position: float = 0.0) -> void:
	player.stream = stream
	player.play(from_position)

func stop() -> void:
	player.stop()

func is_playing() -> bool:
	return player.playing
