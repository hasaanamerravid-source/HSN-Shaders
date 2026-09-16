#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform mat4 gbufferModelView;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec4 shadowPos;
in float hsnFoliage;

#include "/lib/common.glsl"
#include "/lib/lighting.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	vec3 up = normalize(gbufferModelView[1].xyz);
	vec3 n = mix(normal, up, step(0.5, hsnFoliage));
	color.rgb = hsnLight(color.rgb, lmcoord, n, shadowPos, shadowLightPosition, sunPosition, up);
	if (color.a < alphaTestRef) discard;
}
