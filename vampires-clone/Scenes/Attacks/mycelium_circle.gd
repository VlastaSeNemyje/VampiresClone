extends Node2D
## Mycelium Circle - King Bible style: mushrooms orbit the player and damage
## every enemy they touch. Early levels show the mushrooms only for a few
## seconds every few seconds; the last level keeps the circle on permanently.
##
## This node lives on the player (like LeafProtection / Roots). All the numbers
## you want to balance are in the Inspector of Scenes/Attacks/mycelium_circle.tscn.
## Edit MushroomTemplate in this same scene to customize each mushroom.

# --------------------------------------------------------------------- LOOK --
@export_group("Look")
## Center of the circle, relative to the player's origin (feet).
@export var center_offset := Vector2(0, -8)
## Your sprite points UP as drawn -> 90 makes the cap point outward from the circle.
## If the sprite points RIGHT, set this to 0.
@export_range(-180.0, 180.0) var mushroom_rotation_offset_deg := 90.0
## Angle (degrees) where the first mushroom sits. -90 = top.
@export var start_angle_deg := -90.0

# ------------------------------------------------------------------- STATS --
# One entry per level. Element 0 = level 1 (start) ... element 3 = level 4.
# L1: 1 mushroom, 2 s every 5 s     | L2: +1 opposite mushroom, 3 s
# L3: +2 mushrooms, spins 20% faster | L4: +4 mushrooms, always on, +10% faster
@export_group("Stats per level (element 0 = level 1)")
@export var mushroom_count_per_level: Array[int] = [1, 2, 4, 8]
## How long the mushrooms stay out each cycle (ignored when Always On).
@export var active_duration_per_level: Array[float] = [2.0, 3.0, 3.0, 3.0]
## Seconds from the START of one appearance to the START of the next
## (Scroll upgrade shortens it). Ignored when Always On.
@export var cooldown_per_level: Array[float] = [5.0, 5.0, 5.0, 5.0]
## Mushrooms never leave, no cooldown.
@export var always_on_per_level: Array[bool] = [false, false, false, true]
## Damage per hit, per mushroom.
@export var damage_per_level: Array[float] = [5.0, 5.0, 6.0, 7.0]
@export var knockback_per_level: Array[float] = [40.0, 40.0, 40.0, 50.0]
## Seconds before the same enemy can be hit again by the same mushroom.
@export var hit_cooldown_per_level: Array[float] = [0.6, 0.6, 0.6, 0.6]
## Gentle trail behind each mushroom (look is set on MushroomTemplate > Trail).
@export var trail_per_level: Array[bool] = [false, false, false, true]
## Mushroom size multiplier (Tome upgrade adds on top).
@export var size_per_level: Array[float] = [0.8, 0.8, 0.8, 0.8]
## Distance of the mushrooms from the center, in pixels.
@export var orbit_radius_per_level: Array[float] = [34.0, 34.0, 34.0, 34.0]
## Spin speed multiplier. 1.2 = 20% faster, 1.3 = 30% faster (20% + another 10%).
@export var rotation_speed_multiplier_per_level: Array[float] = [1.0, 1.0, 1.2, 1.3]

# ---------------------------------------------------------------- ROTATION --
@export_group("Rotation")
## Degrees per second at multiplier 1.0. Negative = counter-clockwise.
@export var base_rotation_speed_deg := 180.0

@export_group("Extra attacks")
## Ring upgrade ("+1 attack") adds this many mushrooms.
@export var extra_mushrooms_per_ring := 1

# ------------------------------------------------------------ RUNTIME STATE --
var level := 1
var mushroom_count := 1
var active_duration := 2.0
var cooldown := 5.0
var always_on := false
var damage := 5.0
var knockback_amount := 40.0
var hit_cooldown := 0.6
var trail_per_level_value := false
var size := 0.8
var orbit_radius := 34.0
var rotation_speed := 1.0

