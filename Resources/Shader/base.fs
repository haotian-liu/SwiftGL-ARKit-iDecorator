#version 300 es
precision mediump float;

uniform sampler2D yTexture;
uniform sampler2D uvTexture;

in vec2 fragUV;
out vec4 FragColor;
void main() {
    vec4 YPlane = texture(yTexture, fragUV);
    vec4 CbCrPlane = texture(uvTexture, fragUV);

    float Cb, Cr, Y;
    float R, G, B;
    Y = YPlane.r * 255.0;
    Cb = CbCrPlane.r * 255.0 - 128.0;
    Cr = CbCrPlane.a * 255.0 - 128.0;

    R = 1.402 * Cr + Y;
    G = -0.344 * Cb - 0.714 * Cr + Y;
    B = 1.772 * Cb + Y;

    FragColor = vec4(R / 255.0, G / 255.0, B / 255.0, 1.0);
}
