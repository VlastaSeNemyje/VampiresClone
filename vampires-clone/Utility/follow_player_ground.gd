extends Node2D
## Keeps a big ground / border strip centred on the player so the world looks endless.
## The ground shader works in world space, so the pattern stays locked while this node moves.
## Textured strips (no shader) snap to whole texture widths so their pattern doesn't slide.

@export var follow_x: bool = true
@export var follow_y: bool = true

var _start: Vector2
var _snap: Vector2 = Vector2.ONE
var _player: Node2D

func _ready() -> void:
	_player = get_tree().get_first_node_in_group("player")
	_start = position
	var sprite = self
	if sprite is Sprite2D and sprite.material == null and sprite.texture:
		_snap = Vector2(sprite.texture.get_width(), sprite.texture.get_height())
	_update()

func _process(_delta: float) -> void:
	_update()

func _update() -> void:
	if not is_instance_valid(_player):
		_player = get_tree().get_first_node_in_group("player")
		if _player == null:
			return
	var p := _player.global_position
	var pos := _start
	if follow_x:
		pos.x += snappedf(p.x, _snap.x)
	if follow_y:
		pos.y += snappedf(p.y, _snap.y)
	position = pos
