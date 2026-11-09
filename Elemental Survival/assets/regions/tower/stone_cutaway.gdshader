shader_type spatial;
render_mode specular_disabled;
uniform sampler2D surface_texture : source_color, filter_linear_mipmap, repeat_enable;
uniform vec4 tint : source_color = vec4(0.6,0.65,0.59,1.0);
uniform vec2 target_uv = vec2(-10.0);
uniform vec3 target_world = vec3(0.0);
uniform float radius_ratio = 0.0;
uniform bool cutaway_enabled = false;
uniform float tile_scale = 0.35;
varying vec3 world_position;
varying vec3 world_normal;
void vertex(){
	world_position=(MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
	world_normal=normalize(MODEL_NORMAL_MATRIX*NORMAL);
}
void fragment(){
	vec3 weight=pow(abs(world_normal),vec3(4.0));
	weight/=max(weight.x+weight.y+weight.z,0.001);
	vec3 stone=texture(surface_texture,world_position.zy*tile_scale).rgb*weight.x;
	stone+=texture(surface_texture,world_position.xz*tile_scale).rgb*weight.y;
	stone+=texture(surface_texture,world_position.xy*tile_scale).rgb*weight.z;
	ALBEDO=stone*tint.rgb;
	ROUGHNESS=0.94;
	float target_depth=-(VIEW_MATRIX*vec4(target_world,1.0)).z;
	if(!IN_SHADOW_PASS && cutaway_enabled && -VERTEX.z<target_depth+0.12){
		float r=radius_ratio*VIEWPORT_SIZE.y;
		float d=distance(SCREEN_UV*VIEWPORT_SIZE,target_uv*VIEWPORT_SIZE);
		float edge=smoothstep(r*0.66,r,d);
		float pattern=mod(floor(FRAGCOORD.x/2.0)+2.0*floor(FRAGCOORD.y/2.0),4.0)/4.0;
		if(edge<0.03 || pattern>edge){discard;}
	}
}
