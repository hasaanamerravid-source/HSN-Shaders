#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform mat4 gbufferModelView;
uniform float frameTimeCounter;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 viewPos;
in vec4 shadowPos;
in float hsnMat;
in vec3 hsnWorld;

#include "/lib/settings.glsl"
#include "/lib/lighting.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	vec3 up = normalize(gbufferModelView[1].xyz);
	color.rgb = hsnLight(color.rgb, lmcoord, up, shadowPos, shadowLightPosition, sunPosition, up, hsnMat);

	// Water stays the vanilla texture. No tint, ripple colour, or mirror.
	if (color.a < alphaTestRef) discard;
}
