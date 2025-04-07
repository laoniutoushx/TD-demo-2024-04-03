shader_type spatial;
render_mode blend_add, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx, unshaded;

// 质量设置 - 取消注释其中一个
#define SHQ
//#define MEDQ
//#define YUCKQ

uniform sampler2D noise_texture; // 对应原始着色器中的 iChannel0
uniform sampler2D skybox_texture; // 对应原始着色器中的 iChannel1
uniform float time : hint_range(0, 100) = 0.0; // 时间变量
uniform sampler2D SCREEN_TEXTURE : hint_screen_texture, filter_linear_mipmap;

const float tmax = 20.0;

float sdSphere(vec3 p, float s) {
    return length(p) - s;
}

float sdCappedCylinder(vec3 p, float h, float r) {
    vec2 d = abs(vec2(length(p.xz), p.y)) - vec2(h, r);
    return min(max(d.x, d.y), 0.0) + length(max(d, vec2(0.0)));
}

vec2 opU(vec2 d1, vec2 d2) {
    return (d1.x < d2.x) ? d1 : d2;
}

vec2 sdScene(vec3 p) {
    vec2 res = vec2(999.0);
    float r = 7.4;
    res = opU(res, vec2(sdCappedCylinder(p - vec3(0.0, 0.0, 0.0), r, 4.0), r));
    return res;
}

// 3D噪声函数 (基于纹理LUT)
float noise(in vec3 x) {
    vec3 f = fract(x);
    vec3 p = x - f;
    f = f * f * (3.0 - 2.0 * f);
    
    vec2 uv = (p.xy + vec2(37.0, 17.0) * p.z) + f.xy;
    vec2 rg = textureLod(noise_texture, (uv + 0.5) / 256.0, 0.0).yx;
    return mix(rg.x, rg.y, f.z);
}

vec3 computeColour(float density) {
    vec3 result = mix(vec3(0.9, 0.9, 0.9), vec3(0.25, 0.25, 0.25), density);
    return result;
}

float Turbulence(vec3 p) {
    float t = 0.0;
    float oof = 1.0;
    for (int i = 0; i < 7; i++) {
        t += abs(noise(p)) * oof;
        oof *= 0.5;
        p *= 2.7; // 数字越大，细节越多
    }
    
    return t - 1.0;
}

vec4 map(in vec3 p) {
    // 参数设置
    float rotateS = 2.6;
    float riseS = 3.55;
    float rmax = 4.2;
    float rmin = 1.2;
    
    vec3 bottom = vec3(0.0, -4.4, 0.0);
    float den = 0.0;
    float maxH = 8.8;
    vec3 lp = p;
    float height = lp.y - bottom.y + noise(lp) * rmin * 0.33;
    float tease = height / maxH;
    
    float theta_s = TIME * rotateS;
    float down = riseS * time;
    float c = cos(-theta_s - p.y);
    float s = sin(-theta_s - p.y);
    float c1 = cos(-theta_s - p.y);
    float s1 = sin(-theta_s - p.y);
    
    float noi = noise(p);
    float scale = 1.0;
    scale *= noi * 0.01 + 0.77 + 0.23 * abs(sin((p.y + sin(time * 3.3) * 0.1 + noi * 0.08) * 1.9));
    scale *= (0.56 + 0.44 * abs(sin((tease + 0.5) * 3.14159)));
    scale *= 0.6 + tease * 0.3;
    
    vec3 lp1 = lp;
    lp.x *= scale;
    lp.z *= scale;
    lp1.x = lp.x * c - lp.z * s;
    lp1.z = lp.x * s + lp.z * c;
    lp1.y -= down;
    float turb = Turbulence(lp1);
    
    float r = rmax * scale + turb * 0.3 * rotateS;
    float r_sq = r * r;
    float roffset = r * 0.2;
    vec3 center = vec3(roffset * c1, p.y, roffset * s1);
    center.x += turb * 0.1;
    center.y += turb * 0.2;
    center.z += turb * 0.1;
    vec3 diff = p - center;
    float dist_sq = diff.x * diff.x + diff.y * diff.y + diff.z * diff.z;
    den = (1.0 - dist_sq / r_sq + turb * 0.45) * 1.11;
    float rn_seq = (p.x * p.x + p.z * p.z) / r;
    rn_seq = clamp(rn_seq, 0.0, 1.0);
    den *= (0.22 + 0.78 * abs(sin(rn_seq * 3.14159)));
    den *= pow(rmax / r, 2.0);
    
    den = clamp(den, 0.0, 1.0);
    den = pow(den, 0.4);
    
    // 创建颜色
    vec3 color = mix(vec3(0.9, 0.9, 0.9), vec3(0.45, 0.45, 0.45), den);
    return vec4(color, den);
}

