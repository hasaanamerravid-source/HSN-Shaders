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

	float lum = dot(color.rgb, vec3(0.2126, 0.7152, 0.0722));
	float warm = color.r - color.b;

	bool isSun = false;
	bool isMoon = false;
#ifdef MC_RENDER_STAGE_SUN
	isSun = renderStage == MC_RENDER_STAGE_SUN;
#ifdef MC_RENDER_STAGE_MOON
	isMoon = renderStage == MC_RENDER_STAGE_MOON;
#endif
#else
	// Heuristic: warm bright = sun, cool mid-bright = moon
	isSun = lum > 0.40 && warm > 0.04;
	isMoon = !isSun && lum > 0.18 && warm < 0.02 && color.b > color.r * 0.85;
#endif

	if (isSun) {
		// Stronger warm glow so the disc reads clearly and feeds bloom
		color.rgb *= 1.28 + lum * 0.32;
		color.rgb += vec3(1.00, 0.88, 0.55) * lum * 0.14;
		color.rgb = max(color.rgb, vec3(0.0));
	} else if (isMoon) {
		// Cool blue-white glow so the moon is not dim / flat
		color.rgb *= 1.22 + lum * 0.28;
		color.rgb += vec3(0.55, 0.68, 1.00) * lum * 0.18;
		color.rgb = max(color.rgb, vec3(0.0));
	}
}
