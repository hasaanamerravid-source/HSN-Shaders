#version 330 compatibility

uniform sampler2D texture;
uniform float alphaTestRef = 0.1;

varying vec2 texcoord;
varying vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture2D(texture, texcoord) * glcolor;
	if (color.a < alphaTestRef) discard;
}
