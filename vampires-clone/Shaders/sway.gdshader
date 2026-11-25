shader_type canvas_item;

// Gentle wind sway for grass, reeds and (later) trees. Pixels are pushed sideways by a
// whole number of pixels, more the higher they are above the base, so the root stays put.
// One shared material, one texture read per pixel, no scripts. Each sprite gets its own
// phase from its world position so neighbours do not sway in sync.
//
// For a tree, make a new material from this shader and set base_y to the pixel row of the
// trunk's foot (counted from the top of the texture) and height to the tree's height in pixels.

/// Pixel row (from the top of the texture) where the sprite is rooted. Nothing moves here.
uniform float base_y = 25.0;
/// Distance in pixels above the base at which the sway reaches full amplitude.
uniform float height = 16.0;
/// Maximum sideways drift in pixels at full height.
uniform float amplitude = 1.0;
/// Animation steps per second. Low keeps it pixel-art and calm.
uniform float fps = 3.0;
/// Sway speed.
uniform float speed = 1.4;
/// Small per-row lag so the top trails behind the base.
uniform float row_lag = 0.12;

varying float phase;

void vertex() {
	vec2 o = floor((MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy);
	phase = fract(sin(dot(o, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831;
}

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	float row = floor(UV.y * size.y);
	float up = clamp((base_y - row) / height, 0.0, 1.0);
	float t = floor(TIME * fps) / fps;
	float s = sin(t * speed + phase - row * row_lag);
	float shift = floor(s * up * (amplitude + 0.5) + 0.5);
	shift = clamp(shift, -amplitude, amplitude);
	COLOR = texture(TEXTURE, UV - vec2(shift / size.x, 0.0));
}
