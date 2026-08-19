extends Area2D

@export var experience = 1

var spr_green = preload("res://Textures/Sprites/GemGreen.png")
var spr_blue = preload("res://Textures/Sprites/GemBlue.png")
var spr_red = preload("res://Textures/Sprites/GemRed.png")

var target = null
var speed = - 0.75

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var snd_collected: AudioStreamPlayer = $Snd_collected

func _ready():
	if experience < 5:
		return
	elif experience < 25:
		sprite_2d.texture = spr_blue
	else:
		sprite_2d.texture = spr_red

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2*delta

func collect():
	snd_collected.play()
	collision_shape_2d.call_deferred("set", "disabled", true)
	sprite_2d.visible = false
	return experience

func _on_snd_collected_finished():
	queue_free()
