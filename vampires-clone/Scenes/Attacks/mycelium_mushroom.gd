extends Area2D
## One orbiting mushroom of the Mycelium Circle. Spawned (duplicated from
## MushroomTemplate) by mycelium_circle.gd, which fills in damage / knockback /
## size from its per-level tables. The "Look" and "Feel" values below can be
## tweaked on MushroomTemplate in mycelium_circle.tscn (Inspector).

@export var is_template := false

@export_group("Look")
@export var tint := Color.WHITE
## Time the mushroom takes to pop in / shrink away.
@export var pop_in_time := 0.25
@export var pop_out_time := 0.2
## Sprite "punches" this much bigger whenever it hurts something (1.0 = off).
@export var hit_punch := 1.25

@export_group("Trail")
## Number of recorded positions (longer = longer trail).
@export var trail_length := 14
@export var trail_width := 8.0
@export var trail_color := Color(0.95, 0.35, 0.2, 0.45)
@export var trail_end_color := Color(1.0, 0.8, 0.7, 0.0)

@export_group("Hitbox")
@export var collision_radius := 9.0

# ---- filled in by mycelium_circle.gd ----
var damage := 5.0
var knockback_amount := 40.0
## Seconds before the same enemy can be hit again by this mushroom.
var hit_cooldown := 0.6
var size := 1.0

var _active := false
## Set by the circle (on only in the last level).
var trail_enabled := false:
	set(value):
		trail_enabled = value
		if not value and _trail:
			_trail.clear_points()
var _trail: Line2D
var _scale_tween: Tween
var _last_hit_msec := {}   # enemy hurtbox instance id -> msec of last hit

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D


func _ready() -> void:
	if is_template:
		return
	sprite.modulate = tint
	collision.shape = collision.shape.duplicate()
	(collision.shape as CircleShape2D).radius = collision_radius
	collision.disabled = true
	scale = Vector2.ZERO
	_build_trail()


# Line2D that stays in world space and is drawn behind the sprite.
func _build_trail() -> void:
	_trail = Line2D.new()
	_trail.top_level = true
	_trail.show_behind_parent = true
	_trail.width = trail_width
	_trail.joint_mode = Line2D.LINE_JOINT_ROUND
	_trail.begin_cap_mode = Line2D.LINE_CAP_ROUND
	var gradient := Gradient.new()
	# Line2D point 0 is the oldest (tail), the last point is the mushroom
	gradient.set_color(0, trail_end_color)
	gradient.set_color(1, trail_color)
	_trail.gradient = gradient
	var taper := Curve.new()
	taper.add_point(Vector2(0, 0.1))
	taper.add_point(Vector2(1, 1.0))
	_trail.width_curve = taper
	add_child(_trail)


func _process(_delta: float) -> void:
	if is_template or _trail == null:
		return
	if not (trail_enabled and _active):
		if _trail.get_point_count() > 0:
			_trail.clear_points()
		return
	_trail.global_position = Vector2.ZERO
	_trail.add_point(global_position)
	while _trail.get_point_count() > trail_length:
		_trail.remove_point(0)


## Called by the circle when the mushrooms appear / disappear.
func set_active(value: bool, instant := false) -> void:
	if value == _active and not instant:
		return
	_active = value
	collision.set_deferred("disabled", not value)
	if _scale_tween:
		_scale_tween.kill()
	var target := Vector2.ONE * size if value else Vector2.ZERO
	if instant:
		scale = target
		return
	_scale_tween = create_tween()
	_scale_tween.tween_property(self, "scale", target, pop_in_time if value else pop_out_time)\
		.set_trans(Tween.TRANS_BACK if value else Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_OUT if value else Tween.EASE_IN)


## Called when the size changes (level up / Tome) while the mushroom is out.
func set_size(value: float) -> void:
	size = value
	if _active:
		if _scale_tween:
			_scale_tween.kill()
		scale = Vector2.ONE * size


func _physics_process(_delta: float) -> void:
	if is_template or not _active:
		return
	var now := Time.get_ticks_msec()
	var hits := 0
	for area in get_overlapping_areas():
		# Only enemy HurtBoxes have the "hurt" signal (attacks share the layer)
		if not area.has_signal("hurt"):
			continue
		if area.get_parent().get("is_dead") == true:
			continue
		var id := area.get_instance_id()
		if _last_hit_msec.has(id) and now - _last_hit_msec[id] < int(hit_cooldown * 1000.0):
			continue
		_last_hit_msec[id] = now
		var direction := global_position.direction_to(area.global_position)
		# Same signal HurtBox emits for whip/arrow hits -> enemy.gd handles
		# damage, knockback, hit flash and hit sound.
		area.emit_signal("hurt", damage, direction, knockback_amount)
		hits += 1

	if hits > 0 and hit_punch != 1.0:
		sprite.scale = Vector2.ONE * hit_punch
		create_tween().tween_property(sprite, "scale", Vector2.ONE, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# forget enemies that are long gone so the dictionary doesn't grow forever
	if _last_hit_msec.size() > 64:
		for key in _last_hit_msec.keys():
			if now - _last_hit_msec[key] > 5000:
				_last_hit_msec.erase(key)
