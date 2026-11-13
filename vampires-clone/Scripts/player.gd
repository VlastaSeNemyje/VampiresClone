extends CharacterBody2D

# One script for every character. Each player scene (player.tscn / player_2.tscn /
# player_3.tscn) sets its own stats, world slot and starting weapon in the Inspector.
@export_group("Starting Weapon")
## The first level of the weapon granted when this player spawns. Choose none for no weapon.
@export_enum("none", "leaf1", "roots1", "arrow1", "whip1", "tornado1", "falcon1", "kanec1", "mycelium1", "plague1", "incense1") var starting_upgrade: String = "leaf1"

@export_group("Player Stats")
@export var world_index: int = 0
@export var movement_speed: float = 40.0
@export var hp: float = 80
@export var maxhp: float = 80
## Seconds you must survive in this player's world. Reaching this time ends the run as a win; dying earlier is a loss.
## Set per world in each player scene (player.tscn = world 1, player_2.tscn = world 2, player_3.tscn = world 3).
@export var win_time: int = 360
## Multiplier on all experience picked up from gems (1.0 = full value, 0.75 = 25% less).
@export_range(0.0, 3.0, 0.05) var experience_gain: float = 0.75

@export_group("Level-Up Draft")
## Most different attacks the player can hold (the starting attack counts). New attacks stop being offered at this number.
@export var max_attacks: int = 3
## Chance (0-1) that the second card offers the upgrade needed to Ascend an attack the player owns.
@export_range(0.0, 1.0, 0.05) var ascend_path_chance: float = 0.35
@export_group("")

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
var LeafProtection = preload("res://Scenes/Attacks/leaf_protection.tscn")
var Roots = preload("res://Scenes/Attacks/roots_attack.tscn")
var MyceliumCircle = preload("res://Scenes/Attacks/mycelium_circle.tscn")

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D

#AttacksNodes
@onready var ArrowTimer = get_node("%ArrowTimer")
@onready var ArrowAttackTimer = get_node("%ArrowAttackTimer")
@onready var tornadoTimer = get_node("%TornadoTimer")
@onready var tornadoAttackTimer = get_node("%TornadoAttackTimer")
@onready var whipTimer = get_node("%WhipTimer")
@onready var whipAttackTimer = get_node("%WhipAttackTimer")
@onready var falconBase = get_node("%FalconBase")
@onready var kanecBase = get_node("%KanecBase")
@onready var plagueBase = get_node("%PlagueBase")
@onready var incenseBase = get_node("%IncenseBase")

#Arrow
var arrow_ammo = 0
var arrow_baseammo = 0
var arrow_attackspeed = 1.5
var arrow_level = 0

#UPGRADES
var collected_upgrades = []
## Weapons that have evolved, e.g. {"roots": true}. Filled from UpgradeDb entries with an "evolves" key.
var evolved = {}
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
var whip_baseammo = 0
var whip_attackspeed = 1.5
var whip_level = 0

#Falcon
var falcon_ammo = 0
var falcon_level = 0

#Kanec
var kanec_level = 0

#Plague
var plague_level = 0

#Charming Incense
var incense_level = 0

#Leaf Protection
var leaf_level = 0
var leaf_protection = null

#Roots
var roots_level = 0
var roots_attack = null

#Mycelium Circle
var mycelium_level = 0
var mycelium_circle = null

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

@onready var deathPanel = get_node("%DeathPanel")
@onready var lblResult = get_node("%lbl_Result")
@onready var sndVictory = get_node("%snd_victory")
@onready var sndLose = get_node("%snd_lose")

#Pause (button and panel are built in _build_pause_gui, so every player scene gets them)
const PAUSE_ICON = preload("res://Textures/Sprites/Menu/Pause.png")
const BASIC_BUTTON = preload("res://Utility/basic_button.tscn")
# Panel buttons use the main menu look: outline normally, filled on hover and while clicked
const BUTTON_TEXTURE = preload("res://Textures/Sprites/Menu/Button.png")
const BUTTON_FILLED_TEXTURE = preload("res://Textures/Sprites/Menu/Button Selection.png")
const BUTTON_SIDE_TEXTURE = preload("res://Textures/Sprites/Menu/Button Side.png")
const BUTTON_SIDE_TINT := Color(0.5, 0.1, 0.12, 1)   # same as SIDE_DIM in basic_button.gd
const BUTTON_NORMAL_TINT := Color(0.8, 0.2, 0.2, 1)
const BUTTON_HOVER_TINT := Color(0.6, 0.2, 0.25, 1)
const PANEL_BUTTON_SIZE := Vector2(128, 28)
## Top-left corner of the pause button on the 640x360 screen (top right, under the Level label).
@export var pause_button_position := Vector2(604, 26)
@export_range(0.0, 1.0) var pause_button_opacity: float = 0.5
var btnPause: TextureButton
var pausePanel: Panel

