extends ColorRect

@export_group("Ascend look")
@export var evolution_color := Color(0.8, 0.1, 0.1, 1)
@export var evolution_frame_color := Color(1, 0.9, 0.1, 1)
@export var evolution_frame_width := 2.0

@onready var lblName = $lbl_name
@onready var lblDescription = $lbl_description
@onready var lblLevel = $lbl_level
@onready var itemIcon = $ColorRect/ItemIcon
@onready var ascendBadge = $AscendBadge
@onready var ascendIcon = $AscendBadge/AscendIcon
@onready var lblAscend = $AscendBadge/lbl_ascend

var selected = false
var item = null
@onready var player = get_tree().get_first_node_in_group("player")

signal selected_upgrade(upgrade)

func _ready():
	connect("selected_upgrade", Callable(player,"upgrade_character"))
	if item == null:
			item = "food"
	lblName.text = UpgradeDb.UPGRADES[item]["displayname"]
	lblDescription.text = UpgradeDb.UPGRADES[item]["details"]
	lblLevel.text = UpgradeDb.UPGRADES[item]["level"]
	itemIcon.texture = load(UpgradeDb.UPGRADES[item]["icon"])
	if UpgradeDb.UPGRADES[item].has("evolves"):
		_style_as_evolution()
	else:
		_setup_ascend_badge()

func _gui_input(event):
	if event.is_action_pressed("click") and not selected:
		selected = true
		accept_event()
		emit_signal("selected_upgrade", item)


# Ascensions (evolutions) get a red card with a yellow frame so they stand out from normal upgrades
func _style_as_evolution() -> void:
	color = evolution_color
	var frame := ReferenceRect.new()
	frame.editor_only = false
	frame.border_color = evolution_frame_color
	frame.border_width = evolution_frame_width
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(frame)


# If this option is one half of an Ascend and the player already owns the other half,
# show an "Ascend with <icon of the other half>" badge.
func _setup_ascend_badge() -> void:
	var base := _base_id(item)
	for evo in UpgradeDb.UPGRADES:
		var data = UpgradeDb.UPGRADES[evo]
		if not data.has("evolves") or evo in player.collected_upgrades:
			continue
		var partners := []
		var is_part := false
		for pre in data["prerequisite"]:
			if _base_id(pre) == base:
				is_part = true
			else:
				partners.append(pre)
		if not is_part:
			continue
		for partner in partners:
			for owned in player.collected_upgrades:
				if _base_id(owned) == _base_id(partner):
					ascendIcon.texture = load(UpgradeDb.UPGRADES[partner]["icon"])
					ascendBadge.visible = true
					# keep the description clear of the badge
					lblDescription.size.x = ascendBadge.position.x - lblDescription.position.x - 2.0
					return


# "armor3" -> "armor"
func _base_id(id: String) -> String:
	return id.rstrip("0123456789")
