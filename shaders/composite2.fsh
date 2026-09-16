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
	vec2 texel = vec2(0.0, 1.0 / viewHeight);
	vec3 acc = texture(colortex1, texcoord).rgb * 0.227027;
	acc += texture(colortex1, texcoord + texel * 1.384615).rgb * 0.316216;
	acc += texture(colortex1, texcoord - texel * 1.384615).rgb * 0.316216;
	acc += texture(colortex1, texcoord + texel * 3.230769).rgb * 0.070270;
	acc += texture(colortex1, texcoord - texel * 3.230769).rgb * 0.070270;
	color.rgb += acc * (0.35 + BLOOM_STRENGTH * 0.40);
#endif
}
