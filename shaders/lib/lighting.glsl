#ifndef HSN_LIGHTING_GLSL
#define HSN_LIGHTING_GLSL

// Lighting adapted from Miniature Shader (MIT, Mateus A. Kreuch)
// https://github.com/mateuskreuch/minecraft-miniature-shader

#include "/lib/shadows.glsl"

float hsnLuma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float hsnFoliageKeep(vec3 albedo) {
	float g = albedo.g - max(albedo.r, albedo.b);
	return clamp(g * 5.5, 0.0, 1.0);
}

vec3 hsnLight(vec3 albedo, vec2 lmcoord, vec3 normal, vec4 shadowPos, vec3 lightDir, vec3 sunPos, vec3 up) {
	vec2 lm = clamp(lmcoord, 0.0, 1.0);
	vec3 ambient = texture2D(lightmap, lm).rgb;

	float x = ambient.g;
	float boost = (((0.8494 * x + 0.9687) * x - 5.238) * x + 3.711) * x - 0.2864;
	boost = max(boost, 0.0);

	float slen = max(length(sunPos), 0.001);
	float sunH = dot(sunPos / slen, normalize(up));
	float night = 1.0 - smoothstep(-0.06, 0.18, sunH);
	float dusk = (1.0 - smoothstep(0.08, 0.40, sunH)) * (1.0 - night);
	ambient = min(vec3(1.0), ambient + vec3(boost) * clamp(0.2 * sunH, 0.0, 1.0));

	float ndotl = clamp(dot(normalize(normal), normalize(lightDir)), 0.0, 1.0);
	float vis = sampleShadow(shadowPos);
	if (vis < 0.0) {
		vis = mix(0.28, 0.82, ndotl);
	} else {
		vis *= mix(0.32, 1.0, ndotl);
	}
	// Never crush entities / players to a black silhouette in their own shadow.
	vis = max(vis, 0.12 + lm.y * 0.10);

	vec3 shadowCol = vec3(SHADOW_BRIGHTNESS) * mix(vec3(1.00, 0.98, 0.94), vec3(0.90, 0.93, 0.98), night);
	ambient *= mix(shadowCol, vec3(1.0), vis);

	float albedoLuma = hsnLuma(albedo);
	float lightBrightness = max(0.0, 0.92 - 0.45 * albedoLuma * albedoLuma * albedoLuma);
	vec3 lightColor;
	if (sunH > 0.01) {
		float sunRedness = 1.0 - clamp(0.2 * sunH, 0.0, 1.0);
		lightColor = normalize(vec3(1.0 + clamp(sunRedness, 0.12, 1.0), 1.06, 1.0));
	} else {
		// Visible moonlight without turning grass teal.
		lightColor = vec3(0.40, 0.44, 0.50);
	}
	lightColor = mix(vec3(hsnLuma(lightColor)), lightColor, lm.y);

	// Fill light so shadowed faces and player skin stay readable.
	float fill = mix(0.38, 0.12, vis) * (0.35 + lm.y * 0.65);
	ambient *= 0.80 + lightBrightness * (vis * lightColor + fill);

	float plant = hsnFoliageKeep(albedo);
	ambient = mix(ambient, ambient * vec3(1.03, 1.06, 0.92), plant * night * 0.75);

	float torchStr = lm.x * lm.x;
	vec3 torchCol = mix(vec3(1.00, 0.38, 0.10), vec3(1.00, 0.68, 0.32), torchStr);
	vec3 torch = torchStr * torchCol * (0.60 + max(0.0, 1.15 - hsnLuma(ambient)));
	ambient += torch;
	ambient = mix(ambient, ambient * vec3(1.08, 0.78, 0.42), torchStr * 0.35);

	// Night / dusk floor so the world and skins do not fade to black.
	ambient = max(ambient, vec3(0.045 + 0.06 * lm.y) * mix(1.0, 1.8, night + dusk * 0.4));

	return albedo * ambient;
}

#endif
