#ifndef SULFUR_WAVE_GLSL
#define SULFUR_WAVE_GLSL
#include "/lib/settings.glsl"

vec3 waveFoliage(vec3 world, float entityId, float time, vec3 midBlock) {
#ifdef WAVING_FOLIAGE
	if (WAVING_STRENGTH <= 0.0) return world;
	float t = time * WAVING_SPEED;
	float amp = WAVING_STRENGTH;
	if (entityId == 10000.0) {
		world.x += sin(t * 1.7 + world.z * 0.85 + world.x * 0.15) * amp;
		world.z += cos(t * 1.3 + world.x * 0.70 + world.z * 0.12) * amp * 0.75;
		world.y += sin(t * 2.1 + world.x + world.z) * amp * 0.15;
	} else if (entityId == 10002.0) {
		world.x += sin(t * 1.15 + world.z * 0.45 + world.x * 0.08) * amp * 0.45;
		world.z += cos(t * 0.95 + world.x * 0.40 + world.z * 0.07) * amp * 0.35;
	}
	// Vines and hanging plants stay still (no 10001 swing).
#endif
	return world;
}

vec3 waveFoliage(vec3 world, float entityId, float time) {
	return waveFoliage(world, entityId, time, vec3(0.0, -8.0, 0.0));
}
#endif
