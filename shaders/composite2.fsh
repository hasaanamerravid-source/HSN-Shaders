#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D colortex1;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

#include "/lib/settings.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(colortex0, texcoord);
#ifdef BLOOM_ENABLED
	// 5 taps, same cost as 26.3.5, spaced wider (about 3 px) so the halo is visible.
	vec2 texel = vec2(0.0, 1.0 / viewHeight);
	vec3 acc = texture(colortex1, texcoord).rgb * 0.294;
	acc += texture(colortex1, texcoord + texel * 1.45).rgb * 0.250;
	acc += texture(colortex1, texcoord - texel * 1.45).rgb * 0.250;
	acc += texture(colortex1, texcoord + texel * 3.20).rgb * 0.103;
	acc += texture(colortex1, texcoord - texel * 3.20).rgb * 0.103;
	color.rgb += acc * (0.30 + BLOOM_STRENGTH * 0.45 + GLOW_STRENGTH * 0.20);
#endif
}