vec4 raytraceVolumetric(in vec3 rayo, in vec3 rayd, in float t) {
    vec3 pos = rayo + rayd * t;
    float d = sdScene(pos).x;
    vec4 sum = vec4(0.0);
    
    float last_t = t;
    
    #ifdef SHQ
    float steps = 128.0;
    float dt = 0.062;
    #endif
    #ifdef MEDQ
    float steps = 64.0;
    float dt = 0.124;
    #endif
    #ifdef YUCKQ
    float steps = 32.0;
    float dt = 0.248;
    #endif
    
    for (float i = 0.0; i < steps && t < tmax && d < t * 0.001; i += 1.0) {
        if (sum.a > 0.99) continue;
        
        vec4 col = map(pos);
        col.a *= (t - last_t) * 1.5;
        
        // 通过alpha对颜色进行处理
        col.rgb *= col.a;
        
        // alpha混合贡献
        sum = sum + col * (1.0 - sum.a);
        
        // 沿射线前进
        last_t = t;
        t += dt;
        pos = rayo + rayd * t;
        d = sdScene(pos).x;
    }
    
    // 在Godot中处理天空盒背景
    vec3 sky_dir = normalize(rayd);
    vec4 bg = texture(skybox_texture, vec2(
        atan(sky_dir.x, sky_dir.z) / (2.0 * 3.14159) + 0.5,
        acos(sky_dir.y) / 3.14159
    ));
    bg.rgb *= bg.a;
    sum = sum + bg * (1.0 - sum.a);
    
    return clamp(sum, 0.0, 1.0);
}

vec4 raymarch(in vec3 rayo, in vec3 rayd) {
    vec3 pos = rayo;
    float t = 0.0;
    
    for (int i = 0; i < 15 && t < tmax; i++) {
        vec2 h = sdScene(pos);
        if (h.x < 0.0001 * t) {
            return raytraceVolumetric(rayo, rayd, t);
        }
        t += h.x;
        pos = rayo + rayd * t;
    }
    
    // 处理天空盒背景
    vec3 sky_dir = normalize(rayd);
    vec4 bg = texture(skybox_texture, vec2(
        atan(sky_dir.x, sky_dir.z) / (2.0 * 3.14159) + 0.5,
        acos(sky_dir.y) / 3.14159
    ));
    bg.rgb *= bg.a;
    return bg;
}

void fragment() {
    // 使用视口大小而不是SCREEN_TEXTURE的大小
    ivec2 viewport_size = textureSize(SCREEN_TEXTURE, 0);
    vec2 q = FRAGCOORD.xy / vec2(viewport_size);
    vec2 p = -1.0 + 2.0 * q;
    p.x *= float(viewport_size.x) / float(viewport_size.y);
    
    // 固定相机位置（移除鼠标交互）
    float camRadius = 9.8;
    float theta = 3.1415926 * 0.5; // 固定相机角度
    float xoff = camRadius * cos(theta);
    float zoff = camRadius * sin(theta);
    vec3 cameraPos = vec3(xoff, 0.0, zoff);
    
    // 相机目标
    vec3 target = vec3(0.0, 0.0, 0.0);
    
    // 相机框架
    vec3 fo = normalize(target - cameraPos);
    vec3 ri = normalize(vec3(fo.z, 0.0, -fo.x));
    vec3 up = normalize(cross(fo, ri));
    
    // 控制FOV的乘数
    float fov = 0.5;
    
    // 射线方向
    vec3 rayDir = normalize(fo + fov * p.x * ri + fov * p.y * up);
    
    // 渲染
    vec4 col = raymarch(cameraPos, rayDir);
    
    // 用平滑步进处理最终颜色以增加对比度
    ALBEDO = col.xyz * col.xyz * (3.0 - 2.0 * col.xyz);
    ALPHA = col.a;
}