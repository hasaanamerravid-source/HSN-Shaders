#ifndef SULFUR_SETTINGS_GLSL
#define SULFUR_SETTINGS_GLSL

#ifndef SHADOW_QUALITY
#define SHADOW_QUALITY 0 // [-1 0 1 2]
#endif
#ifndef SHADOW_BRIGHTNESS
#define SHADOW_BRIGHTNESS 0.82 // [0.55 0.65 0.72 0.78 0.82 0.88 0.94]
#endif
#ifndef SHADOW_DISTORT_FACTOR
#define SHADOW_DISTORT_FACTOR 0.12 // [0.05 0.08 0.10 0.12 0.15 0.20]
#endif
#ifndef SHADOW_BIAS
#define SHADOW_BIAS 1.00 // [0.50 1.00 1.50 2.00 2.50 3.50 5.00]
#endif
#define SHADOW_DISTORT_ENABLED
#define EXCLUDE_FOLIAGE
#ifndef ENTITY_SHADOW
#define ENTITY_SHADOW -1 // [-1 1]
#endif

const int shadowMapResolution = 2048; // [512 1024 2048 4096]
const float shadowDistance = 96.0; // [64.0 96.0 128.0 160.0 192.0 256.0]
const float shadowIntervalSize = 2.0;
const bool shadowHardwareFiltering = false;
const float sunPathRotation = -30.0;

#ifndef WARMTH
#define WARMTH 0.38 // [0.00 0.15 0.35 0.45 0.55 0.80 1.00]
#endif
#ifndef SATURATION
#define SATURATION 1.10 // [0.80 0.90 1.00 1.08 1.12 1.20 1.32]
#endif
#ifndef CONTRAST
#define CONTRAST 1.02 // [0.90 1.00 1.04 1.08 1.16]
#endif
#ifndef EXPOSURE
#define EXPOSURE 0.98 // [0.80 0.90 1.00 1.05 1.12 1.20 1.35]
#endif
#ifndef GLOW_STRENGTH
#define GLOW_STRENGTH 0.08 // [0.00 0.08 0.18 0.28 0.40]
#endif
#define BLOOM_ENABLED
#ifndef BLOOM_STRENGTH
#define BLOOM_STRENGTH 0.28 // [0.00 0.15 0.30 0.40 0.60 0.80]
#endif
#ifndef VIGNETTE
#define VIGNETTE 0.22 // [0.00 0.15 0.24 0.32 0.38 0.50]
#endif
#ifndef CHROMA_ABERRATION
#define CHROMA_ABERRATION 0.06 // [0.00 0.06 0.08 0.12 0.20]
#endif
#ifndef SHARPEN
#define SHARPEN 0.12 // [0.00 0.10 0.12 0.22 0.32]
#endif
#ifndef WATER_TINT
#define WATER_TINT 0.55 // [0.00 0.20 0.35 0.55 0.70 0.90]
#endif
#define WATER_WAVES
#ifndef FOG_STRENGTH
#define FOG_STRENGTH 1.00 // [0.00 0.50 0.75 1.00 1.25 1.50]
#endif
#ifndef NIGHT_FOG
#define NIGHT_FOG 1.00 // [0.00 0.50 0.75 1.00 1.35 1.70]
#endif
#ifndef FOG_DENSITY
#define FOG_DENSITY 1.00 // [0.35 0.60 1.00 1.40 1.80]
#endif
#ifndef SUN_SIZE
#define SUN_SIZE 1.00 // [0.50 0.75 1.00 1.35 1.80]
#endif
#ifndef MOON_SIZE
#define MOON_SIZE 1.10 // [0.50 0.80 1.10 1.50 2.00]
#endif
#define WAVING_FOLIAGE
#ifndef WAVING_SPEED
#define WAVING_SPEED 1.00 // [0.35 0.70 1.00 1.40 1.80]
#endif
#ifndef WAVING_STRENGTH
#define WAVING_STRENGTH 0.08 // [0.00 0.04 0.08 0.12 0.18]
#endif
#define CLOUDS_ENABLED
#ifndef CLOUD_OPACITY
#define CLOUD_OPACITY 0.40 // [0.00 0.20 0.35 0.40 0.60 0.80]
#endif
#define GODRAYS_ENABLED
#ifndef VL_STRENGTH
#define VL_STRENGTH 0.00 // [0.00 0.20 0.35 0.40 0.55 0.75 1.00]
#endif
#ifndef VL_STEPS
#define VL_STEPS 6 // [6 8 12 16]
#endif
#ifndef GODRAY_STRENGTH
#define GODRAY_STRENGTH 0.22 // [0.00 0.15 0.22 0.28 0.40 0.55 0.70]
#endif
#ifndef SSAO_STRENGTH
#define SSAO_STRENGTH 0.30 // [0.00 0.20 0.30 0.50 0.70]
#endif

#define info0 0 // [0]
#define info1 0 // [0]
#define info2 0 // [0]
#define info3 0 // [0]
#define info4 0 // [0]
#ifndef SHADER_STYLE
#define SHADER_STYLE 0 // [0]
#endif

#endif
