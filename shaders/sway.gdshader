shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform vec4 albedo : source_color = vec4(1.0);
uniform vec4 transmission_color : source_color = vec4(0.1, 0.1, 0.0, 1.0);
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform float alpha_scissor_threshold : hint_range(0.0, 1.0) = 0.5;

uniform float roughness : hint_range(0.0, 1.0) = 1.0;
uniform float metallic : hint_range(0.0, 1.0) = 0.0;
uniform float specular : hint_range(0.0, 1.0) = 0.5;
uniform sampler2D texture_normal : hint_roughness_normal, filter_linear_mipmap, repeat_enable;
uniform float normal_scale : hint_range(-16.0, 16.0) = 1.0;

uniform float wind_speed : hint_range(0.0, 10.0) = 1.0;
uniform float wind_strength : hint_range(0.0, 5.0) = 0.2;
uniform float wind_horizontal_force : hint_range(0.0, 5.0) = 0.5;
uniform float wind_vertical_force : hint_range(0.0, 5.0) = 0.1;
uniform float wind_sway_size : hint_range(0.0, 10.0) = 2.0;

varying float v_color_mask;

void vertex() {
	v_color_mask = COLOR.r;
	vec3 world_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float time = TIME * wind_speed;
	
	float sway = sin(time + (world_pos.x + world_pos.z) / wind_sway_size);
	sway += sin(time * 1.5 + world_pos.y) * 0.5;
	
	float mask = v_color_mask; 
	if (length(COLOR.rgb) < 0.001) mask = UV.y;

	float final_sway = sway * wind_strength * mask;
	
	VERTEX.x += final_sway * wind_horizontal_force;
	VERTEX.y += final_sway * wind_vertical_force;
	VERTEX.z += final_sway * (wind_horizontal_force * 0.5);
}

void fragment() {
	vec4 albedo_tex = texture(texture_albedo, UV);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	
	NORMAL_MAP = texture(texture_normal, UV).rgb;
	NORMAL_MAP_DEPTH = normal_scale;
	
	METALLIC = metallic;
	ROUGHNESS = roughness;
	SPECULAR = specular;
	
	ALPHA = albedo.a * albedo_tex.a;
	ALPHA_SCISSOR_THRESHOLD = alpha_scissor_threshold;
	
	BACKLIGHT = transmission_color.rgb;
}