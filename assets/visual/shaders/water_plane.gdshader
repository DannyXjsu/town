shader_type spatial;
#include "tools.gdshaderinc"

uniform sampler2D world_texture : source_color;
uniform sampler2D screen_texture : source_color, hint_screen_texture;
uniform sampler2D depth_texture : source_color, hint_depth_texture;

group_uniforms Color;
uniform vec3 albedo : source_color;
uniform sampler2D wave_noise;
uniform sampler2D wave_noise_2;
uniform float texture_repeat : hint_range(0.0, 64.0, 0.1) = 1.0;

group_uniforms Waves;
uniform float wave_speed : hint_range(0.0, 8.0, 0.1) = 1.0;
uniform vec2 wave_direction = vec2(0.005,0.009);
uniform vec2 wave2_direction = vec2(0.005,0.009);

group_uniforms Triplanar;
uniform bool triplanar = false;

uniform float normal_map_depth : hint_range(0.0, 8.0, 0.1) = 1.0;
//uniform float normal_map_repeat : hint_range(0.0, 5.0, 0.1) = 1.0;


varying vec4 radiance;
varying vec4 irradiance;

void vertex() {
	
}

void fragment() {
	vec3 world = texture(world_texture, vec2(SCREEN_UV.x,-SCREEN_UV.y)).rgb;
	vec3 screen = textureLod(screen_texture, vec2(SCREEN_UV.x,-SCREEN_UV.y),2.0).rgb;
	float depth = texture(depth_texture, SCREEN_UV).x;
	
	vec3 wave_noise_tex = texture(wave_noise,vec2(UV.x+wave_direction.x*TIME*wave_speed,UV.y+wave_direction.y*TIME*wave_speed)).rgb;
	vec3 wave_noise_tex2 = texture(wave_noise_2,vec2(UV.x+wave2_direction.x*TIME*wave_speed,UV.y+wave2_direction.y*TIME*wave_speed)).rgb;
	
	ALBEDO = albedo;
	NORMAL_MAP = wave_noise_tex*wave_noise_tex2;
	RADIANCE;
	IRRADIANCE;
	radiance = RADIANCE;
	irradiance = IRRADIANCE;
}

void light() {
	float scatter;
	float blinn_phong_specular = 0.0;
	
	scatter = 0.3 / 1.0 * dot(VIEW, LIGHT);
	
	DIFFUSE_LIGHT += scatter * LIGHT_COLOR/PI * ATTENUATION;
	//SPECULAR_LIGHT += max(blinn_phong_specular * LIGHT_COLOR/PI * fresnel(VIEW,NORMAL,fresnel_power) * ATTENUATION,0.0) * specular_intensity;
	//ALPHA = scatter * ATTENUATION;
}