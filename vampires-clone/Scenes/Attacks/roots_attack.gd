extends Node2D
## Roots - every few seconds a wave of roots erupts around the player, stays
## for a few seconds and damages enemies standing on them.
##
## This node lives on the player (like LeafProtection). All the numbers you
## want to balance are in the Inspector of Scenes/Attacks/roots_attack.tscn.
## Edit RootTemplate in this same scene to customize each root.

# --------------------------------------------------------------- PLACEMENT --
@export_group("Where roots appear")
## Center of the ring, relative to the player's origin (feet).
@export var center_offset := Vector2(0, -8)
@export var min_distance := 12.0
@export var max_distance := 48.0
## Chance that a root erupts under a nearby enemy instead of a random spot.
@export_range(0.0, 1.0) var enemy_bias := 0.5
## Only enemies this close to the player can be targeted.
@export var enemy_max_distance := 48.0
## Random offset around a targeted enemy, so it doesn't look robotic.
@export var enemy_jitter := 10.0
## Roots of the same wave try to stay at least this far apart.
@export var min_spacing := 16.0

# ------------------------------------------------------------------ TIMING --
@export_group("Timing")
@export var first_spawn_delay := 5.0
## Seconds between each root of a wave (makes the wave ripple out).
@export var spawn_stagger := 0.04
## Ring upgrade ("+1 attack") adds this many roots per wave.
@export var extra_roots_per_ring := 2

# ------------------------------------------------------------------- STATS --
# One entry per level. Element 0 = level 1 (roots1) ... element 3 = level 4 (roots4).
# Level 1 = start (3 roots)  | level 2 = +3 roots | level 3 = bigger
# Level 4 = +6 roots
@export_group("Stats per level (element 0 = level 1)")
@export var root_count_per_level: Array[int] = [3, 5, 5, 8]
## Seconds between waves (Scroll upgrade shortens it).
@export var cooldown_per_level: Array[float] = [5.0, 5.0, 5.0, 5.0]
## Seconds each root stays out.
@export var lifetime_per_level: Array[float] = [4.0, 4.0, 4.0, 4.0]
## Damage per tick, per root.
@export var damage_per_level: Array[float] = [4.0, 4.0, 4.0, 4.0]
## Seconds between damage ticks.
@export var tick_interval_per_level: Array[float] = [0.5, 0.5, 0.5, 0.5]
## Size multiplier (Tome upgrade adds on top).
@export var size_per_level: Array[float] = [1.0, 1.0, 1.4, 1.4]


# --------------------------------------------------------- EVOLUTION: SHATTER --
# Unlocked by evolving Roots (Roots level 4 + Tome level 4, see UpgradeDb "roots_evo").
@export_group("Evolution - Shatter")
## Evolved waves have this many times more roots (1.5 = +50%, rounded up).
@export var evolved_root_multiplier := 1.5
## Extra multipliers applied on top of the normal level stats while evolved.
@export var evolved_damage_multiplier := 1.0
@export var evolved_size_multiplier := 1.0
@export var evolved_cooldown_multiplier := 1.0
## Seconds after a root becomes active until it explodes.
@export var explosion_delay := 1.5
## Explosion radius in pixels at size 1.0 (it grows with root size, so Tome helps).
@export var explosion_radius := 30.0
@export var explosion_damage := 15.0
@export var explosion_knockback := 60.0
## The root disappears right after exploding (false = keeps hurting until its lifetime ends).
@export var retract_after_explosion := true

# ------------------------------------------------------------ RUNTIME STATE --
var level := 1
var root_count := 3
var cooldown := 5.0
var lifetime := 4.0
var damage := 4.0
var tick_interval := 0.5
var size := 1.0

var evolved := false
var _started := false

@onready var player = get_tree().get_first_node_in_group("player")
@onready var spawn_timer: Timer = $SpawnTimer
@onready var root_template = $RootTemplate


