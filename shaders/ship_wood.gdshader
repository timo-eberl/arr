// NOTE: Shader automatically converted from Godot Engine 4.5.1.stable's StandardMaterial3D.

shader_type spatial;
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

instance uniform float destruction : hint_range(0.0, 1.0, 0.01);

instance uniform vec3 hole_position_0;
instance uniform vec3 hole_direction_0;
instance uniform vec3 hole_position_1;
instance uniform vec3 hole_direction_1;
instance uniform vec3 hole_position_2;
instance uniform vec3 hole_direction_2;

uniform vec4 albedo : source_color;
uniform sampler2D texture_albedo : source_color, filter_linear_mipmap, repeat_enable;
uniform ivec2 albedo_texture_size;
uniform float point_size : hint_range(0.1, 128.0, 0.1);

uniform float roughness : hint_range(0.0, 1.0);
uniform sampler2D texture_metallic : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 metallic_texture_channel;
uniform sampler2D texture_roughness : hint_roughness_r, filter_linear_mipmap, repeat_enable;

uniform float specular : hint_range(0.0, 1.0, 0.01);
uniform float metallic : hint_range(0.0, 1.0, 0.01);

uniform vec3 uv1_scale;
uniform vec3 uv1_offset;
uniform vec3 uv2_scale;
uniform vec3 uv2_offset;

varying vec3 local_pos;

void vertex() {
	local_pos = VERTEX;
	UV = UV * uv1_scale.xy + uv1_offset.xy;
}

// p: the point (local_pos)
// a: a point on the line (hole_position_0)
// b: the direction vector of the line (hole_direction_0)
float distance_to_line(vec3 p, vec3 a, vec3 b) {
  vec3 ap = p - a;
  return length(cross(ap, b)) / length(b);
}

void fragment() {
	vec2 base_uv = UV;

	vec4 albedo_tex = texture(texture_albedo, base_uv);
	ALBEDO = albedo.rgb * albedo_tex.rgb;

	float metallic_tex = dot(texture(texture_metallic, base_uv), metallic_texture_channel);
	METALLIC = metallic_tex * metallic;
	SPECULAR = specular;

	vec4 roughness_texture_channel = vec4(1.0, 0.0, 0.0, 0.0);
	float roughness_tex = dot(texture(texture_roughness, base_uv), roughness_texture_channel);
	ROUGHNESS = roughness_tex * roughness;

	ALBEDO *= (1.0 - destruction * 0.4);

	float darkening = 1.0;
	{
		float d = distance_to_line(local_pos, hole_position_0, hole_direction_0);
		darkening *= clamp(d*0.08, 0.0, 1.0);
	}
	{
		float d = distance_to_line(local_pos, hole_position_1, hole_direction_1);
		darkening *= clamp(d*0.08, 0.0, 1.0);
	}
	{
		float d = distance_to_line(local_pos, hole_position_2, hole_direction_2);
		darkening *= clamp(d*0.08, 0.0, 1.0);
	}

	ALBEDO *= darkening;
}
