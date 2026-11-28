extends Node2D

@export var spawns: Array[Spawn_info] = []

@export_group("Keep The Crowd Around The Player")
## Enemies further than this from the player are moved back to the edge of the screen (their HP is kept).
@export var recycle_distance: float = 650.0
## Chance (0-1) that a new or recycled enemy appears on the side the player is walking towards.
@export_range(0.0, 1.0) var forward_spawn_chance: float = 0.6
## Very fast enemies (the Nemesis) are never recycled.
@export var recycle_max_enemy_speed: float = 100.0

@export_group("Crowd Pressure")
## Enemies closer than this to the player count as "near the crowd".
@export var crowd_radius: float = 520.0
## At least this share (0-1) of all enemies must stay near the player, so walking away only finds an area ~20% less crowded.
@export_range(0.0, 1.0) var min_crowd_fraction: float = 0.8
## How many far-away enemies may be pulled back to the player each second.
@export var max_pulled_per_second: int = 12
## Moments where the crowd gets much denser around the player.
@export var pressure_waves: Array[Pressure_wave] = []

@export_group("Endless Mode")
## After the base run the waves repeat. Seconds the last waves of a cycle keep spawning while the next cycle's first waves start.
@export var endless_overlap: int = 30
## Enemy hp grows by this share (0.5 = 50%) of its base value with every finished cycle.
@export var difficulty_per_cycle: float = 0.5
## Enemy damage grows by this share of its base value with every finished cycle.
@export var damage_per_cycle: float = 0.25
## Every spawn brings this share more enemies (rounded up) with every finished cycle, until the cap is reached.
@export var count_per_cycle: float = 0.25
## No new enemies (swarms included) appear while this many are alive, to keep the game smooth.
@export var max_enemies: int = 250

@onready var player = get_tree().get_first_node_in_group("player")

var time = 0
var _delay_counters := {}

const SIDES = ["up", "down", "right", "left"]

signal changetime(time)

func _ready():
	connect("changetime",Callable(player,"change_time"))

func _on_timer_timeout() -> void:
	time += 1
	# The run repeats: cycle 0 is the base run, every later cycle replays the same waves stronger.
	var run_length = maxi(player.win_time, 1)
	var cycle = (time - 1) / run_length
	var local_time = (time - 1) % run_length + 1
	_recycle_far_enemies()
	_maintain_crowd(local_time)
	var alive = _count_alive()
	alive = _spawn_cycle(cycle, local_time, alive)
	# The last waves of the previous cycle keep coming while the first waves of the new one begin
	if cycle >= 1 and local_time <= endless_overlap:
		_spawn_cycle(cycle - 1, run_length, alive)
	emit_signal("changetime", time)

func _count_alive() -> int:
	var n = 0
	for e in get_tree().get_nodes_in_group("enemy"):
		if not e.get("is_dead"):
			n += 1
	return n

## How many more enemies may appear before the cap is reached (the swarms ask this too).
func free_slots() -> int:
	return maxi(max_enemies - _count_alive(), 0)

