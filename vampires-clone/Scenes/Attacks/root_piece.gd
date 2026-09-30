extends Area2D
## One root: erupts, lingers, damages enemies standing on it, then retracts.
## Spawned by roots_attack.gd, which fills in damage / size / lifetime / slow
## from its per-level tables. The "Look", "Feel" and "Sound" values below are
## tweakable in root_piece.tscn (Inspector).

enum State { ERUPT, ACTIVE, RETRACT }

@export_group("Look")
## MiniFPProjectiles.png (already assigned in the scene).
@export var sheet: Texture2D
@export var frame_size := Vector2i(32, 32)
## Which row of the sheet holds the root animation (0 = top row, y = row * 32).
@export var sheet_row := 0
## First column of the animation on that row.
@export var first_frame := 0
## How many frames the eruption has.
@export var frame_count := 8
## The last N frames loop while the root stays out.
@export var loop_frames := 2
@export var erupt_fps := 14.0
@export var idle_fps := 6.0
@export var tint := Color.WHITE
@export var random_flip := true

@export_group("Feel")
## Seconds before the root starts hurting (matches the eruption animation).
@export var activate_delay := 0.25
## Starts this fraction of its final size, then pops up with a bounce.
@export var start_scale_ratio := 0.3
@export var pop_time := 0.2
## Sprite "punches" this much bigger whenever it damages something (1.0 = off).
@export var hit_punch := 1.12
@export var fade_out_time := 0.4
@export var collision_radius := 12.0

@export_group("Sound")
## Stops 15 roots from playing 15 sounds on the same frame.
@export var min_seconds_between_sounds := 0.06
@export var pitch_variation := 0.1

# ---- filled in by roots_attack.gd before the root enters the tree ----
var damage := 4.0
var tick_interval := 0.5
var lifetime := 4.0          # seconds the root stays out (after eruption)
var size := 1.0
var slow_multiplier := 1.0   # 1.0 = no slow, 0.5 = half speed
var slow_duration := 1.0

static var _last_sound_msec := 0

var _state := State.ERUPT
var _age := 0.0
var _tick_left := 0.0
var _sprite_base_scale := Vector2.ONE

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var snd_erupt: AudioStreamPlayer2D = $snd_erupt


func _ready() -> void:
	_sprite_base_scale = sprite.scale
	sprite.sprite_frames = _build_frames()
	sprite.modulate = tint
	sprite.flip_h = random_flip and randf() < 0.5
	(collision.shape as CircleShape2D).radius = collision_radius
	collision.disabled = true

	# Pop out of the ground
	scale = Vector2.ONE * size * start_scale_ratio
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector2.ONE * size, pop_time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	sprite.animation_finished.connect(_on_animation_finished)
	sprite.play("erupt")
	_play_sound()


func _process(delta: float) -> void:
	_age += delta
	match _state:
		State.ERUPT:
			if _age >= activate_delay:
				_state = State.ACTIVE
				collision.set_deferred("disabled", false)
				_tick_left = 0.05   # give physics a moment, then first hit
		State.ACTIVE:
			_tick_left -= delta
			if _tick_left <= 0.0:
				_tick()
				_tick_left = tick_interval
			if _age >= activate_delay + lifetime:
				_retract()


func _tick() -> void:
	var hits := 0
	for area in get_overlapping_areas():
		# Only enemy HurtBoxes have the "hurt" signal (attacks share the layer)
		if not area.has_signal("hurt"):
			continue
		var enemy = area.get_parent()
		if enemy.get("is_dead") == true:
			continue
		# Same signal HurtBox emits for whip/arrow hits -> enemy.gd handles
		# damage, hit flash and hit sound. Roots hold enemies: no knockback.
		area.emit_signal("hurt", damage, Vector2.ZERO, 0.0)
		if slow_multiplier < 1.0 and enemy.has_method("apply_slow"):
			enemy.apply_slow(slow_multiplier, slow_duration)
		hits += 1

	if hits > 0 and hit_punch != 1.0:
		sprite.scale = _sprite_base_scale * hit_punch
		create_tween().tween_property(sprite, "scale", _sprite_base_scale, 0.12)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)


func _retract() -> void:
	_state = State.RETRACT
	collision.set_deferred("disabled", true)
	sprite.play_backwards("erupt")
	create_tween().tween_property(sprite, "modulate:a", 0.0, fade_out_time)
	# Safety net in case the animation signal never arrives
	get_tree().create_timer(1.5, false).timeout.connect(queue_free)


func _on_animation_finished() -> void:
	if _state == State.RETRACT:
		queue_free()
	else:
		sprite.play("idle")


func _play_sound() -> void:
	if snd_erupt.stream == null:
		return
	var now := Time.get_ticks_msec()
	if now - _last_sound_msec < int(min_seconds_between_sounds * 1000.0):
		return
	_last_sound_msec = now
	snd_erupt.pitch_scale = randf_range(1.0 - pitch_variation, 1.0 + pitch_variation)
	snd_erupt.play()


# Builds "erupt" (plays once) and "idle" (loops the last frames) straight
# from the sprite sheet, so you only change row / frame numbers in the Inspector.
func _build_frames() -> SpriteFrames:
	var frames := SpriteFrames.new()
	if frames.has_animation("default"):
		frames.remove_animation("default")
	frames.add_animation("erupt")
	frames.set_animation_loop("erupt", false)
	frames.set_animation_speed("erupt", erupt_fps)
	frames.add_animation("idle")
	frames.set_animation_loop("idle", true)
	frames.set_animation_speed("idle", idle_fps)

	if sheet == null:
		push_warning("RootPiece: no sheet texture assigned.")
		return frames

	var loop_from := frame_count - mini(maxi(loop_frames, 1), frame_count)
	for i in frame_count:
		var atlas := AtlasTexture.new()
		atlas.atlas = sheet
		atlas.region = Rect2(
			(first_frame + i) * frame_size.x,
			sheet_row * frame_size.y,
			frame_size.x, frame_size.y)
		frames.add_frame("erupt", atlas)
		if i >= loop_from:
			frames.add_frame("idle", atlas)
	return frames
