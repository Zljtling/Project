shader_type spatial;
render_mode cull_disabled, specular_disabled;
uniform sampler2D blades : source_color, filter_linear_mipmap;
uniform float clock = 0.0;
varying vec3 world_at;
void vertex() {
	world_at=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	float tip=1.0-UV.y;
	VERTEX.x += (sin(clock*1.3+world_at.x*0.8+world_at.z*0.5)*0.06+sin(clock*2.1+world_at.z)*0.025)*tip*tip;
}
void fragment() {
	vec4 grass=texture(blades,UV);
	float patch=sin(world_at.x*0.22+world_at.z*0.33)*0.5+0.5;
	ALBEDO=grass.rgb*mix(vec3(0.48,0.62,0.40),vec3(0.71,0.78,0.52),patch);
	ALPHA=grass.a;
	ALPHA_SCISSOR_THRESHOLD=0.35;
	ROUGHNESS=1.0;
}