var _cycle_time := 0.0
var _out := false
var _mushrooms := []

@onready var player = get_tree().get_first_node_in_group("player")
@onready var pivot: Node2D = $Pivot
@onready var template: Area2D = $MushroomTemplate


func _ready() -> void:
	position = center_offset


func _process(delta: float) -> void:
	if not is_instance_valid(player) or level <= 0:
		return
	# Keep spinning even while hidden so mushrooms don't reappear at the same spot
	pivot.rotation += deg_to_rad(base_rotation_speed_deg) * rotation_speed * delta

	if always_on:
		_set_out(true)
		return
	_cycle_time += delta
	var period := maxf(cooldown, active_duration)
	if _cycle_time >= period:
		_cycle_time -= period
	_set_out(_cycle_time < active_duration)


# Called by the player whenever the level or any player stat changes.
func update_mycelium() -> void:
	if not is_instance_valid(player):
		return
	level = clampi(player.mycelium_level, 1, maxi(mushroom_count_per_level.size(), 1))
	var i := level - 1

	mushroom_count = int(_pick(mushroom_count_per_level, i, 1.0)) \
		+ player.additional_attacks * extra_mushrooms_per_ring
	active_duration = _pick(active_duration_per_level, i, 2.0)
	always_on = bool(_pick_bool(always_on_per_level, i))
	damage = _pick(damage_per_level, i, 5.0)
	knockback_amount = _pick(knockback_per_level, i, 40.0)
	hit_cooldown = _pick(hit_cooldown_per_level, i, 0.6)
	trail_per_level_value = _pick_bool(trail_per_level, i)
	orbit_radius = _pick(orbit_radius_per_level, i, 34.0)
	rotation_speed = _pick(rotation_speed_multiplier_per_level, i, 1.0)
	# Same conventions as your other weapons: Tome = size, Scroll = cooldown
	size = _pick(size_per_level, i, 0.8) * (1.0 + player.spell_size)
	cooldown = maxf(0.3, _pick(cooldown_per_level, i, 5.0) * (1.0 - player.spell_cooldown))

	_rebuild_mushrooms()


func _set_out(value: bool) -> void:
	if value == _out:
		return
	_out = value
	for m in _mushrooms:
		m.set_active(value)


func _rebuild_mushrooms() -> void:
	# Remove surplus mushrooms (e.g. never happens on level up, but be safe)
	while _mushrooms.size() > mushroom_count:
		_mushrooms.pop_back().queue_free()
	# Add the missing ones
	while _mushrooms.size() < mushroom_count:
		var m = template.duplicate(Node.DUPLICATE_SCRIPTS)
		m.is_template = false
		m.size = size
		m.visible = true
		m.process_mode = Node.PROCESS_MODE_INHERIT
		m.monitoring = true
		pivot.add_child(m)
		_mushrooms.append(m)
		if _out:
			m.set_active(true)
	# Push the current stats into every mushroom and re-space them evenly
	var start := deg_to_rad(start_angle_deg)
	for n in _mushrooms.size():
		var m = _mushrooms[n]
		var angle := start + TAU * float(n) / float(_mushrooms.size())
		m.position = Vector2.RIGHT.rotated(angle) * orbit_radius
		m.rotation = angle + deg_to_rad(mushroom_rotation_offset_deg)
		m.damage = damage
		m.knockback_amount = knockback_amount
		m.hit_cooldown = hit_cooldown
		m.trail_enabled = trail_per_level_value
		m.set_size(size)
	# Level 4: if we were hidden in a cooldown, show up right away
	if always_on:
		_set_out(true)


func _pick(arr: Array, index: int, fallback: float) -> float:
	if arr.is_empty():
		return fallback
	return float(arr[mini(index, arr.size() - 1)])


func _pick_bool(arr: Array, index: int) -> bool:
	if arr.is_empty():
		return false
	return bool(arr[mini(index, arr.size() - 1)])
