#version 450
layout(location = 0) in vec2 qt_TexCoord0;
layout(location = 0) out vec4 fragColor;
layout(binding = 1) uniform sampler2D source;
layout(std140, binding = 0) uniform buf {
    mat4 qt_Matrix;
    float qt_Opacity;
    vec4 targetColor;
    float colorizeMode; // 0.0 = dock mode (grayscale), 1.0 = tray mode (intensity), 2.0 = distro mode (luminance with better contrast)
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

    if (ubuf.colorizeMode < 0.5) {
        // Dock mode: grayscale using luminance weights
        intensity = dot(rgb, vec3(0.299, 0.587, 0.114));
    } else if (ubuf.colorizeMode < 1.5) {
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

    // Re-premultiply for Qt Quick output
    fragColor = vec4(ubuf.targetColor.rgb * intensity * alpha, alpha) * ubuf.qt_Opacity;
}
