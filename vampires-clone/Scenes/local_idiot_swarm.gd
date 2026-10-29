extends Node2D
## Spawns a ragged mob of Local Idiots that all rush towards the player, then removes itself.
## Add this scene (not the single idiot) to the EnemySpawner.

@export var idiot_scene: PackedScene
@export var count_min: int = 15
@export var count_max: int = 25
## Size of the mob, in pixels: width across the charge, depth along it (the mob is stretched, with a ragged front).
@export var spread_width: float = 90.0
@export var spread_depth: float = 130.0
## Each idiot's speed is multiplied by a random value in this range.
@export var speed_variation: float = 0.3
## Each idiot's charge direction is rotated by up to this many degrees.
@export var angle_jitter_deg: float = 12.0

func _ready():
	_spawn_idiots.call_deferred()

func _spawn_idiots():
	var player = get_tree().get_first_node_in_group("player")
	if idiot_scene == null or player == null:
		queue_free()
		return
	var dir = global_position.direction_to(player.global_position)
	var side = dir.orthogonal()
	var count = randi_range(count_min, maxi(count_min, count_max))

	for i in count:
		var idiot = idiot_scene.instantiate()
		idiot.charge_direction = dir.rotated(deg_to_rad(randf_range(-angle_jitter_deg, angle_jitter_deg)))
		idiot.movement_speed *= randf_range(1.0 - speed_variation, 1.0 + speed_variation)
		get_parent().add_child(idiot)
		# bell-shaped scatter so the mob is dense in the middle and straggly at the edges
		var across = (randf() + randf() + randf() - 1.5) / 1.5 * spread_width * 0.5
		var along = (randf() + randf() + randf() - 1.5) / 1.5 * spread_depth * 0.5
		idiot.global_position = global_position + side * across + dir * along
		# desync the run cycle so they do not step in unison
		var sprite: AnimatedSprite2D = idiot.get_node("AnimatedSprite2D")
		sprite.speed_scale = randf_range(0.8, 1.3)
		sprite.frame = randi() % sprite.sprite_frames.get_frame_count(sprite.animation)
	queue_free()