func _ready() -> void:
	spawn_timer.one_shot = true
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)


# Called by the player whenever the level or any player stat changes.
func update_roots() -> void:
	if not is_instance_valid(player):
		return
	level = clampi(player.roots_level, 1, maxi(root_count_per_level.size(), 1))
	var i := level - 1

	root_count = int(_pick(root_count_per_level, i, 3.0))
	lifetime = _pick(lifetime_per_level, i, 4.0)
	damage = _pick(damage_per_level, i, 4.0)
	tick_interval = maxf(0.1, _pick(tick_interval_per_level, i, 0.5))
	# Same conventions as your other weapons: Tome = size, Scroll = cooldown
	size = _pick(size_per_level, i, 1.0) * (1.0 + player.spell_size)
	cooldown = maxf(0.3, _pick(cooldown_per_level, i, 5.0) * (1.0 - player.spell_cooldown))

	evolved = bool(player.evolved.get("roots", false))
	if evolved:
		damage *= evolved_damage_multiplier
		size *= evolved_size_multiplier
		cooldown = maxf(0.3, cooldown * evolved_cooldown_multiplier)

	if not _started:
		_started = true
		spawn_timer.start(maxf(first_spawn_delay, 0.05))


func _on_spawn_timer_timeout() -> void:
	_spawn_wave()   # runs on its own (has awaits), don't wait for it
	spawn_timer.start(cooldown)


func _spawn_wave() -> void:
	if not is_instance_valid(player):
		return
	var count: int = root_count + player.additional_attacks * extra_roots_per_ring
	if evolved:
		count = ceili(count * evolved_root_multiplier)
	var placed: Array[Vector2] = []
	for n in count:
		if not is_inside_tree():
			return
		var pos := _pick_position(placed)
		placed.append(pos)
		_spawn_root(pos)
		if spawn_stagger > 0.0:
			# false = timer pauses with the game (level-up screen etc.)
			await get_tree().create_timer(spawn_stagger, false).timeout


func _spawn_root(pos: Vector2) -> void:
	var root = root_template.duplicate(Node.DUPLICATE_SCRIPTS)
	root.is_template = false
	root.visible = true
	root.process_mode = Node.PROCESS_MODE_INHERIT
	root.monitoring = true
	root.damage = damage
	root.tick_interval = tick_interval
	root.lifetime = lifetime
	root.size = size
	root.explodes = evolved
	root.explosion_delay = explosion_delay
	root.explosion_radius = explosion_radius
	root.explosion_damage = explosion_damage
	root.explosion_knockback = explosion_knockback
	root.retract_after_explosion = retract_after_explosion
	root.position = pos   # RootPiece is top_level, so this is a world position
	add_child(root)


# -------------------------------------------------------------- PLACEMENT ---
func _pick_position(placed: Array[Vector2]) -> Vector2:
	var center: Vector2 = player.global_position + center_offset
	var pos := center
	for attempt in 8:
		pos = _candidate(center)
		var free := true
		for p in placed:
			if p.distance_to(pos) < min_spacing:
				free = false
				break
		if free:
			break
	return pos


func _candidate(center: Vector2) -> Vector2:
	if randf() < enemy_bias:
		var targets = player.enemy_close.filter(func(e):
			return is_instance_valid(e) and not e.is_dead \
				and e.global_position.distance_to(center) <= enemy_max_distance)
		if targets.size() > 0:
			var enemy = targets.pick_random()
			var offset: Vector2 = enemy.global_position - center \
				+ Vector2.from_angle(randf() * TAU) * randf() * enemy_jitter
			return center + offset.limit_length(max_distance)
	return center + Vector2.from_angle(randf() * TAU) * randf_range(min_distance, max_distance)


func _pick(arr: Array, index: int, fallback: float) -> float:
	if arr.is_empty():
		return fallback
	return float(arr[mini(index, arr.size() - 1)])
