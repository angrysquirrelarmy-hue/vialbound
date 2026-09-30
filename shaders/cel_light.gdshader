// Cel light for normal-mapped sprites and tiles.
//
// Godot's own 2D light pass already samples the light texture and the sprite's
// normal map. All this does is refuse the smooth falloff: N·L times the light's
// own attenuation gets snapped to four steps, which is the whole reason a lit
// scene still reads as pixel art rather than as an airbrushed gradient.
shader_type canvas_item;

uniform float step_1 : hint_range(0.0, 1.0) = 0.62;
uniform float step_2 : hint_range(0.0, 1.0) = 0.38;
uniform float step_3 : hint_range(0.0, 1.0) = 0.16;
uniform float floor_light : hint_range(0.0, 1.0) = 0.18;
uniform float wrap : hint_range(0.0, 1.0) = 0.25;   // half-Lambert: how far light bends around

float ramp(float v) {
	if (v > step_1) { return 1.0; }
	if (v > step_2) { return 0.72; }
	if (v > step_3) { return 0.44; }
	return floor_light;
}

void light() {
	vec3 n = normalize(NORMAL);
	float ndl = dot(n, normalize(LIGHT_DIRECTION));
	ndl = max(0.0, ndl * (1.0 - wrap) + wrap);

	// LIGHT_COLOR already carries the light texture, so its level is the attenuation.
	float atten = max(max(LIGHT_COLOR.r, LIGHT_COLOR.g), LIGHT_COLOR.b);
	vec3 tint = LIGHT_COLOR.rgb / max(atten, 0.001);

	float e = ramp(ndl * clamp(atten, 0.0, 1.0)) * LIGHT_ENERGY;
	LIGHT = vec4(tint * COLOR.rgb * e, LIGHT_COLOR.a);
}
