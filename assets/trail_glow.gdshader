shader_type canvas_item;
render_mode unshaded;

uniform float edge_softness : hint_range(0.0, 1.0) = 0.5;

void fragment() {
	float dist = abs(UV.y - 0.5) * 2.0;
	float soft = 1.0 - smoothstep(edge_softness, 1.0, dist);
	COLOR.a *= soft;
}
