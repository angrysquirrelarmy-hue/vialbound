// The post pass, run once over the 320x180 viewport before it is scaled up.
//
// Ordered dither, then a hard snap to the palette texture. Doing both at virtual
// resolution is what keeps gradients inside the palette instead of banding, and
// it means every frame the game ever shows uses only colours that are in the ramp.
shader_type canvas_item;

uniform sampler2D palette : filter_nearest, source_color;
uniform int palette_size = 32;
uniform float dither : hint_range(0.0, 0.5) = 0.055;
uniform bool enabled = true;
uniform vec3 grade = vec3(1.0, 1.0, 1.0);

const float BAYER[16] = float[16](
	 0.0,  8.0,  2.0, 10.0,
	12.0,  4.0, 14.0,  6.0,
	 3.0, 11.0,  1.0,  9.0,
	15.0,  7.0, 13.0,  5.0
);

void fragment() {
	vec4 src = texture(TEXTURE, UV);
	if (!enabled) { COLOR = src; }
	else {
		vec3 c = src.rgb * grade;

		// dither at virtual pixel scale, not at output scale
		vec2 vp = vec2(textureSize(TEXTURE, 0));
		ivec2 p = ivec2(mod(UV * vp, 4.0));
		c += (BAYER[p.y * 4 + p.x] / 16.0 - 0.5) * dither;

		vec3 best = c;
		float best_d = 1e9;
		for (int i = 0; i < palette_size; i++) {
			vec3 q = texelFetch(palette, ivec2(i, 0), 0).rgb;
			vec3 d = q - c;
			float dd = d.r * d.r * 0.3 + d.g * d.g * 0.59 + d.b * d.b * 0.11;
			if (dd < best_d) { best_d = dd; best = q; }
		}
		COLOR = vec4(best, src.a);
	}
}
