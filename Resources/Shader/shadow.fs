#version 300 es

precision highp float;
precision highp sampler2D;

uniform sampler2D depthTexture;
uniform float timeVariant;

in vec4 shadowCoord;
//in vec3 position;
layout (location = 0) out vec4 color;


const vec2 poissonDisk[16] = vec2[](
                                    vec2( -0.94201624, -0.39906216 ),
                                    vec2( 0.94558609, -0.76890725 ),
                                    vec2( -0.094184101, -0.92938870 ),
                                    vec2( 0.34495938, 0.29387760 ),
                                    vec2( -0.91588581, 0.45771432 ),
                                    vec2( -0.81544232, -0.87912464 ),
                                    vec2( -0.38277543, 0.27676845 ),
                                    vec2( 0.97484398, 0.75648379 ),
                                    vec2( 0.44323325, -0.97511554 ),
                                    vec2( 0.53742981, -0.47373420 ),
                                    vec2( -0.26496911, -0.41893023 ),
                                    vec2( 0.79197514, 0.19090188 ),
                                    vec2( -0.24188840, 0.99706507 ),
                                    vec2( -0.81409955, 0.91437590 ),
                                    vec2( 0.19984126, 0.78641367 ),
                                    vec2( 0.14383161, -0.14100790 )
                                    );

float unpack(vec4 packedZValue) {
    const vec4 unpackFactors = vec4( 1.0 / (256.0 * 256.0 * 256.0), 1.0 / (256.0 * 256.0), 1.0 / 256.0, 1.0 );
    return dot(packedZValue, unpackFactors);
}

float random(vec3 scale, float seed) {
    /* use the fragment position for a different seed per-pixel */
    return fract(sin(dot(scale + seed, scale)) * 43758.5453);
}

float visibilityTest(vec2 uv) {
    float depth = (shadowCoord.z / shadowCoord.w + 1.0) / 2.0;
    float visibility = 1.0;
    for (int i = 0; i < 4; i++){
//        int index = int(16.0 * random(floor(position * 1000.0), float(i))) % 16;
        int index = i;
        vec2 coord = uv + poissonDisk[index] / 70.0;
        vec4 dist_pack = texture(depthTexture, coord);
        float isShadow = float(unpack(dist_pack) < depth);

        visibility -= 0.2 * isShadow;
    }
    return visibility;
}

void main() {
    float depth = (shadowCoord.z / shadowCoord.w + 1.0) / 2.0;
    vec4 dist_pack = texture(depthTexture, shadowCoord.xy);
    bool isShadow = unpack(dist_pack) < depth;
//    float visibility = visibilityTest(shadowCoord.xy);
//    bool isVisible = visibility > 0.6f;
//    color = vec4(isVisible ? clamp(timeVariant * 0.4f, 0.f, 0.4f) : 0.4f);
    if (!isShadow && timeVariant < 0.001f) {
        discard;
    }
    const float shadowColor = .2f;
    color = vec4(isShadow ? shadowColor : clamp(timeVariant * shadowColor, 0.f, shadowColor));
}
