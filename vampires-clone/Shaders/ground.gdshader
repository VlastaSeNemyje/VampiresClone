shader_type canvas_item;

// Layered pixel-art ground. One draw call, two texture reads per pixel.
//   1. flat base colour
//   2. large light / dark patches (procedural noise, hard edged)
//   3. fine tile texture, shown only where a second noise mask allows it
//   4. small detail sprites scattered one-per-cell from an atlas
// Everything is sampled in world space and snapped to whole pixels, so the
// pattern stays locked to the ground and never blurs.

group_uniforms base;
uniform vec4 base_color : source_color = vec4(0.129, 0.263, 0.133, 1.0);
/// Change to get a different layout with the same settings.
uniform float world_seed = 0.0;

group_uniforms patches;
uniform vec4 patch_light_color : source_color = vec4(0.157, 0.306, 0.149, 1.0);
uniform vec4 patch_dark_color : source_color = vec4(0.106, 0.224, 0.122, 1.0);
/// Rough size of a patch in world pixels.
uniform float patch_scale = 150.0;
/// Patch edges are stepped in blocks of this many pixels.
uniform float patch_pixel_size = 4.0;
uniform float patch_light_amount : hint_range(0.0, 1.0) = 0.35;
uniform float patch_dark_amount : hint_range(0.0, 1.0) = 0.3;

group_uniforms fine;
/// Tileable texture. Transparent pixels show the ground colour underneath.
uniform sampler2D fine_texture : source_color, filter_nearest, repeat_enable, hint_default_transparent;
uniform vec4 fine_tint : source_color = vec4(1.0);
/// How much of the ground the fine texture covers.
uniform float fine_coverage : hint_range(0.0, 1.0) = 0.55;
/// Rough size of the covered / uncovered areas in world pixels.
uniform float fine_mask_scale = 90.0;
/// Mask edges are stepped in blocks of this many pixels.
uniform float fine_mask_pixel_size = 8.0;

group_uniforms details;
/// Grid of equally sized frames. Add frames freely; the count is read from the texture size.
uniform sampler2D detail_atlas : source_color, filter_nearest, hint_default_transparent;
uniform ivec2 detail_frame_size = ivec2(16, 16);
/// The world is split into square cells of this size; each holds at most one detail.
uniform float detail_cell_size = 40.0;
/// Chance that a cell holds a detail.
uniform float detail_density : hint_range(0.0, 1.0) = 0.35;

varying vec2 world_pos;
varying vec3 node_tint;

float hash12(vec2 p) {
	vec3 p3 = fract(vec3(p.xyx) * 0.1031);
	p3 += dot(p3, p3.yzx + 33.33);
	return fract((p3.x + p3.y) * p3.z);
}

float value_noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = hash12(i);
	float b = hash12(i + vec2(1.0, 0.0));
	float c = hash12(i + vec2(0.0, 1.0));
	float d = hash12(i + vec2(1.0, 1.0));
	return mix(mix(a, b, f.x), mix(c, d, f.x), f.y);
}

// Value noise bunches up around 0.5; stretch it so the amount sliders feel linear.
float spread(float n) {
	return smoothstep(0.2, 0.8, n);
}

void vertex() {
	world_pos = (MODEL_MATRIX * vec4(VERTEX, 0.0, 1.0)).xy;
	// The node's Modulate colour, so each world can tint the same material.
	node_tint = COLOR.rgb;
}

void fragment() {
	vec2 p = floor(world_pos);
	vec3 col = base_color.rgb;

	// 2. patches
	vec2 pq = floor(p / patch_pixel_size) * patch_pixel_size;
	vec2 pn = pq / patch_scale + world_seed;
	float n = spread(value_noise(pn) * 0.7 + value_noise(pn * 2.7 + 19.3) * 0.3);
	if (n > 1.0 - patch_light_amount) {
		col = patch_light_color.rgb;
	} else if (n < patch_dark_amount) {
		col = patch_dark_color.rgb;
	}

	// 3. fine texture
	vec2 fq = floor(p / fine_mask_pixel_size) * fine_mask_pixel_size;
	float m = spread(value_noise(fq / fine_mask_scale + world_seed + 37.0));
	if (m > 1.0 - fine_coverage) {
		vec2 fine_size = vec2(textureSize(fine_texture, 0));
		vec4 f = texelFetch(fine_texture, ivec2(mod(p, fine_size)), 0);
		if (f.a > 0.5) {
			col = f.rgb * fine_tint.rgb;
		}
	}

	// 4. scattered details
	vec2 cell = floor(p / detail_cell_size);
	vec2 cs = cell + world_seed;
	if (hash12(cs + 71.3) < detail_density) {
		vec2 frame = vec2(detail_frame_size);
		vec2 room = max(vec2(detail_cell_size) - frame, vec2(0.0));
		vec2 offset = floor(vec2(hash12(cs + 11.7), hash12(cs + 23.1)) * (room + 1.0));
		vec2 l = p - cell * detail_cell_size - offset;
		if (all(greaterThanEqual(l, vec2(0.0))) && all(lessThan(l, frame))) {
			ivec2 grid = max(textureSize(detail_atlas, 0) / detail_frame_size, ivec2(1));
			int count = grid.x * grid.y;
			int idx = min(int(hash12(cs + 5.3) * float(count)), count - 1);
			if (hash12(cs + 91.9) > 0.5) {
				l.x = frame.x - 1.0 - l.x;
			}
			ivec2 texel = ivec2(idx % grid.x, idx / grid.x) * detail_frame_size + ivec2(l);
			vec4 d = texelFetch(detail_atlas, texel, 0);
			if (d.a > 0.5) {
				col = d.rgb;
			}
		}
	}

	COLOR = vec4(col * node_tint, 1.0);
}
