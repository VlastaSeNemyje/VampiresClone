extends CanvasLayer
## Debug-only weapon/upgrade menu. Added as a child of the Player (see player.gd).
## Click "DBG" (or press F1) to open. +1 = next level, MAX = all levels in order.

var player
var panel: PanelContainer
var list: VBoxContainer
var groups := {}          # base_id -> {name, type, max}
var level_labels := {}    # base_id -> Label

const FONT_SIZE := 10


func _ready() -> void:
	layer = 100
	player = get_parent()
	_build_groups()
	_build_ui()
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F1:
		panel.visible = not panel.visible


# Turns "arrow1".."arrow4" into one group "arrow" with max level 4.
func _build_groups() -> void:
	for key in UpgradeDb.UPGRADES:
		var data = UpgradeDb.UPGRADES[key]
		if data["type"] == "item" or data.has("evolves"):
			continue
		var base: String = key.rstrip("0123456789")
		var lvl := int(key.substr(base.length()))
		if not groups.has(base):
			groups[base] = {"name": data["displayname"], "type": data["type"], "max": 0}
		groups[base]["max"] = maxi(groups[base]["max"], lvl)


func _build_ui() -> void:
	var toggle := Button.new()
	toggle.text = "DBG"
	toggle.focus_mode = Control.FOCUS_NONE
	toggle.add_theme_font_size_override("font_size", FONT_SIZE)
	toggle.position = Vector2(594, 338)
	toggle.pressed.connect(func(): panel.visible = not panel.visible)
	add_child(toggle)

	panel = PanelContainer.new()
	panel.visible = false
	panel.position = Vector2(400, 90)
	add_child(panel)

	var margin := MarginContainer.new()
	for side in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + side, 4)
	panel.add_child(margin)

	var scroll := ScrollContainer.new()
	scroll.custom_minimum_size = Vector2(228, 240)
	margin.add_child(scroll)

	list = VBoxContainer.new()
	list.add_theme_constant_override("separation", 2)
	scroll.add_child(list)

	var max_all := _make_button("MAX EVERYTHING")
	max_all.pressed.connect(_max_everything)
	list.add_child(max_all)

	# weapons first, then passive upgrades
	for type in ["weapon", "upgrade"]:
		var header := Label.new()
		header.text = "-- %s --" % type.to_upper()
		header.add_theme_font_size_override("font_size", FONT_SIZE)
		list.add_child(header)
		for base in groups:
			if groups[base]["type"] == type:
				_add_row(base)

	# evolutions: only work once both prerequisites are maxed (same rule as the level-up screen)
	var evo_header := Label.new()
	evo_header.text = "-- EVOLUTIONS --"
	evo_header.add_theme_font_size_override("font_size", FONT_SIZE)
	list.add_child(evo_header)
	for key in UpgradeDb.UPGRADES:
		if UpgradeDb.UPGRADES[key].has("evolves"):
			var evo_btn := _make_button("EVOLVE " + UpgradeDb.UPGRADES[key]["displayname"])
			evo_btn.pressed.connect(func(): _evolve(key))
			list.add_child(evo_btn)


func _add_row(base: String) -> void:
	var row := HBoxContainer.new()
	list.add_child(row)

	var name_lbl := Label.new()
	name_lbl.text = groups[base]["name"]
	name_lbl.custom_minimum_size = Vector2(80, 0)
	name_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(name_lbl)

	var lvl_lbl := Label.new()
	lvl_lbl.custom_minimum_size = Vector2(36, 0)
	lvl_lbl.add_theme_font_size_override("font_size", FONT_SIZE)
	row.add_child(lvl_lbl)
	level_labels[base] = lvl_lbl

	var plus := _make_button("+1")
	plus.pressed.connect(func(): _upgrade(base, false))
	row.add_child(plus)

	var max_btn := _make_button("MAX")
	max_btn.pressed.connect(func(): _upgrade(base, true))
	row.add_child(max_btn)


func _make_button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE   # so Space/Enter never "click" it mid-game
	b.add_theme_font_size_override("font_size", FONT_SIZE)
	return b


func _upgrade(base: String, to_max: bool) -> void:
	# upgrade_character() unpauses the tree, so never run it during the level-up screen
	if get_tree().paused:
		return
	for lvl in range(1, groups[base]["max"] + 1):
		var key := base + str(lvl)
		if key in player.collected_upgrades:
			continue
		player.upgrade_character(key)   # goes through the real path: stats, GUI icons, attack()
		if not to_max:
			break
	_refresh()


func _max_everything() -> void:
	for base in groups:
		_upgrade(base, true)


func _refresh() -> void:
	for base in groups:
		var current := 0
		for lvl in range(1, groups[base]["max"] + 1):
			if (base + str(lvl)) in player.collected_upgrades:
				current = lvl
		level_labels[base].text = "%d/%d" % [current, groups[base]["max"]]


func _evolve(key: String) -> void:
	if get_tree().paused or key in player.collected_upgrades:
		return
	for pre in UpgradeDb.UPGRADES[key]["prerequisite"]:
		if not pre in player.collected_upgrades:
			return
	player.upgrade_character(key)
