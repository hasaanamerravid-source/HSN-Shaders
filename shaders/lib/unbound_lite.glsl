#ifndef HSN_UNBOUND_LITE_GLSL
#define HSN_UNBOUND_LITE_GLSL

#include "/lib/atmosphere.glsl"

vec3 hsnSunLightColor(float sunH, float rain) {
	float noon = smoothstep(0.15, 0.55, sunH);
	float sunset = (1.0 - noon) * smoothstep(-0.05, 0.18, sunH);
	vec3 noonC = vec3(1.05, 0.96, 0.82);
	vec3 duskC = vec3(1.15, 0.62, 0.32);
	vec3 moonC = vec3(0.22, 0.28, 0.42);
	vec3 c = mix(moonC, mix(duskC, noonC, noon), sunset + noon);
	c = mix(c, vec3(0.55, 0.58, 0.62), rain * 0.45);
	return c;
}

vec3 hsnAmbientColor(float sunH, vec3 skyColor, float rain) {
	float day = smoothstep(-0.10, 0.22, sunH);
	vec3 dayAmb = pow(max(skyColor, vec3(0.02)), vec3(0.75)) * vec3(0.90, 0.93, 1.00);
	vec3 nightAmb = vec3(0.07, 0.09, 0.14);
	vec3 amb = mix(nightAmb, dayAmb, day);
	amb = mix(amb, vec3(0.16, 0.18, 0.22), rain * 0.35);
	return amb;
}

vec3 hsnAtmFogColor(float sunH, float lookSun, vec3 skyColor, vec3 fogColor, float rain) {
	float day = smoothstep(-0.10, 0.22, sunH);
	vec3 nightFog = vec3(0.035, 0.055, 0.110);
	vec3 dayFog = mix(skyColor, vec3(0.55, 0.72, 0.95), 0.45);
	vec3 duskFog = vec3(0.42, 0.22, 0.12);
	float dusk = (1.0 - smoothstep(0.12, 0.45, sunH)) * day;
	vec3 c = mix(nightFog, dayFog, day);
	c = mix(c, duskFog, dusk * 0.55);
	c = mix(c, c * vec3(0.85, 0.88, 0.92), rain * 0.4);
	c *= 0.85 + 0.15 * lookSun * day;
	return c;
}

vec3 hsnApplyUnbound(vec3 color, vec3 viewPos, float depth, vec3 sunP, vec3 up, vec3 skyColor, vec3 fogColor, float rain) {
	float sunH = sulfurSunHeight(sunP, up);
	float day = sulfurDayFactor(sunP, up);
	vec3 vdir = normalize(viewPos);
	float lookSun = max(dot(vdir, normalize(sunP)), 0.0);
	float dist = length(viewPos);
	bool sky = depth <= 0.00015 || depth >= 0.99985;

	vec3 light = hsnSunLightColor(sunH, rain);
	vec3 amb = hsnAmbientColor(sunH, skyColor, rain);
	color *= mix(vec3(1.0), mix(amb, light, 0.22 * day), 0.10);

	float dens = mix(0.0032, 0.0011, day) * FOG_DENSITY * FOG_STRENGTH;
	float fog = 1.0 - exp(-max(dist - 18.0, 0.0) * dens);
	if (sky) fog = mix(0.06, 0.22, 1.0 - clamp(vdir.y, 0.0, 1.0));
	fog *= mix(0.50, 1.0, 1.0 - clamp(dot(vdir, up), 0.0, 1.0) * 0.65);
	vec3 fcol = hsnAtmFogColor(sunH, lookSun, skyColor, fogColor, rain);
	color = mix(color, fcol, clamp(fog, 0.0, mix(0.55, 0.32, day)));
	return color;
}

#endif
