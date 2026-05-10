/**
 * WIND STRIP SHADER by DIP (Modified with Pause)
 */
shader_type spatial;
render_mode unshaded;

group_uniforms Global;
uniform vec4 color:source_color = vec4(1.0);
uniform float fade_time = 5.0;
uniform float time_scale = 3.0;
/** Задержка между появлениями пучков в секундах */
uniform float pause_time = 15.0;

group_uniforms Wave;
uniform float wave_amplitude = 0.1;
uniform float wave_frequency = 1.0;
uniform float wave_length = 2.0;
uniform float wave_count:hint_range(0.0, 10.0, 1.0) = 1.0;

group_uniforms Twist;
uniform float twist_amplitude = 0.1;
uniform float twist_frequency = 1.0;

group_uniforms Loop;
uniform float loop_radius = 1.0;
uniform float loop_count = 0.5;

instance uniform float extra_offset_time = 0.0;
instance uniform float extra_wave_length = 0.0;
instance uniform float extra_loop_radius = 0.0;

void vertex() {
	float scaled_time = TIME * time_scale + extra_offset_time;
	
	// Базовые расчеты геометрии
	vec3 wave = vec3(
		VERTEX.x + sin(VERTEX.y * twist_frequency + scaled_time) * twist_amplitude,
		VERTEX.y * (wave_length + extra_wave_length),
		VERTEX.z + sin(VERTEX.y * wave_frequency + scaled_time) * wave_amplitude
	);
	
	float loop_angle = VERTEX.y * TAU * loop_count + scaled_time;
	vec3 loop = vec3(
		VERTEX.x,
		sin(loop_angle) * (loop_radius + extra_loop_radius),
		cos(loop_angle) * (loop_radius + extra_loop_radius)
	);
	
	// Расчет таймингов
	float period = TAU; 
	float offset_time = period * 0.5; 
	float hold_time = wave_count * period;
	float active_duration = hold_time + 2.0 * period;
	
	// Общий цикл включает активную фазу и паузу
	float total_cycle = active_duration + (pause_time * time_scale);
	float t = mod(scaled_time + offset_time, total_cycle); 

	// Если время вышло за пределы активной фазы — "выключаем" пучок
	if (t > active_duration) {
		VERTEX = vec3(0.0);
		COLOR.a = 0.0;
	} else {
		float factor;
		if (t < hold_time) {
			factor = 0.0;
		} else if (t < hold_time + period) {
			factor = ((t - hold_time) / period) * 0.5;
		} else {
			factor = (1.0 - (t - hold_time - period) / period) * 0.5;
		}
		
		VERTEX = mix(wave, loop, factor);
		VERTEX.y += t;
		
		COLOR = color;
		// Плавное появление и исчезновение
		if (t < fade_time) {
			COLOR.a = t / fade_time;
		} else if (t > active_duration - fade_time) {
			COLOR.a = (active_duration - t) / fade_time;
		}
	}
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ALPHA = COLOR.a;
}