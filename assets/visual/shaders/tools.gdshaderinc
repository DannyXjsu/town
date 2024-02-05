// Lighting
group_uniforms Lighting;
uniform bool valve_half_diffuse = true;
uniform bool specular = true;
uniform float specular_effect : hint_range(0.0, 16.0, 0.1)= 16.0;
uniform float specular_intensity : hint_range(0.0, 8.0, 0.1)= 1.0;
uniform float fresnel_power : hint_range(0.0, 8.0, 0.1) = 5.0;


// Schlick Fresnel
float fresnel(vec3 view_vec, vec3 normal_vec, float power){
	return pow(1.0 - dot(view_vec, normal_vec),power);
}

// Blend colors
vec3 additive(vec3 base, vec3 blend){
	return base + blend;
}
vec3 multiply(vec3 base, vec3 blend){
	return base * blend;
}
vec3 darken(vec3 base, vec3 blend){
	return min(base, blend);
}
vec3 lighten(vec3 base, vec3 blend){
	return max(base, blend);
}
vec3 difference(vec3 base, vec3 blend){
	return abs(base - blend);
}
vec3 exclusion(vec3 base, vec3 blend){
	return base + blend - 2.0 * base * blend;
}
vec3 overlay(vec3 base, vec3 blend){
	vec3 limit = step(0.5, base);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec3 hard_light(vec3 base, vec3 blend){
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend, 1.0 - 2.0 * (1.0 - base) * (1.0 - blend), limit);
}
vec3 soft_light(vec3 base, vec3 blend){
	vec3 limit = step(0.5, blend);
	return mix(2.0 * base * blend + base * base * (1.0 - 2.0 * blend), sqrt(base) * (2.0 * blend - 1.0) + (2.0 * base) * (1.0 - blend), limit);
}
vec3 color_dodge(vec3 base, vec3 blend){
	return base / (1.0 - blend);
}
vec3 linear_dodge(vec3 base, vec3 blend){
	return base + blend;
}
vec3 color_burn(vec3 base, vec3 blend){
	return 1.0 - (1.0 - base) / blend;
}
vec3 linear_burn (vec3 base, vec3 blend)
{
	return base + blend - 1.0;
}