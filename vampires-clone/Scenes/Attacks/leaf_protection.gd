@tool
extends Area2D
## Leaf Protection - a Garlic-style aura that follows the player and pulses
## damage to every enemy inside it. Leaves are arranged in a ring; at higher
## levels the ring starts to spin.
##
## Every number you might want to tweak is exported, so you can change it in
## the Inspector of the LeafProtection scene (Scenes/Attacks/leaf_protection.tscn).

# Guess for where your Leaf sprite lives. If it's elsewhere, just drag the
# texture into "Leaf Texture" in the Inspector and this is ignored.
const DEFAULT_LEAF_PATH := "res://Textures/Sprites/Weapons/Leaf.png"

# ---------------------------------------------------------------- LOOK ----
@export_group("Look")
@export var leaf_texture: Texture2D
@export var leaf_scale: float = 1.0
@export var leaf_tint: Color = Color.WHITE
## Your leaf sprite points UP as drawn -> 90 makes it point outward from the ring.
## If the sprite points RIGHT, set this to 0.
@export_range(-180.0, 180.0) var leaf_rotation_offset_deg: float = 90.0
## 1.0 = leaves sit exactly on the edge of the aura, 0.9 = slightly inside.
@export_range(0.0, 1.5) var leaf_ring_ratio: float = 0.95
## Where the aura is centered, relative to the player's origin (feet).
@export var center_offset: Vector2 = Vector2(0, -8)
@export var show_aura_disk: bool = true
@export var aura_color: Color = Color(0.85, 0.93, 0.95, 0.30)
@export var edge_color: Color = Color(0.75, 0.95, 0.4, 0.45)
@export var pulse_ring_color: Color = Color(0.75, 0.95, 0.4, 0.9)
## How long the aura takes to grow when spawned / upgraded.
@export var grow_time: float = 0.35
## The leaves "pop" this much bigger on every pulse (1.0 = no pop).
@export var pulse_pop_scale: float = 1.12

# ------------------------------------------------------- FILLER LEAVES ----
@export_group("Filler Leaves")
## Extra leaves placed in each gap between the main leaves (0 = none). Visual only.
@export var filler_per_gap: int = 1
@export var filler_scale: float = 0.75
## Slightly inside the main ring gives a layered look.
@export_range(0.0, 1.5) var filler_ring_ratio: float = 0.9

# ------------------------------------------------------ EDITOR PREVIEW ----
@export_group("Editor Preview")
## Which level to preview in the 2D editor (does not affect the game).
@export_range(1, 4) var preview_level: int = 1
## Spin the leaves in the editor (only works if the preview level rotates).
@export var preview_spin: bool = false
## Draws helper rings + a player-sized box in the editor (never in the game).
@export var show_editor_guides: bool = true

# --------------------------------------------------------------- STATS ----
# One entry per level. Index 0 = level 1, index 3 = level 4.
@export_group("Stats per level (element 0 = level 1)")
@export var damage_per_level: Array[float] = [3.0, 5.0, 5.0, 5.0]
## Seconds between pulses (lower = faster). Level 3 = "shorter cooldown".
@export var tick_interval_per_level: Array[float] = [1.0, 1.0, 0.7, 0.7]
## Aura radius in pixels (this is the attack size). Level 4 = "bigger area".
@export var radius_per_level: Array[float] = [55.0, 55.0, 55.0, 65.0]
@export var knockback_per_level: Array[float] = [40.0, 40.0, 40.0, 60.0]
## Number of MAIN leaves (fillers are added on top of this).
@export var leaf_count_per_level: Array[int] = [8, 8, 8, 10]
## Extra pixels of leniency when checking if an enemy is inside the aura.
@export var hit_padding: float = 6.0

