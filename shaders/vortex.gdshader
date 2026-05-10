shader_type spatial;
render_mode unshaded;

group_uniforms style;
/** The first of the blending colors for the hole borders */
uniform vec4 color_one: source_color = vec4(1.0, 1.0, 1.0, 1.0);
/** The second of the blending colors for the hole borders */
uniform vec4 color_two: source_color = vec4(0.0, 0.0, 0.0, 1.0);
/** Influence the color blending curve (1.0 = linear) */
uniform float color_falloff: hint_range(0.1, 10.0) = 1.0;
/** Influence the transparency blending curve (1.0 = linear) */
uniform float transparency_falloff: hint_range(0.1, 10.0) = 1.0;

group_uniforms hole;
/** Defines the maximum depth of the parallax layers */
uniform float depth_amount = 1.0;
/** Number of layers */
uniform int layers = 12;
/** Base radius of the holes */
uniform float radius: hint_range(0.0, 10.0) = 0.4;
/** Value for radius reduction calculations (higher values make the holes on deeper levels smaller faster) */
uniform float radius_reduction = 0.1;
/** Radius reduction calculation method */
uniform int radius_reduction_type: hint_enum("Exponential", "linear") = 0;
/** Cyclic additional variation of the radius between layers based on TIME */
uniform bool vary_radius = true;
/** Proportional variation amount (percentage of the layers radius) */
uniform float radius_variation = 0.1;
/** Speed of the variation change */
uniform float radius_speed_variation = 1.0;
/** Variation offset between layers */
uniform float radius_variation_offset = 1.0;
/** Randomize an additional offset between layers (to avoid a wave pattern) */
uniform bool radius_random_offset = true;
/** Center of the circular effect in UV coordinates */
uniform vec2 center = vec2(0.5, 0.5);


group_uniforms dither;
/** Size of the pixel blocks used for quantization */
uniform float pixel_size : hint_range(0.0, 100.0) = 10.0;
/** Resolution of the viewport/texture */
uniform vec2 resolution = vec2(512.0, 512.0);
/** Offset applied to the dither pattern lookup */
uniform vec2 dither_offset = vec2(2.0, 0);
/** Size of the dither matrix to use (2x2, 4x4, or 8x8) */
uniform int bayer_size : hint_enum("2x2", "4x4", "8x8") = 2;
/** Whether to interpolate the radius calculation for smoother edges */
uniform bool interpolate = true;
/** Controls how quickly the dither pattern density changes (blend border size) */
uniform float falloff: hint_range(0.1, 10.0) = 2.5;

const int bayer2[4] = {
	0, 2,
	3, 1
};

const int bayer4[16] = {
	0, 8, 2, 10,
	12, 4, 14, 6,
	3, 11, 1, 9,
	15, 7, 13, 5
};

const int bayer8[64] = {
	0, 32,  8, 40,  2, 34, 10, 42,
	48, 16, 56, 24, 50, 18, 58, 26,
	12, 44,  4, 36, 14, 46,  6, 38,
	60, 28, 52, 20, 62, 30, 54, 22,
	3, 35, 11, 43,  1, 33,  9, 41,
	51, 19, 59, 27, 49, 17, 57, 25,
	15, 47,  7, 39, 13, 45,  5, 37,
	63, 31, 55, 23, 61, 29, 53, 21
};

float get_bayer2(vec2 coord) {
	int x = int(mod(coord.x, 2.0));
	int y = int(mod(coord.y, 2.0));
	int index = y * 2 + x;
	return (float(bayer2[index]) + 0.5) / 4.0;
}

float get_bayer4(vec2 coord) {
	int x = int(mod(coord.x, 4.0));
	int y = int(mod(coord.y, 4.0));
	int index = y * 4 + x;
	return (float(bayer4[index]) + 0.5) / 16.0;
}

float get_bayer8(vec2 coord) {
	int x = int(mod(coord.x, 8.0));
	int y = int(mod(coord.y, 8.0));
	int index = y * 8 + x;
	return (float(bayer8[index]) + 0.5) / 64.0;
}

