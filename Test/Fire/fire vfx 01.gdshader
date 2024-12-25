shader_type spatial;
render_mode unshaded;

// 添加必要的 uniform 变量
uniform float rotation_speed : hint_range(0.0, 2.0) = 0.5;
uniform vec3 sun_color : source_color = vec3(0.875, 0.297, 0.171);
uniform float absorption : hint_range(0.0, 1.0) = 0.15;
uniform float scatter : hint_range(0.0, 1.0) = 0.2;

// 噪声函数
float hash(vec3 p) {
    p = fract(p * 0.3183099 + 0.1);
    p *= 17.0;
    return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}

// 分形布朗运动实现
float fbm(vec3 p) {
    float value = 0.0;
    float amplitude = 0.5;
    float frequency = 1.0;

    for (int i = 0; i < 5; i++) {
        value += amplitude * hash(p * frequency);
        amplitude *= 0.5;
        frequency *= 2.0;
    }

    return value;
}

// 密度函数
float density(vec3 p) {
    return 0.1 - length(p) * 0.06 + fbm(p * 0.3 - vec3(TIME));
}

// 相机矩阵
mat3 camera(vec3 cameraPos, vec3 lookAtPoint) {
    vec3 cd = normalize(lookAtPoint - cameraPos);
    vec3 cr = normalize(cross(vec3(0.0, 1.0, 0.0), cd));
    vec3 cu = normalize(cross(cd, cr));
    return mat3(-cr, cu, -cd);
}

void fragment() {
    // 转换UV坐标
    vec2 uv = (UV * 2.0 - 1.0) * vec2(1.0, 1.0);

    // 设置相机和光线方向
    vec3 look_point = vec3(0.0);
    vec3 ray_origin = 25.0 * vec3(cos(-TIME * rotation_speed), 0.0, sin(-TIME * rotation_speed));
    vec3 ray_dir = camera(ray_origin, look_point) * normalize(vec3(uv, -1.0));

    vec3 color = vec3(0.0);

    const int MAX_STEP = 80;
    const float MAX_DIST = 60.0;
    float ds = MAX_DIST / float(MAX_STEP);
    float T = 1.0;

    // 光线步进
    for(int i = 0; i < MAX_STEP; i++) {
        vec3 p1 = ray_origin + float(i) * ds * ray_dir;
        float d1 = density(p1);

        if(d1 > 0.0) {
            T *= exp(-d1 * absorption * ds);
            if(T <= 0.6) break;

            // 光散射计算
            float Tl = 1.0;
            for(int j = 0; j < MAX_STEP/16; j++) {
                vec3 p2 = p1 + float(j) * ds * 16.0 * vec3(1.0, 0.0, 0.0);
                float d2 = density(p2);
                if(d2 > 0.0) {
                    Tl *= exp(-d2 * absorption * ds * 16.0);
                    if(Tl <= 0.2) break;
                }
            }

            color += sun_color * T * Tl * ds;
        }
    }

    color = scatter * color;
    color = pow(color, vec3(2.0/2.2)); // Gamma correction

    ALBEDO = color;
    EMISSION = color; // 添加发光效果
}