# Runs the spawn list for one cycle at the given time of that cycle. Returns the updated enemy count.
func _spawn_cycle(cycle: int, cycle_time: int, alive: int) -> int:
	var mult = Vector2(1.0 + difficulty_per_cycle * cycle, 1.0 + damage_per_cycle * cycle)
	var count_mult = 1.0 + count_per_cycle * cycle
	for idx in spawns.size():
		var i = spawns[idx]
		if cycle_time < i.time_start or cycle_time > i.time_end:
			continue
		var key = Vector2i(idx, cycle)
		var delay_counter = _delay_counters.get(key, 0)
		if delay_counter < i.enemy_spawn_delay:
			_delay_counters[key] = delay_counter + 1
			continue
		_delay_counters[key] = 0
		var group_center = get_random_position()
		var sides = SIDES.duplicate()
		sides.shuffle()
		for counter in ceili(i.enemy_num * count_mult):
			var enemy_spawn = i.enemy.instantiate()
			# Swarms (they have count_min / count_max) reserve their whole size; the Nemesis ignores the cap
			var is_swarm = enemy_spawn.get("count_max") != null
			if is_swarm or enemy_spawn.get("scales_with_difficulty") != false:
				var need = enemy_spawn.get("count_min") if is_swarm else 1
				if alive + need > max_enemies:
					enemy_spawn.free()
					break
				alive += enemy_spawn.get("count_max") if is_swarm else 1
			if i.grouped:
				enemy_spawn.global_position = group_center + Vector2.from_angle(randf() * TAU) * randf_range(0.0, i.group_spread)
			elif i.surround:
				enemy_spawn.global_position = get_random_position(0.0, sides[counter % sides.size()])
			else:
				enemy_spawn.global_position = get_random_position()
			enemy_spawn.set_meta("difficulty", mult)
			add_child(enemy_spawn)
			if enemy_spawn.has_method("apply_difficulty"):
				enemy_spawn.apply_difficulty(mult.x, mult.y)
	return alive

func _recycle_far_enemies():
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.get("is_dead") or e.get("ignore_recycle") or e.movement_speed >= recycle_max_enemy_speed:
			continue
		if e.global_position.distance_to(player.global_position) > recycle_distance:
			e.global_position = get_random_position(maxf(forward_spawn_chance, 0.8))

func _maintain_crowd(cycle_time: int):
	var fraction = min_crowd_fraction
	var pull_rate = max_pulled_per_second
	for wave in pressure_waves:
		if cycle_time >= wave.time_start and cycle_time <= wave.time_end:
			fraction = maxf(fraction, wave.crowd_fraction)
			pull_rate = maxi(pull_rate, wave.pulled_per_second)
	var total = 0
	var near = 0
	var far = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.get("is_dead") or e.get("ignore_recycle") or e.movement_speed >= recycle_max_enemy_speed:
			continue
		total += 1
		if e.global_position.distance_to(player.global_position) <= crowd_radius:
			near += 1
		else:
			far.append(e)
	var needed = mini(mini(ceili(total * fraction) - near, pull_rate), far.size())
	if needed <= 0:
		return
	far.sort_custom(func(a, b): return a.global_position.distance_squared_to(player.global_position) > b.global_position.distance_squared_to(player.global_position))
	for i in needed:
		far[i].global_position = get_random_position(maxf(forward_spawn_chance, 0.8))

func get_random_position(forward_chance = -1.0, forced_side = ""):
	if forward_chance < 0.0:
		forward_chance = forward_spawn_chance
	var vpr = get_viewport_rect().size * randf_range (1.1, 1.4)
	var top_left = Vector2 (player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2 (player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2 (player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2 (player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = SIDES.pick_random()
	var move_dir = player.velocity
	if forced_side != "":
		pos_side = forced_side
	elif move_dir.length() > 1.0 and randf() < forward_chance:
		if absf(move_dir.x) > absf(move_dir.y):
			pos_side = "right" if move_dir.x > 0 else "left"
		else:
			pos_side = "down" if move_dir.y > 0 else "up"
	var spawn_pos1 = Vector2.ZERO
	var spawn_pos2 = Vector2.ZERO

	match pos_side:
		"up":
			spawn_pos1 = top_left
			spawn_pos2 = top_right
		"down":
			spawn_pos1 = bottom_left
			spawn_pos2 = bottom_right
		"right":
			spawn_pos1 = top_right
			spawn_pos2 = bottom_right
		"left":
			spawn_pos1 = top_left
			spawn_pos2 = bottom_left
			
	var x_spawm = randf_range(spawn_pos1.x, spawn_pos2.x)
	var y_spawn = randf_range(spawn_pos1.y, spawn_pos2.y)
	return Vector2 (x_spawm, y_spawn)
