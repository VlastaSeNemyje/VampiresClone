extends StaticBody2D
## A net stretched between two Hunters. The player cannot cross it; it disappears when either Hunter dies.

## Collision thickness of the net (how wide the barrier is for the player).
@export var thickness: float = 6.0
## Net tears when its Hunters are further apart than this (set by the Hunter).
@export var break_distance: float = 160.0
## Tint and opacity of the net sprite.
@export var net_color: Color = Color(1, 1, 1, 1)

## Damage the player takes on touching the net (repeats on the player's hurt cooldown while they keep touching).
@export var damage: int = 3
## How far the damaging zone reaches past the solid net on each side, so the player's hurt box can touch it.
@export var damage_margin: float = 6.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shape: CollisionShape2D = $CollisionShape2D
@onready var hit_box: Area2D = $HitBox
@onready var hit_shape: CollisionShape2D = $HitBox/CollisionShape2D

var hunter_a: Node2D   # set by Hunter before add_child
var hunter_b: Node2D
var _texture_width := 33.0

func _ready():
	_texture_width = sprite.texture.get_width()
	sprite.modulate = net_color
	shape.shape = shape.shape.duplicate()   # own copy, resized every frame
	hit_box.damage = damage
	hit_shape.shape = RectangleShape2D.new()
	_update()

func other_end(hunter: Node2D) -> Node2D:
	return hunter_b if hunter == hunter_a else hunter_a

func length() -> float:
	if not _ends_alive():
		return 0.0
	return hunter_a.global_position.distance_to(hunter_b.global_position)

func _ends_alive() -> bool:
	return is_instance_valid(hunter_a) and is_instance_valid(hunter_b) \
		and not hunter_a.is_dead and not hunter_b.is_dead

func _physics_process(_delta):
	if not _ends_alive() or length() > break_distance:
		_remove()
		return
	_update()

func _update():
	if not _ends_alive():
		return
	var a = hunter_a.global_position
	var b = hunter_b.global_position
	global_position = (a + b) * 0.5
	rotation = (b - a).angle()
	var seg = maxf(a.distance_to(b), 1.0)
	sprite.scale = Vector2(seg / _texture_width, 1.0)
	(shape.shape as RectangleShape2D).size = Vector2(seg, thickness)
	(hit_shape.shape as RectangleShape2D).size = Vector2(seg, thickness + damage_margin * 2.0)

func _remove():
	shape.set_deferred("disabled", true)
	hit_shape.set_deferred("disabled", true)
	queue_free()
