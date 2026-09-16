#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D watertex;
uniform sampler2D noisetex;
uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform vec3 skyColor;
uniform mat4 gbufferModelView;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform float frameTimeCounter;
uniform float alphaTestRef = 0.1;
uniform float viewWidth;
uniform float viewHeight;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec4 shadowPos;

#include "/lib/settings.glsl"
#include "/lib/lighting.glsl"
#include "/lib/reflections.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	vec3 up = normalize(gbufferModelView[1].xyz);
	color.rgb = hsnLight(color.rgb, lmcoord, vec3(0.0, 1.0, 0.0), shadowPos, shadowLightPosition, sunPosition, up);

	vec2 ripple = texture(watertex, texcoord * 2.5 + vec2(frameTimeCounter * 0.03, frameTimeCounter * 0.02)).rg;
	vec2 n2 = texture(noisetex, texcoord * 1.4 - vec2(frameTimeCounter * 0.015, 0.0)).rg;
	float rippleMix = (ripple.x + n2.x) * 0.5;
	color.rgb *= mix(vec3(1.0), vec3(0.92, 1.04, 1.08), rippleMix * 0.35 * WATER_TINT);

	vec3 look = normalize(-viewPos);
	float fresnel = pow(1.0 - clamp(look.y * 0.5 + 0.5, 0.0, 1.0), 2.0);
	vec3 teal = vec3(0.30, 0.62, 0.74);
	vec3 rim = vec3(0.95, 0.70, 0.36);
	vec3 tint = mix(teal, rim, fresnel * 0.4);
	color.rgb = mix(color.rgb, color.rgb * tint * 1.25, WATER_TINT);
	color.a = mix(color.a, min(color.a + 0.10, 0.90), WATER_TINT * 0.5);

#ifdef REFLECTIONS_ENABLED
	vec3 nWorld = normalize(vec3((ripple.x - 0.5) * 0.35, 1.0, (n2.y - 0.5) * 0.35));
	vec3 nView = normalize(mat3(gbufferModelView) * nWorld);
	vec3 ssr = hsnSsr(colortex0, depthtex0, viewPos, nView, gbufferProjection, gbufferProjectionInverse, vec2(viewWidth, viewHeight));
	float skyLight = clamp(lmcoord.y, 0.0, 1.0);
	vec3 fallback = mix(color.rgb, skyColor * 1.15, 0.55) ;
	vec3 env = (ssr.x >= 0.0) ? ssr : fallback;
	float spec = pow(max(dot(normalize(-viewPos), reflect(-normalize(shadowLightPosition), nView)), 0.0), 48.0);
	env += vec3(1.00, 0.90, 0.70) * spec * 0.35 * skyLight;
	float mixAmt = clamp(REFLECTION_STRENGTH * (0.22 + fresnel * 0.75) * skyLight, 0.0, 0.82);
	color.rgb = mix(color.rgb, env, mixAmt);
	color.a = min(color.a + mixAmt * 0.12, 0.94);
#endif

	if (color.a < alphaTestRef) discard;
}
