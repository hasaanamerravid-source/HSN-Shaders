#version 330 compatibility

uniform sampler2D lightmap;
uniform sampler2D gtexture;
uniform vec3 shadowLightPosition;
uniform vec3 sunPosition;
uniform mat4 gbufferModelView;
uniform vec4 entityColor;
uniform float alphaTestRef = 0.1;

in vec2 lmcoord;
in vec2 texcoord;
in vec4 glcolor;
in vec3 normal;
in vec4 shadowPos;

#include "/lib/common.glsl"
#include "/lib/lighting.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	color.rgb = mix(color.rgb, entityColor.rgb, entityColor.a);
	vec3 up = normalize(gbufferModelView[1].xyz);
	color.rgb = hsnLight(color.rgb, lmcoord, normal, shadowPos, shadowLightPosition, sunPosition, up);
	if (color.a < alphaTestRef) discard;
}
