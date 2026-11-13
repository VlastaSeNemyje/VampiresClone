extends Node2D
## Spawns a breakable Food Stump every few seconds just outside the screen, near the player,
## so there is usually one close by to find without crossing the whole map.
## Add one FoodStumpField node to a world scene and tune it in the Inspector.

const STUMP = preload("res://Scenes/Objects/food_stump.tscn")
const BLOCKING_LAYERS := 16 | 32   # walls / level bounds and obstacles (trees, bogs)

## Seconds between two stump spawns.
@export var spawn_interval: float = 35.0
## A new stump appears at least this far beyond the edge of the screen...
@export var offscreen_min: float = 30.0
## ...and at most this far beyond it.
@export var offscreen_max: float = 160.0
## Stumps never appear outside this rectangle, centred on this node (keep it inside the level walls).
@export var area_size := Vector2(3600, 3600)
## Minimum distance between two stumps.
@export var min_distance: float = 140.0
## Most stumps that can exist at once. When a new one would go over, the stump furthest from the player is removed.
@export var max_stumps: int = 6

@export_group("Food Stump")
@export var stump_hp: float = 20.0
## Chance (0-1) that a broken stump drops food.
@export_range(0.0, 1.0, 0.01) var food_drop_chance: float = 0.25
## Health restored by the food (the Food card in the level-up selection heals 20).
@export var heal_amount: float = 20.0

var _stumps: Array = []

func _ready():
	var timer := Timer.new()
	timer.wait_time = maxf(spawn_interval, 0.1)
	timer.timeout.connect(_spawn_stump)
	add_child(timer)
	timer.start()

# The part of the world the camera currently shows.
func _screen_rect() -> Rect2:
	var viewport := get_viewport()
	return viewport.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, viewport.get_visible_rect().size)

func _spawn_stump():
	_stumps = _stumps.filter(func(s): return is_instance_valid(s) and not s.is_queued_for_deletion())
	var screen := _screen_rect()
	var pos = _find_spot(screen)
	if pos == null:
		return   # no free spot this time (e.g. boxed in by walls); try again on the next tick

	# make room first, so the stump removed is always an old far-away one, never the new one
	while _stumps.size() >= maxi(max_stumps, 1):
		var center := screen.get_center()
		var furthest = _stumps[0]
		for s in _stumps:
			if s.global_position.distance_to(center) > furthest.global_position.distance_to(center):
				furthest = s
		_stumps.erase(furthest)
		furthest.queue_free()

	var stump = STUMP.instantiate()
	stump.hp = stump_hp
	stump.food_drop_chance = food_drop_chance
	stump.heal_amount = heal_amount
	add_child(stump)
	stump.global_position = pos
	_stumps.append(stump)

# A random free point in a band just outside the screen, or null when none was found.
func _find_spot(screen: Rect2):
	var allowed := Rect2(global_position - area_size * 0.5, area_size)
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var probe := CircleShape2D.new()
	probe.radius = 14.0
	query.shape = probe
	query.collision_mask = BLOCKING_LAYERS
	var center := screen.get_center()
	var half := screen.size * 0.5

	for attempt in 40:
		var dir := Vector2.RIGHT.rotated(randf() * TAU)
		# distance from the screen centre to the screen edge in this direction
		var edge_x := half.x / maxf(absf(dir.x), 0.0001)
		var edge_y := half.y / maxf(absf(dir.y), 0.0001)
		var to_edge := minf(edge_x, edge_y)
		# measured straight out from the edge that is crossed, so diagonal spots are not closer to the screen
		var toward_edge := maxf(absf(dir.x) if edge_x < edge_y else absf(dir.y), 0.0001)
		var beyond := randf_range(offscreen_min, maxf(offscreen_max, offscreen_min)) / toward_edge
		var pos := center + dir * (to_edge + beyond)
		if not allowed.has_point(pos):
			continue
		var too_close := false
		for s in _stumps:
			if s.global_position.distance_to(pos) < min_distance:
				too_close = true
				break
		if too_close:
			continue
		query.transform = Transform2D(0.0, pos)
		if not space.intersect_shape(query, 1).is_empty():
			continue   # inside a tree, bog or wall
		return pos
	return null
