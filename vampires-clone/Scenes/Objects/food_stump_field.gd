extends Node2D
## Scatters breakable Food Stumps randomly across the level when the run starts.
## Add one FoodStumpField node to a world scene and tune it in the Inspector.

const STUMP = preload("res://Scenes/Objects/food_stump.tscn")
const SCREEN_AREA := 640.0 * 360.0
const BLOCKING_LAYERS := 16 | 32   # walls / level bounds and obstacles (trees, bogs)

## Average number of stumps per screen-sized piece of the level (640x360). 0.4 = roughly one stump every 2-3 screens.
@export_range(0.0, 5.0, 0.05, "or_greater") var density: float = 0.4
## The stumps are scattered inside this rectangle, centred on this node.
@export var area_size := Vector2(3600, 3600)
## No stump is placed within this distance of the centre (where the player starts).
@export var clear_radius: float = 150.0
## Minimum distance between two stumps.
@export var min_distance: float = 140.0
## 0 = a different layout every run. Any other number always gives the same layout.
@export var layout_seed: int = 0

@export_group("Food Stump")
@export var stump_hp: float = 20.0
## Chance (0-1) that a broken stump drops food.
@export_range(0.0, 1.0, 0.01) var food_drop_chance: float = 0.25
## Health restored by the food (the Food card in the level-up selection heals 20).
@export var heal_amount: float = 20.0

func _ready():
	# wait until the obstacles and level bounds exist in the physics world, so stumps avoid them
	await get_tree().physics_frame
	await get_tree().physics_frame
	_scatter()

func _scatter():
	var rng := RandomNumberGenerator.new()
	if layout_seed != 0:
		rng.seed = layout_seed
	else:
		rng.randomize()
	var count := roundi(density * area_size.x * area_size.y / SCREEN_AREA)
	var space := get_world_2d().direct_space_state
	var query := PhysicsShapeQueryParameters2D.new()
	var probe := CircleShape2D.new()
	probe.radius = 14.0
	query.shape = probe
	query.collision_mask = BLOCKING_LAYERS

	var placed: Array[Vector2] = []
	var attempts := 0
	while placed.size() < count and attempts < count * 40:
		attempts += 1
		var pos := Vector2(rng.randf_range(-0.5, 0.5) * area_size.x, rng.randf_range(-0.5, 0.5) * area_size.y)
		if pos.length() < clear_radius:
			continue
		var too_close := false
		for other in placed:
			if other.distance_to(pos) < min_distance:
				too_close = true
				break
		if too_close:
			continue
		query.transform = Transform2D(0.0, to_global(pos))
		if not space.intersect_shape(query, 1).is_empty():
			continue   # inside a tree, bog or wall
		placed.append(pos)
		var stump = STUMP.instantiate()
		stump.hp = stump_hp
		stump.food_drop_chance = food_drop_chance
		stump.heal_amount = heal_amount
		stump.position = pos
		add_child(stump)
