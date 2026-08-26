extends CharacterBody2D

var movement_speed = 40.0
var hp = 80
var maxhp = 80
var last_movement = Vector2.UP
var time = 0

#Experience
var experience = 0
var experience_level = 1
var collected_experience = 0

#Attacks
var Arrow = preload("res://Scenes/Attacks/arrow_attack.tscn")
var Tornado = preload("res://Scenes/Attacks/tornado.tscn")
var Whip = preload("res://Scenes/Attacks/whip_attack.tscn")
var Falcon = preload("res://Scenes/Attacks/falcon.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#AttacksNodes
@onready var ArrowTimer = get_node("%ArrowTimer")
@onready var ArrowAttackTimer = get_node("%ArrowAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var whipTimer = get_node("%WhipTimer")
@onready var whipAttackTimer = get_node("%WhipAttackTimer")
@onready var falconBase = get_node("%FalconBase")

#Arrow
var arrow_ammo = 0
var arrow_baseammo = 0
var arrow_attackspeed = 1.5
var arrow_level = 0

#UPGRADES
var collected_upgrades = []
var upgrade_options = []
var armor = 0
var speed = 0
var spell_cooldown = 0
var spell_size = 0
var additional_attacks = 0

#Tornado
var tornado_ammo = 0
var tornado_baseammo = 0
var tornado_attackspeed = 3
var tornado_level = 0

#Whip
var whip_ammo = 0
var whip_baseammo = 1
var whip_attackspeed = 3
var whip_level = 0

#Falcon
var falcon_ammo = 0
var falcon_level = 0

#Enemy Related
var enemy_close = []

#GUI
@onready var expBar = get_node("%ExperienceBar")
@onready var lblLevel = get_node("%Lbl_level")
@onready var levelPanel = get_node("%LevelUp")
@onready var upgradeOptions: Control = $GUILayer/GUI/LevelUp/UppgradeOptions
@onready var sndLevelUp: AudioStreamPlayer = $GUILayer/GUI/LevelUp/snd_levelup
@onready var itemOptions = preload("res://Utility/item_option.tscn")
@onready var healthBar = get_node("%HealthBar")
@onready var lblTimer = get_node ("%lblTimer")
@onready var collectedWeapons = get_node("%CollectedWeapons")
@onready var collectedUpgrades = get_node("%CollectedUpgrades")
@onready var itemContainer = preload("res://Scenes/GUI/item_container.tscn")

func _ready():
	upgrade_character("whip1")
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)

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
		ArrowTimer.wait_time = arrow_attackspeed * (1-spell_cooldown)
		if ArrowTimer.is_stopped():
			ArrowTimer.start()
	if tornado_level > 0:
		tornadoTimer.wait_time = tornado_attackspeed * (1-spell_cooldown)
		if tornadoTimer.is_stopped():
			tornadoTimer.start()
	if whip_level > 0:
		whipTimer.wait_time = whip_attackspeed * (1-spell_cooldown)
		if whipTimer.is_stopped():
			whipTimer.start()
	if falcon_level > 0:
		spawn_falcon()

func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	print(hp)
	healthBar.max_value = maxhp
	healthBar.value = hp


func _on_arrow_timer_timeout():
	arrow_ammo += arrow_baseammo + additional_attacks
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
	tornado_ammo += tornado_baseammo + additional_attacks
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
	whip_ammo += whip_baseammo + additional_attacks
	whipAttackTimer.start()


func _on_whip_attack_timer_timeout() -> void:
	if whip_ammo > 0:
		var whip_attack = Whip.instantiate()
		whip_attack.position = position
		whip_attack.level = whip_level
		add_child(whip_attack)
		whipTimer.start() 
		
func spawn_falcon():
	var get_falcon_total = falconBase.get_child_count()
	var calc_spawns = (falcon_ammo + additional_attacks) - get_falcon_total
	while calc_spawns > 0:
		var falcon_spawn = Falcon.instantiate()
		falcon_spawn.global_position = global_position
		falconBase.add_child(falcon_spawn)
		calc_spawns -= 1
	#Upgrade Falcon
	var get_falcon = falconBase.get_children()
	for i in get_falcon:
		if i.has_method("update_falcon"):
			i.update_falcon()

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


func _on_grab_area_area_entered(area):
	if area.is_in_group("loot"):
		area.target = self

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp)

