#ifndef HSN_VOLUMETRIC_GLSL
#define HSN_VOLUMETRIC_GLSL

// Original HSN implementation of shadow-map volumetric lighting.
// Same *idea* as BSL / Sildur shafts (raymarch the sun shadow map),
// written from scratch — not a copy of either pack.

#include "/lib/settings.glsl"
#include "/lib/distort.glsl"

vec3 hsnWorldToShadow(vec3 playerPos) {
	vec4 sp = shadowProjection * (shadowModelView * vec4(playerPos, 1.0));
	sp.xyz = distort(sp.xyz);
	return sp.xyz * 0.5 + 0.5;
}

float hsnShadowAt(vec3 shadowPos) {
	if (shadowPos.xy != clamp(shadowPos.xy, 0.002, 0.998)) return 1.0;
	return step(shadowPos.z - 0.0006, texture2D(shadowtex0, shadowPos.xy).r);
}

vec3 hsnVolumetricLight(vec3 viewPos, bool sky, vec2 uv) {
#ifndef VOLUMETRIC_LIGHTING
	return vec3(0.0);
#else
	if (VL_STRENGTH <= 0.001) return vec3(0.0);
	float slen = length(sunPosition);
	if (slen < 0.001) return vec3(0.0);
	vec3 sunWorld = mat3(gbufferModelViewInverse) * (sunPosition / slen);
	float sunH = sunWorld.y;
	if (sunH < 0.02) return vec3(0.0);

	vec3 endView = sky ? normalize(viewPos) * 140.0 : viewPos;
	vec3 startPlayer = (gbufferModelViewInverse * vec4(endView * 0.02, 1.0)).xyz;
	vec3 endPlayer = (gbufferModelViewInverse * vec4(endView, 1.0)).xyz;

	int steps = int(VL_STEPS);
	steps = max(steps, 4);
	vec3 stepP = (endPlayer - startPlayer) / float(steps);
	float stepLen = length(stepP);
	vec3 pos = startPlayer + stepP * (fract(sin(dot(uv, vec2(12.9898, 78.233))) * 43758.5453));

	float acc = 0.0;
	for (int i = 0; i < 16; i++) {
		if (i >= steps) break;
		acc += hsnShadowAt(hsnWorldToShadow(pos));
		pos += stepP;
	}
	acc /= float(steps);

	float lookSun = max(dot(normalize(viewPos), normalize(sunPosition)), 0.0);
	float phase = 0.55 + 0.45 * pow(lookSun, 8.0);
	float heightFade = smoothstep(0.02, 0.18, sunH);
	vec3 rayCol = mix(vec3(1.00, 0.82, 0.52), fogColor, 0.18);
	return rayCol * acc * phase * heightFade * stepLen * 0.012 * VL_STRENGTH * (1.0 - rainStrength * 0.75);
#endif
}

#endif
