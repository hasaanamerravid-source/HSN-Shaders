#ifndef SULFUR_DISTORT_GLSL
#define SULFUR_DISTORT_GLSL

#include "/lib/settings.glsl"

float hsnDistortFactor(vec2 clipXY) {
	return length(clipXY) * 0.85 + 0.15;
}

vec3 distort(vec3 clip) {
	clip.xy /= hsnDistortFactor(clip.xy);
	clip.z *= 0.20;
	return clip;
}

vec4 hsnShadowCoord(vec4 playerPos, float lightDot) {
	vec4 clip = shadowProjection * (shadowModelView * playerPos);
	clip.xyz = distort(clip.xyz);
	clip.xyz = clip.xyz * 0.5 + 0.5;
	float texel = 1.0 / float(shadowMapResolution);
	float ndotl = clamp(lightDot, 0.05, 1.0);
	clip.z -= texel * (0.55 * SHADOW_BIAS) / ndotl;
	return clip;
}

#endif
