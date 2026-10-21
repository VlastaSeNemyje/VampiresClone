extends Node2D
## Spawns a tight group of Viscous Grains that all charge in the same direction, then removes itself.
## Add this scene (not the single grain) to the EnemySpawner.

@export var grain_scene: PackedScene
@export var count_min: int = 20
@export var count_max: int = 30
## Gap between neighbouring grains, in pixels (random per grain).
@export var spacing_min: float = 5.0
@export var spacing_max: float = 10.0

func _ready():
	_spawn_grains.call_deferred()

func _spawn_grains():
	var player = get_tree().get_first_node_in_group("player")
	if grain_scene == null or player == null:
		queue_free()
		return
	var dir = global_position.direction_to(player.global_position)
	var count = randi_range(count_min, maxi(count_min, count_max))
	var cols = ceili(sqrt(count))
	var rows = ceili(float(count) / cols)

	# jittered grid: every step between neighbours is a random 5-10 px
	var xs = [0.0]
	for i in range(1, cols):
		xs.append(xs[i - 1] + randf_range(spacing_min, spacing_max))
	var ys = [0.0]
	for j in range(1, rows):
		ys.append(ys[j - 1] + randf_range(spacing_min, spacing_max))
	var center = Vector2(xs[-1], ys[-1]) * 0.5

	var made = 0
	for j in rows:
		for i in cols:
			if made >= count:
				break
			var grain = grain_scene.instantiate()
			grain.charge_direction = dir
			get_parent().add_child(grain)
			grain.global_position = global_position + Vector2(xs[i], ys[j]) - center
			made += 1
	queue_free()
