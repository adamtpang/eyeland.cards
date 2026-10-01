shader_type spatial;
render_mode diffuse_toon, specular_disabled;
// Cel ground: flat vertex colours with hard-edged brush dabs and sun patches on the grass,
// and a light speckle on the sand.
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
	vec3 base = COLOR.rgb;
	float grass = 1.0 - step(0.7, base.r);  // sand is the only ground colour with a high red channel
	float patch = step(0.6, noise(world.xz * 0.17));
	float dab = step(0.72, noise(world.xz * vec2(2.4, 1.0) + 3.0)) * step(0.45, noise(world.xz * 6.5));
	vec3 color = mix(base, base * 1.09, patch * grass);
	color = mix(color, base * 0.8, dab * grass);
	color -= step(0.8, noise(world.xz * 5.0)) * 0.07 * (1.0 - grass);
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
