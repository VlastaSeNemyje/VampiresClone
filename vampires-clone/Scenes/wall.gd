extends StaticBody2D

@export var hp = 15
@export var flash_duration: float = 0.3

@export_group("Death Particles")
@export var death_particle_amount: int = 20
## Cone width, in degrees, away from the player.
@export var death_particle_spread: float = 60.0
@export var death_particle_lifetime: float = 0.5
@export var death_particle_speed_min: float = 40.0
@export var death_particle_speed_max: float = 100.0
@export var use_sprite_color_for_particles: bool = true
@export var death_particle_color: Color = Color(1, 1, 1, 1)

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite: Sprite2D = $Sprite2D
@onready var snd_hit = $snd_hit

var is_dead = false
var flash_material: ShaderMaterial
static var pixel_texture: ImageTexture

func _ready():
	flash_material = ShaderMaterial.new()
	flash_material.shader = preload("res://Shaders/hit_flash.gdshader")
	sprite.material = flash_material
	if pixel_texture == null:
		var img = Image.create(4, 4, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 1))
		pixel_texture = ImageTexture.create_from_image(img)

func flash_white():
	flash_material.set_shader_parameter("flash_amount", 1.0)
	var tween = create_tween()
	tween.tween_method(
		func(v): flash_material.set_shader_parameter("flash_amount", v),
		1.0, 0.0, flash_duration
	)

func spawn_death_particles():
	var particles = CPUParticles2D.new()
	particles.global_position = global_position
	particles.z_index = z_index
	particles.one_shot = true
	particles.explosiveness = 1.0
	particles.amount = death_particle_amount
	particles.lifetime = death_particle_lifetime
	var away_direction = Vector2.UP
	if player:
		away_direction = (global_position - player.global_position).normalized()
	particles.direction = away_direction
	particles.spread = death_particle_spread
	particles.initial_velocity_min = death_particle_speed_min
	particles.initial_velocity_max = death_particle_speed_max
	particles.gravity = Vector2.ZERO
	particles.damping_min = 60.0
	particles.damping_max = 90.0
	particles.scale_amount_min = 0.3
	particles.scale_amount_max = 0.4
	particles.angle_min = 0.0
	particles.angle_max = 360.0
	particles.angular_velocity_min = -180.0
	particles.angular_velocity_max = 180.0
	particles.texture = pixel_texture
	if use_sprite_color_for_particles:
		var img = sprite.texture.get_image()
		img.resize(1, 1, Image.INTERPOLATE_BILINEAR)
		var avg = img.get_pixel(0, 0)
		avg.a = 1.0
		particles.color = avg
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
	$CollisionShape2D.set_deferred("disabled", true)
	$HurtBox/CollisionShape2D.set_deferred("disabled", true)
	await get_tree().create_timer(0.05).timeout
	spawn_death_particles()
	sprite.visible = false
	await get_tree().create_timer(0.1).timeout
	queue_free()

func _on_hurt_box_hurt(damage, _angle, _knockback_amount):
	hp -= damage
	snd_hit.play()
	flash_white()
	if hp <= 0:
		death()
