extends CharacterBody2D

var movement_speed = 40.0
var hp = 80
var last_movement = Vector2.UP

#Attacks
var Arrow = preload("res://Scenes/Attacks/arrow_attack.tscn")
var Tornado = preload("res://Scenes/Attacks/tornado.tscn")
var Whip = preload("res://Scenes/Attacks/whip_attack.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#AttacksNodes
@onready var ArrowTimer = get_node("%ArrowTimer")
@onready var ArrowAttackTimer = get_node("%ArrowAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var whipTimer = get_node("%WhipTimer")
@onready var whipAttackTimer = get_node("%WhipAttackTimer")

#Arrow
var arrow_ammo = 1
var arrow_baseammo = 1
var arrow_attackspeed = 1.5
var arrow_level = 1

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 3
var tornado_attackspeed = 3
var tornado_level = 0

#Whip
var whip_ammo = 0
var whip_baseammo = 1
var whip_attackspeed = 3
var whip_level = 0

#Enemy Related
var enemy_close = []

func _ready():
	attack()

func _physics_process(delta):
	movement()

func movement():
	var x_mov = Input.get_action_strength("right") - Input.get_action_strength("left")
	var y_mov = Input.get_action_strength("down") - Input.get_action_strength("up")
	var mov = Vector2(x_mov,y_mov)
	
	if x_mov > 0:
		animated_sprite_2d.flip_h = false
	elif x_mov < 0:
		animated_sprite_2d.flip_h = true
	
	velocity = mov.normalized()*movement_speed
	move_and_slide()
	
	if mov == Vector2.ZERO:
		animated_sprite_2d.play("idle")
	else:
		last_movement = mov
		animated_sprite_2d.play("run")

func attack():
	if arrow_level > 0:
		ArrowTimer.wait_time = arrow_attackspeed
		if ArrowTimer.is_stopped():
			ArrowTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if whip_level > 0:
		whipTimer.wait_time = whip_attackspeed
		if whipTimer.is_stopped():
			whipTimer.start()

func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= damage
	print(hp)


func _on_arrow_timer_timeout():
	arrow_ammo += arrow_baseammo
	ArrowAttackTimer.start()

#AttackTimers

func _on_arrow_attack_timer_timeout():
	if arrow_ammo > 0:
		var arrow_attack = Arrow.instantiate()
		arrow_attack.position = position
		arrow_attack.target = get_random_target()
		arrow_attack.level = arrow_level
		add_child(arrow_attack)
		arrow_ammo -= 1
		if arrow_ammo > 0:
			ArrowAttackTimer.start()
		else:
			ArrowAttackTimer.stop()
			
func _on_tornado_timer_timeout():
	tornado_ammo += tornado_baseammo
	tornadoAttackTimer.start()

func _on_tornado_attack_timer_timeout():
	if tornado_ammo > 0:
		var Tornado_attack = Tornado.instantiate()
		Tornado_attack.position = position
		Tornado_attack.last_movement = last_movement
		Tornado_attack.level = tornado_level
		add_child(Tornado_attack)
		tornado_ammo -= 1
		if tornado_ammo > 0:
			tornadoAttackTimer.start()
		else:
			tornadoAttackTimer.stop()

func _on_whip_timer_timeout():
	whip_ammo += whip_baseammo
	whipAttackTimer.start()


func _on_whip_attack_timer_timeout() -> void:
	if whip_ammo > 0:
		var whip_attack = Whip.instantiate()
		whip_attack.position = position
		whip_attack.level = whip_level
		add_child(whip_attack)
		whipTimer.start() 

func get_random_target():
	if enemy_close.size() > 0:
		return enemy_close.pick_random().global_position
	else:
		return Vector2.UP

#BodyEnters detection

func _on_enemy_detection_area_body_entered(body):
	if not enemy_close.has(body):
		enemy_close.append(body)


func _on_enemy_detection_area_body_exited(body):
	if enemy_close.has(body):
		enemy_close.erase(body)
