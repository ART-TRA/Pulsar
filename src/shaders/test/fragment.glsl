uniform float uTime;
uniform vec2 uMouse;
varying vec2 vUv;

mat4 rotationMatrix(vec3 axis, float angle) {
    axis = normalize(axis);
    float s = sin(angle);
    float c = cos(angle);
    float oc = 1.0 - c;

    return mat4(oc * axis.x * axis.x + c, oc * axis.x * axis.y - axis.z * s, oc * axis.z * axis.x + axis.y * s, 0.0,
    oc * axis.x * axis.y + axis.z * s, oc * axis.y * axis.y + c, oc * axis.y * axis.z - axis.x * s, 0.0,
    oc * axis.z * axis.x - axis.y * s, oc * axis.y * axis.z + axis.x * s, oc * axis.z * axis.z + c, 0.0,
    0.0, 0.0, 0.0, 1.0);
}

vec3 getColor(float amount) {
    //color(t) = a + b ⋅ cos[ 2π(c⋅t+d)] https://iquilezles.org/www/articles/palettes/palettes.htm
    vec3 col = 0.5 + 0.5 * cos(6.28319*(vec3(0.2, 0.0, 0.0) + amount * vec3(1.0, 1.0, 0.5)));
    return col * amount;
}

//get the color depending on the distance to the center
vec3 getColorAmount(vec3 p) {
    //clamp - constrain a value to lie between two further values
    float amount = clamp((1.5 - length(p))/2.0, 0.0, 1.0);
    vec3 col = 0.5 + 0.5 * cos(6.28319*(vec3(0.2, 0.0, 0.0) + amount * vec3(1.0, 1.0, 0.5)));
    return col * amount;
}

vec3 rotate(vec3 v, vec3 axis, float angle) {
    mat4 m = rotationMatrix(axis, angle);
    return (m * vec4(v, 1.0)).xyz;
}

float sphere(vec3 point, float radius) {
    return length(point) - radius;
}

float sdBox(vec3 p, vec3 b) {
    vec3 q = abs(p) - b;
    return length(max(q, 0.0)) + min(max(q.x, max(q.y, q.z)), 0.0);
}

float sinShape(vec3 p) {
    return 1.0 - (sin(p.x) + sin(p.y) + sin(p.z))/3.0;
}

float scene(vec3 p) {
    vec3 p1 = rotate(p, vec3(1.0), uTime*0.2);
    //    return sphere(p, 0.5);
    //    return sdBox(p1, vec3(0.5));
    float scale = 15.0 + 10.0*sin(uTime*0.2);
    return max(sphere(p1, 0.5), (0.85 - sinShape(p1*scale))/scale);
}

vec3 getNormal(vec3 p) {
    vec2 o = vec2(0.001, 0.0);
    return normalize(vec3(
    scene(p + o.xyy) - scene(p - o.xyy),
    scene(p + o.yxy) - scene(p - o.yxy),
    scene(p + o.yyx) - scene(p - o.yyx)
    ));

}

void main() {
    float alpha = 1.0 - step(0.5, length(gl_PointCoord - vec2(0.5)));
    vec2 p = vUv - vec2(0.5);
    p.x += uMouse.x * 0.07;
    p.y -= uMouse.y * 0.07;

    vec3 camPos = vec3(0.0, 0.0, 4.0 + 0.5*sin(uTime*0.4));//2 - приближение по z (положение камеры)
    vec3 ray = normalize(vec3(p, -1.0));//-1 - отдаление по z (объект за экраном)
    vec3 rayPos = camPos;
    float curDist = 0.0;
    float rayLength = 0.0;
    vec3 light = vec3(-1.0, 1.0, 1.0);
    vec3 color = vec3(0.0);

    //для raymatching стандартно берётся от 64 до 100 циклов
    for (int i = 0; i < 64; ++i) {
        //rayPos - текущее положение ray
        curDist = scene(rayPos);
        rayLength += 0.6 * curDist;

        //next step position
        rayPos = camPos + ray*rayLength;

        //если дистанция до необх объекта слишком низкая, то достигли его
        if (abs(curDist) < 0.001) {
            vec3 n = getNormal(rayPos);//точка пересечение луча с необх объектом
            float diff = dot(n, light);//произв-е векторов x[0]*y[0]+x[1]*y[1]...
            // color = getColor(diff);
            // color = getColor(2.8 - length(rayPos));
            break;
        }
        color += 0.02 * getColorAmount(rayPos);
    }
    gl_FragColor = vec4(color, 1.0);

    //в завис-ти от приближ-я курсора фигура становится ярче
//    gl_FragColor = vec4(color, 1.0)*clamp(1.0 - abs(uMouse.x), 0.8, 1.0);
    //в завис-ти от приближ-я курсора фигура меняет цвет
    gl_FragColor.r -= abs(uMouse.x) * 0.6;
}