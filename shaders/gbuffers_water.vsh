#version 330 compatibility

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
out vec4 shadowPos;

#include "/lib/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;

	vec4 vp = gl_ModelViewMatrix * gl_Vertex;
	viewPos = vp.xyz;
	vec4 playerPos = gbufferModelViewInverse * vp;
	float lightDot = max(dot(normalize(shadowLightPosition), vec3(0.0, 1.0, 0.0)), 0.15);
	shadowPos = hsnShadowCoord(playerPos, lightDot);
	shadowPos.w = lightDot;
	gl_Position = gl_ProjectionMatrix * vp;
}
