#version 300 es

in vec3 vertPos;
out vec2 fragUV;
void main() {
    fragUV = (vec2(1.f, 1.f) - vertPos.yx) / 2.f;
    gl_Position = vec4(vertPos, 1.f);
}
