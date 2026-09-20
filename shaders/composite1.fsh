#version 330 compatibility

uniform sampler2D colortex1;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

#include "/lib/settings.glsl"

/* RENDERTARGETS: 1 */
layout(location = 0) out vec4 bloom;

void main() {
#ifdef BLOOM_ENABLED
	// Tight 5-tap horizontal blur — old 1.8 / 4.2 taps smeared the whole frame.
	vec2 texel = vec2(1.0 / viewWidth, 0.0);
	vec3 acc = texture(colortex1, texcoord).rgb * 0.294;
	acc += texture(colortex1, texcoord + texel * 1.15).rgb * 0.250;
	acc += texture(colortex1, texcoord - texel * 1.15).rgb * 0.250;
	acc += texture(colortex1, texcoord + texel * 2.40).rgb * 0.103;
	acc += texture(colortex1, texcoord - texel * 2.40).rgb * 0.103;
	bloom = vec4(acc, 1.0);
#else
	bloom = texture(colortex1, texcoord);
#endif
}