#Signal
signal playerdeath

func _ready():
	change_time(0)   # show the full countdown before the first second ticks
	_build_pause_gui()
	collision_mask |= 32   # the Obstacle layer (trees and bogs)
	# Whip swings come in bursts: one-shot, short gap between swings of the same burst
	whipAttackTimer.one_shot = true
	whipAttackTimer.wait_time = 0.25
	if starting_upgrade != "" and UpgradeDb.UPGRADES.has(starting_upgrade):
		upgrade_character(starting_upgrade)
	elif starting_upgrade != "" and starting_upgrade != "none":
		push_warning("Player: unknown starting_upgrade '%s'" % starting_upgrade)
	# Debug-only weapon menu (never included in exported release builds).
	# Added after the starting weapon so its level labels are correct.
	if OS.is_debug_build():
		add_child(preload("res://Utility/debug_weapon.gd").new())
	attack()
	set_expbar(experience, calculate_experiencecap())
	_on_hurt_box_hurt(0,0,0)

func _physics_process(_delta):
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
	if kanec_level > 0:
		kanecBase.update_kanec(kanec_level)
	if incense_level > 0:
		incenseBase.update_incense(incense_level)
	if plague_level > 0:
		plagueBase.update_plague(plague_level)
	if falcon_level > 0:
		spawn_falcon()
	if leaf_level > 0:
		spawn_leaf_protection()
	if roots_level > 0:
		spawn_roots()
	if mycelium_level > 0:
		spawn_mycelium_circle()


func _on_hurt_box_hurt(damage, _angle, _knockback):
	hp -= clamp(damage-armor, 1.0, 999.0)
	print(hp)
	healthBar.max_value = maxhp
	healthBar.value = hp
	if hp <= 0:
		death()


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
		whip_ammo -= 1
		if whip_ammo > 0:
			whipAttackTimer.start()
		else:
			whipAttackTimer.stop()
		
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
			
func spawn_leaf_protection():
	if not is_instance_valid(leaf_protection):
		leaf_protection = LeafProtection.instantiate()
		add_child(leaf_protection)
	leaf_protection.update_leaf_protection()
	
func spawn_roots():
	if not is_instance_valid(roots_attack):
		roots_attack = Roots.instantiate()
		add_child(roots_attack)
	roots_attack.update_roots()

func spawn_mycelium_circle():
	if not is_instance_valid(mycelium_circle):
		mycelium_circle = MyceliumCircle.instantiate()
		add_child(mycelium_circle)
	mycelium_circle.update_mycelium()

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

# Restores health (Food card, food dropped by Food Stumps) and refreshes the health bar.
func heal(amount: float):
	hp = clamp(hp + amount, 0, maxhp)
	healthBar.max_value = maxhp
	healthBar.value = hp

func _on_collect_area_area_entered(area):
	if area.is_in_group("loot"):
		var gem_exp = area.collect()
		calculate_experience(gem_exp * experience_gain)

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
	# Early levels stay cheap; from level 8 the cost climbs faster to slow the mid game.
	if experience_level < 8:
		exp_cap = experience_level*5
	elif experience_level < 20:
		exp_cap = 35 + (experience_level-7)*12
	elif experience_level < 40:
		exp_cap = 179 + (experience_level-19)*14
	elif experience_level < 50:
		exp_cap = 459 + (experience_level-39)*18
	else:
		exp_cap = 639 + (experience_level-49)*22
	return exp_cap
	
func set_expbar (set_value = 1, set_max_value = 100):
	expBar.max_value = set_max_value
	# Keep the bar full while the upgrade screen is open
	expBar.value = set_max_value if expBar.flashing else set_value
	
func levelup():
	sndLevelUp.play()
	lblLevel.text = str("Level",experience_level)
	var tween = levelPanel.create_tween()
	tween.tween_property(levelPanel,"position", Vector2(220,50),0.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_IN)
	tween.play()
	levelPanel.visible = true
	for item in get_level_up_options(3):
		var option_choice = itemOptions.instantiate()
		option_choice.item = item
		upgradeOptions.add_child(option_choice)
	expBar.start_flash()
	get_tree().paused = true
	
