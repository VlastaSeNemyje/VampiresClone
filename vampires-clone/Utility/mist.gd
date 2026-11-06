extends Node2D
## Endless drifting mist around the camera. Everything is adjustable in the Inspector.

const MIST_TEXTURE := preload("res://Textures/Sprites/VFX/MistParticles.png")

## Number of clouds alive at once.
@export_range(0, 200) var density: int = 14
## Direction of drift in degrees (0 = right, 90 = down, 180 = left, 270 = up).
@export_range(0, 360) var direction_degrees: float = 0.0
## Average drift speed (pixels per second).
@export var speed: float = 10.0
## 0 = all clouds move at the same speed, 1 = speeds vary by +/-100%.
@export_range(0, 1) var speed_variability: float = 0.4
## Overall size multiplier for every cloud.
@export var size: float = 1.0
## 0 = all clouds the same size, 1 = sizes vary from 0% to 200%.
@export_range(0, 1) var size_variability: float = 0.4
## Area (in pixels) around the camera that holds the clouds. Keep it larger than the screen.
@export var area: Vector2 = Vector2(1000, 640)
## Fade in/out distance at the edge of the area so clouds never pop.
@export var edge_fade: float = 150.0
## The visual looks of the clouds (three by default). Add, remove or edit them.
@export var variants: Array[MistVariant] = []

var _clouds: Array[Sprite2D] = []
var _speeds: Array[float] = []
var _base_alpha: Array[float] = []


func _ready() -> void:
	if variants.is_empty():
		push_warning("Mist: no variants set, nothing to show.")
		return
	_rebuild()


func _rebuild() -> void:
	for c in _clouds:
		c.queue_free()
	_clouds.clear()
	_speeds.clear()
	_base_alpha.clear()
	var center := _camera_center()
	for i in density:
		var s := Sprite2D.new()
		s.texture = MIST_TEXTURE
		s.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
		var v := _pick_variant()
		var k := size * maxf(0.1, 1.0 + randf_range(-1.0, 1.0) * size_variability)
		s.scale = v.stretch * k
		s.rotation_degrees = randf_range(-v.tilt_degrees, v.tilt_degrees)
		s.flip_h = randf() < 0.5
		s.modulate = v.tint
		s.global_position = center + Vector2(
			randf_range(-area.x * 0.5, area.x * 0.5),
			randf_range(-area.y * 0.5, area.y * 0.5))
		add_child(s)
		_clouds.append(s)
		_speeds.append(speed * maxf(0.1, 1.0 + randf_range(-1.0, 1.0) * speed_variability))
		_base_alpha.append(v.tint.a)


func _pick_variant() -> MistVariant:
	var total := 0.0
	for v in variants:
		total += v.weight
	var r := randf() * total
	for v in variants:
		r -= v.weight
		if r <= 0.0:
			return v
	return variants[0]


func _camera_center() -> Vector2:
	var cam := get_viewport().get_camera_2d()
	return cam.get_screen_center_position() if cam else Vector2.ZERO


func _process(delta: float) -> void:
	if _clouds.is_empty():
		return
	var dir := Vector2.RIGHT.rotated(deg_to_rad(direction_degrees))
	var center := _camera_center()
	var half := area * 0.5
	for i in _clouds.size():
		var c := _clouds[i]
		c.global_position += dir * _speeds[i] * delta
		# Wrap around so the mist is endless as the player moves.
		var off := c.global_position - center
		if off.x > half.x: off.x -= area.x
		elif off.x < -half.x: off.x += area.x
		if off.y > half.y: off.y -= area.y
		elif off.y < -half.y: off.y += area.y
		c.global_position = center + off
		# Soft fade near the edge of the area.
		var edge := minf(half.x - absf(off.x), half.y - absf(off.y))
		var f := clampf(edge / maxf(edge_fade, 1.0), 0.0, 1.0)
		c.modulate.a = _base_alpha[i] * f
