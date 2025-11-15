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

// --- Splash (Height) Data ---
const int MAX_SPLASHES = 32;
uniform vec3 splash_positions[MAX_SPLASHES];
uniform float splash_start_times[MAX_SPLASHES];

// --- Foam (Visual) Data ---
const int MAX_FOAM = 16;
uniform vec3 foam_positions[MAX_FOAM];
uniform float foam_start_times[MAX_FOAM];
uniform float foam_sizes[MAX_FOAM];
uniform sampler2D splash_texture : source_color, filter_linear_mipmap, repeat_enable;


varying vec3 vertex_world;

uniform sampler2D depth_texture : hint_depth_texture, repeat_disable, filter_nearest;

mat2 rotate(float angle) {
	float s = sin(angle);
	float c = cos(angle);
	return mat2(vec2(c, -s), vec2(s, c));
}

vec3 gerstner_wave(vec2 xz, vec2 dir, float steepness, float amp, float freq, float speed, float time) {
	float dot_product = dot(dir, xz) * freq + time * speed;
	float s = sin(dot_product);
	float c = cos(dot_product);
	float dx = steepness * dir.x * amp * c;
	float dz = steepness * dir.y * amp * c;
	float dy = amp * s;
	return vec3(dx, dy, dz);
}


float gameplay_height(vec2 xz) {
	float time = time_ms * 0.001;
	float height = 0.0;
	vec3 wave_1_displacement = gerstner_wave(xz, normalize(vec2(1.0, 0.6)), 0.4, 0.5, 0.3, 1.1, time);
	height += wave_1_displacement.y;
	vec3 wave_2_displacement = gerstner_wave(xz, normalize(vec2(1.0, 1.1)), 0.6, 0.9, 0.12, 0.9, time);
	height += wave_2_displacement.y;
	return height;
}

float visual_height(vec2 xz) {
	float time = time_ms * 0.001 * 0.7;
	float height = 0.0;
	float amp = 0.1;
	vec2 freq = vec2(0.9, 0.7) * 0.7;
	vec2 diff = vec2(1.03, 0.96);
	float speed = 5.0;
	for (int i = 0; i < 7; i++) {
		vec2 p = rotate(float(i) * 0.85) * xz;
		height += (sin(p.x * freq.x + time * diff.x + sin(p.y * freq.y + time * 0.3)) + sin((p.y + sin(p.x * freq.x + time * 0.7)) * freq.y + time * diff.y)) * amp;
		amp *= 0.7;
		freq *= 1.3;
		diff += 1.7;
	}
	return height;
}

