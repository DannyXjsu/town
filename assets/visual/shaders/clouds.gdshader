shader_type spatial;
//render_mode cull_disabled;

uniform int _ShellIndex = 0; // This is the current shell layer being operated on, it ranges from 0 -> _ShellCount 
uniform int _ShellCount = 16; // This is the total number of shells, useful for normalizing the shell index
uniform float _ShellLength = 0.15; // This is the amount of distance that the shells cover, if this is 1 then the shells will span across 1 world space unit
uniform float _Density = 100.0;  // This is the density of the strands, used for initializing the noise
uniform float _NoiseMin = 0.0;
uniform float _NoiseMax = 1.0; // This is the range of possible hair lengths, which the hash then interpolates between 
uniform float _Thickness = 1.0; // This is the thickness of the hair strand
uniform float _Attenuation = 1.0; // This is the exponent on the shell height for lighting calculations to fake ambient occlusion (the lack of ambient light)
uniform float _OcclusionBias = 0.0; // This is an additive constant on the ambient occlusion in order to make the lighting less harsh and maybe kind of fake in-scattering
uniform float _ShellDistanceAttenuation = 1.0; // This is the exponent on determining how far to push the shell outwards, which biases shells downwards or upwards towards the minimum/maximum distance covered
//uniform float _Curvature; // This is the exponent on the physics displacement attenuation, a higher value controls how stiff the hair is
//uniform float _DisplacementStrength; // The strength of the displacement (very complicated)
uniform vec3 _ShellColor : source_color; // The color of the shells (very complicated)
//uniform vec3 _ShellDirection; // The direction the shells are going to point towards, this is updated by the CPU each frame based on user input/movement

float hash(uint n) {
    return float(n*(n^(n>>15u))) * (1.0/float(0xffffffffU));
}
float hash2(uint n) {
	// integer hash copied from Hugo Elias
	n = (n << 13U) ^ n;
	n = n * (n * n * 15731U + 0x789221U) + 0x13763125U;
	return float(n & uint(0x7fffffffU)) / float(0x7fffffff);
}

void vertex() {
	float shellHeight = float(_ShellIndex) / float(_ShellCount);
	shellHeight = pow(shellHeight, _ShellDistanceAttenuation);
	
	VERTEX += NORMAL * _ShellLength * shellHeight;
	
	//VERTEX += _ShellDirection;
}

float saturate(float value){
	return pow(value,1.0);;
}

float lerp(float a, float b, float t){
	return (1.0 - t) * a + t * b;
}

void fragment() {
	vec2 new_uv = UV * _Density;
	vec2 local_uv = fract(new_uv)* 2.0-1.0;
	float local_distace_from_center = length(local_uv);
	
	ivec2 tid = ivec2(new_uv);
	uint seed = uint(tid.x + 100 * tid.y + 100 * 10);
	
	float rand = mix(_NoiseMin, _NoiseMax, hash2(seed));
	
	float shellIndex = float(_ShellIndex);
	float shellCount = float(_ShellCount);
	float h = shellIndex / shellCount;
	
	int outsideThickness = int((local_distace_from_center) > (_Thickness * (rand - h)));
	
	// This culls the pixel if it is outside the thickness of the strand, it also ensures that the base shell is fully opaque that way there aren't
	// any real holes in the mesh, although there's certainly better ways to do that
	if (int(bool(outsideThickness) && bool(_ShellIndex)) > 0) discard;
	
	ALBEDO = clamp(_ShellColor,vec3(0.0,0.0,0.0),vec3(1.0,1.0,1.0));
	//ALPHA = 1.0;
}

void light() {
	float shellIndex = float(_ShellIndex);
	float shellCount = float(_ShellCount);
	float h = shellIndex / shellCount;
	float ambientOcclusion = pow(h, _Attenuation);
	ambientOcclusion += _OcclusionBias;
	ambientOcclusion = saturate(ambientOcclusion);
	
	float ndotl = clamp(dot(NORMAL, LIGHT.rgb) * 0.5 + 0.5,0.0, 1.0);
	ndotl = ndotl * ndotl;
	DIFFUSE_LIGHT += ndotl * ambientOcclusion;
}
