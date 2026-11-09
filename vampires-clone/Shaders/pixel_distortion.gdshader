shader_type canvas_item;

// Full-screen pixel displacement. Everything drawn BEFORE this node is
// distorted; nodes drawn after it (character cards, buttons) stay clean.
// The node's own texture (Pixel distortion.png) is blended on top and
// glitches together with the screen.

uniform sampler2D screen_tex : hint_screen_texture, repeat_disable, filter_nearest;

group_uniforms Timing;
// How many times per second the glitch pattern changes.
uniform float updates_per_second : hint_range(1.0, 60.0) = 12.0;
// Chance (per update) that a glitch burst happens at all. Low = occasional.
uniform float burst_chance : hint_range(0.0, 1.0) = 0.25;

group_uniforms Blocks;
// Resolution of the pixel grid used for the blocks (the game viewport).
uniform vec2 grid_resolution = vec2(640.0, 360.0);
// Block size in pixels. Small width + height = small groups of pixels.
uniform vec2 block_size = vec2(16.0, 4.0);
// Chance (per block, during a burst) that a block is displaced.
uniform float block_chance : hint_range(0.0, 1.0) = 0.08;
// Max horizontal displacement in pixels.
uniform float max_shift : hint_range(0.0, 64.0) = 12.0;
// Extra random block width stretching (0 = uniform blocks).
uniform float width_variation : hint_range(0.0, 1.0) = 0.6;

group_uniforms Look;
// Master strength of the whole effect (0 = off).
uniform float effect_strength : hint_range(0.0, 1.0) = 1.0;
// Opacity of the Pixel distortion texture laid over the screen.
uniform float overlay_strength : hint_range(0.0, 1.0) = 0.35;
// Overlay only shows inside displaced blocks when enabled.
uniform bool overlay_only_in_glitch = false;
// Splits red/blue inside glitched blocks (pixels).
uniform float chroma_split : hint_range(0.0, 8.0) = 1.0;

float hash11(float p) {
	p = fract(p * 0.1031);
	p *= p + 33.33;
	p *= p + p;
	return fract(p);
}

float hash21(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

void fragment() {
	vec2 px = SCREEN_UV * grid_resolution;
	float tick = floor(TIME * updates_per_second);

	// Burst gate: whole glitch is off most of the time.
	float burst = step(hash11(tick * 1.37 + 3.1), burst_chance);

	// Rows are the base unit; each row gets its own random block width
	// so displaced groups vary in length.
	float row = floor(px.y / block_size.y);
	float row_w = block_size.x * (1.0 + width_variation * 3.0 * hash21(vec2(row, tick + 11.0)));
	float col = floor(px.x / row_w);
	vec2 cell = vec2(col, row);

	float hit = step(hash21(cell + vec2(tick * 0.73, tick * 1.91)), block_chance) * burst * effect_strength;
	float dir = hash21(cell + vec2(tick, 5.0)) < 0.5 ? -1.0 : 1.0;
	float amount = (0.25 + 0.75 * hash21(cell + vec2(7.0, tick))) * max_shift;
	float shift_px = floor(amount) * dir * hit;
	vec2 shift_uv = vec2(shift_px / grid_resolution.x, 0.0);
	vec2 split = vec2(chroma_split / grid_resolution.x * hit, 0.0);

	vec2 suv = SCREEN_UV - shift_uv;
	vec3 col_rgb;
	col_rgb.r = texture(screen_tex, suv + split).r;
	col_rgb.g = texture(screen_tex, suv).g;
	col_rgb.b = texture(screen_tex, suv - split).b;

	vec4 ov = texture(TEXTURE, UV - shift_uv);
	float ov_amt = overlay_strength * effect_strength * (overlay_only_in_glitch ? hit : 1.0);
	col_rgb = mix(col_rgb, col_rgb + ov.rgb, ov_amt);

	COLOR = vec4(col_rgb, 1.0);
}
