shader_type canvas_item;
// One shader for cards, tokens and hero portraits.
// Artwork draws are tagged with a marker vertex colour (see card_face.gd ART) so only the
// illustration is restyled; frames, gems and text pass through untouched.
uniform float unavailable : hint_range(0.0, 1.0) = 0.0;
uniform float style = 0.0;    // 0 painted (classic), 1 cel (day), 2 engraved (night)
uniform float all_art = 0.0;  // 1 when the whole item is artwork
varying float is_art;

void vertex() {
	bool tagged = abs(COLOR.r - 0.5) < 0.02 && abs(COLOR.g - 0.25) < 0.02 && abs(COLOR.b - 0.75) < 0.02;
	is_art = (tagged || all_art > 0.5) ? 1.0 : 0.0;
	if (tagged) COLOR = vec4(1.0);
}

float luma(vec3 c) { return dot(c, vec3(0.2126, 0.7152, 0.0722)); }

void fragment() {
	vec4 pixel = COLOR;
	if (is_art > 0.5 && style > 0.5) {
		float l = luma(pixel.rgb);
		if (style < 1.5) {
			// Cel: five flat value bands lifted toward the light, stronger colour, ink only on strong edges.
			float band = (floor(l * 5.0) + 0.8) / 5.0;
			vec3 flat_color = clamp(pixel.rgb / max(l, 0.06) * band, 0.0, 1.0);
			float grey = luma(flat_color);
			flat_color = clamp(mix(vec3(grey), flat_color, 1.35) * 1.08, 0.0, 1.0);
			vec2 step_size = TEXTURE_PIXEL_SIZE * 9.0;
			float dx = luma(texture(TEXTURE, UV + vec2(step_size.x, 0.0)).rgb) - luma(texture(TEXTURE, UV - vec2(step_size.x, 0.0)).rgb);
			float dy = luma(texture(TEXTURE, UV + vec2(0.0, step_size.y)).rgb) - luma(texture(TEXTURE, UV - vec2(0.0, step_size.y)).rgb);
			float edge = smoothstep(0.34, 0.6, length(vec2(dx, dy)));
			pixel.rgb = mix(flat_color, vec3(0.114, 0.165, 0.302), edge * 0.7);
		} else {
			// Engraved: bone ink on indigo, tone carried by diagonal hatching.
			float hatch = sin((FRAGCOORD.x + FRAGCOORD.y) * 1.7) * 0.5 + 0.5;
			float cross_hatch = sin((FRAGCOORD.x - FRAGCOORD.y) * 1.7) * 0.5 + 0.5;
			float tone = smoothstep(0.0, 0.12, l * 1.25 - hatch * 0.75);
			tone = min(tone, smoothstep(0.0, 0.12, l * 2.6 - cross_hatch * 0.75));
			tone = mix(tone, l, 0.3);
			pixel.rgb = mix(vec3(0.075, 0.066, 0.115), vec3(0.851, 0.812, 0.722), tone);
		}
	}
	float gray = luma(pixel.rgb);
	pixel.rgb = mix(pixel.rgb, vec3(gray), unavailable * 0.65);
	pixel.rgb *= 1.0 - unavailable * 0.18;
	COLOR = pixel;
}
