#ifndef SULFUR_WAVE_GLSL
#define SULFUR_WAVE_GLSL
#include "/lib/settings.glsl"

vec3 waveFoliage(vec3 world, float entityId, float time) {
#ifdef WAVING_FOLIAGE
	if (entityId != 10000.0 || WAVING_STRENGTH <= 0.0) return world;
	float t = time * WAVING_SPEED;
	float amp = WAVING_STRENGTH;
	world.x += sin(t * 1.7 + world.z * 0.85 + world.x * 0.15) * amp;
	world.z += cos(t * 1.3 + world.x * 0.70 + world.z * 0.12) * amp * 0.75;
	world.y += sin(t * 2.1 + world.x + world.z) * amp * 0.15;
#endif
	return world;
}
#endif