# ------------------------------------------------------------ ROTATION ----
@export_group("Rotation")
## Leaves start spinning from this level on (set to 99 to disable).
@export var rotate_from_level: int = 4
@export var rotation_speed_deg: float = 90.0
## How quickly the spin ramps up (so it doesn't snap on).
@export var rotation_accel_deg: float = 180.0

# ---------------------------------------------------------- BIG PULSE -----
@export_group("Big Pulse")
@export var big_pulse_from_level: int = 4
## 0.10 = 10% of pulses are "big".
@export_range(0.0, 1.0) var big_pulse_chance: float = 0.10
## 0.30 = a big pulse is 30% wider than the normal aura.
@export var big_pulse_bonus: float = 0.30

# ------------------------------------------------------- RUNTIME STATE ----
var level := 1
var damage := 3.0
var tick_interval := 1.0
var base_radius := 50.0
var knockback_amount := 40.0
var leaf_count := 8

# What is currently drawn (tweened), as opposed to base_radius (the target).
var visual_radius := 0.0:
	set(value):
		visual_radius = value
		_layout_leaves()
		queue_redraw()

var pulse_progress := 1.0:
	set(value):
		pulse_progress = value
		queue_redraw()

var pulse_strength := 1.0
var spin := 0.0

var _radius_tween: Tween
var _pulse_tween: Tween
var _warned_no_texture := false
var _fallback_texture: Texture2D
var _last_signature: Array = []

@onready var player = get_tree().get_first_node_in_group("player")
@onready var leaves: Node2D = $Leaves
@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var tick_timer: Timer = $TickTimer
@onready var snd_pulse: AudioStreamPlayer2D = $snd_pulse


func _ready() -> void:
	if Engine.is_editor_hint():
		_editor_refresh()
		return
	position = center_offset
	tick_timer.timeout.connect(_on_tick_timer_timeout)
	update_leaf_protection()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		_editor_process(delta)
		return
	var target_spin := deg_to_rad(rotation_speed_deg) if level >= rotate_from_level else 0.0
	spin = move_toward(spin, target_spin, deg_to_rad(rotation_accel_deg) * delta)
	if spin != 0.0:
		leaves.rotation += spin * delta


# Called by the player whenever the level or any player stat changes.
func update_leaf_protection() -> void:
	# Ring ("+1 attack") makes the aura 20% wider per level
	_apply_stats(player.leaf_level, player.spell_size + 0.2 * player.additional_attacks, player.spell_cooldown)


func _apply_stats(lvl: int, size_bonus: float, cooldown_bonus: float) -> void:
	level = clampi(lvl, 1, maxi(damage_per_level.size(), 1))
	var i := level - 1

	damage = _pick(damage_per_level, i, 3.0)
	knockback_amount = _pick(knockback_per_level, i, 40.0)
	leaf_count = int(_pick(leaf_count_per_level, i, 8.0))
	# Same conventions as your other weapons: Tome = size, Scroll = cooldown
	base_radius = _pick(radius_per_level, i, 50.0) * (1.0 + size_bonus)
	tick_interval = maxf(0.1, _pick(tick_interval_per_level, i, 1.0) * (1.0 - cooldown_bonus))

	# Collision circle always covers the biggest possible pulse; the exact
	# radius of each pulse is checked by distance in _on_tick_timer_timeout.
	var max_radius := base_radius
	if level >= big_pulse_from_level:
		max_radius *= 1.0 + big_pulse_bonus
	(collision.shape as CircleShape2D).radius = max_radius + hit_padding

	if Engine.is_editor_hint():
		# Editor: no timer, no tweens - just show the final look instantly
		_rebuild_leaves(true)
		leaves.position = center_offset
		visual_radius = base_radius
		queue_redraw()
		return

	tick_timer.wait_time = tick_interval
	if tick_timer.is_stopped():
		tick_timer.start()

	_rebuild_leaves()
	_tween_radius_to(base_radius, grow_time)


