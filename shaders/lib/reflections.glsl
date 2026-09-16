#ifndef HSN_REFLECTIONS_GLSL
#define HSN_REFLECTIONS_GLSL

// Lightweight screen-space reflections for water.
// Idea is the same class of effect as RenderPearl (trace the reflected
// view ray against the already-drawn opaque scene), kept to a small
// step count so Low/Medium GPUs can toggle it by hand.

vec3 hsnViewFromScreen(vec3 screen, mat4 invProj) {
	vec4 ndc = vec4(screen.xy * 2.0 - 1.0, screen.z * 2.0 - 1.0, 1.0);
	vec4 v = invProj * ndc;
	return v.xyz / max(v.w, 1e-6);
}

vec3 hsnScreenFromView(vec3 view, mat4 proj) {
	vec4 clip = proj * vec4(view, 1.0);
	vec3 ndc = clip.xyz / max(clip.w, 1e-6);
	return ndc * 0.5 + 0.5;
}

vec3 hsnSsr(sampler2D scene, sampler2D depthTex, vec3 viewPos, vec3 normal, mat4 proj, mat4 invProj, vec2 pixel) {
	vec3 V = normalize(viewPos);
	vec3 R = normalize(reflect(V, normalize(normal)));
	if (R.z > 0.15) return vec3(-1.0);

	vec3 start = viewPos + normal * 0.08;
	float travel = mix(0.35, 2.8, clamp(-R.z, 0.0, 1.0));
	vec3 stepV = R * travel;
	vec3 hit = vec3(-1.0);

	for (int i = 1; i <= 10; i++) {
		vec3 sampleView = start + stepV * (float(i) / 10.0);
		vec3 uvz = hsnScreenFromView(sampleView, proj);
		if (uvz.xy != clamp(uvz.xy, vec2(0.002), vec2(0.998))) break;

		float sceneZ = texture(depthTex, uvz.xy).r;
		if (sceneZ <= 0.00015 || sceneZ >= 0.99985) continue;

		vec3 sceneView = hsnViewFromScreen(vec3(uvz.xy, sceneZ), invProj);
		if (sampleView.z < sceneView.z - 0.08 && sampleView.z > sceneView.z - 2.8) {
			hit = texture(scene, uvz.xy).rgb;
			float edge = smoothstep(0.00, 0.08, uvz.x) * smoothstep(0.00, 0.08, uvz.y)
			           * smoothstep(1.00, 0.92, uvz.x) * smoothstep(1.00, 0.92, uvz.y);
			hit *= edge;
			break;
		}
	}
	return hit;
}

#endif
