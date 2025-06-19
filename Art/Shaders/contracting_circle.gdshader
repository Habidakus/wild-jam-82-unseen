shader_type canvas_item;

uniform float fraction;

void fragment() {
    vec2 vec_from_center = UV - vec2(0.5, 0.5);
    float closeness_to_center = (0.5 - length(vec_from_center));
    float closeness_measure = closeness_to_center + abs(closeness_to_center);
    float far_from_fraction = 0.1 - abs(fraction - closeness_measure);
    float abs_fff = 10.0 * (far_from_fraction + abs(far_from_fraction)) * sqrt(closeness_to_center);
    float alpha = abs_fff * abs_fff;
    COLOR.rgba = vec4(1, 1, 1, alpha);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
