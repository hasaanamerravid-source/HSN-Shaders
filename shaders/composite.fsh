#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform vec3 sunPosition;
uniform vec3 cameraPosition;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float rainStrength;
uniform int isEyeInWater;
uniform float blindness;
uniform float near;
uniform float far;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

#include "/lib/common.glsl"
#include "/lib/atmosphere.glsl"
#include "/lib/unbound_lite.glsl"
#include "/lib/settings.glsl"

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 bloom;

vec3 screenToView(vec3 screen) {
	vec4 ndc = vec4(screen.xy * 2.0 - 1.0, screen.z * 2.0 - 1.0, 1.0);
	vec4 v = gbufferProjectionInverse * ndc;
	return v.xyz / v.w;
}

// Simple screen-space AO (experimental, low sample count)
float hsnSSAO(vec2 uv, float depth) {
	if (depth <= 0.00015 || depth >= 0.99985) return 1.0;
	vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
	float occ = 0.0;
	const int N = 8;
	// Small fixed kernel
	vec2 offs[8] = vec2[8](
		vec2( 1.0,  0.0), vec2(-1.0,  0.0),
		vec2( 0.0,  1.0), vec2( 0.0, -1.0),
		vec2( 0.7,  0.7), vec2(-0.7,  0.7),
		vec2( 0.7, -0.7), vec2(-0.7, -0.7)
	);
	float radius = 2.8 * texel.x;
	float bias = 0.0008 + depth * 0.0012;
	for (int i = 0; i < N; i++) {
		vec2 s = uv + offs[i] * radius * (1.0 + float(i) * 0.12);
		float d = texture(depthtex0, s).r;
		float diff = depth - d;
		if (diff > bias && diff < 0.035) {
			occ += (1.0 - smoothstep(bias, 0.035, diff));
		}
	}
	float ao = 1.0 - (occ / float(N)) * SSAO_STRENGTH;
	return clamp(ao, 0.35, 1.0);
}

// Lightweight god rays (experimental)
vec3 hsnGodrays(vec2 uv, vec3 col, float depth) {
	// Project sun into screen space
	vec4 sunClip = gbufferProjection * vec4(sunPosition, 1.0);
	if (sunClip.w <= 0.0) return col;
	vec2 sunScreen = (sunClip.xy / sunClip.w) * 0.5 + 0.5;
	if (sunScreen.x < -0.15 || sunScreen.x > 1.15 || sunScreen.y < -0.15 || sunScreen.y > 1.15)
		return col;

	vec3 up = normalize(gbufferModelView[1].xyz);
	float day = sulfurDayFactor(sunPosition, up);
	if (day < 0.05) return col; // skip at night

	float dens = 0.0;
	const int STEPS = 12;
	vec2 dir = sunScreen - uv;
	float len = length(dir);
	if (len < 0.001) return col;
	dir /= len;
	float stepLen = min(len, 0.55) / float(STEPS);
	vec2 p = uv;
	for (int i = 0; i < STEPS; i++) {
		p += dir * stepLen;
		float d = texture(depthtex0, clamp(p, 0.0, 1.0)).r;
		// Contribute when sample is sky / far (allows light shafts through gaps)
		if (d > 0.999 || d >= depth - 0.0002) {
			dens += 1.0;
		}
	}
	dens = (dens / float(STEPS)) * GODRAYS_STRENGTH * day * (1.0 - rainStrength * 0.7);
	vec3 rayCol = mix(vec3(1.00, 0.92, 0.70), vec3(1.00, 0.72, 0.38), 1.0 - day);
	return col + rayCol * dens * dens * 0.55;
}

void main() {
	color = texture(colortex0, texcoord);
	float depth = texture(depthtex0, texcoord).r;
	vec3 viewPos = screenToView(vec3(texcoord, depth));
	vec3 worldPos = cameraPosition + (gbufferModelViewInverse * vec4(viewPos, 1.0)).xyz;

	vec3 up = normalize(gbufferModelView[1].xyz);
	float day = sulfurDayFactor(sunPosition, up);
#ifdef POST_PROCESSING
	color.rgb *= EXPOSURE * 1.05;
	color.rgb = sulfurWarmth(color.rgb, WARMTH * 0.28 * day);
	color.rgb = sulfurSaturation(color.rgb, SATURATION);
	color.rgb = sulfurContrast(color.rgb, CONTRAST);
#endif
	color.rgb = hsnApplyUnbound(color.rgb, viewPos, depth, sunPosition, up, skyColor, fogColor, rainStrength, far, worldPos);
	color.rgb = sulfurNightGrade(color.rgb, sunPosition, up);
	color.rgb = mix(color.rgb, color.rgb * vec3(0.90, 0.94, 1.02), rainStrength * 0.25);

	if (isEyeInWater == 1) {
		// Underwater fog: distance-based density so water is not crystal clear
		float waterDist = min(length(viewPos), far);
		float waterFog = 1.0 - exp(-waterDist * 0.045);
		waterFog = clamp(waterFog, 0.0, 0.92);
		vec3 waterFogColor = vec3(0.05, 0.22, 0.38);
		color.rgb = mix(color.rgb * vec3(0.72, 0.88, 1.04), waterFogColor, waterFog);
	} else if (isEyeInWater == 2) {
		color.rgb *= vec3(1.12, 0.55, 0.24);
	}
	color.rgb *= (1.0 - blindness);

#ifdef SSAO_ENABLED
	float ao = hsnSSAO(texcoord, depth);
	color.rgb *= ao;
#endif

#ifdef GODRAYS_ENABLED
	color.rgb = hsnGodrays(texcoord, color.rgb, depth);
#endif

#if defined POST_PROCESSING && defined BLOOM_ENABLED
	float lum = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	float warm = max(color.r - color.b * 0.65, 0.0);
	// Only hot highlights (sun, lava, lamps). Stops random blocks glowing.
	float knee = mix(0.48, 0.22, clamp(warm * 2.8, 0.0, 1.0));
	float soft = max(lum - knee, 0.0);
	soft = soft * soft / (soft + 0.28);
	vec3 bright = color.rgb * (soft / max(lum, 1e-4));
	bright += vec3(1.00, 0.52, 0.16) * warm * warm * (0.16 + GLOW_STRENGTH * 0.40);
	bright += max(color.rgb - vec3(0.92), 0.0) * 0.22;
	bloom = vec4(bright * (0.22 + BLOOM_STRENGTH * 0.42 + GLOW_STRENGTH * 0.16), 1.0);
#else
	bloom = vec4(0.0);
#endif
}
