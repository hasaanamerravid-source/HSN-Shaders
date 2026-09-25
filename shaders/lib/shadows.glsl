#ifndef SULFUR_SHADOWS_GLSL
#define SULFUR_SHADOWS_GLSL

#include "/lib/settings.glsl"

uniform sampler2D shadowtex0;

float hsnHash(vec2 p) {
	return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453);
}

float shadowHit(vec3 pos) {
	if (pos.xy != clamp(pos.xy, 0.002, 0.998)) return -1.0;
	return float(texture2D(shadowtex0, pos.xy).r >= pos.z);
}

vec2 hsnVogel(int i, int n, float rot) {
	float r = sqrt((float(i) + 0.5) / float(n));
	float a = float(i) * 2.399963229728653 + rot;
	return vec2(cos(a), sin(a)) * r;
}

float sampleShadow(vec4 shadowPos) {
#if SHADOW_QUALITY < 0
	return 1.0;
#else
	if (shadowPos.w <= 0.0) return 0.0;
	vec3 pos = shadowPos.xyz;
	float s = 1.0 / float(shadowMapResolution);

	// Fade out instead of snapping to full sun at the map edge.
	float edge = min(min(pos.x, pos.y), min(1.0 - pos.x, 1.0 - pos.y));
	float inMap = smoothstep(0.00, 0.06, edge);

#if SHADOW_QUALITY == 0
	float hit = shadowHit(pos);
	if (hit < 0.0) return -1.0;
	return mix(-1.0, hit, inMap);
#else
	// Soft: per-pixel rotated Vogel disk (not a static 3x3 grid).
	float rot = hsnHash(pos.xy * float(shadowMapResolution)) * 6.2831853;
	s *= 1.35;
	float v = 0.0;
	float used = 0.0;
	const int TAPS = 12;
	for (int i = 0; i < TAPS; i++) {
		vec2 off = hsnVogel(i, TAPS, rot) * s * 2.15;
		float h = shadowHit(pos + vec3(off, 0.0));
		if (h >= 0.0) {
			v += h;
			used += 1.0;
		}
	}
	if (used < 0.5) return -1.0;
	return mix(-1.0, v / used, inMap);
#endif
#endif
}

vec3 applyShadowLighting(vec3 color, sampler2D lightmap, vec2 lmcoord, vec4 shadowPos) {
	float vis = sampleShadow(shadowPos);
	if (vis < 0.0) vis = 1.0;
	vec2 lm = lmcoord;
	lm.y *= mix(0.55, 1.0, vis);
	color *= texture2D(lightmap, lm).rgb;
	return color;
}

#endif
