extends Area2D
## A single Kanec projectile. Spawned and configured by kanec_base.gd (Player/Attack/KanecBase).

var damage = 6.0
var knockback_amount = 100.0
var attack_size = 1.0
var speed = 160.0
var hp = 9999
var angle = Vector2.RIGHT          # also used by the HurtBox as knockback direction
var travel_distance = 800.0        # how far it runs before it is removed
var sprite_faces_right = true

var travelled = 0.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

signal remove_from_array(object)

func _ready():
	scale = Vector2.ONE * attack_size
	sprite.flip_h = (angle.x < 0) == sprite_faces_right
	sprite.play("default")

func _physics_process(delta):
	var step = speed * delta
	position += angle * step
	travelled += step
	if travelled >= travel_distance:
		emit_signal("remove_from_array", self)
		queue_free()

func enemy_hit(charge = 1):
	hp -= charge
	if hp <= 0:
		emit_signal("remove_from_array", self)
		queue_free()
