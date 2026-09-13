#version 330 compatibility

uniform sampler2D gtexture;
uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;

#include "/lib/settings.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	float lum = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	// Keep vanilla sun/moon discs bright so they punch through the sky.
	color.rgb *= 1.0 + GLOW_STRENGTH * 1.8 + lum * 0.8;
	if (color.a < alphaTestRef) discard;
}