float get_dither(vec2 uv, vec2 step_size, float l_radius) {
	vec2 bayer_coord = floor(uv / step_size + 1.0e-5);
	vec2 grid_uv = bayer_coord * step_size + step_size * 0.5;
	float dist = distance(grid_uv, center);
	float t = pow(clamp(dist / l_radius, 0.0, 1.0), falloff);
	float threshold;
	if (bayer_size == 0) {
		threshold = get_bayer2(bayer_coord);
	} else if (bayer_size == 1) {
		threshold = get_bayer4(bayer_coord);
	} else {
		threshold = get_bayer8(bayer_coord);
	}
	return step(threshold, 1.0 - t);
}

float get_mask(vec2 uv, vec2 step_size, vec2 offset, float l_radius) {
	float d1 = get_dither(uv, step_size, l_radius);
	float d2 = get_dither(uv - offset, step_size, l_radius);
	return max(d1, d2);
}

float random(int x)
{
    return fract(sin(float(x)) * 521695.2921843);
}

float double_dither(vec2 l_uv, float l_radius) {
	vec2 uv_step = pixel_size / resolution;
	vec2 raw_offset_uv = dither_offset * uv_step;
	vec2 effective_offset = interpolate ? raw_offset_uv * 0.5 : raw_offset_uv;
	vec2 centered_uv = l_uv + effective_offset * 0.5;
	float dither;
	if (interpolate) {
		vec2 sub_step = uv_step * 0.5;
		vec2 quantized_uv = floor(centered_uv / uv_step) * uv_step;

		vec2 q1 = vec2(uv_step.x * 0.25, uv_step.y * 0.25);
		vec2 q3 = vec2(uv_step.x * 0.75, uv_step.y * 0.75);

		float v1 = get_mask(quantized_uv + q1, sub_step, effective_offset, l_radius);
		float v2 = get_mask(quantized_uv + vec2(q3.x, q1.y), sub_step, effective_offset, l_radius);
		float v3 = get_mask(quantized_uv + vec2(q1.x, q3.y), sub_step, effective_offset, l_radius);
		float v4 = get_mask(quantized_uv + q3, sub_step, effective_offset, l_radius);

		dither = (v1 + v2 + v3 + v4) * 0.25;
	} else {
		vec2 quantized_uv = floor(centered_uv / uv_step) * uv_step;
		dither = get_mask(quantized_uv, uv_step, effective_offset, l_radius);
	}

	return dither;
}

vec2 parallax(float depth, vec3 n, vec3 t, vec3 v) {
	vec3 normal = normalize(n);
	vec3 tangent = normalize(t);
	vec3 bitangent = cross(normal, tangent);
	vec3 view = normalize(v);
	vec3 view_tangent = vec3(dot(view, tangent), dot(view, bitangent), dot(view, normal));
	vec2 offset = (view_tangent.xy / max(view_tangent.z, 0.001)) * depth;
	offset = vec2(-offset.x, offset.y);
	return offset;
}

void fragment() {
	float value = 1.0;
	float sum_radius_reduction = radius;
	
	for(int i = 0; i < layers; i++){
		float radius_random_offset_value = float(radius_random_offset);
		float random_value = 1.0 - radius_random_offset_value + random(i) * float(layers) * radius_random_offset_value;
		float t = float(i) / float(layers);
		float depth = t * depth_amount;
		vec2 circle_uv = UV + parallax(depth, NORMAL, TANGENT, VIEW);
		float radius_vary_modifier = (1.0 + radius_variation * sin((TIME + float(i) * radius_variation_offset + random_value) * radius_speed_variation) * float(vary_radius));
		float dither_value = double_dither(circle_uv, sum_radius_reduction * radius_vary_modifier) * 4.0;
		dither_value = step(0.75, dither_value);
		dither_value = max(dither_value, float(i)/float(layers));
		value = min(value, dither_value);
		sum_radius_reduction = sum_radius_reduction * (1.0 * float(radius_reduction_type) + (1.0 - radius_reduction) * float(1 - radius_reduction_type));
		sum_radius_reduction -= (1.0 * float(radius_reduction_type)) * radius_reduction;
	}
	ALBEDO = mix(color_one.rgb, color_two.rgb, pow(value, color_falloff));
	ALPHA = mix(color_one.a, color_two.a, pow(value, transparency_falloff));
}
