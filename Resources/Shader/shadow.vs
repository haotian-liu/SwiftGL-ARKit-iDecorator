#version 300 es

uniform mat4 shadowMatrix;
uniform mat4 MVPMatrix;

layout(location=0) in vec3 vertPos;
//out vec3 position;
out vec4 shadowCoord;

void main() {
    const mat4 biasMatrix = transpose(mat4(
                                 vec4(.5f, 0.f, 0.f, .5f),
                                 vec4(0.f, .5f, 0.f, .5f),
                                 vec4(0.f, 0.f, 1.f, 0.f),
                                 vec4(0.f, 0.f, 0.f, 1.f)
    ));
    shadowCoord = biasMatrix * shadowMatrix * vec4(vertPos, 1.f);
//    position = vertPos;
    gl_Position = MVPMatrix * vec4(vertPos, 1.f);
}
