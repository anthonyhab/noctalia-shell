#version 450
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 targetColor;
    vec4 params; // x = colorizeMode, yzw reserved
} ubuf;

void main() {
    vec4 tex = texture(source, qt_TexCoord0);
    float alpha = tex.a;

    if (alpha <= 0.001) {
        fragColor = vec4(0.0);
        return;
    }

    // Un-premultiply to get raw color values
    vec3 rgb = tex.rgb / alpha;

    float intensity;
    float colorizeMode = ubuf.params.x;

    if (colorizeMode < 0.5) {
        // Dock mode: grayscale using luminance weights
        intensity = dot(rgb, vec3(0.299, 0.587, 0.114));
    } else if (colorizeMode < 1.5) {
        // Tray mode: max channel intensity with gentle normalization
        intensity = max(max(rgb.r, rgb.g), rgb.b);
        intensity = smoothstep(0.1, 0.9, intensity);
    } else {
        // Distro mode: brightness boost
        float maxChannel = max(max(rgb.r, rgb.g), rgb.b);
        intensity = maxChannel * 1.5;
        intensity = min(intensity, 1.0);
        intensity = intensity * 0.7 + 0.3;
    }

    // Luminance-aware output: adapt strategy to target brightness
    float targetLum = dot(ubuf.targetColor.rgb, vec3(0.299, 0.587, 0.114));
    float t = smoothstep(0.3, 0.7, targetLum);

    // Light target: modulate color, keep full alpha (original)
    // Dark target: keep color pure, modulate alpha (avoids muddy darks)
    float boosted = pow(intensity, 0.6);
    float colorMod = mix(1.0, intensity, t);
    float alphaMod = mix(boosted, 1.0, t);

    fragColor = vec4(ubuf.targetColor.rgb * colorMod * alpha, alphaMod * alpha) * ubuf.qt_Opacity;
}
