extends ColorRect

@export_group("Evolution look")
@export var evolution_color := Color(0.8, 0.1, 0.1, 1)
@export var evolution_frame_color := Color(1, 0.9, 0.1, 1)
@export var evolution_frame_width := 2.0

@onready var lblName = $lbl_name
@onready var lblDescription = $lbl_description
@onready var lblLevel = $lbl_level
@onready var itemIcon = $ColorRect/ItemIcon

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

func _gui_input(event):
	if event.is_action_pressed("click") and not selected:
		selected = true
		accept_event()
		emit_signal("selected_upgrade", item)


# Evolutions get a red card with a yellow frame so they stand out from normal upgrades
func _style_as_evolution() -> void:
	color = evolution_color
	var frame := ReferenceRect.new()
	frame.editor_only = false
	frame.border_color = evolution_frame_color
	frame.border_width = evolution_frame_width
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(frame)
