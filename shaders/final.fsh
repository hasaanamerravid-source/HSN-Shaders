#version 330 compatibility

uniform sampler2D colortex0;
uniform float viewWidth;
uniform float viewHeight;

in vec2 texcoord;

#include "/lib/settings.glsl"
#include "/lib/common.glsl"
#include "/lib/tonemap.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

void main() {
	vec2 uv = texcoord;
	vec3 col = texture(colortex0, uv).rgb;

	if (CHROMA_ABERRATION > 0.001) {
		float amt = CHROMA_ABERRATION * 0.0025 * distance(uv, vec2(0.5));
		col.r = texture(colortex0, uv + vec2(amt, 0.0)).r;
		col.b = texture(colortex0, uv - vec2(amt, 0.0)).b;
	}

	col = sulfurSaturation(col, SATURATION);
	col = hsnGrade(col);
	col = mix(col, hsnAces(col), 0.40);

	if (SHARPEN > 0.001) {
		vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
		vec3 blur = texture(colortex0, uv + vec2(texel.x, 0.0)).rgb
		          + texture(colortex0, uv - vec2(texel.x, 0.0)).rgb
		          + texture(colortex0, uv + vec2(0.0, texel.y)).rgb
		          + texture(colortex0, uv - vec2(0.0, texel.y)).rgb;
		blur *= 0.25;
		col = mix(col, col * 1.35 - hsnAces(blur) * 0.35, SHARPEN * 0.65);
	}

	float dist = distance(uv, vec2(0.5));
	col *= 1.0 - smoothstep(0.48, 1.15, dist) * VIGNETTE;
	color = vec4(clamp(col, 0.0, 1.0), 1.0);
}
