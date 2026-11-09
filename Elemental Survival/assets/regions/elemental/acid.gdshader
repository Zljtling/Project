shader_type spatial;
render_mode cull_disabled;
uniform float clock = 0.0;
varying vec2 world_uv;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() { world_uv = VERTEX.xz; }
void fragment() {
	vec2 p = world_uv;
	float field = noise(p*0.18+vec2(clock*0.008,0.0))*0.7+noise(p*0.6-vec2(0.0,clock*0.012))*0.3;
	float vein = sin(p.y*0.45+p.x*0.25+noise(p*0.18)*4.0+clock*0.12);
	vec3 deep = vec3(0.08,0.15,0.046);
	vec3 light = vec3(0.24,0.33,0.10);
	float swirl=smoothstep(0.88,1.0,vein)*0.09;
	float ripple=sin(p.x*3.2+p.y*1.4+field*10.0-clock*0.65);
	float glint=smoothstep(0.97,1.0,ripple)*smoothstep(0.48,0.72,field)*0.06;
	ALBEDO = mix(deep,light,smoothstep(0.18,0.82,field))+vec3(0.35,0.40,0.14)*(swirl+glint);
	vec2 q = world_uv/vec2(29.0,25.0);
	float a = atan(q.y,q.x);
	float shore = 1.0+0.035*sin(a*5.0)+0.022*cos(a*9.0);
	ALBEDO = mix(ALBEDO,vec3(0.36,0.42,0.16),smoothstep(shore-0.018,shore,length(q))*0.65);
	EMISSION = ALBEDO*0.07;
	ROUGHNESS = 0.58;
}
