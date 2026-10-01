shader_type canvas_item;
uniform float unavailable : hint_range(0.0, 1.0) = 0.0;
void fragment() {
    vec4 pixel = COLOR;
    float gray = dot(pixel.rgb, vec3(0.2126, 0.7152, 0.0722));
    pixel.rgb = mix(pixel.rgb, vec3(gray), unavailable * 0.65);
    pixel.rgb *= 1.0 - unavailable * 0.18;
    COLOR = pixel;
}
