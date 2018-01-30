#version 300 es

uniform mat4 viewMatrix;
uniform mat4 modelMatrix;
uniform mat4 projectionMatrix;
uniform mat3 modelViewMatrix;

layout(location=0) in vec3 vertPos;
in vec3 vertNormal;
in vec3 vertUV;
in vec3 vertTangent;
in vec3 vertBitangent;

out vec2 texCoord;
out vec3 worldCoord;
out vec3 eyeCoord;
out vec3 normal;
out vec3 tangent;
out vec3 bitangent;

void main() {
    vec4 position = vec4(vertPos, 1.0f);

    vec4 worldPos = modelMatrix * position;
    vec4 eyePos = viewMatrix * worldPos;
    vec4 clipPos = projectionMatrix * eyePos;

    worldCoord = worldPos.xyz;
    eyeCoord = eyePos.xyz;
    texCoord = vertUV.xy * 2.0;
//    texCoord = abs(normalize(vertUV));
//    texCoord = vec2(vertUV.x, 1.0 - vertUV.y);
//    normal = normalize(modelViewMatrix * vertNormal);
    //    normal = normalize(mat3(viewMatrix * modelMatrix) * vertNormal);
    //    tangent = normalize(mat3(viewMatrix * modelMatrix) * vertTangent);
    //    bitangent = normalize(mat3(viewMatrix * modelMatrix) * vertBitangent);

    normal = normalize(modelViewMatrix * vertNormal);
    tangent = normalize(modelViewMatrix * vertTangent);
    bitangent = normalize(modelViewMatrix * vertBitangent);

    //    normal = normalize((modelViewMatrix * vec4(vertNormal, 1.f)).xyz);
    //    normal = ((modelViewMatrix * vec4(vertNormal, 1.f)).xyz);
    //    tangent = normalize((modelViewMatrix * vec4(vertTangent, 1.f)).xyz);
    //    bitangent = normalize((modelViewMatrix * vec4(vertBitangent, 1.f)).xyz);

    gl_Position = clipPos;
}
