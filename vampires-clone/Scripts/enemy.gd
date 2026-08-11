extends CharacterBody2D

@export var movement_speed = 20
@export var hp = 10
@export var knockback_recovery = 3.5
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var snd_hit = $snd_hit


signal remove_from_array(object)

func _physics_process(_delta):
	knockback = knockback.move_toward(Vector2.ZERO, knockback_recovery)
	var direction = global_position.direction_to(player.global_position)
	velocity = direction*movement_speed
	velocity += knockback
	move_and_slide()
	
	if direction.x > 0.1:
		animated_sprite_2d.flip_h = false
	elif direction.x < -0.1:
		animated_sprite_2d.flip_h = true
		


func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	if hp <= 0:
		emit_signal("remove_from_array", self)
		queue_free()
	else:
		snd_hit.play()
