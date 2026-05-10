/*
	壁シールドシェーダー by あるる（きのもと 結衣） @arlez80
	Wall Shield Shader by KINOMOTO Yui

	MIT License
*/

shader_type spatial;
render_mode depth_draw_never;

uniform float scale = 15.0;
uniform float line_speed = 0.5;
uniform float ripple_speed = 1.564;

uniform vec4 line_color : source_color = vec4( 0.2, 1.0, 1.0, 1.0 );
uniform vec4 ripple_color : source_color = vec4( 0.6, 0.7, 1.0, 0.7 );
uniform vec4 surface_color : source_color = vec4( 0.01, 0.18, 0.7, 0.4 );

uniform float sphere_size = 2.0;

uniform vec3 pos1 = vec3( 0.0, 0.0, 0.0 );
uniform vec3 pos2 = vec3( 10000, 10000, 10000 );
uniform vec3 pos3 = vec3( 10000, 10000, 10000 );
uniform vec3 pos4 = vec3( 10000, 10000, 10000 );
uniform vec3 pos5 = vec3( 10000, 10000, 10000 );
uniform vec3 pos6 = vec3( 10000, 10000, 10000 );

varying vec3 world_vertex;

float hex_cells( vec2 uv )
{
	float x = uv.x * scale;
	float y = mod( floor( x ), 2.0 ) * 0.5 + ( uv.y * scale / 1.25 );
	vec2 base_chip = abs( vec2( 0.5 ) - mod( vec2( x, y ), 1.0 ) );
	return abs( max( base_chip.x * 1.5 + base_chip.y, base_chip.y * 2.0 ) - 1.0 );
}

void vertex( )
{
	world_vertex = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

// ... твои старые юниформы ...
uniform float fade_dist_min = 5.0; // На каком расстоянии начинает исчезать
uniform float fade_dist_max = 15.0; // На каком расстоянии исчезает полностью

void fragment( )
{
	// --- Твой существующий код расчета цвета ---
	float hex = hex_cells( UV );
	vec3 final_line_color = clamp( line_color.rgb + ( fract( length( UV * scale * 0.5 ) + TIME * line_speed ) * 2.0 - 1.0 ), vec3( 0.0 ), vec3( 1.0 ) );
	float ripple = float( abs( hex - mod( -TIME * ripple_speed, 1.0 ) ) * 5.0 < 0.2 );

	vec4 final = mix(
		mix(surface_color, ripple_color, ripple),
		vec4( final_line_color, 1.0 ),
		float( hex < 0.02 )
	);

	float min_dist = min(
		length( pos1 - world_vertex ),
		min(length( pos2 - world_vertex ),
		min(length( pos3 - world_vertex ),
		min(length( pos4 - world_vertex ),
		min(length( pos5 - world_vertex ),
		length( pos6 - world_vertex )))))
	);
	// ------------------------------------------

	// Расчет дистанции до камеры
	// VERTEX в fragment() — это позиция в View Space (пространство камеры)
	float dist_to_camera = length(VERTEX);

	// Вычисляем коэффициент прозрачности на основе расстояния
	// smoothstep вернет 1.0 на близком расстоянии и 0.0 на дальнем
	float distance_fade = 1.0 - smoothstep(fade_dist_min, fade_dist_max, dist_to_camera);

	ALBEDO = final.rgb;
	
	// Перемножаем твою старую альфу на новый коэффициент затухания
	float initial_alpha = clamp( final.a * sphere_size - min_dist, 0.0, 1.0 );
	ALPHA = initial_alpha * distance_fade;
}