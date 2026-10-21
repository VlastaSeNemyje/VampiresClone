extends "res://Scripts/enemy.gd"

## Direction the grain flies in (set by the swarm at spawn). The grain does not steer; survivors fly past the player.
var charge_direction := Vector2.ZERO

@export_group("Charge")
## Once further than this from the player and moving away, the grain disappears.
@export var despawn_distance: float = 900.0

@export_group("Push")
## Speed given to other enemies the grain runs into, in the grain's flight direction.
@export var push_strength: float = 80.0
@export var push_other_enemies: bool = true

@onready var push_area: Area2D = $PushArea

func _ready():
	super()
	add_to_group("grain")

func _get_move_direction() -> Vector2:
	return charge_direction

func _physics_process(delta):
	super(delta)
	if is_dead or player == null:
		return
	if push_other_enemies:
		_push_touching_enemies()
	var away = global_position - player.global_position
	if away.length() > despawn_distance and away.dot(charge_direction) > 0.0:
		emit_signal("remove_from_array", self)
		queue_free()

func _push_touching_enemies():
	for body in push_area.get_overlapping_bodies():
		if body == self or body.is_in_group("grain") or not body.is_in_group("enemy"):
			continue
		# keep the stronger push if the enemy is already being shoved
		if body.knockback.dot(charge_direction) < push_strength:
			body.knockback = charge_direction * push_strength
