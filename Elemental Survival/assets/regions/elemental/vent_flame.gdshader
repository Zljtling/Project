shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;
uniform float clock = 0.0;
void vertex() {
	float tip=1.0-UV.y;
	VERTEX.x += sin(clock*4.5+VERTEX.y*2.4)*tip*0.13;
}
void fragment() {
	float y=1.0-UV.y;
	float drift=sin(y*7.0-clock*4.8)*0.08*y+sin(y*13.0+clock*3.7)*0.035;
	float width=mix(0.36,0.025,pow(y,0.8));
	float edge=1.0-smoothstep(width*0.62,width,abs(UV.x-0.5+drift));
	float tip=1.0-smoothstep(0.72+sin(clock*3.0)*0.06,1.0,y);
	float base=smoothstep(0.0,0.09,y);
	vec3 fire=mix(vec3(1.0,0.72,0.27),vec3(0.88,0.20,0.045),y);
	float core=(1.0-smoothstep(0.0,width*0.55,abs(UV.x-0.5+drift)))*(1.0-y);
	ALBEDO=mix(fire,vec3(1.0,0.94,0.66),core);
	EMISSION=ALBEDO*1.2;
	ALPHA=edge*tip*base*0.8;
}