func upgrade_character(upgrade):
	var evolves_weapon = UpgradeDb.UPGRADES[upgrade].get("evolves", "")
	if evolves_weapon != "":
		evolved[evolves_weapon] = true
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
		"kanec1","kanec2","kanec3","kanec4":
			kanec_level = int(upgrade.right(1))
		"incense1","incense2","incense3","incense4":
			incense_level = int(upgrade.right(1))
		"plague1","plague2","plague3","plague4":
			plague_level = int(upgrade.right(1))
		"leaf1":
			leaf_level = 1
		"leaf2":
			leaf_level = 2
		"leaf3":
			leaf_level = 3
		"leaf4":
			leaf_level = 4
		"roots1","roots2","roots3","roots4":
			roots_level = int(upgrade.right(1))
		"mycelium1","mycelium2","mycelium3","mycelium4":
			mycelium_level = int(upgrade.right(1))
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
			heal(20)
	adjust_gui_collection(upgrade)
	attack()
	var option_children = upgradeOptions.get_children()
	for i in option_children:
		i.queue_free()
	upgrade_options.clear()
	collected_upgrades.append(upgrade)
	levelPanel.visible = false
	levelPanel.position = Vector2(800, 50)
	expBar.stop_flash()
	get_tree().paused = false
	calculate_experience(0)
	
# Builds the level-up cards together so each one has a job and they never repeat:
#   1. Attack      - the next rank of an attack the player already owns (higher ranks are favoured)
#   2. Ascend path - the upgrade an owned attack needs for its Ascend (ascend_path_chance),
#                    otherwise another owned rank-up or any passive upgrade
#   3. Wildcard    - anything, and the only card that can offer a new attack (until max_attacks)
# An Ascend that is ready always takes the first card. A null entry is shown as Food.
func get_level_up_options(count: int = 3) -> Array:
	var eligible = []
	for id in UpgradeDb.UPGRADES:
		var data = UpgradeDb.UPGRADES[id]
		if id in collected_upgrades or data["type"] == "item":
			continue
		if data["prerequisite"].all(func(pre): return pre in collected_upgrades):
			eligible.append(id)

	var owned_attacks = _owned_attack_bases()
	var can_add_attack = owned_attacks.size() < max_attacks
	# attack -> the passive its Ascend needs, for every Ascend not taken yet
	var ascend_passive = {}
	for id in UpgradeDb.UPGRADES:
		var data = UpgradeDb.UPGRADES[id]
		if data.has("evolves") and not id in collected_upgrades:
			for pre in data["prerequisite"]:
				if _base_id(pre) != data["evolves"]:
					ascend_passive[data["evolves"]] = _base_id(pre)
	var path_passives = []
	for attack in owned_attacks:
		if ascend_passive.has(attack):
			path_passives.append(ascend_passive[attack])
	var owns_ascendable = path_passives.size() > 0

	var ready_ascends = []   # Ascends with both halves maxed
	var attack_ranks = []    # next rank of an owned attack
	var path = []            # next rank of a passive an owned attack needs to Ascend
	var steady = []          # owned rank-ups and every passive (never a new attack)
	var wild = []            # steady + new attacks while under the cap
	var attack_weights = {}
	var wild_weights = {}
	for id in eligible:
		var data = UpgradeDb.UPGRADES[id]
		if data.has("evolves"):
			ready_ascends.append(id)
		elif _is_new_attack(id):
			if can_add_attack:
				wild.append(id)
				# no Ascend possible yet: steer the player towards an attack that has one
				if not owns_ascendable and ascend_passive.has(_base_id(id)):
					wild_weights[id] = 3.0
		else:
			steady.append(id)
			wild.append(id)
			if data["type"] == "weapon":
				attack_ranks.append(id)
				attack_weights[id] = float(int(id.right(1)))
			elif _base_id(id) in path_passives:
				path.append(id)

	var chosen = []
	ready_ascends.shuffle()
	for id in ready_ascends:
		if chosen.size() < count:
			chosen.append(id)

	var jobs = [
		[attack_ranks, attack_weights],
		[path if randf() < ascend_path_chance else steady, {}],
		[wild, wild_weights],
	]
	var new_attack_offered = false
	for job in jobs.slice(chosen.size()):
		if chosen.size() >= count:
			break
		var pick = null
		# fall back to wider pools when the card's own pool is empty
		for pool in [job[0], steady, wild]:
			var source = pool
			if new_attack_offered: # never more than one new attack per screen
				source = pool.filter(func(id): return not _is_new_attack(id))
			pick = _pick_weighted(source, chosen, job[1])
			if pick != null:
				break
		if pick != null and _is_new_attack(pick):
			new_attack_offered = true
		chosen.append(pick)

	upgrade_options = chosen.filter(func(id): return id != null)
	return chosen


