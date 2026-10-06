extends Node2D
## A single Plague projectile. Spawned and configured by plague_base.gd (Player/Attack/PlagueBase).
## Flies to an enemy, hurts it, then bounces to the nearest enemy it has not hit yet.
## Sprite and spin are in plague_attack.tscn; the trail (fading copies of the sprite) is set in the Inspector.

@export_group("Look")
## Degrees per second the sprite spins.
@export var spin_speed: float = 360.0

@export_group("Trail")
## Number of fading copies behind the projectile.
@export var ghost_count: int = 5
## Distance the projectile travels before the next copy is left behind.
@export var ghost_spacing: float = 3.0
@export var ghost_start_scale: float = 0.9
@export var ghost_end_scale: float = 0.45
@export var ghost_start_alpha: float = 0.7
@export var ghost_end_alpha: float = 0.2
## Colour multiplied onto the copies (white = unchanged).
@export var ghost_tint: Color = Color(1, 1, 1)
## Seconds between copies vanishing once the projectile is gone.
@export var ghost_fade_interval: float = 0.05

var damage = 10.0
var knockback_amount = 60.0
var attack_size = 1.0
var speed = 260.0
var hit_radius = 14.0
var extra_hits = 2
var bounce_range = 220.0
var target: Node2D = null

var hits_left = 0
var hit_list = []
var finished = false
var ghosts = []
var history = []
var fade_timer = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready():
	top_level = true
	scale = Vector2.ONE * attack_size
	hits_left = extra_hits + 1
	_build_ghosts()

func _physics_process(delta):
	if not finished:
		sprite.rotation += deg_to_rad(spin_speed) * delta
		if not _is_valid(target):
			target = _find_next()
		if target == null:
			_finish()
		else:
			var to_target = target.global_position - global_position
			var step = speed * delta
			if to_target.length() <= hit_radius + step:
				_hit(to_target.normalized())
			else:
				global_position += to_target.normalized() * step
	_update_trail(delta)

func _hit(direction: Vector2):
	global_position = target.global_position
	target.get_node("HurtBox").hurt.emit(damage, direction, knockback_amount)
	hit_list.append(target)
	hits_left -= 1
	target = _find_next() if hits_left > 0 else null
	if target == null:
		_finish()

func _is_valid(enemy) -> bool:
	return is_instance_valid(enemy) and not enemy.get("is_dead")

func _find_next() -> Node2D:
	var best: Node2D = null
	var best_dist = bounce_range
	for e in get_tree().get_nodes_in_group("enemy"):
		if hit_list.has(e) or not _is_valid(e):
			continue
		var d = global_position.distance_to(e.global_position)
		if d <= best_dist:
			best_dist = d
			best = e
	return best

func _finish():
	finished = true
	sprite.visible = false

# The trail is a row of fading, shrinking copies of the sprite left behind the projectile.
func _build_ghosts():
	for i in ghost_count:
		var t = float(i) / max(1, ghost_count - 1)
		var ghost = Sprite2D.new()
		ghost.texture = sprite.texture
		ghost.top_level = true
		ghost.z_index = z_index   # top_level nodes ignore the parent z_index
		ghost.scale = Vector2.ONE * attack_size * lerpf(ghost_start_scale, ghost_end_scale, t)
		ghost.modulate = Color(ghost_tint, lerpf(ghost_start_alpha, ghost_end_alpha, t))
		ghost.visible = false
		add_child(ghost)
		ghosts.append(ghost)

func _update_trail(delta):
	if finished:
		fade_timer += delta
		if fade_timer >= ghost_fade_interval and not history.is_empty():
			fade_timer = 0.0
			history.pop_back()
		if history.is_empty():
			queue_free()
	elif history.is_empty() or global_position.distance_to(history[0]) >= ghost_spacing:
		history.push_front(global_position)
		if history.size() > ghost_count:
			history.pop_back()
	for i in ghosts.size():
		ghosts[i].visible = i < history.size()
		if ghosts[i].visible:
			ghosts[i].global_position = history[i]
			ghosts[i].rotation = sprite.rotation
