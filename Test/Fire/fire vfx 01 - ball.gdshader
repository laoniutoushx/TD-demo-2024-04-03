shader_type spatial;
render_mode unshaded;

const float DENSITY = 4.5;

// 可调节参数
uniform float time_scale : hint_range(0.0, 2.0) = 0.45;
uniform float noise_scale : hint_range(0.0, 2.0) = 0.45;
uniform vec3 color1 : source_color = vec3(1.0, 0.19, 0.0);
uniform vec3 color2 : source_color = vec3(1.0, 0.91, 0.0);

// Hash函数
float hash(vec3 p3) {
    p3 = fract(p3 * vec3(.1031, .11369, .13787));
    p3 += dot(p3, p3.yzx + 19.19);
    return fract((p3.x + p3.y) * p3.z);
}

// 梯度函数
vec3 grad(vec3 p) {
    return normalize(-1.0 + 2.0 * vec3(hash(p.xyz), hash(p.yxy), hash(p.zyx)));
}

// 平滑过渡函数
vec3 fade(vec3 p, vec3 corner) {
    vec3 t = abs(p - corner);
    return vec3(1.0) - (6.0 * t * t * t * t * t - 15.0 * t * t * t * t + 10.0 * t * t * t);
}

// Perlin噪声实现
float perlin(vec3 p) {
    p *= DENSITY;
    vec3 min_corner = floor(p);
    vec3 local = fract(p);
    float ret = 0.0;
    
    for (int dx = 0; dx <= 1; ++dx) {
        for (int dy = 0; dy <= 1; ++dy) {
            for (int dz = 0; dz <= 1; ++dz) {
                // 修复：将整数显式转换为浮点数
                vec3 corner = min_corner + vec3(float(dx), float(dy), float(dz));
                vec3 g = grad(corner);
                vec3 d = local - vec3(float(dx), float(dy), float(dz));
                vec3 f = fade(p, corner);
                ret += dot(g, d) * f.x * f.y * f.z;
            }
        }
    }
    return ret;
}

// 分形布朗运动
float fbm(vec3 p) {
    float ret = 0.0;
    float amp = 1.0;
    
    for (int i = 0; i < 4; ++i) {
        ret += amp * perlin(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return ret;
}

// 光线步进
vec4 rayMarch(vec3 ro, vec3 rd) {
    float t = 0.0;
    vec4 color = vec4(0.0);
    
    for(int i = 0; i < 50; i++) {
        vec3 p = ro + t * rd;
        float sdf = length(p) - 1.0;
        float noise = fbm(p * noise_scale + TIME * time_scale);
        noise = (noise + 0.7) / 3.0;
        float density = pow(7.2, -1.66 * sdf) * noise;
        
        if(density > 1e-3) {
            vec4 c = vec4(mix(color1, color2, density), density);
            c.a *= 0.2;
            c.rgb *= c.a;
            color += c * (1.0 - color.a);
        }
        t += sdf;
    }
    return color;
}

void fragment() {
    // 转换UV坐标
    vec2 uv = (UV * 2.0 - 1.0);
    
    // 设置光线原点和方向
    vec3 ro = vec3(0.0, 0.0, -2.0);
    vec3 rd = normalize(vec3(uv, 1.0));
    
    // 执行光线步进
    vec4 color = rayMarch(ro, rd);
    
    // 输出最终颜色
    ALBEDO = color.rgb;
    ALPHA = color.a;
    EMISSION = color.rgb; // 添加发光效果
}