# "armor3" -> "armor"
func _base_id(id: String) -> String:
	return id.rstrip("0123456789")


# Rank 1 of an attack, i.e. an attack the player does not have yet
func _is_new_attack(id: String) -> bool:
	var data = UpgradeDb.UPGRADES[id]
	return data["type"] == "weapon" and not data.has("evolves") and data["prerequisite"].is_empty()


# Every attack the player holds, e.g. ["leaf", "kanec"]
func _owned_attack_bases() -> Array:
	var bases = []
	for id in collected_upgrades:
		var data = UpgradeDb.UPGRADES[id]
		if data["type"] == "weapon" and not data.has("evolves") and not _base_id(id) in bases:
			bases.append(_base_id(id))
	return bases


# Random entry of pool that is not already on a card. weights: id -> weight (default 1).
func _pick_weighted(pool: Array, taken: Array, weights: Dictionary):
	var candidates = pool.filter(func(id): return not id in taken)
	if candidates.is_empty():
		return null
	var total = 0.0
	for id in candidates:
		total += weights.get(id, 1.0)
	var roll = randf() * total
	for id in candidates:
		roll -= weights.get(id, 1.0)
		if roll <= 0.0:
			return id
	return candidates.back()


func change_time(argtime = 0):
	time = argtime
	# The timer counts down from win_time to zero
	var time_left = maxi(win_time - time, 0)
	var get_m = int(time_left/60.0)
	var get_s = time_left % 60
	if get_m < 10:
		get_m = str(0, get_m)
	if get_s < 10:
		get_s = str(0, get_s)
	lblTimer.text = str(get_m,".",get_s)
	# Surviving until win_time ends the run as a win
	if time >= win_time and not deathPanel.visible:
		death()

func adjust_gui_collection(upgrade):
	var get_upgraded_displayname = UpgradeDb.UPGRADES[upgrade]["displayname"]
	var get_type = UpgradeDb.UPGRADES[upgrade]["type"]
	if get_type != "item":
		var get_collected_displayname = []
		for i in collected_upgrades:
			get_collected_displayname.append(UpgradeDb.UPGRADES[i]["displayname"])
		if not get_upgraded_displayname in get_collected_displayname:
			# An evolution takes the place of the weapon it evolves
			var evolves_weapon = UpgradeDb.UPGRADES[upgrade].get("evolves", "")
			if evolves_weapon != "":
				for c in collectedWeapons.get_children():
					if c.upgrade != null and UpgradeDb.UPGRADES[c.upgrade]["displayname"] == UpgradeDb.UPGRADES[evolves_weapon + "1"]["displayname"]:
						c.queue_free()
			var new_item = itemContainer.instantiate()
			new_item.upgrade = upgrade
			match get_type:
				"weapon":
					collectedWeapons.add_child(new_item)
				"upgrade":
					collectedUpgrades.add_child(new_item)
		else:
			# Already shown: move its slot to the new rank so it gains a level square
			for c in collectedWeapons.get_children() + collectedUpgrades.get_children():
				if c.upgrade != null and UpgradeDb.UPGRADES[c.upgrade]["displayname"] == get_upgraded_displayname:
					c.set_upgrade(upgrade)

