extends TextureProgressBar

## Rainbow flash on the experience bar while the player is choosing an upgrade.
## Set the Process Mode to Always so it keeps animating while the game is paused.

## How strongly the rainbow replaces the bar's own color (0 = no effect, 1 = full rainbow).
@export_range(0.0, 1.0, 0.01) var intensity: float = 1.0
## How many full colour cycles per second.
@export var speed: float = 1.5
## Colour saturation of the rainbow.
@export_range(0.0, 1.0, 0.01) var saturation: float = 1.0
## Colour brightness of the rainbow.
@export_range(0.0, 1.0, 0.01) var brightness: float = 1.0
## Also pulse the brightness of the bar (0 = steady, 1 = strong pulse).
@export_range(0.0, 1.0, 0.01) var pulse: float = 0.3
## The colours of the rainbow, in order. Leave empty to use the full hue wheel.
@export var colors: Array[Color] = []

# The bar texture is green, so a plain tint can't produce other colours;
# this shader recolours the coloured pixels while keeping their shading.
const SHADER_CODE := """
shader_type canvas_item;
uniform vec4 tint : source_color = vec4(1.0);
uniform float amount : hint_range(0.0, 1.0) = 1.0;
void fragment() {
	vec4 c = texture(TEXTURE, UV);
	float lum = dot(c.rgb, vec3(0.299, 0.587, 0.114));
	float sat = max(c.r, max(c.g, c.b)) - min(c.r, min(c.g, c.b));
	float m = smoothstep(0.1, 0.3, sat) * amount;
	COLOR = vec4(mix(c.rgb, tint.rgb * lum * 1.6, m), c.a);
}
"""

var flashing := false
var _t := 0.0
var _mat: ShaderMaterial

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shader := Shader.new()
	shader.code = SHADER_CODE
	_mat = ShaderMaterial.new()
	_mat.shader = shader

func start_flash() -> void:
	flashing = true
	_t = 0.0
	material = _mat

func stop_flash() -> void:
	flashing = false
	material = null

func _process(delta: float) -> void:
	if not flashing:
		return
	_t += delta * speed
	var c := _sample(fposmod(_t, 1.0))
	var glow := 1.0 + pulse * 0.5 * sin(_t * TAU * 2.0)
	_mat.set_shader_parameter("tint", Color(c.r * glow, c.g * glow, c.b * glow))
	_mat.set_shader_parameter("amount", intensity)

func _sample(p: float) -> Color:
	if colors.size() < 2:
		return Color.from_hsv(p, saturation, brightness)
	var f := p * colors.size()
	var i := int(f) % colors.size()
	return colors[i].lerp(colors[(i + 1) % colors.size()], f - floorf(f))
