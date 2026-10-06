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

@onready var player = get_tree().get_first_node_in_group("player")

var time = 0

signal changetime(time)

func _ready():
	connect("changetime",Callable(player,"change_time"))

func _on_timer_timeout() -> void:
	time += 1
	_recycle_far_enemies()
	_maintain_crowd()
	var enemy_spawns = spawns
	for i in enemy_spawns:
		if time >= i.time_start and time <= i.time_end:
			if i.spawn_delay_counter < i.enemy_spawn_delay:
				i.spawn_delay_counter += 1
			else:
				i.spawn_delay_counter = 0
				var new_enemy = i.enemy
				var counter = 0
				while counter < i.enemy_num:
					var enemy_spawn = new_enemy.instantiate()
					enemy_spawn.global_position = get_random_position()
					add_child(enemy_spawn)
					counter += 1
	emit_signal("changetime", time)

func _recycle_far_enemies():
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.get("is_dead") or e.movement_speed >= recycle_max_enemy_speed:
			continue
		if e.global_position.distance_to(player.global_position) > recycle_distance:
			e.global_position = get_random_position(maxf(forward_spawn_chance, 0.8))

func _maintain_crowd():
	var fraction = min_crowd_fraction
	var pull_rate = max_pulled_per_second
	for wave in pressure_waves:
		if time >= wave.time_start and time <= wave.time_end:
			fraction = maxf(fraction, wave.crowd_fraction)
			pull_rate = maxi(pull_rate, wave.pulled_per_second)
	var total = 0
	var near = 0
	var far = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.get("is_dead") or e.movement_speed >= recycle_max_enemy_speed:
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

func get_random_position(forward_chance = -1.0):
	if forward_chance < 0.0:
		forward_chance = forward_spawn_chance
	var vpr = get_viewport_rect().size * randf_range (1.1, 1.4)
	var top_left = Vector2 (player.global_position.x - vpr.x/2, player.global_position.y - vpr.y/2)
	var top_right = Vector2 (player.global_position.x + vpr.x/2, player.global_position.y - vpr.y/2)
	var bottom_left = Vector2 (player.global_position.x - vpr.x/2, player.global_position.y + vpr.y/2)
	var bottom_right = Vector2 (player.global_position.x + vpr.x/2, player.global_position.y + vpr.y/2)
	var pos_side = ["up", "down", "right", "left"].pick_random()
	var move_dir = player.velocity
	if move_dir.length() > 1.0 and randf() < forward_chance:
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