func _build_pause_gui():
	var gui = deathPanel.get_parent()

	# The button is paused together with the game, so it cannot be clicked
	# while the level-up, end-game or pause panel is open.
	btnPause = TextureButton.new()
	btnPause.name = "btn_pause"
	btnPause.texture_normal = PAUSE_ICON
	btnPause.position = pause_button_position
	btnPause.modulate.a = pause_button_opacity
	btnPause.focus_mode = Control.FOCUS_NONE
	btnPause.pressed.connect(_on_btn_pause_pressed)
	gui.add_child(btnPause)

	# Same Panel, size and place as the end-game panel
	pausePanel = Panel.new()
	pausePanel.name = "PausePanel"
	pausePanel.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	pausePanel.visible = false
	pausePanel.position = Vector2(220, 50)
	pausePanel.size = deathPanel.size
	gui.add_child(pausePanel)

	var lbl = Label.new()
	lbl.text = "Pause"
	lbl.size = Vector2(pausePanel.size.x, 50)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	pausePanel.add_child(lbl)

	var btn_continue = BASIC_BUTTON.instantiate()
	btn_continue.name = "btn_continue"
	btn_continue.text = "Continue"
	btn_continue.position = Vector2(48, 160)
	btn_continue.click_end.connect(_on_btn_continue_click_end)
	pausePanel.add_child(btn_continue)

	for btn in [btn_continue, deathPanel.get_node("btn_retry"), deathPanel.get_node("btn_menu")]:
		_style_panel_button(btn)
	# Keyboard: arrows / W S move between the buttons of a panel, Enter / Space confirm
	btn_continue.link_focus([btn_continue])
	btn_continue.link_focus([deathPanel.get_node("btn_retry"), deathPanel.get_node("btn_menu")])

func _button_style(texture: Texture2D, tint: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.modulate_color = tint
	# The button art sits in the upper part of its texture, so lift the text 2 px to centre it
	style.content_margin_top = 0.0
	style.content_margin_bottom = 4.0
	return style

# Gives a panel button its normal / hover / click look and centres it in its panel.
func _style_panel_button(btn: Button):
	btn.flat = false
	btn.text = btn.text.strip_edges()   # "Menu" has a stray line break in the scenes
	btn.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	btn.add_theme_stylebox_override("normal", _button_style(BUTTON_TEXTURE, BUTTON_NORMAL_TINT))
	btn.add_theme_stylebox_override("hover", _button_style(BUTTON_FILLED_TEXTURE, BUTTON_HOVER_TINT))
	btn.add_theme_stylebox_override("pressed", _button_style(BUTTON_FILLED_TEXTURE, BUTTON_HOVER_TINT))
	# the keyboard cursor looks the same as mouse hover
	btn.add_theme_stylebox_override("focus", _button_style(BUTTON_FILLED_TEXTURE, BUTTON_HOVER_TINT))
	btn.add_theme_color_override("font_color", Color(0.96, 0.9, 0.75, 1))
	for color_name in ["font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color"]:
		btn.add_theme_color_override(color_name, Color.WHITE)
	btn.size = PANEL_BUTTON_SIZE
	btn.position.x = (btn.get_parent().size.x - PANEL_BUTTON_SIZE.x) * 0.5
	# Side ornaments, placed as in the main menu; basic_button.gd brightens them on hover
	for side in [["SideL", -26.0], ["SideR", PANEL_BUTTON_SIZE.x + 4.0]]:
		var ornament := TextureRect.new()
		ornament.name = side[0]
		ornament.texture = BUTTON_SIDE_TEXTURE
		ornament.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		ornament.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		ornament.mouse_filter = Control.MOUSE_FILTER_IGNORE
		ornament.modulate = BUTTON_SIDE_TINT
		ornament.position = Vector2(side[1], 3)
		ornament.size = Vector2(22, 22)
		btn.add_child(ornament)

func _on_btn_pause_pressed():
	if get_tree().paused:
		return
	pausePanel.visible = true
	get_tree().paused = true
	pausePanel.get_node("btn_continue").grab_focus()

# Esc pauses the game (the player is paused with the game, so this never runs while a panel is open)
func _unhandled_input(event):
	if event.is_action_pressed("ui_cancel"):
		_on_btn_pause_pressed()
		get_viewport().set_input_as_handled()

func _on_btn_continue_click_end():
	pausePanel.visible = false
	get_tree().paused = false

func death():
	btnPause.visible = false
	deathPanel.visible = true
	deathPanel.get_node("btn_retry").grab_focus()
	emit_signal("playerdeath")
	get_tree().paused = true
	var tween = deathPanel.create_tween()
	tween.tween_property(deathPanel,"position",Vector2(220,50),3.0).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	if time >= win_time:
		lblResult.text = "You Win"
		sndVictory.play()
		GameProgress.unlock_next(world_index)
	else:
		lblResult.text = "You Lose"
		sndLose.play()


func _on_btn_menu_click_end():
	get_tree().paused = false
	var _level = get_tree().change_scene_to_file("res://Utility/menu.tscn")


# Retry: start the current world's run again from the beginning
func _on_btn_retry_click_end():
	get_tree().paused = false
	get_tree().reload_current_scene()
