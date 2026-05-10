shader_type canvas_item;

uniform float luminance_cutoff: hint_range(-1.0, 1.5) = 0.0;
uniform bool invert = false;
uniform sampler2D mask_texture;
uniform sampler2D display_texture;

void fragment() {
	vec4 sample_color = texture(mask_texture, UV);
	float luminance = dot(sample_color.rgb, vec3(0.2126, 0.7152, 0.0722));
	bool filter = luminance > luminance_cutoff;
	if (invert) {
		filter = !filter;
	}
	
	if (filter) {
		COLOR = texture(display_texture, UV);
	} else {
		COLOR = vec4(1.0, 1.0, 1.0, 0.0) * texture(display_texture, UV);
	}
}
