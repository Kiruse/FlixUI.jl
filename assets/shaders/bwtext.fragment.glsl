#version 330 core

in vec2 vecUv;
out vec4 outColor;

uniform vec4 uniColor;
uniform sampler2D texText;

void main()
{
    outColor = uniColor;
    outColor.a *= texture(texText, vecUv).r;
}
