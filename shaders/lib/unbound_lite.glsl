#ifndef HSN_UNBOUND_LITE_GLSL
#define HSN_UNBOUND_LITE_GLSL

#include "/lib/atmosphere.glsl"

vec3 hsnSunLightColor(float sunH, float rain) {
	float noon = smoothstep(0.15, 0.55, sunH);
	float sunset = (1.0 - noon) * smoothstep(-0.05, 0.18, sunH);
	vec3 noonC = vec3(1.05, 0.96, 0.82);
	vec3 duskC = vec3(1.15, 0.62, 0.32);
	vec3 moonC = vec3(0.26, 0.28, 0.32);
	vec3 c = mix(moonC, mix(duskC, noonC, noon), sunset + noon);
	c = mix(c, vec3(0.55, 0.58, 0.62), rain * 0.45);
	return c;
}

vec3 hsnAmbientColor(float sunH, vec3 skyColor, float rain) {
	float day = smoothstep(-0.10, 0.22, sunH);
	vec3 dayAmb = pow(max(skyColor, vec3(0.02)), vec3(0.75)) * vec3(0.90, 0.93, 1.00);
	vec3 nightAmb = vec3(0.08, 0.085, 0.095);
	vec3 amb = mix(nightAmb, dayAmb, day);
	amb = mix(amb, vec3(0.16, 0.18, 0.22), rain * 0.35);
	return amb;
}

vec3 hsnAtmFogColor(float sunH, float lookSun, vec3 skyColor, vec3 fogColor, float rain) {
	float day = smoothstep(-0.10, 0.22, sunH);
	// Bliss-like: night fog is a dim warm-gray, day mixes vanilla fog with a hazy blue.
	vec3 nightFog = vec3(0.062, 0.058, 0.066);
	vec3 dayFog = mix(fogColor, mix(skyColor, vec3(0.62, 0.76, 0.92), 0.40), 0.55);
	vec3 duskFog = vec3(0.42, 0.22, 0.12);
	float dusk = (1.0 - smoothstep(0.12, 0.45, sunH)) * day;
	vec3 c = mix(nightFog, dayFog, day);
	c = mix(c, duskFog, dusk * 0.55);
	c = mix(c, c * vec3(0.78, 0.80, 0.84), rain * 0.55);
	c *= 0.82 + 0.18 * lookSun * day;
	return c;
}

// Height + distance fog inspired by Bliss overworld_fog.glsl
// (gradientFog / rainyFog ideas, without Bliss's raymarch + extra uniforms).
vec3 hsnApplyUnbound(vec3 color, vec3 viewPos, float depth, vec3 sunP, vec3 up, vec3 skyColor, vec3 fogColor, float rain, float farPlane, vec3 worldPos) {
	float sunH = sulfurSunHeight(sunP, up);
	float day = sulfurDayFactor(sunP, up);
	vec3 vdir = normalize(viewPos);
	float lookSun = max(dot(vdir, normalize(sunP)), 0.0);
	float dist = length(viewPos);
	bool sky = depth <= 0.00015 || depth >= 0.99985;

	vec3 light = hsnSunLightColor(sunH, rain);
	vec3 amb = hsnAmbientColor(sunH, skyColor, rain);
	color *= mix(vec3(1.0), mix(amb, light, 0.22 * day), 0.10);

	float range = max(farPlane, 96.0);
	float viewDist = sky ? range * 1.05 : min(dist, range);

	// Bliss-style height falloff: denser near sea level / looking through low air.
	float heightAbove = max(worldPos.y - 62.0, 0.0);
	float lowGradient  = exp2(-0.28 * heightAbove);
	float midGradient  = exp2(-0.12 * heightAbove);
	float highGradient = exp2(-0.05 * heightAbove);
	float heightFog = mix(midGradient, lowGradient, 0.55);
	heightFog = mix(heightFog, highGradient, clamp((heightAbove - 40.0) / 80.0, 0.0, 1.0) * 0.35);

	float horizon = 1.0 - clamp(dot(vdir, up), 0.0, 1.0);
	horizon = pow(horizon, 1.35);

	float dens = mix(0.0115, 0.0038, day) * FOG_DENSITY * FOG_STRENGTH;
	dens *= mix(max(NIGHT_FOG, 0.70), 1.0, day);
	dens *= 1.0 + rain * 1.10;
	dens *= mix(0.70, 1.25, heightFog);
	dens *= mix(0.85, 1.20, horizon);

	float start = mix(4.0, 12.0, day);
	float optical = max(viewDist - start, 0.0) * dens;
	float fog = 1.0 - exp(-optical);

	// Rainy ground fog extra (Bliss rainyFog idea).
	fog = max(fog, (1.0 - exp(-viewDist * 0.0045 * rain)) * midGradient * rain * 0.65);

	if (sky) {
		fog = max(fog, horizon * mix(0.50, 0.28, day) * FOG_STRENGTH * FOG_DENSITY);
	}

	float cap = mix(0.94, 0.68, day);
	fog = clamp(fog, 0.0, cap);

	vec3 fcol = hsnAtmFogColor(sunH, lookSun, skyColor, fogColor, rain);
	// Horizon warms a touch at night so it does not read as blue haze on grass.
	fcol = mix(fcol, mix(fcol, vec3(0.085, 0.070, 0.060), 0.35), (1.0 - day) * horizon);
	color = mix(color, fcol, fog);
	return color;
}

#endif
