shader_type canvas_item;

// Wind sway for the swamp trees. Only the thin, high parts move (hanging moss and thin
// branch tips); the trunk and the lower part of the tree stay still. Whole pixels, stepped
// at a low frame rate, one shared material for every tree texture.
//
// Which pixels may move:
//   - olive / green pixels (moss), and
//   - brown pixels that are thin (less than ~4 px wide or less than ~3 px tall) - so the
//     thick trunk is skipped.
// Both only in the upper part of the sprite: rows below `rigid_fraction` of the height are
// never touched. Each tree gets its own phase from its world position.

/// Bottom part of the sprite that never moves (0 = whole tree may sway, 1 = nothing moves).
uniform float rigid_fraction : hint_range(0.0, 1.0) = 0.4;
/// Maximum sideways drift in pixels at the very top.
uniform float amplitude = 1.0;
/// Animation steps per second.
uniform float fps = 3.0;
/// Sway speed.
uniform float speed = 1.2;
/// Per-row lag so the tips trail behind the lower parts.
uniform float row_lag = 0.10;

varying float phase;
varying vec4 modulate_col;

void vertex() {
	vec2 o = floor((MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy);
	phase = fract(sin(dot(o, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831;
	modulate_col = COLOR;
	// Grow the quad by one pixel on each side so a shifted pixel at the sprite's edge is not cut off.
	float pad = 1.0;
	float side = UV.x - 0.5;
	VERTEX.x += side * 2.0 * pad;
	UV.x += side * 2.0 * pad * TEXTURE_PIXEL_SIZE.x;
}

vec4 px(sampler2D tex, vec2 p) {
	ivec2 size = textureSize(tex, 0);
	if (p.x < 0.0 || p.y < 0.0 || p.x >= float(size.x) || p.y >= float(size.y)) {
		return vec4(0.0);
	}
	return texelFetch(tex, ivec2(p), 0);
}

bool movable(sampler2D tex, vec2 p, vec4 c) {
	if (c.a < 0.5) {
		return false;
	}
	if (c.g > c.r) {
		return true; // moss
	}
	// brown: only if thin
	int h = 0;
	for (int i = -3; i <= 3; i++) {
		if (i != 0 && px(tex, p + vec2(float(i), 0.0)).a > 0.5) h++;
	}
	int v = 0;
	for (int j = -2; j <= 2; j++) {
		if (j != 0 && px(tex, p + vec2(0.0, float(j))).a > 0.5) v++;
	}
	return !(h >= 4 && v >= 3);
}

void fragment() {
	vec2 size = vec2(textureSize(TEXTURE, 0));
	vec2 p = floor(UV * size);
	vec4 orig = px(TEXTURE, p);

	float height_frac = (size.y - p.y) / size.y; // 0 at the bottom, 1 at the top
	float up = clamp((height_frac - rigid_fraction) / (1.0 - rigid_fraction), 0.0, 1.0);
	float t = floor(TIME * fps) / fps;
	float s = sin(t * speed + phase - p.y * row_lag);
	float shift = clamp(floor(s * up * (amplitude + 0.5) + 0.5), -amplitude, amplitude);

	vec4 res = orig;
	if (shift != 0.0) {
		res = vec4(0.0);
		if (orig.a > 0.5 && !movable(TEXTURE, p, orig)) {
			res = orig; // trunk pixels stay and win over anything sliding onto them
		} else {
			vec2 sp = p - vec2(shift, 0.0);
			vec4 src = px(TEXTURE, sp);
			if (movable(TEXTURE, sp, src)) {
				res = src;
			}
		}
	}
	COLOR = res * modulate_col;
}
