#version 300 es

precision highp float;

in vec4 vertexCoord;
layout (location = 0) out vec4 color;

vec4 pack(float depth) {
    const vec4 bitSh = vec4(256.0 * 256.0 * 256.0,
                            256.0 * 256.0,
                            256.0,
                            1.0);
    const vec4 bitMsk = vec4(0,
                             1.0 / 256.0,
                             1.0 / 256.0,
                             1.0 / 256.0);
    vec4 comp = fract(depth * bitSh);
    comp -= comp.xxyz * bitMsk;
    return comp;
}

void main() {
    float normalizedDistance = vertexCoord.z / vertexCoord.w;
    normalizedDistance = (normalizedDistance + 1.0) / 2.0;
    color = pack(normalizedDistance);
//    color = vertexCoord;
//    color = vec4(0.5f);
}
