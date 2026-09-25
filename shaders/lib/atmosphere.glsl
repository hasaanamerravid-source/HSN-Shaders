#ifndef SULFUR_ATMOS_GLSL
#define SULFUR_ATMOS_GLSL

#include "/lib/settings.glsl"

float sulfurSunHeight(vec3 sunPosition, vec3 up) {
	float len = length(sunPosition);
	if (len < 0.001 || length(up) < 0.001) return 0.0;
	return dot(sunPosition / len, normalize(up));
}

float sulfurDayFactor(vec3 sunPosition, vec3 up) {
	return smoothstep(-0.12, 0.22, sulfurSunHeight(sunPosition, up));
}

vec3 sulfurNightZenith() { return vec3(0.018, 0.028, 0.062); }
vec3 sulfurNightHorizon() { return vec3(0.12, 0.10, 0.16); }
vec3 sulfurDuskHorizon() { return vec3(0.92, 0.38, 0.16); }

vec3 sulfurSky(vec3 viewDir, vec3 up, vec3 sunP, vec3 moonP, vec3 vanillaSky, vec3 vanillaFog) {
	float upDot = dot(viewDir, up);
	float horizon = pow(1.0 - clamp(upDot, 0.0, 1.0), 2.05);
	float mid = pow(1.0 - clamp(upDot, 0.0, 1.0), 1.15);
	float day = sulfurDayFactor(sunP, up);
	float sunH = sulfurSunHeight(sunP, up);
	float duskAmt = (1.0 - smoothstep(0.02, 0.32, sunH)) * day;

	vec3 dayZenith = mix(vanillaSky, vec3(0.18, 0.46, 0.96), 0.82);
	vec3 dayHor = mix(vanillaFog, vec3(0.70, 0.82, 0.96), 0.35);
	dayHor = mix(dayHor, sulfurDuskHorizon(), duskAmt);
	vec3 duskPink = vec3(0.95, 0.42, 0.48);
	dayHor = mix(dayHor, duskPink, duskAmt * mid * 0.35);

	vec3 nightZen = sulfurNightZenith();
	vec3 nightHor = sulfurNightHorizon();
	vec3 night = mix(nightZen, nightHor, horizon);
	// Soft night-blue dome so the sky is not a flat black void.
	night += vec3(0.010, 0.018, 0.040) * pow(clamp(upDot, 0.0, 1.0), 1.8);

	vec3 dayCol = mix(dayZenith, dayHor, horizon);
	vec3 sky = mix(night, dayCol, day);

	vec3 sunDir = normalize(sunP);
	float sunDot = max(dot(viewDir, sunDir), 0.0);
	float sunGlow = pow(sunDot, 32.0) * 0.52 * day;
	float sunWash = pow(sunDot, 10.0) * 0.12 * day;
	sky += vec3(1.00, 0.86, 0.55) * sunGlow;
	sky += vec3(1.00, 0.74, 0.42) * sunWash * duskAmt;

	vec3 moonDir = normalize(moonP);
	float moonDot = max(dot(viewDir, moonDir), 0.0);
	float nightAmt = 1.0 - day;
	float moonHalo = pow(moonDot, 24.0) * 0.58;
	float moonBloom = pow(moonDot, 7.0) * 0.28;
	sky += vec3(0.58, 0.68, 1.00) * (moonHalo + moonBloom) * nightAmt;

	return max(sky, vec3(0.0));
}

vec3 sulfurDistanceFog(vec3 color, float dist, float upDot, vec3 sunP, vec3 up, vec3 vanillaFog) {
	float day = sulfurDayFactor(sunP, up);
	float dens = mix(0.0120, 0.0036, day) * FOG_DENSITY * FOG_STRENGTH * mix(NIGHT_FOG, 1.0, day);
	float fog = 1.0 - exp(-max(dist - 6.0, 0.0) * dens);
	fog *= mix(0.78, 1.0, 1.0 - clamp(upDot, 0.0, 1.0));
	vec3 nightFog = mix(sulfurNightHorizon(), vec3(0.06, 0.055, 0.058), 0.35) * max(NIGHT_FOG, 0.55);
	vec3 dayFog = mix(vanillaFog, vec3(0.72, 0.80, 0.88), 0.2);
	dayFog = mix(dayFog, sulfurDuskHorizon() * 0.55, (1.0 - smoothstep(0.0, 0.25, sulfurSunHeight(sunP, up))) * day);
	vec3 fogCol = mix(nightFog, dayFog, day);
	return mix(color, fogCol, clamp(fog, 0.0, mix(0.90, 0.58, day)));
}

vec3 sulfurNightGrade(vec3 color, vec3 sunP, vec3 up) {
	float night = 1.0 - sulfurDayFactor(sunP, up);
	if (night < 0.01) return color;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	float warmth = smoothstep(0.04, 0.22, color.r - color.b);
	warmth = max(warmth, smoothstep(0.35, 0.75, color.r) * smoothstep(0.25, 0.05, color.b));
	float plant = clamp((color.g - max(color.r, color.b)) * 5.5, 0.0, 1.0);
	// Keep player / villager skin from going grey-blue.
	float skin = smoothstep(0.015, 0.08, color.r - color.b) * (1.0 - smoothstep(0.12, 0.28, abs(color.r - color.g)));
	vec3 cool = mix(color, vec3(luma), 0.08);
	cool *= vec3(0.94, 0.96, 0.99);
	float gradeAmt = night * 0.42 * (1.0 - warmth * 0.95) * (1.0 - plant * 0.90) * (1.0 - skin * 0.85);
	vec3 graded = mix(color, cool, gradeAmt);
	vec3 cozy = color * vec3(1.12, 0.82, 0.48);
	graded = mix(graded, mix(graded, cozy, 0.55), warmth * night);
	return graded;
}

#endif
