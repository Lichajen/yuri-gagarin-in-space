shader_type canvas_item;

uniform sampler2D screen_texture : hint_screen_texture;
uniform float brightness = 1.0;
uniform float yellow_tint = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
}

void fragment() {
	// Called for every pixel the material is visible on.
	vec4 colour = texture(screen_texture, SCREEN_UV);
	colour.r *= brightness;
	colour.g = colour.r;
	colour.b = colour.r * yellow_tint;
	
	COLOR = colour;
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
