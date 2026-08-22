extends Area2D
var level = 1
var hp = 9999
var speed = 100.0
var damage = 5
var attack_size = 1.0
var knockback_amount = 100
var last_movement = Vector2.ZERO
var base_direction = Vector2.ZERO   # the "straight line" direction it curves around
var angle_offset = 0.0              # this is what we tween, in radians
var angle = Vector2.ZERO

signal remove_from_array(object)
@onready var player = get_tree().get_first_node_in_group("player")

func _ready():
	match level:
		1:
			hp = 9999
			speed = 100.0
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 * ( 1+player.spell_size)
		2:
			hp = 9999
			speed = 100.0
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 * ( 1+player.spell_size)
		3:
			hp = 9999
			speed = 125.0
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 * ( 1+player.spell_size)
		4:
			hp = 9999
			speed = 125.0
			damage = 7
			knockback_amount = 125
			attack_size = 1.0 * ( 1+player.spell_size)

	# Direction
	base_direction = Vector2.RIGHT.rotated(randf_range(0, TAU))

	var tween = create_tween()
	var swing = deg_to_rad(90) # how wide the half-circle swing is, tweak to taste
	var dir_sign = 1 if randi_range(0, 1) == 1 else -1
	for i in range(3):
		tween.tween_property(self, "angle_offset", dir_sign * swing, 2)
		tween.tween_property(self, "angle_offset", -dir_sign * swing, 2)
	tween.play()
		
	var initial_tween = create_tween().set_parallel(true)
	initial_tween.tween_property(self, "scale", Vector2(1,1)*attack_size,3).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	var final_speed = speed
	speed = speed/5.0
	initial_tween.tween_property(self,"speed", final_speed, 6).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	initial_tween.play()

	# Oscillate the angle_offset back and forth -> traces arcs, like a tornado weaving
	for i in range(3):
		tween.tween_property(self, "angle_offset", dir_sign * swing, 2)
		tween.tween_property(self, "angle_offset", -dir_sign * swing, 2)

	tween.play()
	
	# Auto-remove after 3 seconds
	get_tree().create_timer(3.0).timeout.connect(_on_timer_timeout)


func _physics_process(delta):
	var current_dir = base_direction.rotated(angle_offset)
	position += current_dir * speed * delta
	angle = base_direction.rotated(angle_offset)

func _on_timer_timeout():
	emit_signal("remove_from_array")
	queue_free()
