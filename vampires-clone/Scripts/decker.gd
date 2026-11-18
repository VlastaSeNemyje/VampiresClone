extends "res://Scripts/enemy.gd"

@export_group("Keep Distance")
## Distance from the player Decker tries to hold.
@export var keep_distance: float = 150.0
## Decker stands still while the distance is within keep_distance +/- this value.
@export var distance_tolerance: float = 10.0
## Multiplier on movement_speed while backing away from the player.
@export var flee_speed_multiplier: float = 1.0

@export_group("Drone")
@export var drone_scene: PackedScene
@export var drone_interval: float = 8.0
## Seconds between reaching the keep distance and the first drone.
@export var first_drone_delay: float = 1.0

@export_group("Hand Light")
## Same blink as the drone's light, so the two clearly belong together.
@export var light_blink_speed: float = 8.0
@export var light_min_alpha: float = 0.2
@export var light_max_alpha: float = 1.0
@export var light_min_scale: float = 0.6
@export var light_max_scale: float = 1.2

@onready var hand_light: Sprite2D = $HandLight

var drone_timer := 0.0
var in_position := false
var _blink_time := 0.0
var _light_base_scale := Vector2.ONE
var _light_base_x := 0.0

func _ready():
	super()
	_light_base_scale = hand_light.scale
	_light_base_x = hand_light.position.x

func _process(delta):
	_blink_time += delta * light_blink_speed
	var pulse = (sin(_blink_time) + 1.0) * 0.5
	hand_light.modulate.a = lerpf(light_min_alpha, light_max_alpha, pulse)
	hand_light.scale = _light_base_scale * lerpf(light_min_scale, light_max_scale, pulse)
	# the hand swaps sides when Decker turns around
	var side := -1.0 if animated_sprite_2d.flip_h else 1.0
	hand_light.position.x = _light_base_x * side
	hand_light.visible = not is_dead

func _get_move_direction() -> Vector2:
	var to_player = global_position.direction_to(player.global_position)
	var dist = global_position.distance_to(player.global_position)
	if dist > keep_distance + distance_tolerance:
		in_position = false
		return to_player
	if dist < keep_distance - distance_tolerance:
		in_position = false
		return -to_player * flee_speed_multiplier
	if not in_position:
		in_position = true
		drone_timer = drone_interval - first_drone_delay
	return Vector2.ZERO

func _physics_process(delta):
	super(delta)
	if is_dead or stun_time_left > 0.0:
		return
	if in_position:
		drone_timer += delta
		if drone_timer >= drone_interval:
			drone_timer = 0.0
			launch_drone()

func launch_drone():
	if drone_scene == null or player == null:
		return
	var drone = drone_scene.instantiate()
	drone.global_position = global_position
	drone.target_position = player.global_position
	get_tree().current_scene.add_child(drone)
