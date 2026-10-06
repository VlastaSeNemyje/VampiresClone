extends Node2D
## Charming Incense weapon controller. Lives at Player/Attack/IncenseBase - tweak everything in the Inspector.
## The per-level values (bombs, fuse, damage, area, cooldown, puddle) are in the child nodes Level1..Level4.

var Bomb = preload("res://Scenes/Attacks/incense_bomb.tscn")

@export_group("Base Stats")
@export var damage: float = 10.0
@export var knockback: float = 80.0
## Explosion radius in pixels.
@export var explosion_radius: float = 40.0

@export_group("Placement")
## Bombs land between these distances from the player.
@export var spawn_min_distance: float = 20.0
@export var spawn_max_distance: float = 70.0
## Bombs of the same volley try to stay at least this far from each other.
@export var min_bomb_spacing: float = 30.0
## Delay between bombs of the same volley.
@export var spawn_delay: float = 0.1
## Centre of the spawn ring, relative to the player.
@export var spawn_center_offset: Vector2 = Vector2(0, -8)

@export_group("Look")
## Size of the bomb sprite (Potion.png).
@export var bomb_scale: float = 1.0
## How visible the warning circle on the ground is while the fuse burns (0 = hidden).
@export_range(0.0, 1.0) var warning_alpha: float = 0.2
## How long the explosion flash (Explosion.png) takes to fade.
@export var explosion_visual_time: float = 0.35

@export_group("Puddle")
## How long the area stays after the explosion (last level).
@export var puddle_duration: float = 3.0
## Seconds between puddle damage ticks.
@export var puddle_tick_interval: float = 0.5
## Damage of one puddle tick as a fraction of the explosion damage.
@export var puddle_damage_multiplier: float = 0.3
## Puddle knockback as a fraction of the explosion knockback.
@export var puddle_knockback_multiplier: float = 0.0
@export_range(0.0, 1.0) var puddle_alpha: float = 0.7

var level = 0
var timer: Timer

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_drop_volley)
	add_child(timer)

# Called by player.gd whenever the weapon is (up)graded.
func update_incense(new_level: int):
	level = new_level
	if timer.is_stopped():
		_drop_volley()

func _level_stats() -> IncenseLevel:
	var levels = get_children().filter(func(c): return c is IncenseLevel)
	if levels.is_empty():
		return null
	return levels[clampi(level - 1, 0, levels.size() - 1)]

func _drop_volley():
	var stats = _level_stats()
	if stats == null:
		return
	var count = stats.bombs + player.additional_attacks
	var spots = _pick_spots(count)
	for i in count:
		_spawn_later(i * spawn_delay, spots[i], stats)
	timer.start(max(0.1, stats.cooldown * (1 - player.spell_cooldown)))

func _pick_spots(count: int) -> Array:
	var center = player.global_position + spawn_center_offset
	var spots = []
	for i in count:
		var best = center
		var best_gap = -1.0
		for attempt in 12:
			var candidate = center + Vector2.RIGHT.rotated(randf() * TAU) * randf_range(spawn_min_distance, spawn_max_distance)
			var gap = INF
			for s in spots:
				gap = min(gap, candidate.distance_to(s))
			if gap >= min_bomb_spacing:
				best = candidate
				break
			if gap > best_gap:
				best_gap = gap
				best = candidate
		spots.append(best)
	return spots

func _spawn_later(delay: float, pos: Vector2, stats: IncenseLevel):
	if delay <= 0.0:
		_spawn(pos, stats)
	else:
		get_tree().create_timer(delay, false).timeout.connect(_spawn.bind(pos, stats))

func _spawn(pos: Vector2, stats: IncenseLevel):
	var bomb = Bomb.instantiate()
	bomb.damage = damage * stats.damage_multiplier
	bomb.knockback_amount = knockback
	bomb.radius = explosion_radius * stats.area_multiplier * (1 + player.spell_size)
	bomb.fuse_time = stats.fuse_time
	bomb.bomb_scale = bomb_scale
	bomb.warning_alpha = warning_alpha
	bomb.explosion_visual_time = explosion_visual_time
	bomb.leaves_puddle = stats.leaves_puddle
	bomb.puddle_duration = puddle_duration
	bomb.puddle_tick_interval = puddle_tick_interval
	bomb.puddle_damage = damage * stats.damage_multiplier * puddle_damage_multiplier
	bomb.puddle_knockback = knockback * puddle_knockback_multiplier
	bomb.puddle_alpha = puddle_alpha
	bomb.global_position = pos
	add_child(bomb)
