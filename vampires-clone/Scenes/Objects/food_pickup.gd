extends Area2D
## Food dropped by a Food Stump. It is "loot" like an experience gem: the player's grab area pulls it in
## and the collect area picks it up. Picking it up heals instead of giving experience.

@export var heal_amount: float = 20.0

var target = null   # set by the player's grab area
var speed = -0.75

@onready var sprite_2d: Sprite2D = $Sprite2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

func _physics_process(delta):
	if target != null:
		global_position = global_position.move_toward(target.global_position, speed)
		speed += 2 * delta

# Called by the player when the food reaches them. Returns the experience it is worth (none).
func collect():
	var player = target if target != null else get_tree().get_first_node_in_group("player")
	if player != null and player.has_method("heal"):
		player.heal(heal_amount)
	AudioManager.play_xp()
	collision_shape_2d.set_deferred("disabled", true)
	sprite_2d.visible = false
	queue_free()
	return 0
