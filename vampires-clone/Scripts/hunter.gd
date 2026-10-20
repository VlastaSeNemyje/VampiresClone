extends "res://Scripts/enemy.gd"

@export_group("Surrounding")
## Distance from the player Hunters circle at. Keep it below net_player_distance so nets can form.
@export var orbit_radius: float = 60.0
## 1 = clockwise, -1 = counter-clockwise. All Hunters circle the same way, so they run into each other.
@export_enum("Clockwise:1", "Counter-clockwise:-1") var orbit_direction: int = 1
## Hunters further than orbit_radius + this value walk straight at the player; closer in they start circling.
@export var orbit_blend_range: float = 80.0
## Hunters within this distance of each other are pulled together, so they form groups.
## Width of the zone around the orbit radius where the Hunter eases between moving in and out.
@export var radius_smoothing: float = 20.0
@export var gather_range: float = 120.0
@export_range(0.0, 2.0) var gather_strength: float = 0.5

@export_group("Nets")
@export var net_scene: PackedScene
## Two Hunters this close to each other connect with a net...
@export var net_link_distance: float = 10.0
## ...but only when both are closer than this to the player.
@export var net_player_distance: float = 75.0
## A Hunter can hold this many nets (2 lets them form a chain around the player).
@export var max_nets_per_hunter: int = 2
## Hunters holding a net walk apart along the circle until the net is this long, then stand still.
@export var net_max_length: float = 25.0
## The net tears when its Hunters get further apart than this (e.g. one was moved away).
@export var net_break_distance: float = 160.0

var nets: Array = []

func _ready():
	super()
	add_to_group("hunter")

func _get_move_direction() -> Vector2:
	var to_player = global_position.direction_to(player.global_position)
	var dist = global_position.distance_to(player.global_position)
	var tangent = to_player.orthogonal() * -orbit_direction
	var radial = to_player * clampf((dist - orbit_radius) / maxf(radius_smoothing, 0.01), -1.0, 1.0)

	_clean_nets()
	if not nets.is_empty():
		return _holding_net_direction(radial, tangent)

	var circle_weight = clampf(1.0 - (dist - orbit_radius) / orbit_blend_range, 0.0, 1.0)
	var dir = radial + tangent * circle_weight + _gather_direction() * gather_strength
	return dir.normalized()

# A Hunter with a net spreads away from its partners along the circle, stretching the net.
func _holding_net_direction(radial: Vector2, tangent: Vector2) -> Vector2:
	var center = Vector2.ZERO
	for net in nets:
		if net.length() >= net_max_length:
			return Vector2.ZERO
		center += net.other_end(self).global_position
	center /= nets.size()
	var spread = tangent * signf(tangent.dot(global_position - center))
	if spread == Vector2.ZERO:
		return radial
	return (radial + spread).normalized()

func _gather_direction() -> Vector2:
	var closest: Node2D = null
	var closest_dist = gather_range
	for other in get_tree().get_nodes_in_group("hunter"):
		if other == self or other.is_dead:
			continue
		var d = global_position.distance_to(other.global_position)
		if d < closest_dist:
			closest_dist = d
			closest = other
	if closest == null:
		return Vector2.ZERO
	return global_position.direction_to(closest.global_position)

func _physics_process(delta):
	super(delta)
	if is_dead:
		return
	_try_link_nets()

func _clean_nets():
	nets = nets.filter(func(n): return is_instance_valid(n) and not n.is_queued_for_deletion())

func _is_linked_with(other) -> bool:
	for net in nets:
		if net.other_end(self) == other:
			return true
	return false

func _try_link_nets():
	if net_scene == null or nets.size() >= max_nets_per_hunter:
		return
	if global_position.distance_to(player.global_position) > net_player_distance:
		return
	for other in get_tree().get_nodes_in_group("hunter"):
		# the Hunter with the lower id does the linking, so a pair never gets two nets
		if other == self or other.is_dead or other.get_instance_id() < get_instance_id():
			continue
		if other.nets.size() >= other.max_nets_per_hunter or _is_linked_with(other):
			continue
		if global_position.distance_to(other.global_position) > net_link_distance:
			continue
		if other.global_position.distance_to(player.global_position) > net_player_distance:
			continue
		var net = net_scene.instantiate()
		net.break_distance = net_break_distance
		net.hunter_a = self
		net.hunter_b = other
		get_tree().current_scene.add_child(net)
		nets.append(net)
		other.nets.append(net)
		if nets.size() >= max_nets_per_hunter:
			return
