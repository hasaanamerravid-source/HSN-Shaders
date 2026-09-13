#ifndef HSN_LIGHTING_GLSL
#define HSN_LIGHTING_GLSL

#include "/lib/shadows.glsl"

vec3 hsnLight(vec3 albedo, vec2 lmcoord, vec3 normal, vec4 shadowPos, vec3 lightDir, vec3 sunPos, vec3 up) {
	float vis = sampleShadow(shadowPos);
	float ndotl = max(dot(normalize(normal), normalize(lightDir)), 0.0);
	float wrap = max(dot(normalize(normal), normalize(lightDir)) * 0.5 + 0.5, 0.0);
	float sky = clamp(lmcoord.y * 1.07, 0.0, 1.0);
	float block = clamp(lmcoord.x, 0.0, 1.0);

	float slen = max(length(sunPos), 0.001);
	float sunH = dot(sunPos / slen, normalize(up));
	float day = smoothstep(-0.10, 0.20, sunH);
	float dusk = day * (1.0 - smoothstep(0.08, 0.42, sunH));

	vec3 torch = vec3(1.00, 0.50, 0.22) * pow(block, 2.0) * 1.85;

	vec3 nightAmb = vec3(0.018, 0.024, 0.048);
	vec3 dayAmb = vec3(0.28, 0.34, 0.42);
	vec3 ambient = mix(nightAmb, dayAmb, day) * (0.18 + 0.82 * sky);

	vec3 noonSun = vec3(1.12, 1.00, 0.84);
	vec3 duskSun = vec3(1.22, 0.62, 0.30);
	vec3 moonCol = vec3(0.16, 0.22, 0.40);
	vec3 sunCol = mix(moonCol, mix(duskSun, noonSun, 1.0 - dusk), day);

	float shade = mix(0.10, 1.0, vis);
	float lightAmt = mix(0.22, 1.0, day);
	vec3 sunLit = sunCol * sky * (0.17 * wrap + 0.88 * ndotl) * shade * lightAmt;

	return albedo * (ambient + sunLit + torch);
}

#endif
