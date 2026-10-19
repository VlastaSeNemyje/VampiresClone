extends "res://Scripts/enemy.gd"

@export_group("Wall Spawning")
@export var wall_scene: PackedScene
## Distance from the player at which walls appear.
@export var wall_distance: float = 90.0
## Random +/- variation added to the distance of each wall.
@export var wall_distance_variation: float = 0.0
## Seconds between walls.
@export var wall_spawn_interval: float = 6.0
## Seconds before the first wall appears (-1 = use the normal interval).
@export var first_wall_delay: float = -1.0

var wall_timer := 0.0

func _ready():
	super()
	if first_wall_delay >= 0.0:
		wall_timer = wall_spawn_interval - first_wall_delay

func _physics_process(delta):
	super(delta)
	if is_dead:
		return
	wall_timer += delta
	if wall_timer >= wall_spawn_interval:
		wall_timer = 0.0
		spawn_wall()

func spawn_wall():
	if wall_scene == null or player == null:
		return
	var wall = wall_scene.instantiate()
	var dist = wall_distance + randf_range(-wall_distance_variation, wall_distance_variation)
	wall.global_position = player.global_position + Vector2.RIGHT.rotated(randf() * TAU) * dist
	get_tree().current_scene.add_child(wall)
