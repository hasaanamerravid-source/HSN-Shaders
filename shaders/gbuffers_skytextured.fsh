#version 330 compatibility

uniform sampler2D gtexture;
uniform int renderStage;
uniform float alphaTestRef = 0.1;

in vec2 texcoord;
in vec4 glcolor;

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	color = texture(gtexture, texcoord) * glcolor;
	if (color.a < alphaTestRef) discard;

	// Small sun-only lift so bloom can catch the disc. Moon is left alone.
	bool isSun = false;
#ifdef MC_RENDER_STAGE_SUN
	isSun = renderStage == MC_RENDER_STAGE_SUN;
#else
	float warm = color.r - color.b;
	isSun = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722)) > 0.40 && warm > 0.04;
#endif
	if (isSun) {
		float lum = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
		color.rgb *= 1.16 + lum * 0.18;
		color.rgb += vec3(1.00, 0.86, 0.52) * lum * 0.07;
	}
}
