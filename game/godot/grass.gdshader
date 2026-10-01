shader_type spatial;
render_mode diffuse_toon, specular_disabled, cull_disabled;
// Grass blades drawn as one MultiMesh. Tips sway in a slow wind; roots stay planted.
void vertex() {
	vec3 origin = MODEL_MATRIX[3].xyz;
	float tip = VERTEX.y + 0.17;
	VERTEX.x += sin(TIME * 1.7 + origin.x * 0.6 + origin.z * 0.4) * 0.28 * tip;
}

void fragment() {
	ALBEDO = COLOR.rgb;
	ROUGHNESS = 1.0;
}
