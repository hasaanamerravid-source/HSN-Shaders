#version 330 compatibility

uniform sampler2D colortex0;
uniform sampler2D depthtex0;
uniform sampler2D cloudtex;
uniform sampler2D shadowtex0;
uniform mat4 gbufferProjection;
uniform mat4 gbufferProjectionInverse;
uniform mat4 gbufferModelView;
uniform mat4 gbufferModelViewInverse;
uniform mat4 shadowModelView;
uniform mat4 shadowProjection;
uniform vec3 sunPosition;
uniform vec3 moonPosition;
uniform vec3 fogColor;
uniform vec3 skyColor;
uniform float viewWidth;
uniform float viewHeight;
uniform float frameTimeCounter;
uniform float rainStrength;

in vec2 texcoord;

#include "/lib/settings.glsl"
#include "/lib/volumetric.glsl"

/* RENDERTARGETS: 0 */
layout(location = 0) out vec4 color;

vec3 screenToView(vec3 screen) {
	vec4 ndc = vec4(screen.xy * 2.0 - 1.0, screen.z * 2.0 - 1.0, 1.0);
	vec4 v = gbufferProjectionInverse * ndc;
	return v.xyz / v.w;
}

bool isSky(float depth) {
	return depth <= 0.00015 || depth >= 0.99985;
}

float sunHeight() {
	float len = length(sunPosition);
	if (len < 0.001) return 0.0;
	vec3 up = normalize(gbufferModelView[1].xyz);
	return dot(sunPosition / len, up);
}

void main() {
	color = texture(colortex0, texcoord);
	float depth = texture(depthtex0, texcoord).r;
	float sh = sunHeight();

#ifdef SSAO_ENABLED
	if (!isSky(depth) && SSAO_STRENGTH > 0.001) {
		vec2 texel = 1.0 / vec2(viewWidth, viewHeight);
		float s = 0.0;
		for (int i = 0; i < 6; i++) {
			float a = float(i) * 2.39996;
			vec2 off = vec2(cos(a), sin(a)) * texel * (3.0 + float(i));
			float nd = texture(depthtex0, texcoord + off).r;
			s += float(abs(nd - depth) < 0.004 || nd < depth);
		}
		color.rgb *= mix(1.0, s / 6.0, SSAO_STRENGTH * 0.45);
	}
#endif

	// BSL-like 2D cloud plane: only a band of sky, only when the sun is up,
	// using the smooth cloud atlas — never raw white noise.
	float discProtect = 1.0 - smoothstep(0.55, 0.82, dot(color.rgb, vec3(0.2126, 0.7152, 0.0722)));

#ifdef CLOUDS_ENABLED
	if (isSky(depth) && CLOUD_OPACITY > 0.001 && sh > -0.05) {
		vec3 dir = normalize(screenToView(vec3(texcoord, 1.0)));
		float band = smoothstep(0.04, 0.14, dir.y) * (1.0 - smoothstep(0.42, 0.78, dir.y));
		if (band > 0.001) {
			vec2 cuv = dir.xz / max(dir.y, 0.08) * 0.06;
			cuv += vec2(frameTimeCounter * 0.0022, frameTimeCounter * 0.0007);
			float c0 = texture(cloudtex, cuv).r;
			float c1 = texture(cloudtex, cuv * 2.15 + vec2(0.33, 0.17)).r;
			float c = smoothstep(0.42, 0.72, c0 * 0.7 + c1 * 0.3);
			float day = smoothstep(-0.05, 0.18, sh);
			c *= band * day * (1.0 - rainStrength * 0.7) * discProtect;
			vec3 cloudCol = mix(vec3(1.00, 0.96, 0.90), skyColor, 0.22);
			color.rgb = mix(color.rgb, cloudCol, c * CLOUD_OPACITY);
		}
	}
#endif

	#ifdef GODRAYS_ENABLED
	if (GODRAY_STRENGTH > 0.001) {
		vec3 body = sh > 0.0 ? sunPosition : moonPosition;
		vec3 rayCol = sh > 0.0 ? vec3(1.00, 0.86, 0.58) : vec3(0.45, 0.58, 0.85);
		float rayAmt = GODRAY_STRENGTH * (sh > 0.0 ? 0.70 : 0.45);
		vec4 clip = gbufferProjection * vec4(body, 1.0);
		if (clip.w > 0.0) {
			vec2 sunUV = clip.xy / clip.w * 0.5 + 0.5;
			if (sunUV == clamp(sunUV, vec2(-0.08), vec2(1.08))) {
				vec2 delta = (sunUV - texcoord) / 16.0;
				vec2 p = texcoord;
				float acc = 0.0;
				for (int i = 0; i < 16; i++) {
					p += delta;
					if (p != clamp(p, vec2(0.0), vec2(1.0))) continue;
					acc += float(isSky(texture(depthtex0, p).r));
				}
				float fall = pow(1.0 - clamp(distance(texcoord, sunUV), 0.0, 1.0), 2.2);
				float skyW = float(isSky(depth));
				color.rgb += rayCol * (acc / 16.0) * fall * skyW * rayAmt * (1.0 - rainStrength);
			}
		}
	}
#endif

#ifdef VOLUMETRIC_LIGHTING
	vec3 viewPos = screenToView(vec3(texcoord, depth));
	color.rgb += hsnVolumetricLight(viewPos, isSky(depth), texcoord);
#endif
}
