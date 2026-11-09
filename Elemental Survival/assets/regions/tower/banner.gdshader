shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform float clock = 0.0;
void vertex(){
	VERTEX.z+=sin(clock*1.8+UV.y*5.0+MODEL_MATRIX[3].x)*UV.y*0.12;
}
void fragment(){
	float border=step(UV.x,0.10)+step(0.90,UV.x);
	float sigil=1.0-smoothstep(0.025,0.05,abs(abs(UV.x-0.5)+abs(UV.y-0.43)*0.65-0.18));
	ALBEDO=mix(vec3(0.09,0.25,0.26),vec3(0.57,0.40,0.16),clamp(border+sigil,0.0,1.0));
	ROUGHNESS=1.0;
}
