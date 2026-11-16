shader_type canvas_item;

// Darkness overlay with a round pool of light around the player (the screen
// centre). While the player moves, the pool slides slightly ahead of them.
// The falloff is drawn in flat bands with a dither pattern between them,
// snapped to game pixels, so it matches the pixel art.
// All sizes are in screen heights: 0.5 reaches the top and bottom edges,
// about 0.89 reaches the left and right edges on a 16:9 screen.

group_uniforms darkness;
uniform vec4 shadow_color : source_color = vec4(0.012, 0.035, 0.05, 1.0);
/// Darkest the unlit area gets. Below 1 leaves silhouettes faintly visible.
uniform float max_darkness : hint_range(0.0, 1.0) = 0.93;

group_uniforms pool;
/// Distance from the pool's centre where the light has faded out completely.
uniform float pool_radius = 0.48;
/// Share of the radius used for the fade. 0 = hard edge, 1 = fades from the centre.
uniform float pool_softness : hint_range(0.0, 1.0) = 0.6;
/// How far the pool's centre slides ahead of the player while moving.
uniform float lead = 0.12;

group_uniforms style;
/// Number of flat darkness steps. 0 = smooth gradient.
uniform int bands : hint_range(0, 16) = 6;
/// How much of each step is a dither pattern. 0 = hard steps, 1 = dithered all the way.
uniform float dither_width : hint_range(0.0, 1.0) = 0.6;
/// Torch-like wobble of the light's size. 0 = steady.
uniform float flicker_amount : hint_range(0.0, 0.2) = 0.0;
uniform float flicker_speed = 6.0;

group_uniforms set_by_script;
/// Movement direction, eased between zero (standing) and length 1 (moving). Set by light_pool.gd.
uniform vec2 heading = vec2(0.0);
/// Screen pixels per game pixel, so bands and dither line up with the art. Set by light_pool.gd.
uniform float pixel_size = 2.6;

const float BAYER[16] = float[](
	0.0, 8.0, 2.0, 10.0,
	12.0, 4.0, 14.0, 6.0,
	3.0, 11.0, 1.0, 9.0,
	15.0, 7.0, 13.0, 5.0
);

void fragment() {
	vec2 screen = 1.0 / SCREEN_PIXEL_SIZE;
	// Snap to game pixels, measured from the screen centre.
	vec2 cell = floor((SCREEN_UV - 0.5) * screen / pixel_size);
	vec2 p = (cell + 0.5) * pixel_size / screen.y;
	float d = length(p - heading * lead);

	float size = 1.0 + flicker_amount * (sin(TIME * flicker_speed) * 0.6 + sin(TIME * flicker_speed * 2.3 + 1.7) * 0.4);
	float radius = pool_radius * size;
	float dark = smoothstep(radius * (1.0 - pool_softness), radius, d);

	if (bands > 0) {
		float v = dark * float(bands);
		float f = fract(v);
		float half_w = dither_width * 0.5;
		f = smoothstep(0.5 - half_w, 0.5 + half_w + 0.0001, f);
		vec2 b = mod(cell, 4.0);
		float threshold = (BAYER[int(b.x) + int(b.y) * 4] + 0.5) / 16.0;
		dark = (floor(v) + step(threshold, f)) / float(bands);
	}

	COLOR = vec4(shadow_color.rgb, dark * max_darkness);
}
