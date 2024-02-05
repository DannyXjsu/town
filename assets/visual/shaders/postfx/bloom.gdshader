shader_type spatial;
render_mode unshaded,depth_draw_never;
#include "res://assets/visual/shaders/tools.gdshaderinc"

group_uniforms Bloom;
uniform sampler2D screen_texture : source_color, filter_linear_mipmap_anisotropic;

uniform float downsample : hint_range(0.1, 8.0, 0.01) = 1.0;
uniform float affect : hint_range(0.1, 4.0, 0.01) = 1.0;
uniform float strength : hint_range(0.1, 4.0, 0.01) = 1.0;
uniform float opacity : hint_range(0.0, 1.0, 0.01) = 1.0;


void vertex() {
	POSITION = vec4(VERTEX, 1.0);
	POSITION.z += 0.1;
}

void fragment() {
	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
	vec3 screen_lod = textureLod(screen_texture, SCREEN_UV + vec2(0.0 * downsample, 0.0075*downsample*0.40), downsample).rgb;
	
	vec3 bloom_rgb_lin = pow(screen_lod, vec3(affect));
	float luminance = 0.2126 * bloom_rgb_lin.r + 0.7152 * bloom_rgb_lin.g + 0.0722 * bloom_rgb_lin.b;
	
	vec3 output = multiply(screen,vec3(luminance*strength));
	ALBEDO = clamp(output,0.0,1.0);
	//ALBEDO = vec3(luminance*strength);
	ALPHA = opacity;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