func calculate_experience(gem_exp):
	var exp_required = calculate_experiencecap()
	collected_experience += gem_exp
	if experience + collected_experience >= exp_required: #level up
		collected_experience -= exp_required-experience
		experience_level +=1
		experience = 0
		exp_required = calculate_experiencecap()
		levelup()
	else:
		experience += collected_experience
		collected_experience = 0
	
	set_expbar(experience, exp_required)

func calculate_experiencecap():
	var exp_cap = experience_level
	if experience_level < 20:
		exp_cap = experience_level*5
	elif experience_level < 40:
		exp_cap + 95 + (experience_level-19)*8
	else:
		exp_cap = 255 + (experience_level-39)*12
	return exp_cap
	
func set_expbar (set_value = 1, set_max_value = 100):
	expBar.value = set_value
	expBar.max_value = set_max_value
	
func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level",experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel,"position", Vector2(220,50),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	var options = 0
	var optionsmax = 3
	while options < optionsmax:
		var option_choice = itemOptions.instantiate()
		option_choice.item = get_random_item()
		upgradeOptions.add_child(option_choice)
		options += 1
	get_tree().paused = true
	
func upgrade_character(upgrade):
	match upgrade:
		"arrow1":
			arrow_level = 1
			arrow_baseammo += 1
		"arrow2":
			arrow_level = 2
			arrow_baseammo += 1
		"arrow3":
			arrow_level = 3
		"arrow4":
			arrow_level = 4
			arrow_baseammo += 2
		"tornado1":
			tornado_level = 1
			tornado_baseammo += 1
		"tornado2":
			tornado_level = 2
			tornado_baseammo += 1
		"tornado3":
			tornado_level = 3
			tornado_attackspeed -= 0.5
		"tornado4":
			tornado_level = 4
			tornado_baseammo += 1
		"whip1":
			whip_level = 1
			whip_baseammo += 1
		"whip2":
			whip_level = 2
			whip_baseammo += 1
		"whip3":
			whip_level = 3
		"whip4":
			whip_level = 4
			whip_baseammo += 2
		"falcon1":
			falcon_level = 1
			falcon_ammo = 1
		"falcon2":
			falcon_level = 2
		"falcon3":
			falcon_level = 3
		"falcon4":
			falcon_level = 4
		"armor1","armor2","armor3","armor4":
			armor += 1
		"speed1","speed2","speed3","speed4":
			movement_speed += 20.0
		"tome1","tome2","tome3","tome4":
			spell_size += 0.10
		"scroll1","scroll2","scroll3","scroll4":
			spell_cooldown += 0.05
		"ring1","ring2":
			additional_attacks += 1
		"food":
			hp += 20
			hp = clamp(hp,0,maxhp)
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(800, 50)
	get_tree().paused = false
	calculate_experience(0)
	
func get_random_item():
	var dblist = []
	for i in UpgradeDb.UPGRADES:
		if i in collected_upgrades: #Find already collected upgrades
			pass
		elif i in upgrade_options: #If the upgrade is already an option
			pass
		elif UpgradeDb.UPGRADES[i]["type"] == "item": #Dont pick food
			pass
		elif UpgradeDb.UPGRADES[i]["prerequisite"].size() > 0: #Check for PreRequsities
			var to_add = true
			for n in UpgradeDb.UPGRADES [i]["prerequisite"]:
				if not n in collected_upgrades:
					to_add = false
				if to_add:
					dblist.append(i)
		else:
			dblist.append(i)
	if dblist.size() > 0:
		var randomitem = dblist.pick_random()
		upgrade_options.append(randomitem)
		return randomitem
	else:
		return null
		
func change_time(argtime = 0):
	time = argtime
	var get_m = int(time/60.0)
	var get_s = time % 60
	if get_m < 10:
		get_m = str(0, get_m)
	if get_s < 10:
		get_s = str(0, get_s)
	lblTimer.text = str(get_m,",",get_s)
	
func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displayname = []
		for i in collected_upgrades:
			get_collected_displayname.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displayname:
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)
			
