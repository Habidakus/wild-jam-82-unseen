shader_type canvas_item;

uniform vec2 direction;
uniform float fraction;

void fragment() {
    vec2 vec_from_center = UV - vec2(0.5, 0.5) - (fraction - 0.5) * direction;
    float closeness_to_center = (0.5 - length(vec_from_center));
    float closeness_measure = closeness_to_center + abs(closeness_to_center);
    vec2 norm_from_center = normalize(vec_from_center);
    vec2 perp_vec_from_center = vec2(vec_from_center.y, 0.0 - vec_from_center.x);
    vec2 norm_perp = normalize(perp_vec_from_center);
    vec2 norm_dir = normalize(direction);
    float is_space_in_middle = abs(dot(norm_perp, norm_dir));
    float is_time_in_middle = 10.0 * ((fraction - 0.4) + abs(fraction - 0.4)) / 2.0;
    float alpha = is_space_in_middle * is_space_in_middle *is_space_in_middle * is_time_in_middle * closeness_measure; 
    COLOR.rgba = vec4(1, 1, 1, alpha);
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
