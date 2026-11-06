#ifndef HSN_FOG_GLSL
#define HSN_FOG_GLSL

#include "/lib/atmosphere.glsl"

vec3 hsnSunLightColor(float sunH, float rain) {
	float noon = smoothstep(0.15, 0.55, sunH);
	float sunset = (1.0 - noon) * smoothstep(-0.05, 0.18, sunH);
	vec3 noonC = vec3(1.04, 0.96, 0.84);
	vec3 duskC = vec3(1.10, 0.64, 0.34);
	vec3 moonC = vec3(0.30, 0.32, 0.36);
	vec3 c = mix(moonC, mix(duskC, noonC, noon), sunset + noon);
	c = mix(c, vec3(0.58, 0.60, 0.64), rain * 0.40);
	return c;
}

vec3 hsnAmbientColor(float sunH, vec3 skyColor, float rain) {
	float day = smoothstep(-0.10, 0.22, sunH);
	vec3 dayAmb = pow(max(skyColor, vec3(0.02)), vec3(0.80)) * vec3(0.94, 0.96, 1.00);
	vec3 nightAmb = vec3(0.09, 0.095, 0.10);
	vec3 amb = mix(nightAmb, dayAmb, day);
	amb = mix(amb, vec3(0.18, 0.19, 0.21), rain * 0.30);
	return amb;
}

vec3 hsnApplyFog(vec3 color, vec3 viewPos, float depth, vec3 sunP, vec3 moonP, vec3 up, vec3 skyColor, vec3 fogColor, float rain, float farPlane, vec3 worldPos) {
	if (depth >= 0.99999 || FOG_STRENGTH <= 0.001) return color;

	float day = hsnDayFactor(sunP, up);
	float sunH = hsnSunHeight(sunP, up);

	color *= mix(vec3(1.0), mix(hsnAmbientColor(sunH, skyColor, rain), hsnSunLightColor(sunH, rain), 0.18 * day), 0.08);

	float dist = length(viewPos);
	vec3 vdir = viewPos / max(dist, 0.001);
	float range = max(farPlane, 96.0);
	float viewDist = min(dist, range);

	float aboveSea = max(worldPos.y - 63.0, 0.0);
	float lowAir = 1.0 - smoothstep(0.0, 26.0, aboveSea);
	float midAir = 1.0 - smoothstep(10.0, 78.0, aboveSea);
	float heightFog = lowAir * 0.62 + midAir * 0.38;
	float horizon = pow(1.0 - clamp(dot(vdir, up), 0.0, 1.0), 1.35);

	float dens = mix(0.0046, 0.0032, day) * FOG_DENSITY * FOG_STRENGTH;
	dens *= mix(max(NIGHT_FOG, 0.55), 1.0, day);
	dens *= 1.0 + rain * 0.90;
	dens *= mix(0.75, 1.20, heightFog);
	dens *= mix(0.88, 1.15, horizon);

	float fog = 1.0 - exp(-max(viewDist - mix(6.0, 12.0, day), 0.0) * dens);
	fog = max(fog, (1.0 - exp(-viewDist * 0.0048 * rain)) * lowAir * rain * 0.50);
	fog = clamp(fog, 0.0, mix(0.36, 0.58, day));

	float highW = smoothstep(100.0, 140.0, worldPos.y);
	float highFog = min(pow(horizon, 1.5) * 0.50 * clamp(FOG_STRENGTH * FOG_DENSITY, 0.0, 1.5), mix(0.34, 0.58, day));
	fog = mix(fog, highFog, highW);

	vec3 hdir = vdir - up * dot(vdir, up);
	float hl = length(hdir);
	hdir = hl > 0.001 ? hdir / hl : vdir;
	vec3 fcol = hsnSky(hdir, up, sunP, moonP, skyColor, fogColor, rain);
	fcol = mix(fcol, fogColor, 0.28);
	fcol *= mix(1.0, 0.88, rain);
	return mix(color, fcol, fog);
}

#endif
