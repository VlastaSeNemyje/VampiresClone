extends TextureRect

const LEVEL_PIXEL = preload("res://Textures/Sprites/Floating pixel big.png")
# The opaque 2x2 square inside the 8x8 "Floating pixel big" texture
const LEVEL_PIXEL_REGION = Rect2(3, 2, 2, 2)

# One square per reached level, in a row along the bottom of the frame
@export var level_pixel_size: float = 1.5
@export var level_pixel_gap: float = 0.5
@export var level_pixel_offset: Vector2 = Vector2(1.5, 9.0)
@export var level_pixel_tint: Color = Color.WHITE # white keeps the texture's own red

var upgrade = null
var level_pixels = []

func _ready():
	set_upgrade(upgrade)

# Shows the icon and level squares of the given upgrade rank
func set_upgrade(new_upgrade):
	upgrade = new_upgrade
	if upgrade == null or not is_node_ready():
		return
	var data = UpgradeDb.UPGRADES[upgrade]
	$ItemTexture.texture = load(data["icon"])
	# "Level: 3" -> 3; "Ascend" and "N/A" have no number and show no squares
	set_level(int(str(data["level"])))

func set_level(level: int):
	while level_pixels.size() > max(level, 0):
		level_pixels.pop_back().queue_free()
	while level_pixels.size() < level:
		var atlas = AtlasTexture.new()
		atlas.atlas = LEVEL_PIXEL
		atlas.region = LEVEL_PIXEL_REGION
		var pixel = TextureRect.new()
		pixel.texture = atlas
		pixel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		pixel.mouse_filter = Control.MOUSE_FILTER_IGNORE
		pixel.self_modulate = level_pixel_tint
		pixel.size = Vector2(level_pixel_size, level_pixel_size)
		pixel.position = level_pixel_offset + Vector2(level_pixels.size() * (level_pixel_size + level_pixel_gap), 0)
		add_child(pixel)
		level_pixels.append(pixel)
