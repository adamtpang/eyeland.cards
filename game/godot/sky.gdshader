shader_type sky;
// Flat cel sky: a two-colour gradient, a hard sun or moon disc with a soft halo,
// and twinkling stars at night.
uniform vec3 top_color : source_color = vec3(0.23, 0.65, 0.91);
uniform vec3 horizon_color : source_color = vec3(0.75, 0.92, 1.0);
uniform vec3 disc_color : source_color = vec3(1.0, 0.96, 0.6);
uniform float disc_size = 0.05;
uniform float stars = 0.0;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }

void sky() {
	float height = clamp(EYEDIR.y, 0.0, 1.0);
	vec3 color = mix(horizon_color, top_color, pow(height, 0.5));
	// a paler band just above the horizon reads as distant haze
	color = mix(color, mix(horizon_color, vec3(1.0), 0.35), (1.0 - smoothstep(0.0, 0.09, EYEDIR.y)) * 0.8);
	if (stars > 0.0 && EYEDIR.y > 0.0) {
		vec2 cell = floor(EYEDIR.xz / (EYEDIR.y + 0.35) * 80.0);
		float star = step(0.991, hash(cell));
		float twinkle = 0.55 + 0.45 * sin(TIME * 2.0 + hash(cell + 3.0) * 30.0);
		color += vec3(0.95, 0.92, 0.82) * star * twinkle * stars * smoothstep(0.02, 0.3, EYEDIR.y);
	}
	float away = distance(EYEDIR, LIGHT0_DIRECTION);
	float disc = 1.0 - smoothstep(disc_size, disc_size + 0.004, away);
	float halo = (1.0 - smoothstep(disc_size, disc_size * 3.4, away)) * 0.28;
	color = mix(color, disc_color, clamp(disc + halo, 0.0, 1.0));
	COLOR = color;
}
