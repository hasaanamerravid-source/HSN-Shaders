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

vec3 sulfurNightZenith() { return vec3(0.012, 0.022, 0.055); }
vec3 sulfurNightHorizon() { return vec3(0.075, 0.100, 0.175); }
vec3 sulfurDuskHorizon() { return vec3(0.62, 0.28, 0.14); }

vec3 sulfurSky(vec3 viewDir, vec3 up, vec3 sunP, vec3 moonP, vec3 vanillaSky, vec3 vanillaFog) {
	float upDot = dot(viewDir, up);
	float horizon = pow(1.0 - clamp(upDot, 0.0, 1.0), 2.2);
	float day = sulfurDayFactor(sunP, up);
	float sunH = sulfurSunHeight(sunP, up);

	vec3 dayZenith = mix(vanillaSky, vec3(0.28, 0.52, 0.92), 0.70);
	vec3 dayHor = mix(vanillaFog, vec3(0.78, 0.84, 0.90), 0.25);
	dayHor = mix(dayHor, sulfurDuskHorizon(), (1.0 - smoothstep(0.02, 0.28, sunH)) * day);

	vec3 night = mix(sulfurNightZenith(), sulfurNightHorizon(), horizon);
	vec3 dayCol = mix(dayZenith, dayHor, horizon);
	vec3 sky = mix(night, dayCol, day);

	vec3 sunDir = normalize(sunP);
	float sunDot = max(dot(viewDir, sunDir), 0.0);
	float sunCore = smoothstep(0.9994 - 0.00025 * SUN_SIZE, 0.99992, sunDot);
	float sunGlow = pow(sunDot, 48.0 / SUN_SIZE) * 0.55 * day;
	sky += vec3(1.00, 0.88, 0.55) * (sunCore * 4.0 + sunGlow * 1.4) * day;

	vec3 moonDir = normalize(moonP);
	float moonDot = max(dot(viewDir, moonDir), 0.0);
	float nightAmt = 1.0 - day;
	float moonCore = smoothstep(0.9992 - 0.0003 * MOON_SIZE, 0.99985, moonDot);
	float moonHalo = pow(moonDot, 80.0 / MOON_SIZE) * 0.35;
	sky += vec3(0.62, 0.72, 0.95) * (moonCore * 1.6 + moonHalo) * nightAmt;

	return sky;
}

vec3 sulfurDistanceFog(vec3 color, float dist, float upDot, vec3 sunP, vec3 up, vec3 vanillaFog) {
	float day = sulfurDayFactor(sunP, up);
	float dens = mix(0.0030, 0.0010, day) * FOG_DENSITY * FOG_STRENGTH;
	float fog = 1.0 - exp(-max(dist - 12.0, 0.0) * dens);
	fog *= mix(0.55, 1.0, 1.0 - clamp(upDot, 0.0, 1.0));
	vec3 nightFog = mix(sulfurNightHorizon(), vec3(0.04, 0.07, 0.14), 0.35) * NIGHT_FOG;
	vec3 dayFog = mix(vanillaFog, vec3(0.72, 0.80, 0.88), 0.2);
	dayFog = mix(dayFog, sulfurDuskHorizon() * 0.55, (1.0 - smoothstep(0.0, 0.25, sulfurSunHeight(sunP, up))) * day);
	vec3 fogCol = mix(nightFog, dayFog, day);
	return mix(color, fogCol, clamp(fog, 0.0, mix(0.50, 0.22, day)));
}

vec3 sulfurNightGrade(vec3 color, vec3 sunP, vec3 up) {
	float night = 1.0 - sulfurDayFactor(sunP, up);
	if (night < 0.01) return color;
	float luma = dot(color, vec3(0.2126, 0.7152, 0.0722));
	vec3 cool = color * vec3(0.78, 0.86, 1.12);
	cool = mix(cool, vec3(luma) * vec3(0.70, 0.82, 1.05), 0.18);
	cool += vec3(0.01, 0.02, 0.045) * night * NIGHT_FOG * (1.0 - luma);
	return mix(color, cool, night * 0.85);
}

#endif
