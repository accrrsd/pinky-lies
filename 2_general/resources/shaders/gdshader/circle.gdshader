shader_type canvas_item;

uniform float edge_softness: hint_range(0.0, 0.5, 0.001) = 0.005;

void fragment() {
    vec2 uv = UV * 2.0 - 1.0;
    float dist = length(uv);
    float alpha = 1.0 - smoothstep(1.0 - edge_softness, 1.0, dist);
    COLOR.a *= alpha;
}