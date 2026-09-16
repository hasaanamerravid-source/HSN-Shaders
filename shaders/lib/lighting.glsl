#ifndef HSN_LIGHTING_GLSL
#define HSN_LIGHTING_GLSL

// Lighting adapted from Miniature Shader (MIT, Mateus A. Kreuch)
// https://github.com/mateuskreuch/minecraft-miniature-shader

#include "/lib/shadows.glsl"

float hsnLuma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

vec3 hsnLight(vec3 albedo, vec2 lmcoord, vec3 normal, vec4 shadowPos, vec3 lightDir, vec3 sunPos, vec3 up) {
	vec2 lm = clamp(lmcoord, 0.0, 1.0);
	vec3 ambient = texture2D(lightmap, lm).rgb;

	float x = ambient.g;
	float boost = (((0.8494 * x + 0.9687) * x - 5.238) * x + 3.711) * x - 0.2864;
	boost = max(boost, 0.0);

	float slen = max(length(sunPos), 0.001);
	float sunH = dot(sunPos / slen, normalize(up));
	ambient = min(vec3(1.0), ambient + vec3(boost) * clamp(0.2 * sunH, 0.0, 1.0));

	float vis = sampleShadow(shadowPos);
	float ndotl = clamp(dot(normalize(normal), normalize(lightDir)), 0.0, 1.0);
	vis *= mix(0.35, 1.0, ndotl);

	vec3 shadowCol = vec3(SHADOW_BRIGHTNESS) + vec3(0.0, 0.22, 0.55) * 0.18;
	ambient *= mix(shadowCol, vec3(1.0), vis);

	float albedoLuma = hsnLuma(albedo);
	float lightBrightness = max(0.0, 0.90 - 0.5 * albedoLuma * albedoLuma * albedoLuma);
	vec3 lightColor;
	if (sunH > 0.01) {
		float sunRedness = 1.0 - clamp(0.2 * sunH, 0.0, 1.0);
		lightColor = normalize(vec3(1.0 + clamp(sunRedness, 0.12, 1.0), 1.06, 1.0));
	} else {
		lightColor = vec3(0.10, 0.15, 0.30);
	}
	lightColor = mix(vec3(hsnLuma(lightColor)), lightColor, lm.y);
	ambient *= 0.75 + lightBrightness * vis * lightColor;

	float torchStr = lm.x * lm.x;
	vec3 torch = max(0.0, 1.0 - hsnLuma(ambient)) * torchStr
		* mix(vec3(1.00, 0.55, 0.20), vec3(1.00, 0.85, 0.70), torchStr);
	ambient += torch;

	return albedo * ambient;
}

#endif
