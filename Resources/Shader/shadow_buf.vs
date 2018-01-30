#version 300 es

uniform mat4 MVPMatrix;

layout(location = 0) in vec3 vertPos;
out vec4 vertexCoord;

void main() {
    vertexCoord = MVPMatrix * vec4(vertPos, 1.f);
    gl_Position = vertexCoord;
}
