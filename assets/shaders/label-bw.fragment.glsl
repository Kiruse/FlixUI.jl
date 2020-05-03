#version 330 core

in vec2 vecUv;
out vec4 outColor;

uniform vec4 uniColor;
uniform sampler2D texText;

void main()
{
    outColor = vec4(uniColor.rgb, texture(texText, vecUv).r);
}
