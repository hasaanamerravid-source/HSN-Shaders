#version 330 compatibility

in vec4 mc_Entity;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec4 shadowPos;

#include "/lib/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	normal = gl_NormalMatrix * gl_Normal;

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	vec4 playerPos = gbufferModelViewInverse * viewPos;

	float lightDot = dot(normalize(shadowLightPosition), normalize(normal));
#ifdef EXCLUDE_FOLIAGE
	if (mc_Entity.x == 10000.0) lightDot = 1.0;
#endif

	shadowPos = hsnShadowCoord(playerPos, max(lightDot, 0.08));
	shadowPos.w = lightDot;
	gl_Position = gl_ProjectionMatrix * viewPos;
}
