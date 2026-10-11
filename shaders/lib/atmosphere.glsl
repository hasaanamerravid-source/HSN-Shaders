#ifndef HSN_ATMOS_GLSL
#define HSN_ATMOS_GLSL

#include "/lib/settings.glsl"

float hsnSunHeight(vec3 sunPosition, vec3 up) {
	float len = length(sunPosition);
	if (len < 0.001 || length(up) < 0.001) return 0.0;
	return dot(sunPosition / len, normalize(up));
}

float hsnDayFactor(vec3 sunPosition, vec3 up) {
	return smoothstep(-0.12, 0.22, hsnSunHeight(sunPosition, up));
}

vec3 hsnNightZenith() { return vec3(0.018, 0.028, 0.062); }
// Neutral blue-gray, not purple. Fog uses this same sky colour so the horizon has no seam.
vec3 hsnNightHorizon() { return vec3(0.082, 0.090, 0.128); }
vec3 hsnDuskHorizon() { return vec3(0.92, 0.38, 0.16); }

vec3 hsnSky(vec3 viewDir, vec3 up, vec3 sunP, vec3 moonP, vec3 vanillaSky, vec3 vanillaFog, float rain) {
	float upDot = dot(viewDir, up);
	float horizon = pow(1.0 - clamp(upDot, 0.0, 1.0), 2.05);
	float mid = pow(1.0 - clamp(upDot, 0.0, 1.0), 1.15);
	float day = hsnDayFactor(sunP, up);
	float sunH = hsnSunHeight(sunP, up);
	float clear = 1.0 - rain;
	float duskAmt = (1.0 - smoothstep(0.02, 0.32, sunH)) * day * (1.0 - rain * 0.85);

	// The bright blue is only for clear weather. In rain the sky follows vanilla (gray).
	vec3 dayZenith = mix(vanillaSky, vec3(0.32, 0.55, 0.92), 0.48 * clear);
	vec3 dayHor = mix(vanillaFog, vec3(0.74, 0.82, 0.92), 0.28 * clear);
	dayHor = mix(dayHor, hsnDuskHorizon(), duskAmt);
	vec3 duskPink = vec3(0.95, 0.42, 0.48);
	dayHor = mix(dayHor, duskPink, duskAmt * mid * 0.22);

	vec3 nightZen = hsnNightZenith();
	vec3 nightHor = hsnNightHorizon();
	vec3 night = mix(nightZen, nightHor, horizon);
	// Soft night-blue dome so the sky is not a flat black void.
	night += vec3(0.010, 0.018, 0.040) * pow(clamp(upDot, 0.0, 1.0), 1.8);

	vec3 dayCol = mix(dayZenith, dayHor, horizon);
	vec3 sky = mix(night, dayCol, day);

	vec3 sunDir = normalize(sunP);
	float sunDot = max(dot(viewDir, sunDir), 0.0);
	float sunGlow = pow(sunDot, 28.0) * 0.72 * day * (1.0 - rain * 0.85);
	float sunWash = pow(sunDot, 8.0) * 0.16 * day * (1.0 - rain * 0.85);
	sky += vec3(1.00, 0.86, 0.55) * sunGlow;
	sky += vec3(1.00, 0.74, 0.42) * sunWash * duskAmt;

	vec3 moonDir = normalize(moonP);
	float moonDot = max(dot(viewDir, moonDir), 0.0);
	float nightAmt = 1.0 - day;
	// Tighter than before. The old wide wash covered half the sky and blacked out the clouds.
	float moonHalo = pow(moonDot, 48.0) * 0.60;
	float moonBloom = pow(moonDot, 12.0) * 0.17;
	sky += vec3(0.58, 0.68, 1.00) * (moonHalo + moonBloom) * nightAmt * (1.0 - rain * 0.8);

	return max(sky, vec3(0.0));
}

vec3 hsnNightGrade(vec3 color, vec3 sunP, vec3 up) {
	float night = 1.0 - hsnDayFactor(sunP, up);
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
