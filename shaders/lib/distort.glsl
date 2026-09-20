#ifndef SULFUR_DISTORT_GLSL
#define SULFUR_DISTORT_GLSL

#include "/lib/settings.glsl"

// Milder warp than 26.3.1 so nearby casters (the player) stay on the map.
// SHADOW_DISTORT_FACTOR is the unwarped core — higher = less pinch, fewer cut-off shadows.
float hsnDistortFactor(vec2 clipXY) {
	float core = max(SHADOW_DISTORT_FACTOR, 0.18);
	return length(clipXY) * (1.0 - core) + core;
}

vec3 distort(vec3 clip) {
	clip.xy /= hsnDistortFactor(clip.xy);
	// Do not crush Z the way 26.3.1 did (z *= 0.20). That clipped player shadows.
	clip.z *= 0.55;
	return clip;
}

vec4 hsnShadowCoord(vec4 playerPos, float lightDot) {
	vec4 clip = shadowProjection * (shadowModelView * playerPos);
	clip.xyz = distort(clip.xyz);
	clip.xyz = clip.xyz * 0.5 + 0.5;
	float texel = 1.0 / float(shadowMapResolution);
	// Slope-scaled bias WITHOUT dividing by ndotl.
	// The old `/ ndotl` exploded on block sides at noon and made shadows
	// tuck in and out as you walked.
	float slope = 1.0 - clamp(lightDot, 0.0, 1.0);
	clip.z -= texel * SHADOW_BIAS * (0.40 + slope * 1.25);
	return clip;
}

#endif
