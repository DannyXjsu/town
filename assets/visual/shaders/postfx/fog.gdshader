shader_type spatial;
render_mode unshaded,depth_draw_never;

varying mat4 CAMERA;

uniform sampler2D screen_texture : source_color, hint_screen_texture;
uniform sampler2D depth_texture : source_color, hint_depth_texture;

uniform vec3 fog_color : source_color;
uniform float fog_start : hint_range(0.0, 100.0, 0.1) = 1.0;
uniform float fog_end : hint_range(0.1, 10.0, 0.1) = 1.0;
uniform float fog_density : hint_range(0.1, 1.0, 0.01) = 1.0;
uniform float fog_intensity : hint_range(0.1, 1.0, 0.01) = 1.0;
uniform bool fog_affect_sky = false;

void vertex() {
	CAMERA = INV_VIEW_MATRIX;
	POSITION = vec4(VERTEX, 1.0);
}

void fragment() {
	vec3 screen = texture(screen_texture, SCREEN_UV).rgb;
	float depth = texture(depth_texture, SCREEN_UV).x;
	
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
	vec4 view = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	view.xyz /= view.w;
	float linear_depth = max(-view.z -fog_start, 0.0);
	
	float _fog_end = fog_end * 10.0;
	float fog = linear_depth / _fog_end;
	
	if(fog > _fog_end && !fog_affect_sky)
		discard;
	ALBEDO = screen + clamp(vec3(fog)*fog_color, 0.0, fog_intensity) * fog_density;
	ALPHA = 1.0;
}

//void light() {
	// Called for every pixel for every light affecting the material.
	// Uncomment to replace the default light processing function with this one.
//}
