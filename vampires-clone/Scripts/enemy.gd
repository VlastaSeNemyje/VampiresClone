extends CharacterBody2D

@export var movement_speed = 20
@export var hp = 10
@export var knockback_recovery = 3.5
@export var experience = 1
var knockback = Vector2.ZERO

@onready var player = get_tree().get_first_node_in_group("player")
@onready var loot_base = get_tree().get_first_node_in_group("loot")
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var snd_hit = $snd_hit

var is_dead = false
var exp_gem = preload("res://Scenes/exp_gem.tscn")


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

func death():
	
	if is_dead:
		return

	is_dead = true
	emit_signal("remove_from_array", self)
	velocity = Vector2.ZERO
	animated_sprite_2d.play("hit_dead")
	await animated_sprite_2d.animation_finished
	var new_gem = exp_gem.instantiate()
	new_gem.global_position = global_position
	new_gem.experience = experience
	loot_base.call_deferred("add_child", new_gem)
	queue_free()

func _on_hurt_box_hurt(damage, angle, knockback_amount):
	hp -= damage
	knockback = angle * knockback_amount
	if hp <= 0:
		animated_sprite_2d.play("hit")
		snd_hit.play()
		death()
	else:
		snd_hit.play()
		animated_sprite_2d.play("hit")
	
