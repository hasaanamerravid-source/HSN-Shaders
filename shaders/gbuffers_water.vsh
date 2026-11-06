#version 330 compatibility

uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 shadowLightPosition;
uniform vec3 cameraPosition;

in vec4 mc_Entity;

out vec2 lmcoord;
out vec2 texcoord;
out vec4 glcolor;
out vec3 viewPos;
out vec3 normal;
out vec4 shadowPos;
out float hsnMat;
out vec3 hsnWorld;

#include "/lib/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	lmcoord  = (gl_TextureMatrix[1] * gl_MultiTexCoord1).xy;
	glcolor = gl_Color;
	hsnMat = mc_Entity.x;
	normal = gl_NormalMatrix * gl_Normal;

	vec4 vp = gl_ModelViewMatrix * gl_Vertex;
	viewPos = vp.xyz;
	vec4 playerPos = gbufferModelViewInverse * vp;
	hsnWorld = playerPos.xyz + cameraPosition;
	// Water faces up. Other translucent blocks (glass, ice, portals) keep their
	// real normal so their shading does not flatten out. Use view-space up, not
	// world (0,1,0), so the water light angle does not change with the camera.
	vec3 upView = normalize(gbufferModelView[1].xyz);
	float waterMask = float(hsnMat > 10199.5 && hsnMat < 10200.5);
	vec3 lightNormal = normalize(mix(normalize(normal), upView, waterMask));
	float minDot = mix(0.08, 0.15, waterMask);
	float lightDot = max(dot(normalize(shadowLightPosition), lightNormal), minDot);
	shadowPos = hsnShadowCoord(playerPos, lightDot);
	shadowPos.w = lightDot;
	gl_Position = gl_ProjectionMatrix * vp;
}
