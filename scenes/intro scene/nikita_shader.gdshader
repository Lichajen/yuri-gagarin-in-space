shader_type canvas_item;

uniform float alpha_line = 1.0;
uniform float alpha_mult = 1.0;

void vertex() {
	// Called for every vertex the material is visible on.
	
	COLOR.a *= float(UV.y < alpha_line);
	COLOR.a *= alpha_mult;
}

void fragment() {
	// Called for every pixel the material is visible on.
}

//void light() {
//	// Called for every pixel for every light affecting the CanvasItem.
//	// Uncomment to replace the default light processing function with this one.
//}
