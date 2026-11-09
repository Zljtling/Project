shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float clock = 0.0;
uniform float phase = 0.0;
float hash(vec2 p) { return fract(sin(dot(p,vec2(127.1,311.7)))*43758.5453); }
float noise(vec2 p) {
	vec2 i=floor(p); vec2 f=fract(p); f=f*f*(3.0-2.0*f);
	return mix(mix(hash(i),hash(i+vec2(1,0)),f.x),mix(hash(i+vec2(0,1)),hash(i+vec2(1,1)),f.x),f.y);
}
void vertex() {
	float age = fract(clock*0.075+phase);
	VERTEX.xz *= 0.7+age*0.8;
	VERTEX.y += age*4.8;
	VERTEX.x += sin(age*4.0+phase*20.0)*age*1.4;
}
void fragment() {
	vec2 p = UV-0.5;
	float age = fract(clock*0.075+phase);
	float cloud=noise(UV*4.0+vec2(phase*23.0,-clock*0.12));
	cloud=cloud*0.7+noise(UV*9.0+vec2(clock*0.06,phase*12.0))*0.3;
	float edge=1.0-smoothstep(0.18,0.49,length(p*vec2(1.0,0.85))+(cloud-0.5)*0.13);
	float fade=smoothstep(0.0,0.18,age)*(1.0-smoothstep(0.58,1.0,age));
	ALBEDO=mix(vec3(0.43,0.52,0.26),vec3(0.74,0.79,0.48),cloud);
	ALPHA=edge*fade*(0.10+cloud*0.18);
}
