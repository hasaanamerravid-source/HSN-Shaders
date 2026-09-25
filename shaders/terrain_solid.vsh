#version 330 compatibility

in vec4 mc_Entity;
in vec3 at_midBlock;

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform float frameTimeCounter;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 normal;
out vec4 shadowPos;
out float hsnFoliage;

#include "/lib/distort.glsl"
#include "/lib/wave.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	normal = gl_NormalMatrix * gl_Normal;
	hsnFoliage = float(mc_Entity.x == 10000.0);

	vec4 viewPos = gl_ModelViewMatrix * gl_Vertex;
	vec4 playerPos = gbufferModelViewInverse * viewPos;
	playerPos.xyz = waveFoliage(playerPos.xyz, mc_Entity.x, frameTimeCounter, at_midBlock);
	viewPos = gbufferModelView * playerPos;

	float lightDot = dot(normalize(shadowLightPosition), normalize(normal));
#ifdef EXCLUDE_FOLIAGE
	if (mc_Entity.x == 10000.0) lightDot = 1.0;
#endif

	shadowPos = hsnShadowCoord(playerPos, max(lightDot, 0.08));
	shadowPos.w = lightDot;
	gl_Position = gl_ProjectionMatrix * viewPos;
}