func _on_tick_timer_timeout() -> void:
	var big := level >= big_pulse_from_level and randf() < big_pulse_chance
	var radius := base_radius * (1.0 + (big_pulse_bonus if big else 0.0))
	var hits := 0

	for area in get_overlapping_areas():
		# Only enemy HurtBoxes have the "hurt" signal (player attacks share our layer)
		if not area.has_signal("hurt"):
			continue
		if area.get_parent().get("is_dead") == true:
			continue
		if global_position.distance_to(area.global_position) > radius + hit_padding:
			continue
		var direction := global_position.direction_to(area.global_position)
		# Same signal HurtBox emits for whip/arrow hits -> enemy.gd handles
		# damage, knockback, hit flash and hit sound for us.
		area.emit_signal("hurt", damage, direction, knockback_amount)
		hits += 1

	_play_pulse(big, hits, radius)


# ------------------------------------------------------------- FEEDBACK ---
func _play_pulse(big: bool, hits: int, radius: float) -> void:
	# Stronger ring when the pulse actually hit something
	pulse_strength = 1.0 if hits > 0 else 0.35

	if _pulse_tween:
		_pulse_tween.kill()
	pulse_progress = 0.0
	leaves.scale = Vector2.ONE * pulse_pop_scale
	_pulse_tween = create_tween().set_parallel(true)
	_pulse_tween.tween_property(self, "pulse_progress", 1.0, 0.35)\
		.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_pulse_tween.tween_property(leaves, "scale", Vector2.ONE, 0.2)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	if big:
		# Aura visibly swells to the bigger radius, then settles back
		if _radius_tween:
			_radius_tween.kill()
		_radius_tween = create_tween()
		_radius_tween.tween_property(self, "visual_radius", radius, 0.12)\
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_radius_tween.tween_property(self, "visual_radius", base_radius, 0.3)\
			.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)

	if hits > 0 and snd_pulse.stream != null:
		snd_pulse.pitch_scale = randf_range(0.95, 1.1)
		snd_pulse.play()


func _tween_radius_to(target: float, time: float) -> void:
	if _radius_tween:
		_radius_tween.kill()
	_radius_tween = create_tween()
	_radius_tween.tween_property(self, "visual_radius", target, time)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)


func _draw() -> void:
	# In the game the whole node sits at center_offset. In the editor the root
	# stays at the origin (the player's feet) and we offset the drawing instead.
	var o := center_offset if Engine.is_editor_hint() else Vector2.ZERO
	if Engine.is_editor_hint() and show_editor_guides:
		_draw_editor_guides(o)
	if visual_radius <= 0.0:
		return
	if show_aura_disk:
		draw_circle(o, visual_radius, aura_color)
		draw_arc(o, visual_radius, 0.0, TAU, 64, edge_color, 1.0)
	if pulse_progress < 1.0:
		var r := lerpf(visual_radius * 0.6, visual_radius * 1.1, pulse_progress)
		var c := pulse_ring_color
		c.a *= (1.0 - pulse_progress) * pulse_strength
		draw_arc(o, r, 0.0, TAU, 64, c, 2.0)


func _draw_editor_guides(o: Vector2) -> void:
	# Player-sized box (32x33 sprite standing on the origin) for scale
	draw_rect(Rect2(-16, -31, 32, 33), Color(1, 1, 1, 0.5), false, 1.0)
	# Origin cross = the player's feet
	draw_line(Vector2(-4, 0), Vector2(4, 0), Color(1, 1, 1, 0.8), 1.0)
	draw_line(Vector2(0, -4), Vector2(0, 4), Color(1, 1, 1, 0.8), 1.0)
	# Red = where enemies actually get hit (radius + hit padding)
	draw_arc(o, base_radius + hit_padding, 0.0, TAU, 64, Color(1, 0.3, 0.3, 0.7), 1.0)
	# Yellow = size of a "big pulse"
	if level >= big_pulse_from_level:
		draw_arc(o, base_radius * (1.0 + big_pulse_bonus) + hit_padding, 0.0, TAU, 64, Color(1, 0.9, 0.2, 0.6), 1.0)


