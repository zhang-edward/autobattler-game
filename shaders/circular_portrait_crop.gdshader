shader_type canvas_item;

// 0.5 = circle just touches the edges of the composited buffer's
// shorter dimension. Shrink this if the border clips into the art.
uniform float radius : hint_range(0.0, 1.0) = 0.48;
uniform float border_width : hint_range(0.0, 0.2) = 0.03;
uniform vec4 border_color : source_color = vec4(1.0, 1.0, 1.0, 1.0);

void fragment() {
	// CanvasGroup's merged buffer is sized to fit its children's bounding
	// box and isn't guaranteed square, so measure distance in actual pixels
	// (normalized against the shorter side) rather than raw UV, or the
	// circle would come out stretched into an ellipse.
	vec2 tex_size = vec2(1.0) / TEXTURE_PIXEL_SIZE;
	float shorter_side = min(tex_size.x, tex_size.y);

	vec2 centered_uv = UV - vec2(0.5);
	vec2 pixel_offset = centered_uv * tex_size;
	float dist = length(pixel_offset) / shorter_side;

	if (dist > radius) {
		COLOR = vec4(0.0);
	} else if (dist > radius - border_width) {
		COLOR = border_color;
	} else {
		COLOR = texture(TEXTURE, UV);
	}
}
