shader_type canvas_item;

// Maximum number of distinct color swaps allowed
const int MAX_COLORS = 4;

// Enable how many color swaps to perform (up to 4)
uniform int active_colors : hint_range(1, 4) = 2;

// Arrays for source colors, target colors, and individual tolerances
uniform vec4 source_colors[MAX_COLORS] : source_color;
uniform vec4 target_colors[MAX_COLORS] : source_color;
uniform float tolerances[MAX_COLORS];

void fragment() {
    vec4 tex_color = texture(TEXTURE, UV);

    // Default to keeping the original pixel color
    vec4 final_color = tex_color;

    // Only process non-transparent pixels
    if (tex_color.a > 0.0) {
        for (int i = 0; i < MAX_COLORS; i++) {
            if (i >= active_colors) {
                break;
            }

            float dist = distance(tex_color.rgb, source_colors[i].rgb);

            // Check if the current pixel matches the source color within its tolerance
            if (dist <= tolerances[i]) {
                final_color = vec4(target_colors[i].rgb, tex_color.a);
                break; // Stop at the first matching color
            }
        }
    }

    COLOR = final_color;
}