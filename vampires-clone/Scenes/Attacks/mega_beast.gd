extends Node2D
## Mega Beast - the Forest Spirit evolution. Spawned every `spawn_interval` seconds by kanec_base.gd.
## A beast starts at the player, grows for `grow_time` seconds until it fills most of the screen
## (a circle around the player) and at its biggest it hurts every enemy in that circle once.
##
## Every number you might want to tweak is exported - change it in the Inspector of the
## MegaBeast scene (Scenes/Attacks/mega_beast.tscn).
## To animate the beast: select BeastSprite and edit its SpriteFrames (animation "default",
## or set "Animation Name" below). Whatever frames you draw are scaled to the current circle size.

enum ScreenReference { WIDTH, HEIGHT, DIAGONAL, SMALLER_SIDE }

@export_group("Spawning")
## Seconds between beasts.
@export var spawn_interval := 15.0
## Seconds after evolving until the first beast.
@export var first_spawn_delay := 5.0
## true = the Scroll upgrade shortens the interval like it does for other weapons.
@export var affected_by_scroll := false

@export_group("Growth")
## Seconds the beast needs to grow from start to full size.
@export var grow_time := 4.0
## Diameter in pixels when it appears (about the size of the player).
@export var start_diameter := 32.0
## Final diameter as a fraction of the screen (0.8 = 80%).
@export_range(0.05, 3.0) var end_screen_fraction := 0.8
## Which screen measurement the fraction above refers to. SMALLER_SIDE (the screen height) keeps the whole circle on screen.
@export var screen_reference: ScreenReference = ScreenReference.SMALLER_SIDE
## 1.0 = steady growth, 2.0 = starts slow and rushes at the end (like running towards you).
@export_range(0.2, 6.0) var growth_exponent := 2.0
## true = the circle stays centred on the player while they move.
@export var follow_player := true

@export_group("Damage")
## Damage to every enemy inside the circle when the beast is at full size.
@export var damage := 50.0
@export var knockback := 0.0
## Hit area as a fraction of the final circle (1.0 = exactly the visible circle).
@export_range(0.1, 2.0) var damage_radius_ratio := 1.0

@export_group("Look")
## Animation of BeastSprite that is played (add your own frames to its SpriteFrames).
@export var animation_name := &"default"
## Beast sprite size relative to the circle (1.0 = sprite touches the circle edge).
@export var sprite_size_ratio := 1.0
@export var sprite_tint := Color(1, 1, 1, 0.9)
@export var show_zone := true
@export var zone_color := Color(0.9, 0.2, 0.1, 0.12)
@export var zone_edge_color := Color(1.0, 0.8, 0.2, 0.6)
@export var zone_edge_width := 1.5
## Colour of the circle flash at the moment of impact.
@export var impact_flash_color := Color(1, 1, 1, 0.8)
## Seconds the beast takes to fade out after the hit.
@export var fade_out_time := 0.4
@export var beast_z_index := 5

var _elapsed := 0.0
var _hit_done := false
var _diameter := 32.0
var _end_diameter := 100.0
var _sprite_base := 32.0
var _flash := 0.0   # 0..1, drawn as an extra bright disk after impact

@onready var player = get_tree().get_first_node_in_group("player")
@onready var sprite: AnimatedSprite2D = $BeastSprite
@onready var snd_impact: AudioStreamPlayer2D = get_node_or_null("snd_impact")


func _ready() -> void:
	top_level = true
	z_index = beast_z_index
	_end_diameter = _screen_size() * end_screen_fraction
	_diameter = start_diameter
	_follow()
	if sprite.sprite_frames != null and sprite.sprite_frames.has_animation(animation_name):
		sprite.animation = animation_name
		sprite.play(animation_name)
		_sprite_base = _frame_size()
	sprite.modulate = sprite_tint
	_update_visual()


func _process(delta: float) -> void:
	if follow_player:
		_follow()
	if not _hit_done:
		_elapsed += delta
		var t := clampf(_elapsed / maxf(grow_time, 0.01), 0.0, 1.0)
		_diameter = lerpf(start_diameter, _end_diameter, pow(t, growth_exponent))
		_update_visual()
		if t >= 1.0:
			_impact()
	queue_redraw()


func _follow() -> void:
	if is_instance_valid(player):
		global_position = player.global_position + Vector2(0, -8)


func _screen_size() -> float:
	var size := get_viewport_rect().size
	match screen_reference:
		ScreenReference.HEIGHT:
			return size.y
		ScreenReference.DIAGONAL:
			return size.length()
		ScreenReference.SMALLER_SIDE:
			return minf(size.x, size.y)
	return size.x


# Size of the current animation frame in pixels (used to scale any sprite to the circle)
func _frame_size() -> float:
	var tex := sprite.sprite_frames.get_frame_texture(sprite.animation, 0)
	if tex == null:
		return 32.0
	return maxf(1.0, float(maxf(tex.get_width(), tex.get_height())))


func _update_visual() -> void:
	sprite.scale = Vector2.ONE * (_diameter * sprite_size_ratio / _sprite_base)


func _impact() -> void:
	_hit_done = true
	var radius := _end_diameter * 0.5 * damage_radius_ratio
	for e in get_tree().get_nodes_in_group("enemy"):
		if e.get("is_dead") == true or global_position.distance_to(e.global_position) > radius:
			continue
		e.get_node("HurtBox").hurt.emit(damage, global_position.direction_to(e.global_position), knockback)
	if snd_impact != null and snd_impact.stream != null:
		snd_impact.play()
	_flash = 1.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "_flash", 0.0, fade_out_time)
	tween.tween_property(sprite, "modulate:a", 0.0, fade_out_time)
	tween.chain().tween_callback(queue_free)


func _draw() -> void:
	var r := _diameter * 0.5
	if show_zone:
		var fade := 1.0 if not _hit_done else clampf(_flash, 0.0, 1.0)
		var fill := zone_color
		fill.a *= fade
		var edge := zone_edge_color
		edge.a *= fade
		draw_circle(Vector2.ZERO, r, fill)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 96, edge, zone_edge_width)
	if _flash > 0.0:
		var flash := impact_flash_color
		flash.a *= _flash
		draw_circle(Vector2.ZERO, r, flash)
