extends Node2D
## A single Charming Incense bomb. Spawned and configured by incense_base.gd (Player/Attack/IncenseBase).
## Sits still while the fuse burns, explodes (damages every enemy in the radius),
## and on the last level leaves a puddle that keeps hurting enemies for a while.

var damage = 10.0
var knockback_amount = 80.0
var radius = 40.0
var fuse_time = 4.0
var bomb_scale = 1.0
var warning_alpha = 0.2
var explosion_visual_time = 0.35
var leaves_puddle = false
var puddle_duration = 3.0
var puddle_tick_interval = 0.5
var puddle_damage = 3.0
var puddle_knockback = 0.0
var puddle_alpha = 0.7

enum Phase { FUSE, PUDDLE, DONE }
var phase = Phase.FUSE
var elapsed = 0.0
var tick_timer = 0.0

@onready var bomb_sprite: Sprite2D = $Bomb
@onready var warning_sprite: Sprite2D = $Warning
@onready var explosion_sprite: Sprite2D = $Explosion
@onready var puddle_sprite: Sprite2D = $Puddle

func _ready():
	top_level = true
	bomb_sprite.scale = Vector2.ONE * bomb_scale
	warning_sprite.scale = Vector2.ONE * _fit_scale(warning_sprite.texture, radius * 2.0)
	warning_sprite.modulate.a = warning_alpha
	warning_sprite.visible = warning_alpha > 0.0
	explosion_sprite.visible = false
	puddle_sprite.visible = false

# Scale that makes the visible part of a texture exactly `diameter` pixels wide.
func _fit_scale(tex: Texture2D, diameter: float) -> float:
	var used = tex.get_image().get_used_rect().size.x
	return diameter / max(1.0, float(used))

func _process(delta):
	match phase:
		Phase.FUSE:
			elapsed += delta
			# the bomb pulses faster and faster as the explosion gets closer
			var t = clampf(elapsed / max(0.01, fuse_time), 0.0, 1.0)
			bomb_sprite.scale = Vector2.ONE * bomb_scale * (1.0 + 0.12 * sin(elapsed * lerpf(4.0, 24.0, t)))
			if elapsed >= fuse_time:
				_explode()
		Phase.PUDDLE:
			elapsed += delta
			tick_timer += delta
			if tick_timer >= puddle_tick_interval:
				tick_timer = 0.0
				_damage_area(puddle_damage, puddle_knockback)
			if elapsed >= puddle_duration:
				phase = Phase.DONE
				var tween = create_tween()
				tween.tween_property(puddle_sprite, "modulate:a", 0.0, 0.3)
				tween.tween_callback(queue_free)

func _explode():
	bomb_sprite.visible = false
	warning_sprite.visible = false
	_damage_area(damage, knockback_amount)
	var full = _fit_scale(explosion_sprite.texture, radius * 2.0)
	explosion_sprite.visible = true
	explosion_sprite.scale = Vector2.ONE * full * 0.3
	explosion_sprite.modulate.a = 1.0
	var tween = create_tween().set_parallel(true)
	tween.tween_property(explosion_sprite, "scale", Vector2.ONE * full, explosion_visual_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(explosion_sprite, "modulate:a", 0.0, explosion_visual_time)
	if leaves_puddle:
		puddle_sprite.visible = true
		puddle_sprite.scale = Vector2.ONE * _fit_scale(puddle_sprite.texture, radius * 2.0)
		puddle_sprite.modulate.a = puddle_alpha
		elapsed = 0.0
		tick_timer = 0.0
		phase = Phase.PUDDLE
	else:
		phase = Phase.DONE
		tween.chain().tween_callback(queue_free)

func _damage_area(amount: float, knockback: float):
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.get("is_dead") or global_position.distance_to(e.global_position) > radius:
			continue
		var direction = global_position.direction_to(e.global_position)
		e.get_node("HurtBox").hurt.emit(amount, direction, knockback)
