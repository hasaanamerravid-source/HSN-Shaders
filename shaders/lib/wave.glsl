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
	} else if (entityId == 10001.0) {
		// Hanging vines only (lanterns removed from block.10001 — no swing).
		float drop = clamp(0.62 - midBlock.y * 0.015625, 0.05, 1.25);
		float hang = amp * 1.1 * drop;
		float a = sin(t * 1.45 + world.x * 0.55 + world.z * 0.38) * hang;
		float b = cos(t * 1.08 + world.z * 0.47 + world.x * 0.21) * hang * 0.55;
		world.x += a;
		world.z += b;
		world.y -= (a * a + b * b) * 1.8;
	}
#endif
	return world;
}

vec3 waveFoliage(vec3 world, float entityId, float time) {
	return waveFoliage(world, entityId, time, vec3(0.0, -8.0, 0.0));
}
#endif
