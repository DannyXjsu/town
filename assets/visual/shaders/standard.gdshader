shader_type spatial;
#include "tools.gdshaderinc"

#define FILTER_NEAREST

group_uniforms Texturing;
uniform vec3 albedo : source_color;
#ifdef FILTER_NEAREST
uniform sampler2D texture_sample : filter_nearest_mipmap;
uniform sampler2D normal_map_sample : filter_nearest_mipmap;
#else
uniform sampler2D texture_sample : filter_linear_mipmap;
uniform sampler2D normal_map_sample : filter_linear_mipmap;
#endif
uniform float texture_repeat : hint_range(0.0, 64.0, 0.1) = 1.0;
uniform float normal_map_depth : hint_range(0.0, 8.0, 0.1) = 1.0;
//uniform float normal_map_repeat : hint_range(0.0, 5.0, 0.1) = 1.0;

// TRIPLANAR
// Stolen from godot's standard shader stuff
group_uniforms Texturing.Triplanar;
uniform bool triplanar = false;
varying vec3 triplanar_power_normal;
varying vec3 triplanar_pos;
uniform float triplanar_blend_sharpness : hint_range(0.0, 64.0, 0.1)= 16.0;
vec4 triplanar_texture(sampler2D p_sampler,vec3 p_weights,vec3 p_triplanar_pos) {
	vec4 samp=vec4(0.0);
	samp+= texture(p_sampler,p_triplanar_pos.xy) * p_weights.z;
	samp+= texture(p_sampler,p_triplanar_pos.xz) * p_weights.y;
	samp+= texture(p_sampler,p_triplanar_pos.zy * vec2(-1.0,1.0)) * p_weights.x;
	return samp;
}

void vertex() {
vec3 normal = MODEL_NORMAL_MATRIX * NORMAL;
	TANGENT = vec3(0.0,0.0,-1.0) * abs(normal.x);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.y);
	TANGENT+= vec3(1.0,0.0,0.0) * abs(normal.z);
	TANGENT = inverse(MODEL_NORMAL_MATRIX) * normalize(TANGENT);
	BINORMAL = vec3(0.0,1.0,0.0) * abs(normal.x);
	BINORMAL+= vec3(0.0,0.0,-1.0) * abs(normal.y);
	BINORMAL+= vec3(0.0,1.0,0.0) * abs(normal.z);
	BINORMAL = inverse(MODEL_NORMAL_MATRIX) * normalize(BINORMAL);
	triplanar_power_normal=pow(abs(normal),vec3(triplanar_blend_sharpness));
	triplanar_pos = (MODEL_MATRIX * vec4(VERTEX, 1.0f)).xyz * texture_repeat;
	triplanar_power_normal/=dot(triplanar_power_normal,vec3(1.0));
	triplanar_pos *= vec3(1.0,-1.0, 1.0);
}

void fragment() {
	vec3 albedo_tex = texture(texture_sample, UV * texture_repeat).rgb;
	vec3 normal_map_tex = texture(normal_map_sample, UV).rgb;
	
	if(triplanar){
		vec4 albedo_tex = triplanar_texture(texture_sample,triplanar_power_normal,triplanar_pos);
		ALBEDO = albedo.rgb * albedo_tex.rgb;
	}
	else
		ALBEDO = albedo * albedo_tex;
	if(normal_map_tex != vec3(1.0)){
		if(triplanar){
			vec4 normal_map_tri = triplanar_texture(normal_map_sample,triplanar_power_normal,triplanar_pos);
			NORMAL_MAP = normal_map_tri.rgb;
			NORMAL_MAP_DEPTH = normal_map_depth;
		}
		else{
			NORMAL_MAP = normal_map_tex;
			NORMAL_MAP_DEPTH = normal_map_depth;
		}
		
	}
}

void light() {
	float lambert;
	float blinn_phong_specular = 0.0;
	
	if(!valve_half_diffuse)
		// Standard Lambert diffusion
		lambert = max(dot(NORMAL,LIGHT),0.0);
	else
		// Valve's Lambert diffusion
		lambert = max(dot(NORMAL,LIGHT) * 0.5 + 0.5,0.0);
	
	// Blinn Phong specular
	if (lambert > 0.0 && specular){
		// half direction
		vec3 blinn_phong_halfv = normalize(LIGHT+VIEW);
		// specular angle
		float blinn_phong_specAng = max(dot(blinn_phong_halfv, NORMAL), 0.0);
		// specular value
		blinn_phong_specular = pow(blinn_phong_specAng,max(specular_effect, SPECULAR_AMOUNT));

		blinn_phong_specular *= smoothstep(0.0, blinn_phong_specular, lambert);
	}
	DIFFUSE_LIGHT += lambert * LIGHT_COLOR/PI * ATTENUATION;
	SPECULAR_LIGHT += max(blinn_phong_specular * LIGHT_COLOR/PI * fresnel(VIEW,NORMAL,fresnel_power) * ATTENUATION,0.0) * specular_intensity;
}
