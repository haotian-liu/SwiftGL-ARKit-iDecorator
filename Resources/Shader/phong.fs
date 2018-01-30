#version 300 es
precision mediump float;

uniform bool selected;
//uniform vec3 lightDirection;
//uniform float lightDistance;
uniform sampler2D mapKaSampler;
uniform sampler2D mapBumpSampler;
uniform bool hasTexture;

uniform vec3 Ka;
uniform vec3 Kd;
uniform vec3 Ks;
uniform float Ns;

in vec3 worldCoord;
in vec3 eyeCoord;
in vec2 texCoord;

in vec3 normal;
in vec3 tangent;
in vec3 bitangent;

out vec4 FragColor;

void main() {
//    float Shininess = Ns;

//    vec3 color = vec3(texture(textureSampler, vec2(texCoord.x, 1.f - texCoord.y)));
    //    vec3 color = vec3(texture(textureSampler, texCoord));

//    vec3 KaColor = hasTexture ? color : Ka;
//    vec3 KdColor = Kd;
//    vec3 KsColor = Ks;
//    vec3 KaColor = vec3(0.f);
    vec3 bump = texture(mapBumpSampler, texCoord).xyz * 2.0 - 1.0;
    vec3 KaColor = hasTexture ? texture(mapKaSampler, texCoord).xyz : vec3(0.f, 0.f, 0.f);
    vec3 KdColor = vec3(0.5f);
    vec3 KsColor = vec3(0.8f);
    vec3 lightDirection = vec3(1.f);
    float lightDistance = 1.2;
    float Shininess = 10.f;

//    vec3 N = normal + bump;
    mat3 TBN = mat3(tangent, bitangent, normal);
    vec3 N = TBN * bump;
//    vec3 N = normal;
    vec3 L = normalize(lightDirection * lightDistance - worldCoord);
    vec3 R = reflect(-L, N);
    vec3 E = normalize(eyeCoord);

    float NdotL = abs(dot(N, L));
    float EdotR = dot(-E, R);

    float diffuse = max(NdotL, 0.f) / lightDistance;
    float specular = hasTexture ? max(pow(EdotR, Shininess), 0.f) / lightDistance : 0.f;

    vec3 combined = vec3(KaColor + KdColor * diffuse + KsColor * specular);

    FragColor = vec4(selected ? vec3(combined.x, combined.yz + vec2(0.3f)) : combined, 1.f);
//    FragColor = vec4(vec3(N), 1.f);
}
