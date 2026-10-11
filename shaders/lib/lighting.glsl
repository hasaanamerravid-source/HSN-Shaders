#ifndef HSN_LIGHTING_GLSL
#define HSN_LIGHTING_GLSL

#include "/lib/shadows.glsl"

// True in the Nether (no sky, no sun). Plain lightmap lighting there.
uniform bool hasCeiling;

float hsnLuma(vec3 c) {
	return dot(c, vec3(0.2126, 0.7152, 0.0722));
}

float hsnFoliageKeep(vec3 albedo) {
	float g = albedo.g - max(albedo.r, albedo.b);
	return clamp(g * 5.5, 0.0, 1.0);
}

vec3 hsnEmission(vec3 albedo, float mat) {
	// Shared glow, different color per source. Dark texels stay dark (lantern frame).
	float warm = float(mat > 10149.5 && mat < 10150.5);
	float lava = float(mat > 10152.5 && mat < 10153.5);
	float portal = float(mat > 10153.5 && mat < 10154.5);
	float soul = float(mat > 10155.5 && mat < 10156.5);
	float on = max(max(warm, lava), max(portal, soul));
	if (on < 0.5) return vec3(0.0);
	float hot = max(max(albedo.r, albedo.g), albedo.b);
	hot = smoothstep(0.16, 0.62, hot);
	hot *= hot;
	vec3 col = vec3(1.00, 0.52, 0.14) * warm
	         + vec3(1.00, 0.38, 0.06) * lava
	         + vec3(0.62, 0.16, 0.95) * portal
	         + vec3(0.28, 0.70, 1.00) * soul;
	return col * hot * 1.45;
}

vec3 hsnLight(vec3 albedo, vec2 lmcoord, vec3 normal, vec4 shadowPos, vec3 lightDir, vec3 sunPos, vec3 up, float mat) {
	vec2 lm = clamp(lmcoord, 0.0, 1.0);
	vec3 ambient = texture2D(lightmap, lm).rgb;

	if (hasCeiling) {
		// Nether: the sun shadow and night math do not apply here.
		return albedo * ambient * 1.04 + hsnEmission(albedo, mat);
	}

	// Original skylight lift. Mid sky-light rises a little; caves and full noon stay put.
	float skyLit = clamp(ambient.g, 0.0, 1.0);
	float boost = smoothstep(0.20, 0.70, skyLit) * (1.0 - smoothstep(0.84, 1.0, skyLit)) * 0.20;

	float slen = max(length(sunPos), 0.001);
	float sunH = dot(sunPos / slen, normalize(up));
	float night = 1.0 - smoothstep(-0.06, 0.18, sunH);
	float dusk = (1.0 - smoothstep(0.08, 0.40, sunH)) * (1.0 - night);
	ambient = min(vec3(1.0), ambient + vec3(boost) * clamp(0.2 * sunH, 0.0, 1.0));

	float ndotl = clamp(dot(normalize(normal), normalize(lightDir)), 0.0, 1.0);
	float vis;
	if (night >= 0.999) {
		// True night: moon shadows are weak and a 512 map stripes them, so skip the
		// whole shadow lookup. This is the cheapest part of the night.
		vis = 0.86;
	} else {
		vec2 sh = sampleShadow2(shadowPos);
		float visMap = sh.x * mix(0.32, 1.0, ndotl);
		float visOut = mix(0.28, 0.82, ndotl);
		vis = mix(visOut, visMap, sh.y);
		// Dusk and dawn: fade the shadow strength so it matches the flat night.
		vis = mix(vis, mix(0.72, 1.0, vis), night);
	}
	// Never crush entities / players to a black silhouette in their own shadow.
	vis = max(vis, 0.12 + lm.y * 0.10);

	vec3 shadowCol = vec3(SHADOW_BRIGHTNESS) * mix(vec3(1.00, 0.98, 0.94), vec3(0.90, 0.93, 0.98), night);
	ambient *= mix(shadowCol, vec3(1.0), vis);

	float albedoLuma = hsnLuma(albedo);
	float lightBrightness = max(0.0, 0.92 - 0.45 * albedoLuma * albedoLuma * albedoLuma);
	float dayAmt = smoothstep(0.04, 0.48, sunH);
	vec3 noonLight = vec3(1.00, 0.97, 0.90);
	vec3 duskLight = vec3(1.05, 0.58, 0.30);
	vec3 moonLight = vec3(0.42, 0.46, 0.52);
	vec3 lightColor = mix(moonLight, mix(duskLight, noonLight, dayAmt), smoothstep(-0.04, 0.18, sunH));
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

	return albedo * ambient + hsnEmission(albedo, mat);
}

#endif
