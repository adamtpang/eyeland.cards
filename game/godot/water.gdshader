shader_type spatial;
render_mode unshaded;
// Flat cel water: shallow colour near the island, foam rings that breathe along the shore,
// and sparse drifting glints on the open sea. The island is an ellipse (35 by 28).
uniform vec3 deep : source_color = vec3(0.07, 0.5, 0.78);
uniform vec3 shallow : source_color = vec3(0.3, 0.82, 0.9);
uniform vec3 foam : source_color = vec3(1.0);
uniform float glints = 0.6;
varying vec3 world;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i + vec2(1.0, 0.0)), f.x), mix(hash(i + vec2(0.0, 1.0)), hash(i + vec2(1.0, 1.0)), f.x), f.y);
}

void vertex() { world = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	float edge = length(vec2(world.x / 35.0, world.z / 28.0));
	vec3 color = mix(shallow, deep, smoothstep(0.95, 1.7, edge));
	float wobble = noise(world.xz * 0.35) * 0.05;
	float wave = sin((edge + wobble) * 46.0 - TIME * 1.3) * 0.5 + 0.5;
	float ring = smoothstep(0.78, 0.84, wave) * (1.0 - smoothstep(0.97, 1.2, edge)) * step(0.9, edge);
	float shore = 1.0 - smoothstep(0.925, 0.945 + wobble * 0.3, edge);
	vec2 drift = world.xz * vec2(0.08, 0.32) + vec2(TIME * 0.04, 0.0);
	float glint = step(0.72, noise(drift * 3.0)) * step(0.62, noise(drift * 9.0 + 7.0)) * smoothstep(1.15, 1.5, edge);
	ALBEDO = mix(color, foam, clamp(ring + shore + glint * glints, 0.0, 1.0));
}
