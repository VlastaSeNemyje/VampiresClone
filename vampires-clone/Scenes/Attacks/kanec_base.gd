extends Node2D
## Kanec weapon controller. Lives at Player/Attack/KanecBase - tweak everything in the Inspector.
## Level 1: 1 from the left + 1 from the right.
## Level 2: +50% size, 2 per side.
## Level 3: double the projectiles (4 per side).
## Level 4: one extra big, hard-hitting projectile from a random side.

var Kanec = preload("res://Scenes/Attacks/kanec.tscn")

@export_group("Base Stats")
@export var damage: float = 6.0
@export var knockback: float = 100.0
@export var size: float = 1.0
@export var speed: float = 160.0
## Seconds between volleys (player cooldown upgrades shorten it).
@export var cooldown: float = 3.0
## How many enemies one Kanec can hit before it disappears.
@export var pierce: int = 9999
## Set to false if the sprite in Kanec.png looks backwards while running.
@export var sprite_faces_right: bool = true

@export_group("Spawning")
## Delay between projectiles of the same volley.
@export var spawn_delay: float = 0.15
## How far outside the screen edge projectiles start/end.
@export var screen_margin: float = 30.0
## Keeps random Y positions away from the top/bottom of the screen.
@export var vertical_margin: float = 20.0

@export_group("Projectiles Per Side")
@export var per_side_level_1: int = 1
@export var per_side_level_2: int = 2
@export var per_side_level_3: int = 4
@export var per_side_level_4: int = 4

@export_group("Upgrades")
## Level 2 and up: size increase (0.5 = +50%).
@export var size_bonus_level_2: float = 0.5
## Level 4: extra projectile from a random side.
@export var big_projectile_enabled_level: int = 4
## Size of the big one relative to a normal one (3.0 = 200% bigger).
@export var big_size_multiplier: float = 3.0
@export var big_damage_multiplier: float = 2.0
@export var big_knockback_multiplier: float = 1.0

var level = 0
var timer: Timer

@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	timer = Timer.new()
	timer.one_shot = false
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)

# Called by player.gd whenever the weapon is (up)graded.
func update_kanec(new_level: int):
	var first_time = level == 0
	level = new_level
	timer.wait_time = max(0.1, cooldown * (1 - player.spell_cooldown))
	if timer.is_stopped():
		timer.start()
	if first_time:
		_on_timer_timeout()

func _per_side() -> int:
	match level:
		1: return per_side_level_1
		2: return per_side_level_2
		3: return per_side_level_3
	return per_side_level_4

func _on_timer_timeout():
	timer.wait_time = max(0.1, cooldown * (1 - player.spell_cooldown))
	var count = _per_side() + player.additional_attacks
	var normal_size = size * (1 + player.spell_size)
	if level >= 2:
		normal_size *= 1 + size_bonus_level_2
	for i in count:
		_spawn_later(i * spawn_delay, true, normal_size, 1.0, 1.0)
		_spawn_later(i * spawn_delay, false, normal_size, 1.0, 1.0)
	if big_projectile_enabled_level > 0 and level >= big_projectile_enabled_level:
		_spawn_later(randf() * spawn_delay * count, randf() < 0.5, normal_size * big_size_multiplier, big_damage_multiplier, big_knockback_multiplier)

func _spawn_later(delay: float, from_left: bool, proj_size: float, damage_mult: float, knockback_mult: float):
	if delay <= 0.0:
		_spawn(from_left, proj_size, damage_mult, knockback_mult)
	else:
		get_tree().create_timer(delay, false).timeout.connect(_spawn.bind(from_left, proj_size, damage_mult, knockback_mult))

func _spawn(from_left: bool, proj_size: float, damage_mult: float, knockback_mult: float):
	var viewport = get_viewport()
	var rect: Rect2 = viewport.get_canvas_transform().affine_inverse() * Rect2(Vector2.ZERO, viewport.get_visible_rect().size)
	var y = randf_range(rect.position.y + vertical_margin, rect.end.y - vertical_margin)
	var projectile = Kanec.instantiate()
	projectile.damage = damage * damage_mult
	projectile.knockback_amount = knockback * knockback_mult
	projectile.attack_size = proj_size
	projectile.speed = speed
	projectile.hp = pierce
	projectile.sprite_faces_right = sprite_faces_right
	projectile.angle = Vector2.RIGHT if from_left else Vector2.LEFT
	projectile.travel_distance = rect.size.x + screen_margin * 2.0
	projectile.global_position = Vector2(rect.position.x - screen_margin if from_left else rect.end.x + screen_margin, y)
	add_child(projectile)
