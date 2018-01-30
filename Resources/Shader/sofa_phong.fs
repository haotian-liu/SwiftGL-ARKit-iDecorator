#version 300 es
precision mediump float;

uniform bool selected;
//uniform vec3 lightDirection;
//uniform float lightDistance;
uniform sampler2D mapKaSampler;
uniform sampler2D mapBumpSampler;
uniform sampler2D mapReflSampler;
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

vec4 calculateNormal(vec2 tex_coord) {
    const vec2 size = vec2(2.0,0.0);
    const ivec3 off = ivec3(-1,0,1);

    vec4 wave = texture(mapBumpSampler, tex_coord);
    float s11 = wave.x;
    float s01 = textureOffset(mapBumpSampler, tex_coord, off.xy).x;
    float s21 = textureOffset(mapBumpSampler, tex_coord, off.zy).x;
    float s10 = textureOffset(mapBumpSampler, tex_coord, off.yx).x;
    float s12 = textureOffset(mapBumpSampler, tex_coord, off.yz).x;
    vec3 va = normalize(vec3(size.xy,s21-s01));
    vec3 vb = normalize(vec3(size.yx,s12-s10));
    vec4 bump = vec4( cross(va,vb), s11 );

    return bump;
}

vec3 normalMap(vec3 normal) {
    return (normal + vec3(1.f)) / 2.0;
}

void main() {
    //    float Shininess = Ns;

    //    vec3 color = vec3(texture(textureSampler, vec2(texCoord.x, 1.f - texCoord.y)));
    //    vec3 color = vec3(texture(textureSampler, texCoord));

    //    vec3 KaColor = hasTexture ? color : Ka;
    //    vec3 KdColor = Kd;
    //    vec3 KsColor = Ks;
    //    vec3 KaColor = vec3(0.f);
//    vec3 bump = texture(mapBumpSampler, texCoord).xyz * 2.0 - 1.0;
//    float height = texture(mapBumpSampler, texCoord).x;
    vec3 KdColor = hasTexture ? texture(mapKaSampler, texCoord).xyz : vec3(0.5f);
    vec3 KaColor = vec3(.1f) * KdColor;
    vec3 KsColor = hasTexture ? length(texture(mapReflSampler, texCoord).xyz) * vec3(0.5f) : vec3(0.5f);
    vec3 lightDirection = vec3(1.f);
    float lightDistance = 1.25f;
    float Shininess = 10.f;

    //    vec3 N = normal + bump;
    mat3 TBN = mat3(tangent, bitangent, normal);
    vec3 N;
//    N = TBN * bump;
//    N = normal;
    N = TBN * calculateNormal(texCoord).xyz;
    vec3 L = normalize(lightDirection * lightDistance - worldCoord);
    vec3 R = reflect(-L, N);
    vec3 E = normalize(eyeCoord);

    float NdotL = abs(dot(N, L));
    float EdotR = dot(-E, R);

    float diffuse = max(NdotL, 0.f) / lightDistance;
    float specular = hasTexture ? max(pow(EdotR, Shininess), 0.f) / lightDistance : 0.f;
    specular = clamp(specular, 0.f, 1.f);

    vec3 combined = vec3(KaColor + KdColor * diffuse + KsColor * specular);

//    FragColor = vec4(selected ? vec3(combined.x, combined.yz + vec2(0.3f)) : combined, 1.f);
//    FragColor = vec4(normalMap(normal), 1.f);
    FragColor = vec4(combined, 1.f);
}
