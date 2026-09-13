#ifndef SULFUR_COMMON_GLSL
#define SULFUR_COMMON_GLSL

#include "/lib/settings.glsl"

vec3 sulfurWarmth(vec3 color, float amount) {
	vec3 warmMul = mix(vec3(1.0), vec3(1.06, 0.98, 0.88), amount);
	color *= warmMul;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float mid = smoothstep(0.15, 0.45, luma) * (1.0 - smoothstep(0.78, 0.96, luma));
	color += vec3(0.04, 0.015, -0.01) * amount * mid;
	return color;
}

vec3 sulfurSaturation(vec3 color, float sat) {
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	return mix(vec3(luma), color, sat);
}

vec3 sulfurContrast(vec3 color, float contrast) {
	return clamp((color - 0.5) * contrast + 0.5, 0.0, 1.5);
}

#endif