float get_splash_height(vec2 vertex_pos) {
	float h = 0.0;
	float current_time = time_ms * 0.001;

	for (int i = 0; i < MAX_SPLASHES; i++) {
		vec3 pos = splash_positions[i];
		float start_time = splash_start_times[i];
		float time_diff = current_time - start_time;

		if (time_diff < 0.0 || time_diff > 2.0) continue; 

		float dist = distance(vertex_pos, pos.xz);
		
		float frequency = 6.0;
		float speed = 10.0;
		float decay_dist = 0.4;
		float decay_time = 1.0;
		float fade_in_duration = 0.3;

		float wave = sin(dist * frequency - time_diff * speed);
		
		float amplitude = 1.0 * exp(-dist * decay_dist) * exp(-time_diff * decay_time);
		
		float fade_in_factor = smoothstep(0.0, fade_in_duration, time_diff);
		amplitude *= fade_in_factor;
		
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
	float epsilon = 0.05;
	float h = height(xz);
	float hx = height(vec2(xz.x + epsilon, xz.y));
	float hz = height(vec2(xz.x, xz.y + epsilon));
	vec3 tangentX = normalize(vec3(epsilon, hx - h, 0.0));
	vec3 tangentZ = normalize(vec3(0.0, hz - h, epsilon));
	vec3 normal = normalize(cross(tangentZ, tangentX));
	return normal;
}

void vertex() {
	vertex_world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vertex_world.y += height(vertex_world.xz);
	VERTEX = (VIEW_MATRIX * vec4(vertex_world, 1.0)).xyz;
}

float get_foam_effect(vec2 world_pos_xz) {
	float foam = 0.0;
	float current_time = time_ms * 0.001;

	for (int i = 0; i < MAX_FOAM; i++) {
		float start_time = foam_start_times[i];
		float time_diff = current_time - start_time;

		float life_time = 3.0;
		if (time_diff < 0.0 || time_diff > life_time) continue;

		// --- Sizing and Animation (MODIFIED) ---
		// The size is now controlled by the uniform array passed from the script.
		// The foam will animate from half its target size to its full target size.
		float end_size = foam_sizes[i];    // Final size in world units
		float start_size = end_size * 0.6; // Start at half the final size for a nice growing effect
		
		// Interpolate the size based on how old the foam is
		float current_size = mix(start_size, end_size, time_diff / life_time);

		// --- UV Calculation ---
		vec2 relative_pos = world_pos_xz - foam_positions[i].xz;
		vec2 uv = relative_pos / current_size + 0.5;

		float foam_from_tex = 0.0;
		if (uv.x > 0.0 && uv.x < 1.0 && uv.y > 0.0 && uv.y < 1.0) {
			foam_from_tex = texture(splash_texture, uv).r;
		}

		// --- Intensity and Fades ---
		float fade_in = smoothstep(0.0, 0.2, time_diff);
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
	
	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	vec3  pixel_pos_world;
	float waterDist = 0.;
	float dEpsilon = 0.;
	float angle = 0.;
	float angleDelta = 3.14 / 3.;
	for (int i = 0; i < 8; i++) {
		float depth = textureLod(depth_texture, SCREEN_UV + vec2(0.5*dEpsilon*sin(angle),dEpsilon*(-2.+cos(angle))), 0.0).r;;
		depth = depth * 2.0 - 1.0;
		vec4 upos = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, depth, 1.0);
		vec3 pixel_position = upos.xyz / upos.w;
		vec3 pixel_pos_world_local = (INV_VIEW_MATRIX * vec4(pixel_position, 1.0)).xyz;
		if (i == 0) {
			pixel_pos_world = pixel_pos_world_local;
		}
		waterDist += length(vertex_world - pixel_pos_world_local) * 0.1;
		dEpsilon += 0.0005 * (1.-depth);
		angle += angleDelta;
	}

	vec4 distorsion = texture(foam_noise, vertex_world.xz * 0.5) * clamp(1. - waterDist * 0.02, 0.3, 1.) * 0.7;
	distorsion *= mix(1.0, 1.5 * texture(foam_noise, vertex_world.xz * 0.01).x, 1.0);
	//worldNormal -= distorsion.xyz;
	worldNormal = normalize(worldNormal);
	NORMAL = normalize((VIEW_MATRIX * vec4(worldNormal, 0.0)).xyz);

	vec3 cameraDirection = normalize(pixel_pos_world - CAMERA_POSITION_WORLD);
	float reflectionFactor = 1.0 - dot(-cameraDirection, worldNormal) * -cameraDirection.y;
	reflectionFactor = mix(1.0, reflectionFactor, 0.7);
	ALBEDO += clamp(1. - waterDist * 0.1, 0.0, 0.3);

	ALBEDO += clamp(pow((visual_height(vertex_world.xz) + gameplay_height(vertex_world.xz) * 0.45 + texture(foam_noise, vertex_world.zx * 0.01).x) * worldNormal.y * 0.6, 4.), 0.0, 1.0);

	float t = clamp(pow(waterDist * 0.5, 2.0), 0.0, 1.0);
	ALBEDO = mix(ALBEDO + reflectionFactor, ALBEDO, t);
	ALPHA = mix(0.1, 1.0, t) * reflectionFactor;
	ALPHA -= pow(clamp(1. - waterDist * 0.05, 0.0, 1.0) * distorsion.y, 2.0);
	
	// The function call is renamed for clarity, now using its own data.
	float foam_intensity = get_foam_effect(vertex_world.xz);
	ALBEDO += vec3(foam_intensity * 0.8);
}