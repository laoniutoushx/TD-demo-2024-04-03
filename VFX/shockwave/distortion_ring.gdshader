shader_type spatial;
render_mode unshaded;

// 原有的 fragment uniforms
uniform float distortionView : hint_range(0.0, 0.3, 0.005) = 0.03;
uniform float speedView : hint_range(0.0, 1.0, 0.005) = 0.5;
uniform sampler2D noiseViewX;
uniform sampler2D noiseViewY;
uniform sampler2D screenTexture : hint_screen_texture;
uniform vec3 tintColor : source_color;
uniform float fesnelAmount : hint_range(0.0, 5.0, 0.1);

// 原有的 vertex uniforms
uniform float distortionVertex : hint_range(0.0, 0.3, 0.005) = 0.03;
uniform float speedVertex : hint_range(0.0, 1.0, 0.005) = 0.1;
uniform sampler2D noiseVertex;

// 新增的圆环参数
uniform float outerRadius : hint_range(0.0, 1.0, 0.01) = 0.9;  // 外圆半径
uniform float innerRadius : hint_range(0.0, 1.0, 0.01) = 0.7;  // 内圆半径
uniform vec2 ringCenter = vec2(0.5, 0.5);  // 圆环中心点，默认在UV中心
// 新增横纵比校正参数（理想情况下设置为屏幕宽高比）
uniform float aspect : hint_range(0.1, 3.0, 0.01) = 1.0;

float fresnel(float amount, vec3 normal, vec3 view) {
    return pow((1.0 - clamp(dot(normalize(normal), normalize(view)), 0.0, 1.0)), amount);
}

// 修正后的圆环函数，通过校正 x 分量保证圆形外边界
float isInRing(vec2 uv, vec2 center, float _innerRadius, float _outerRadius) {
    vec2 diff = uv - center;
    diff.x *= aspect; // 校正横向比例
    float dist = length(diff);
    // 使用 smoothstep 创建平滑过渡边缘
    float outerMask = 1.0 - smoothstep(_outerRadius - 0.01, _outerRadius + 0.01, dist);
    float innerMask = smoothstep(_innerRadius - 0.01, _innerRadius + 0.01, dist);
    return outerMask * innerMask;
}

void vertex() {
    // 计算顶点所在的圆环因子
    float ringFactor = isInRing(UV, ringCenter, innerRadius, outerRadius);
    float noiseVal = (texture(noiseVertex, UV + (TIME * speedVertex)).r * 2.0) - 1.0;
    vec3 displacement = NORMAL * noiseVal * distortionVertex * ringFactor;
    VERTEX += displacement;
}

void fragment() {
    // 计算片段所在的圆环因子
    float ringFactor = isInRing(UV, ringCenter, innerRadius, outerRadius);
    
    float noiseValueX = (texture(noiseViewX, UV + (TIME * speedView)).r * 2.0) - 1.0;
    float noiseValueY = (texture(noiseViewY, UV + (TIME * speedView)).r * 2.0) - 1.0;
    
    vec2 noiseDistort = vec2(noiseValueX, noiseValueY) * distortionView * ringFactor;
    vec3 distortedScreenTexture = texture(screenTexture, SCREEN_UV + noiseDistort).rgb;
    
    vec3 fesnelTint = tintColor * fresnel(fesnelAmount, NORMAL, VIEW) * ringFactor;
    
    vec3 screenColor = texture(screenTexture, SCREEN_UV).rgb;
    ALBEDO = mix(screenColor, distortedScreenTexture + fesnelTint, ringFactor);
}
