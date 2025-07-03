shader_type canvas_item;

uniform float time = 0;
uniform float alignment = 0;
uniform float ring1_speed = -1;
uniform float ring2_speed = 2;
uniform float ring3_speed = 3;
uniform float ring4_speed = -5;
uniform float ring5_speed = 7;

float CalcBubble(float speed, float dist, vec2 pixel)
{
    float radius = 0.15;
    float ret_val = 0.0;
    for (float i = 0.0; i<3.0; ++i)
    {
        float rad = alignment + 0.2 * time * speed + i * 0.4 * speed / abs(speed);
        float x = cos(rad) * dist;
        float y = sin(rad) * dist;
        float len = length(pixel - vec2(x, y));
        float glow = radius - len;
        glow = (glow + abs(glow)) / (2.0 * radius);
        glow = glow * glow;
        ret_val = max(glow, ret_val);
        radius /= 2.0;
    }
    return ret_val;
}

void fragment() {
    vec2 vec_from_center = 2.0 * (UV - vec2(0.5, 0.5));
    float chance1 = CalcBubble(ring1_speed, 2.0/7.0, vec_from_center);
    float chance2 = CalcBubble(ring2_speed, 3.0/7.0, vec_from_center);
    float chance3 = CalcBubble(ring3_speed, 4.0/7.0, vec_from_center);
    float chance4 = CalcBubble(ring4_speed, 5.0/7.0, vec_from_center);
    float chance5 = CalcBubble(ring5_speed, 6.0/7.0, vec_from_center);
    float alpha = max(max(max(chance1, chance2), max(chance3, chance4)), chance5);
    COLOR.rgba = vec4(1, 1, 1, alpha);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
