#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform sampler2D watertex;
uniform sampler2D noisetex;
uniform float frameTimeCounter;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec4 shadowPos;

#include "/lib/settings.glsl"
#include "/lib/shadows.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color.rgb = applyShadowLighting(color.rgb, lightmap, lmcoord, shadowPos);

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

	if (color.a < alphaTestRef) discard;
}
