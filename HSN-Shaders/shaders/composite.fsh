#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform vec3 sunPosition;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float rainStrength;
uniform int isEyeInWater;
uniform float blindness;
uniform float near;
uniform float far;

in vec2 texcoord;

#include "/lib/common.glsl"
#include "/lib/atmosphere.glsl"
#include "/lib/unbound_lite.glsl"

/* RENDERTARGETS: 0,1 */
layout(location = 0) out vec4 color;
layout(location = 1) out vec4 bloom;

vec3 screenToView(vec3 screen) {
	vec4 ndc = vec4(screen.xy * 2.0 - 1.0, screen.z * 2.0 - 1.0, 1.0);
	vec4 v = gbufferProjectionInverse * ndc;
	return v.xyz / v.w;
}

void main() {
	color = texture(colortex0, texcoord);
	float depth = texture(depthtex0, texcoord).r;
	vec3 viewPos = screenToView(vec3(texcoord, depth));
	float dist = length(viewPos);
	float upDot = normalize(viewPos).y;

	color.rgb *= EXPOSURE * 1.05;
	vec3 up = normalize(gbufferModelView[1].xyz);
	float day = sulfurDayFactor(sunPosition, up);
	color.rgb = sulfurWarmth(color.rgb, WARMTH * 0.28 * day);
	color.rgb = sulfurSaturation(color.rgb, SATURATION);
	color.rgb = sulfurContrast(color.rgb, CONTRAST);
	color.rgb = sulfurNightGrade(color.rgb, sunPosition, up);
	color.rgb = hsnApplyUnbound(color.rgb, viewPos, depth, sunPosition, up, skyColor, fogColor, rainStrength);
	color.rgb = mix(color.rgb, color.rgb * vec3(0.90, 0.94, 1.02), rainStrength * 0.25);

	if (isEyeInWater == 1) color.rgb *= vec3(0.72, 0.88, 1.04);
	else if (isEyeInWater == 2) color.rgb *= vec3(1.12, 0.55, 0.24);
	color.rgb *= (1.0 - blindness);

	float lum = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
#ifdef BLOOM_ENABLED
	float knee = 0.48;
	vec3 bright = max(color.rgb - vec3(knee), 0.0);
	bloom = vec4(bright * BLOOM_STRENGTH, 1.0);
#else
	bloom = vec4(0.0);
#endif
}