# ------------------------------------------------------- EDITOR PREVIEW ---
func _editor_process(delta: float) -> void:
	var sig := _preview_signature()
	if sig != _last_signature:
		_last_signature = sig
		_editor_refresh()
	if preview_spin and level >= rotate_from_level:
		leaves.rotation += deg_to_rad(rotation_speed_deg) * delta
	elif not preview_spin and leaves.rotation != 0.0:
		leaves.rotation = 0.0


func _editor_refresh() -> void:
	if leaves == null or collision == null:
		return
	_apply_stats(preview_level, 0.0, 0.0)


# Every value that changes how the preview looks. Arrays are duplicated so
# in-place edits in the Inspector are noticed.
func _preview_signature() -> Array:
	return [
		leaf_texture, leaf_scale, leaf_tint, leaf_rotation_offset_deg,
		leaf_ring_ratio, center_offset, show_aura_disk, aura_color, edge_color,
		filler_per_gap, filler_scale, filler_ring_ratio,
		radius_per_level.duplicate(), leaf_count_per_level.duplicate(),
		hit_padding, big_pulse_from_level, big_pulse_bonus, rotate_from_level,
		preview_level, show_editor_guides,
	]


# --------------------------------------------------------------- LEAVES ---
# Children 0 .. leaf_count-1 are the main leaves (they define the ring).
# Children after that are filler leaves, placed in the gaps between them.
func _get_leaf_texture() -> Texture2D:
	if leaf_texture != null:
		return leaf_texture
	if _fallback_texture == null and ResourceLoader.exists(DEFAULT_LEAF_PATH):
		_fallback_texture = load(DEFAULT_LEAF_PATH)
	return _fallback_texture


func _rebuild_leaves(force := false) -> void:
	var fillers := maxi(filler_per_gap, 0)
	var total := leaf_count + leaf_count * fillers
	if not force and leaves.get_child_count() == total:
		return
	var tex := _get_leaf_texture()
	if tex == null and not _warned_no_texture:
		_warned_no_texture = true
		push_warning("LeafProtection: no Leaf Texture set. Assign one in the Inspector.")
	for c in leaves.get_children():
		leaves.remove_child(c)
		c.queue_free()
	if tex == null:
		return
	for i in total:
		var leaf := Sprite2D.new()
		leaf.texture = tex
		if i < leaf_count:
			leaf.scale = Vector2.ONE * leaf_scale
		else:
			leaf.scale = Vector2.ONE * leaf_scale * filler_scale
		leaf.modulate = leaf_tint
		leaves.add_child(leaf)
	_layout_leaves()


func _layout_leaves() -> void:
	if leaves == null or leaf_count <= 0:
		return
	var fillers := maxi(filler_per_gap, 0)
	var total := leaves.get_child_count()
	for i in total:
		var leaf := leaves.get_child(i) as Sprite2D
		var angle := 0.0
		var ratio := leaf_ring_ratio
		if i < leaf_count or fillers == 0:
			# main leaves, first one at the top
			angle = TAU * float(i) / float(leaf_count) - PI / 2.0
		else:
			# fillers, evenly spread inside each gap between two main leaves
			var f := i - leaf_count
			var gap := f / fillers
			var slot := f % fillers
			var t := float(gap) + float(slot + 1) / float(fillers + 1)
			angle = TAU * t / float(leaf_count) - PI / 2.0
			ratio = filler_ring_ratio
		leaf.position = Vector2.RIGHT.rotated(angle) * visual_radius * ratio
		leaf.rotation = angle + deg_to_rad(leaf_rotation_offset_deg)


func _pick(arr: Array, index: int, fallback: float) -> float:
	if arr.is_empty():
		return fallback
	return float(arr[mini(index, arr.size() - 1)])
