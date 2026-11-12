extends Node2D
## Breakable Food Stump (the candle). Player attacks damage it through its HurtBox, exactly like an enemy.
## When it breaks it may drop a food pickup that heals the player.
## Stumps scattered by a FoodStumpField get these three values from the field's Inspector settings.

@export var hp: float = 20.0
## Chance (0-1) that food is dropped when the stump breaks.
@export_range(0.0, 1.0, 0.01) var food_drop_chance: float = 0.25
## Health restored by the dropped food.
@export var heal_amount: float = 20.0

@export_group("Look")
## Frames per second of the candle flame animation.
@export var animation_fps: float = 6.0
@export var flash_duration: float = 0.3
@export var death_particle_amount: int = 14

const FOOD = preload("res://Scenes/Objects/food_pickup.tscn")

@onready var sprite: Sprite2D = $Sprite2D
@onready var snd_hit: AudioStreamPlayer2D = $snd_hit
@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")

var is_dead := false
var flash_material: ShaderMaterial
var _anim_time := 0.0
static var pixel_texture: ImageTexture

func _ready():
	flash_material = ShaderMaterial.new()
	flash_material.shader = preload("res://Shaders/hit_flash.gdshader")
	sprite.material = flash_material
	_anim_time = randf() * sprite.hframes   # candles do not flicker in unison
	if pixel_texture == null:
		var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		pixel_texture = ImageTexture.create_from_image(img)

func _process(delta):
	_anim_time += delta * animation_fps
	sprite.frame = int(_anim_time) % sprite.hframes

func _on_hurt_box_hurt(damage, _angle, _knockback_amount):
	if is_dead:
		return
	hp -= damage
	snd_hit.play()
	flash_material.set_shader_parameter("flash_amount", 1.0)
	create_tween().tween_method(
		func(v): flash_material.set_shader_parameter("flash_amount", v),
		1.0, 0.0, flash_duration
	)
	if hp <= 0:
		_break()

func _break():
	is_dead = true
	$HurtBox/CollisionShape2D.set_deferred("disabled", true)
	if randf() < food_drop_chance:
		var food = FOOD.instantiate()
		food.heal_amount = heal_amount
		food.global_position = global_position
		(loot_base if loot_base != null else get_parent()).call_deferred("add_child", food)
	_spawn_break_particles()
	sprite.visible = false
	# keep the node until the hit sound has played
	await get_tree().create_timer(0.4).timeout
	queue_free()

func _spawn_break_particles():
	var particles = CPUParticles2D.new()
	particles.z_index = z_index
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = death_particle_amount
	particles.lifetime = 0.5
	particles.direction = Vector2.UP
	if player:
		particles.direction = (global_position - player.global_position).normalized()
	particles.spread = 70.0
	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2.ZERO
	particles.damping_min = 60.0
	particles.damping_max = 90.0
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.4
	particles.texture = pixel_texture
	particles.color = Color(0.45, 0.28, 0.16)   # stump brown
	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	particles.color_ramp = gradient
	get_tree().current_scene.add_child(particles)
	particles.global_position = global_position
	particles.emitting = true
	get_tree().create_timer(particles.lifetime + 0.2).timeout.connect(particles.queue_free)
