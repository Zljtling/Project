shader_type spatial;
render_mode specular_disabled;
uniform vec4 deep_water : source_color = vec4(0.12, 0.28, 0.30, 1.0);
uniform vec4 shallow_water : source_color = vec4(0.19, 0.37, 0.35, 1.0);
uniform float clock = 0.0;
varying vec2 world_water;
void vertex() { world_water = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz; }
void fragment() {
	vec2 p = world_water;
	float wave = sin(p.x*0.7+clock*0.35)+cos(p.y*0.9-clock*0.2);
	float ripple=sin(p.x*4.4+p.y*1.3+clock*1.1+wave*1.3);
	float glint=smoothstep(0.96,1.0,ripple)*smoothstep(0.4,1.5,wave)*0.19;
	ALBEDO = mix(deep_water.rgb, shallow_water.rgb, (wave+2.0)*0.25)+vec3(0.40,0.52,0.42)*glint;
	ROUGHNESS = 0.66;
}
