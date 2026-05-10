shader_type spatial;
uniform vec4 baseColor : source_color = vec4(0, 0, 0, 1.0);
uniform vec4 fresnelAlbedo : source_color = vec4(0.3, 0.3, 0.3, 1.0);
uniform bool invertFresnel = false;
uniform float roughness = 0.2;
uniform float metallic = 0.3;
uniform sampler2D normalMap;
uniform float normalMapStrngth = 0.40;
uniform float scaleX = 5;
uniform float scaleY = 5;
uniform float speedX = 20;
uniform float speedY = 20;

vec3 fresnel_glow(float amount, float intensity, vec3 color, vec3 normal, vec3 view)
{
	return pow((1.0 - dot(normalize(normal), normalize(view))), amount) * color * intensity;
}


void fragment(){
	float f_dot = 1.0 - dot(normalize(NORMAL), normalize(VIEW));
	float fresnel_factor = pow(f_dot, 4.0);
	vec2 uv_offset = vec2(TIME * speedX / 10000.0, TIME * speedY / 10000.0);
	NORMAL_MAP = texture(normalMap, (UV + uv_offset) * vec2(scaleX, scaleY)).rgb;
	NORMAL_MAP_DEPTH = normalMapStrngth;
	ROUGHNESS = roughness;
	METALLIC = metallic;

	if (invertFresnel){
		ALBEDO = mix(baseColor.rgb, fresnelAlbedo.rgb, clamp(fresnel_factor * 4.5, 0.0, 1.0));
	}
	else{
		vec3 fresnel = fresnel_factor * fresnelAlbedo.rgb * 4.5;
		ALBEDO = baseColor.rgb + fresnel;
	}

}