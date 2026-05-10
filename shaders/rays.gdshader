shader_type spatial;
render_mode unshaded, cull_disabled, blend_add, depth_draw_never;

uniform vec4 beam_color : source_color = vec4(1.0, 0.9, 0.4, 1.0);
uniform float vertical_speed : hint_range(0.0, 5.0) = 0.5;
uniform bool reverse_direction = false;
uniform float rotation_speed : hint_range(0.0, 1.0) = 0.0;
uniform float density : hint_range(1.0, 50.0) = 20.0;
uniform float ray_sharpness : hint_range(0.0, 1.0) = 0.5;

uniform sampler2D noise_texture; 

void fragment() {
	vec2 scrolling_uv = UV;
	
	if (reverse_direction) {
		scrolling_uv.y -= TIME * vertical_speed;
	} else {
		scrolling_uv.y += TIME * vertical_speed;
	}
	
	if (rotation_speed > 0.0) {
		scrolling_uv.x += TIME * rotation_speed;
	}
	
	vec2 noise_uv = scrolling_uv;
	noise_uv.x *= density;
	noise_uv.y *= 0.1;
	
	float noise_value = texture(noise_texture, noise_uv).r;
	float rays = smoothstep(ray_sharpness, ray_sharpness + 0.1, noise_value);
	
	float vertical_fade = 1.0 - UV.y;
	vertical_fade = pow(vertical_fade, 2.0);
	
	ALBEDO = beam_color.rgb;
	ALPHA = rays * vertical_fade * beam_color.a;
	EMISSION = beam_color.rgb;
}