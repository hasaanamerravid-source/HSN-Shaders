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
	vec2 texel = vec2(1.0 / viewWidth, 0.0);
	vec3 acc = texture(colortex1, texcoord).rgb * 0.227027;
	acc += texture(colortex1, texcoord + texel * 1.384615).rgb * 0.316216;
	acc += texture(colortex1, texcoord - texel * 1.384615).rgb * 0.316216;
	acc += texture(colortex1, texcoord + texel * 3.230769).rgb * 0.070270;
	acc += texture(colortex1, texcoord - texel * 3.230769).rgb * 0.070270;
	bloom = vec4(acc, 1.0);
#else
	bloom = texture(colortex1, texcoord);
#endif
}
