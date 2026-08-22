extends Area2D

var level = 1
var hp = 1
var speed = 100
var damage = 5
var knockback_amount = 100
var attack_size = 1.0
var paths = 1
var attack_speed = 1
var spell_size = 1

@onready var player = get_tree().get_first_node_in_group("player")

signal remove_from_array(object)

func update_falcon():
	level = player.falcon_level
	match level:
		1:
			hp = 9999
			speed = 200.0
			damage = 10
			knockback_amount = 100
			paths = 1
			attack_size = 1.0 * (1 + spell_size)
			attack_speed = 5.0 * (1 - player.spell_cooldown)
		2:
			hp = 9999
			speed = 200.0
			damage = 10
			knockback_amount = 100
			paths = 2
			attack_size = 1.0 * (1 + spell_size)
			attack_speed = 5.0 * (1 - player.spell_cooldown)
		3:
			hp = 9999
			speed = 200.0
			damage = 10
			knockback_amount = 100
			paths = 3
			attack_size = 1.0 * (1 + spell_size)
			attack_speed = 5.0 * (1 - player.spell_cooldown)
		4:
			hp = 9999
			speed = 200.0
			damage = 15
			knockback_amount = 120
			paths = 3
			attack_size = 1.0 * (1 + spell_size)
			attack_speed = 5.0 * (1 - player.spell_cooldown)
