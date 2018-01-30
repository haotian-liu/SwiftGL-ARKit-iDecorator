#version 300 es

precision mediump float;

uniform float id;
layout (location = 0) out float color;

void main() {
    color = id;
}
