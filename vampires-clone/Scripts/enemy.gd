extends CharacterBody2D

@export var movement_speed = 20
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
@export var enemy_damage = 1
var knockback = Vector2.ZERO

@export var flash_duration: float = 0.3

@export var death_particle_amount: int = 20
@export var death_particle_spread: float = 60.0  # cone width, in degrees, away from player

@export var use_sprite_color_for_particles: bool = true
@export var death_particle_color: Color = Color(1, 1, 1, 1)  # used when the toggle above is false

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var snd_hit = $snd_hit
@onready var hitBox = $HitBox

var is_dead = false
var exp_gem = preload("res://Scenes/exp_gem.tscn")
var flash_shader = preload("res://Shaders/hit_flash.gdshader")
var flash_material: ShaderMaterial

# 4x4 white square used as the death-particle texture, built once and reused
static var pixel_texture: ImageTexture

signal remove_from_array(object)

func _ready():
	hitBox.damage = enemy_damage

	flash_material = ShaderMaterial.new()
	flash_material.shader = flash_shader
	animated_sprite_2d.material = flash_material

	if pixel_texture == null:
		var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		pixel_texture = ImageTexture.create_from_image(img)

func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction * movement_speed
	velocity += knockback
	move_and_slide()

	if direction.x > 0.1:
		animated_sprite_2d.flip_h = false
	elif direction.x < -0.1:
		animated_sprite_2d.flip_h = true

func flash_white():
	if flash_material == null:
		return
	flash_material.set_shader_parameter("flash_amount", 1.0)
	var tween = create_tween()
	tween.tween_method(
		func(v): flash_material.set_shader_parameter("flash_amount", v),
		1.0, 0.0, flash_duration
	)

func _get_average_sprite_color() -> Color:
	var frames = animated_sprite_2d.sprite_frames
	var anim = animated_sprite_2d.animation
	var frame = animated_sprite_2d.frame
	var texture = frames.get_frame_texture(anim, frame)

	var img = texture.get_image()
	if img == null:
		return Color(1, 1, 1, 1)

	img.resize(1, 1, Image.INTERPOLATE_BILINEAR)
	var avg = img.get_pixel(0, 0)
	avg.a = 1.0
	return avg

func spawn_death_particles():
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.z_index = z_index
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = death_particle_amount
	particles.lifetime = 0.5

	# fire away from the player instead of in all directions
	var away_direction = Vector2.UP
	if player:
		away_direction = (global_position - player.global_position).normalized()
	particles.direction = away_direction
	particles.spread = death_particle_spread

	particles.initial_velocity_min = 40.0
	particles.initial_velocity_max = 100.0
	particles.gravity = Vector2.ZERO
	particles.damping_min = 60.0
	particles.damping_max = 90.0

	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.4
	particles.angle_min = 0.0
	particles.angle_max = 360.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0

	# tiny pixel-square texture, tinted either by the enemy's sprite color
	# or by a fixed color set in the Inspector
	particles.texture = pixel_texture
	if use_sprite_color_for_particles:
		particles.color = _get_average_sprite_color()
	else:
		particles.color = death_particle_color

	var gradient = Gradient.new()
	gradient.set_color(0, Color(1, 1, 1, 1))
	gradient.set_color(1, Color(1, 1, 1, 0))
	var gradient_texture = GradientTexture1D.new()
	gradient_texture.gradient = gradient
	particles.color_ramp = gradient_texture

	get_tree().current_scene.add_child(particles)
	particles.emitting = true

	get_tree().create_timer(particles.lifetime + 0.2).timeout.connect(particles.queue_free)

func death():
	if is_dead:
		return

	is_dead = true
	emit_signal("remove_from_array", self)
	velocity = Vector2.ZERO

	await get_tree().create_timer(0.05).timeout

	spawn_death_particles()
	animated_sprite_2d.visible = false

	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child", new_gem)

	await get_tree().create_timer(0.1).timeout
	queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	snd_hit.play()
	flash_white()

	if hp <= 0:
		death()
