extends Polygon2D

## Darkness overlay that leaves a round pool of light around the player.
## While the player moves, the pool slides slightly ahead of them, and it
## drifts back to the centre when they stop.
## Add as a child of the player (a CharacterBody2D with a centred camera).
## The look is set on the material's shader parameters.

## How quickly the pool slides toward the movement direction. Higher is snappier.
@export var follow_speed := 4.0

var _heading := Vector2.ZERO
@onready var _body := get_parent() as CharacterBody2D
@onready var _material := material as ShaderMaterial


func _process(delta: float) -> void:
	var target := Vector2.ZERO
	if _body and _body.velocity.length_squared() > 1.0:
		target = _body.velocity.normalized()
	_heading = _heading.lerp(target, 1.0 - exp(-follow_speed * delta))
	_material.set_shader_parameter("heading", _heading)

	# Screen pixels per game pixel = window scale * camera zoom.
	var viewport := get_viewport()
	var window_scale := viewport.get_final_transform().get_scale().y
	var camera := viewport.get_camera_2d()
	var zoom := camera.zoom.y if camera else 1.0
	_material.set_shader_parameter("pixel_size", maxf(window_scale * zoom, 1.0))
