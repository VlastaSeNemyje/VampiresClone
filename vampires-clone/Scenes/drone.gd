extends Node2D

@export_group("Stats")
@export var hp = 50
@export var damage = 20
@export var speed: float = 90.0
@export var flash_duration: float = 0.3

@export_group("Flight Path")
## How far past the player's position (at launch) the drone keeps flying before disappearing.
@export var overshoot_distance: float = 100.0
## Sideways swing of the zig-zag path, in pixels (0 = straight line).
@export var wobble_amplitude: float = 25.0
## Zig-zag waves per pixel travelled.
@export var wobble_frequency: float = 0.01

@export_group("Light")
@export var light_blink_speed: float = 8.0
@export var light_min_alpha: float = 0.2
@export var light_max_alpha: float = 1.0
## Light size pulses between these multipliers of its base scale.
@export var light_min_scale: float = 0.6
@export var light_max_scale: float = 1.2

@onready var sprite: Sprite2D = $Sprite2D
@onready var light: Sprite2D = $Light
@onready var hit_box = $HitBox
@onready var snd_hit = $snd_hit

var target_position := Vector2.ZERO   # set by Decker before add_child
var start_position := Vector2.ZERO
var direction := Vector2.RIGHT
var total_distance := 0.0
var travelled := 0.0
var flash_material: ShaderMaterial
var is_dead = false
var _blink_time := 0.0
var _light_base_scale := Vector2.ONE

func _ready():
	_light_base_scale = light.scale
	start_position = global_position
	direction = start_position.direction_to(target_position)
	total_distance = start_position.distance_to(target_position) + overshoot_distance
	hit_box.damage = damage
	hit_box.area_entered.connect(_on_hit_box_area_entered)
	flash_material = ShaderMaterial.new()
	flash_material.shader = preload("res://Shaders/hit_flash.gdshader")
	sprite.material = flash_material

func _physics_process(delta):
	if is_dead:
		return
	travelled += speed * delta
	var side = direction.orthogonal() * sin(travelled * wobble_frequency * TAU) * wobble_amplitude
	global_position = start_position + direction * travelled + side
	if travelled >= total_distance:
		queue_free()

func _process(delta):
	_blink_time += delta * light_blink_speed
	var pulse = (sin(_blink_time) + 1.0) * 0.5
	light.modulate.a = lerpf(light_min_alpha, light_max_alpha, pulse)
	light.scale = _light_base_scale * lerpf(light_min_scale, light_max_scale, pulse)

func _on_hit_box_area_entered(area):
	# only the player's hurt box ends the flight
	if not is_dead and area.has_signal("hurt") and area.get_parent().is_in_group("player"):
		is_dead = true
		queue_free()

func _on_hurt_box_hurt(dmg, _angle, _knockback_amount):
	if is_dead:
		return
	hp -= dmg
	snd_hit.play()
	flash_material.set_shader_parameter("flash_amount", 1.0)
	var tween = create_tween()
	tween.tween_method(
		func(v): flash_material.set_shader_parameter("flash_amount", v),
		1.0, 0.0, flash_duration
	)
	if hp <= 0:
		is_dead = true
		hit_box.set_deferred("monitoring", false)
		$HurtBox/CollisionShape2D.set_deferred("disabled", true)
		sprite.visible = false
		light.visible = false
		await get_tree().create_timer(0.15).timeout
		queue_free()
