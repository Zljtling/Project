shader_type spatial;
render_mode specular_disabled;
uniform vec4 shadow_grass : source_color = vec4(0.28, 0.37, 0.21, 1.0);
uniform vec4 mid_grass : source_color = vec4(0.31, 0.40, 0.23, 1.0);
uniform vec4 light_grass : source_color = vec4(0.34, 0.43, 0.24, 1.0);
varying vec2 world_ground;

float hash(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hash(i), hash(i+vec2(1,0)), f.x), mix(hash(i+vec2(0,1)), hash(i+vec2(1,1)), f.x), f.y);
}
void vertex() { world_ground = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz; }
void fragment() {
	vec2 p = world_ground;
	float field = noise(p * 0.12)*0.65+noise(p*0.34)*0.28+noise(p*2.5)*0.07;
	vec3 color = mix(vec3(0.23,0.32,0.20),vec3(0.39,0.46,0.29),smoothstep(0.2,0.8,field));
	color += (noise(p*12.0)-0.5)*0.016;
	ALBEDO = color;
	ROUGHNESS = 1.0;
}
