// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx, skip_vertex_transform;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform sampler2D foam_noise : filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

uniform float time_ms;

const int MAX_SPLASHES = 64; // Limit loops for performance
uniform vec3 splash_positions[MAX_SPLASHES];
uniform float splash_start_times[MAX_SPLASHES];
uniform sampler2D splash_texture : source_color, filter_linear_mipmap, repeat_enable;

varying vec3 vertex_world;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

mat2 rotate(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

vec3 gerstner_wave(vec2 xz, vec2 dir, float steepness, float amp, float freq, float speed, float time) {
	// Calculate the main wave function component
	float dot_product = dot(dir, xz) * freq + time * speed;

	// Use cos for horizontal and sin for vertical displacement to create the circular motion
	float s = sin(dot_product);
	float c = cos(dot_product);

	// Calculate the displacements
	float dx = steepness * dir.x * amp * c;
	float dz = steepness * dir.y * amp * c;
	float dy = amp * s;

	// The final displacement vector
	return vec3(dx, dy, dz);
}


float gameplay_height(vec2 xz) {
	float time = time_ms * 0.001;
	float height = 0.0;

	// --- Wave 1 ---
	float steepness_1 = 0.4;     // How sharp the peak is (0=sine wave, 1=very sharp)
	float amp_1 = 0.5;
	float freq_1 = 0.3;
	float speed_1 = 1.1;
	vec2 dir_1 = normalize(vec2(1.0, 0.6));

	// Calculate the first Gerstner wave and only take its height (y-component)
	vec3 wave_1_displacement = gerstner_wave(xz, dir_1, steepness_1, amp_1, freq_1, speed_1, time);
	height += wave_1_displacement.y;


	// --- Wave 2 ---
	float steepness_2 = 0.6;     // A slightly sharper secondary wave
	float amp_2 = 0.9;
	float freq_2 = 0.12;
	float speed_2 = 0.9;
	vec2 dir_2 = normalize(vec2(1.0, 1.1));

	// Calculate the second Gerstner wave and add its height
	vec3 wave_2_displacement = gerstner_wave(xz, dir_2, steepness_2, amp_2, freq_2, speed_2, time);
	height += wave_2_displacement.y;

	return height;
}

float visual_height(vec2 xz) {
	float time = time_ms * 0.001;
	time *= 0.7;
	float height = 0.0;

	float  amp = 0.1;
	vec2 freq = vec2(0.9,0.7)*0.7;
	vec2 diff = vec2(1.03, 0.96);
	// The 'speed' variable was not used in the original function.
	// You might want to integrate it into the time calculation, for example: time * speed
	float speed = 5.0;

	for (int i = 0; i < 7; i++) {
		// Rotate the coordinates for each wave layer.
		// The angle of rotation is changed in each iteration.
		vec2 p = rotate(float(i) * 0.85) * xz;

		height += (
			sin(p.x*freq.x + time*diff.x+sin(p.y*freq.y+time*0.3))
			+ sin((p.y+sin(p.x*freq.x+time*0.7))*freq.y + time*diff.y)
		) * amp;

		amp *= 0.7;
		freq *= 1.3;
		diff += 1.7;
	}
	return height;
}

float get_splash_height(vec2 vertex_pos) {
	float h = 0.0;
	float current_time = time_ms * 0.001; // Convert ms to seconds

	for (int i = 0; i < MAX_SPLASHES; i++) {
		vec3 pos = splash_positions[i];
		float start_time = splash_start_times[i];
		float time_diff = current_time - start_time;

		// Optimization: If splash is too old or hasn't happened yet, skip
		if (time_diff < 0.0 || time_diff > 2.0) continue; 

		float dist = distance(vertex_pos, pos.xz);
		
		// Splash Shape Parameters
		float frequency = 6.0;
		float speed = 10.0;
		float decay_dist = 0.4;
		float decay_time = 1.0;
		float fade_in_duration = 0.3; // <-- The duration of the fade-in in seconds

		// The Wave Math
		float wave = sin(dist * frequency - time_diff * speed);
		
		// Calculate base amplitude
		float amplitude = 1.0 * exp(-dist * decay_dist) * exp(-time_diff * decay_time);
		
		// === THIS IS THE NEW PART ===
		// Create a fade-in factor that goes from 0.0 to 1.0 over fade_in_duration
		float fade_in_factor = smoothstep(0.0, fade_in_duration, time_diff);
		amplitude *= fade_in_factor;
		// ===========================
		
		// Create a central "crater" immediately after impact
		if (time_diff < 0.2) {
			float crater = smoothstep(0.5, 0.0, dist) * smoothstep(0.2, 0.0, time_diff);
			h -= crater * 0.5; 
		}

		h += wave * amplitude * 0.3;
	}
	return h;
}

float height(vec2 xz) {
	return gameplay_height(xz) + visual_height(xz) + get_splash_height(xz);
}

vec3 calculateNormal(vec2 xz) {
	// A small offset value to sample neighboring points
	float epsilon = 0.05;

	// Sample the height at the current point and at points slightly offset in x and z
	float h = height(xz);
	float hx = height(vec2(xz.x + epsilon, xz.y));
	float hz = height(vec2(xz.x, xz.y + epsilon));

	// Create two tangent vectors
	vec3 tangentX = normalize(vec3(epsilon, hx - h, 0.0));
	vec3 tangentZ = normalize(vec3(0.0, hz - h, epsilon));

	// The normal is the cross product of the two tangents
	vec3 normal = normalize(cross(tangentZ, tangentX));

	return normal;
}

void vertex() {
	vertex_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;

	vertex_world.y += height(vertex_world.xz);

	VERTEX = (VIEW_MATRIX * vec4(vertex_world, 1.0)).xyz;
//	NORMAL = normalize((MODELVIEW_MATRIX * vec4(NORMAL, 0.0)).xyz);
//	NORMAL = vertex_world.xyz;
//	BINORMAL = normalize((VIEW_MATRIX * vec4(BINORMAL, 0.0)).xyz);
//	TANGENT = normalize((VIEW_MATRIX * vec4(TANGENT, 0.0)).xyz);

//	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

float get_splash_foam(vec2 world_pos_xz) {
	float foam = 0.0;
	float current_time = time_ms * 0.001;

	for (int i = 0; i < MAX_SPLASHES; i++) {
		float start_time = splash_start_times[i];
		float time_diff = current_time - start_time;

		// --- Foam Lifetime ---
		float life_time = 3.0; // How long foam is visible in seconds
		if (time_diff < 0.0 || time_diff > life_time) continue;

		// --- Sizing and Animation ---
		// The splash will grow from start_size to end_size over its lifetime
		float start_size = 4.0;  // Size in world units when it starts
		float end_size = 8.0;    // Size in world units when it fades out
		
		// Interpolate the size based on how old the splash is
		float current_size = mix(start_size, end_size, time_diff / life_time);

		// --- UV Calculation ---
		// 1. Get the vector from the splash center to the current pixel's world position.
		vec2 relative_pos = world_pos_xz - splash_positions[i].xz;
		
		// 2. Map this world-space vector to the texture's UV coordinates ([0,1] space).
		// Dividing by 'current_size' makes the texture scale up over time.
		// We add 0.5 to center the texture at the splash origin.
		vec2 uv = relative_pos / current_size + 0.5;

		float foam_from_tex = 0.0;
		// 3. Only sample the texture if the calculated UVs are within the valid [0,1] range.
		if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
			// We're inside the splash area, sample the texture (using .r for grayscale)
			foam_from_tex = texture(splash_texture, uv).r;
		}

		// --- Intensity and Fades ---
		float fade_in = smoothstep(0.0, 0.4, time_diff);
		// Start fading out in the last 60% of the lifetime for a smooth exit
		float fade_out = smoothstep(life_time, life_time * 0.4, time_diff);

		float intensity = fade_in * fade_out;
		
		float dist_from_center = distance(uv, vec2(0.5));
		float edge_mask = smoothstep(0.5, 0.3, dist_from_center);

		foam += foam_from_tex * intensity * edge_mask;
	}
	return clamp(foam, 0.0, 1.0);
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;
	vec3 worldNormal = calculateNormal(vertex_world.xz);
	//ALBEDO = NORMAL;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	float depth = textureLod(depth_texture, SCREEN_UV, 0.0).r;
	depth = depth * 2.0 - 1.0;
	vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
	vec3 pixel_position = upos.xyz / upos.w;
	vec3 pixel_pos_world = (INV_VIEW_MATRIX * vec4(pixel_position, 1.0)).xyz;
	float waterDist = distance(pixel_pos_world, vertex_world);

	vec4 distorsion = texture(foam_noise, vertex_world.xz*0.5) * clamp(1. - waterDist*0.02, 0.3, 1.) * 0.7;
	worldNormal -= distorsion.xyz;
	worldNormal = normalize(worldNormal);
	NORMAL = normalize((VIEW_MATRIX * vec4(worldNormal, 0.0)).xyz);

	vec3 cameraDirection = normalize(pixel_pos_world - CAMERA_POSITION_WORLD);
	float reflectionFactor = 1.-dot(-cameraDirection, worldNormal)*-cameraDirection.y;
	reflectionFactor = mix(1.0, reflectionFactor, 0.7);
	ALBEDO += clamp(1. - waterDist*0.1, 0.0, 0.3);


	ALBEDO += clamp(pow(
		(visual_height(vertex_world.xz)
		+gameplay_height(vertex_world.xz)*0.45
		+texture(foam_noise, vertex_world.zx*0.01).x)*worldNormal.y*0.6,4.
	), 0.0, 1.0);


	float t = clamp(pow(waterDist * 0.5, 2.0), 0.0, 1.0);
	ALBEDO = mix(ALBEDO + reflectionFactor, ALBEDO, t);
	//ALBEDO = vec3(t);
	ALPHA = mix(0.1, 1.0, t) * reflectionFactor;
	ALPHA -= pow(clamp(1.-waterDist*0.05, 0.0, 1.0)*distorsion.y,2.0);
	
	// splash foam
	float splash_foam_intensity = get_splash_foam(vertex_world.xz);
	ALBEDO += vec3(splash_foam_intensity * 0.8); // Add white foam (0.8 is brightness)
}
