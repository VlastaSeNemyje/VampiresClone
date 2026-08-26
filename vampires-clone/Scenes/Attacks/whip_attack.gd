extends Area2D

var level = 1
var hp = 999          # high pierce count — whip hits many enemies per swing, unlike the arrow's hp = 1
var damage = 5
var knockback_amount = 100
var attack_size = 1.0
var angle = Vector2.ZERO   # read by hurt_box.gd for knockback direction
var facing = 1             # 1 = right, -1 = left

@onready var player = get_tree().get_first_node_in_group("player")
signal remove_from_array(object)

func _ready():
	if player.animated_sprite_2d.flip_h:
		facing = -1
	else:
		facing = 1
	var life_timer = Timer.new()
	life_timer.wait_time = 0.05
	life_timer.one_shot = true
	add_child(life_timer)
	life_timer.timeout.connect(queue_free)
	life_timer.start()

	angle = Vector2(facing, 0)  # side knockback, matching whichever way player faces

	match level:
		1:
			hp = 999
			damage = 5
			knockback_amount = 100
			attack_size = 1.0 * ( 1+player.spell_size)
		2:
			hp = 999
			damage = 7.5
			knockback_amount = 100
			attack_size = 1.0 * ( 1+player.spell_size)
		3:
			hp = 999
			damage = 9
			knockback_amount = 100
			attack_size = 1.5 * ( 1+player.spell_size)
		4:
			hp = 999
			damage = 9
			knockback_amount = 125
			attack_size = 2 * ( 1+player.spell_size)

	# Whips behavior
	scale = Vector2(facing, 1) * 0.2
	var tween = create_tween()
	tween.tween_property(self, "scale", Vector2(facing, 1) * attack_size, 0.12)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.play()

func enemy_hit(charge = 1):
	hp -= charge
	if hp <= 0:
		emit_signal("remove_from_array", self)
		queue_free()

func _on_timer_timeout():
	emit_signal("remove_from_array", self)
	queue_free()
