shader_type canvas_item;

// Gently drifting reflection for the bog pools. Cheap: two texture reads, no extra nodes.
// The bog sprite already has its streaks baked in, so the streaks are painted over with the
// plain water colour and redrawn from the reflection texture, shifted sideways one pixel at a
// time. Rows move out of phase, which reads as slow ripples on standing water. Each pool gets
// its own phase from its world position, so they never move in sync.

uniform sampler2D reflection_tex : source_color, filter_nearest, hint_default_transparent;
/// Colour of the pool where there is no streak (the bog's main body colour).
uniform vec4 water_color : source_color = vec4(0.192, 0.173, 0.086, 1.0);
/// Animation steps per second. Low keeps it pixel-art and calm.
uniform float fps = 2.5;
/// Ripple speed.
uniform float speed = 1.3;
/// Phase difference between pixel rows; higher = tighter ripples.
uniform float row_phase = 0.9;
/// Maximum drift in pixels.
uniform float amplitude = 1.0;

varying float phase;

void vertex() {
	vec2 o = floor((MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xy);
	phase = fract(sin(dot(o, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831;
}

void fragment() {
	vec4 base = texture(TEXTURE, UV);
	vec2 size = vec2(textureSize(TEXTURE, 0));
	float row = floor(UV.y * size.y);
	float t = floor(TIME * fps) / fps;
	float shift = floor(sin(t * speed + row * row_phase + phase) * (amplitude + 0.5) + 0.5);
	shift = clamp(shift, -amplitude, amplitude);

	vec3 col = base.rgb;
	// remove the baked streaks
	if (texture(reflection_tex, UV).a > 0.0) {
		col = water_color.rgb;
	}
	// draw them again, shifted, only where there is pool underneath
	vec4 r = texture(reflection_tex, UV - vec2(shift / size.x, 0.0));
	if (r.a > 0.0 && base.a > 0.0) {
		col = r.rgb;
	}
	COLOR = vec4(col, base.a);
}
