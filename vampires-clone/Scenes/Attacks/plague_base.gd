extends Node2D
## Plague weapon controller. Lives at Player/Attack/PlagueBase - tweak everything in the Inspector.
## The per-level values (projectiles, bounces, damage, cooldown) are in the child nodes Level1..Level4.

var Plague = preload("res://Scenes/Attacks/plague_attack.tscn")

@export_group("Base Stats")
@export var damage: float = 10.0
@export var knockback: float = 60.0
@export var size: float = 1.0
@export var speed: float = 260.0
## How close the projectile must get to an enemy's centre to hit it.
@export var hit_radius: float = 14.0

@export_group("Targeting")
## Enemies further than this from the player are ignored for the first hit.
@export var first_target_range: float = 400.0
## Max distance from one hit enemy to the next one it can bounce to.
@export var bounce_range: float = 220.0
## Delay between projectiles of the same volley.
@export var spawn_delay: float = 0.2
## Where the projectile starts, relative to the player.
@export var spawn_offset: Vector2 = Vector2(0, -10)
## When no enemy is around, how often to look again (seconds).
@export var retry_interval: float = 0.25

var level = 0
var timer: Timer

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	timer = Timer.new()
	timer.one_shot = true
	timer.timeout.connect(_fire_volley)
	add_child(timer)

# Called by player.gd whenever the weapon is (up)graded.
func update_plague(new_level: int):
	level = new_level
	if timer.is_stopped():
		_fire_volley()

func _level_stats() -> PlagueLevel:
	var levels = get_children().filter(func(c): return c is PlagueLevel)
	if levels.is_empty():
		return null
	return levels[clampi(level - 1, 0, levels.size() - 1)]

func _fire_volley():
	var stats = _level_stats()
	if stats == null:
		return
	var targets = _enemies_by_distance()
	if targets.is_empty():
		timer.start(retry_interval)
		return
	var count = stats.projectiles + player.additional_attacks
	for i in count:
		_spawn_later(i * spawn_delay, targets[i % targets.size()], stats)
	timer.start(max(0.1, stats.cooldown * (1 - player.spell_cooldown)))

func _enemies_by_distance() -> Array:
	var result = []
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.get("is_dead") or player.global_position.distance_to(e.global_position) > first_target_range:
			continue
		result.append(e)
	result.sort_custom(func(a, b): return player.global_position.distance_squared_to(a.global_position) < player.global_position.distance_squared_to(b.global_position))
	return result

func _spawn_later(delay: float, target: Node2D, stats: PlagueLevel):
	if delay <= 0.0:
		_spawn(target, stats)
	else:
		get_tree().create_timer(delay, false).timeout.connect(_spawn.bind(target, stats))

func _spawn(target: Node2D, stats: PlagueLevel):
	if not is_instance_valid(target) or target.get("is_dead"):
		var fallback = _enemies_by_distance()
		if fallback.is_empty():
			return
		target = fallback[0]
	var projectile = Plague.instantiate()
	projectile.damage = damage * stats.damage_multiplier
	projectile.knockback_amount = knockback
	projectile.attack_size = size * (1 + player.spell_size)
	projectile.speed = speed
	projectile.hit_radius = hit_radius
	projectile.extra_hits = stats.extra_hits
	projectile.bounce_range = bounce_range
	projectile.target = target
	projectile.global_position = player.global_position + spawn_offset
	add_child(projectile)
