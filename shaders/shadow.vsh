#version 330 compatibility

attribute vec4 mc_Entity;

varying vec2 texcoord;
varying vec4 glcolor;

#include "/lib/distort.glsl"

void main() {
	texcoord = (gl_TextureMatrix[0] * gl_MultiTexCoord0).xy;
	glcolor = gl_Color;

#ifdef EXCLUDE_FOLIAGE
	if (mc_Entity.x == 10000.0) {
		gl_Position = vec4(10.0);
		return;
	}
#endif

	gl_Position = ftransform();
	gl_Position.xyz = distort(gl_Position.xyz);
}
