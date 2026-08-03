extends CharacterBody2D

var movement_speed = 40.0
var hp = 80
@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D


func _physics_process(delta):
	movement()

func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	
	if x_mov > 0:
		animated_sprite_2d.flip_h = false
	elif x_mov < 0:
		animated_sprite_2d.flip_h = true
	
	velocity = mov.normalized()*movement_speed
	move_and_slide()
	
	if movement_speed == 0:
		animated_sprite_2d.play("idle")
	else:
		animated_sprite_2d.play("run")


func _on_hurt_box_hurt(damage):
	hp -= damage
	print(hp)
