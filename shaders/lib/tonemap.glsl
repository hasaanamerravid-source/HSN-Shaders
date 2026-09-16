#ifndef HSN_TONEMAP_GLSL
#define HSN_TONEMAP_GLSL

vec3 hsnAces(vec3 x) {
	x = max(x, 0.0);
	return clamp((x * (2.51 * x + 0.03)) / (x * (2.43 * x + 0.59) + 0.14), 0.0, 1.0);
}

vec3 hsnGrade(vec3 c) {
	float luma = dot(c, vec3(0.2126, 0.7152, 0.0722));
	vec3 shadows = c * vec3(0.92, 0.96, 1.06);
	vec3 mids = c * vec3(1.02, 1.00, 0.98);
	vec3 highs = c * vec3(1.04, 1.00, 0.94);
	float s = 1.0 - smoothstep(0.08, 0.28, luma);
	float h = smoothstep(0.55, 0.88, luma);
	c = mix(c, shadows, s * 0.35);
	c = mix(c, mids, (1.0 - s) * (1.0 - h) * 0.20);
	c = mix(c, highs, h * 0.28);
	return c;
}

#endif
