@tool
extends Node2D
## Scatters the obstacle groups (obstacle_group_1..8) across the level. Change `seed` in the Inspector
## to get a different layout; the groups are shown live in the editor.

const OBSTACLE_LAYER := 32

@export var seed: int = 1:
	set(value):
		seed = value
		_queue_generate()
@export var group_scenes: Array[PackedScene] = []:
	set(value):
		group_scenes = value
		_queue_generate()
## Number of groups to place.
@export var group_count: int = 90:
	set(value):
		group_count = value
		_queue_generate()
## The groups are scattered inside this rectangle, centred on this node.
@export var area_size := Vector2(3600, 3600):
	set(value):
		area_size = value
		_queue_generate()
## Nothing is placed within this distance of the centre, so the player never starts inside a thicket.
@export var clear_radius: float = 220.0:
	set(value):
		clear_radius = value
		_queue_generate()
## Minimum distance between the centres of two groups.
@export var min_group_distance: float = 110.0:
	set(value):
		min_group_distance = value
		_queue_generate()

var _pending := false

func _ready():
	_generate()

func _queue_generate():
	if not is_inside_tree() or _pending:
		return
	_pending = true
	_generate.call_deferred()

func _generate():
	_pending = false
	for child in get_children():
		remove_child(child)
		child.queue_free()
	if group_scenes.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	var centres: Array[Vector2] = []
	var attempts := 0
	while centres.size() < group_count and attempts < group_count * 40:
		attempts += 1
		var pos := Vector2(rng.randf_range(-area_size.x, area_size.x), rng.randf_range(-area_size.y, area_size.y)) * 0.5
		if pos.length() < clear_radius:
			continue
		var too_close := false
		for c in centres:
			if c.distance_to(pos) < min_group_distance:
				too_close = true
				break
		if too_close:
			continue
		centres.append(pos)
		var scene := group_scenes[rng.randi() % group_scenes.size()]
		var group := scene.instantiate()
		group.position = pos
		add_child(group)
