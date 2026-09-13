#ifndef SULFUR_SHADOWS_GLSL
#define SULFUR_SHADOWS_GLSL

#include "/lib/settings.glsl"

uniform sampler2D shadowtex0;

float shadowHit(vec3 pos) {
	if (pos.xy != clamp(pos.xy, 0.0, 1.0)) return 1.0;
	return float(texture2D(shadowtex0, pos.xy).r >= pos.z);
}

float sampleShadow(vec4 shadowPos) {
#if SHADOW_QUALITY < 0
	return 1.0;
#else
	if (shadowPos.w <= 0.0) return 0.0;
	vec3 pos = shadowPos.xyz;
	float s = 1.0 / float(shadowMapResolution);
#if SHADOW_QUALITY == 0
	return shadowHit(pos);
#else
	s *= 0.70;
	float v = 0.0;
	v += shadowHit(pos);
	v += shadowHit(pos + vec3(-s,  0.0, 0.0));
	v += shadowHit(pos + vec3( s,  0.0, 0.0));
	v += shadowHit(pos + vec3( 0.0,-s, 0.0));
	v += shadowHit(pos + vec3( 0.0, s, 0.0));
	v += shadowHit(pos + vec3(-s, -s, 0.0));
	v += shadowHit(pos + vec3( s, -s, 0.0));
	v += shadowHit(pos + vec3(-s,  s, 0.0));
	v += shadowHit(pos + vec3( s,  s, 0.0));
	return v / 9.0;
#endif
#endif
}

vec3 applyShadowLighting(vec3 color, sampler2D lightmap, vec2 lmcoord, vec4 shadowPos) {
	float vis = sampleShadow(shadowPos);
	vec2 lm = lmcoord;
	lm.y *= mix(0.55, 1.0, vis);
	color *= texture2D(lightmap, lm).rgb;
	return color;
}

#endif
