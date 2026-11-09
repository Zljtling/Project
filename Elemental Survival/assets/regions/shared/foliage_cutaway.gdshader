shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D leaf_texture : source_color, filter_linear, repeat_disable;
uniform vec2 target_uv = vec2(-10.0);
uniform vec3 target_world = vec3(0.0);
uniform float radius_ratio = 0.0;
uniform bool cutaway_enabled = true;
uniform float clock = 0.0;

void vertex() {
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(MAIN_CAM_INV_VIEW_MATRIX[0], MAIN_CAM_INV_VIEW_MATRIX[1], MAIN_CAM_INV_VIEW_MATRIX[2], MODEL_MATRIX[3]);
	VERTEX.x += sin(clock*1.1+MODEL_MATRIX[3].x*0.7+MODEL_MATRIX[3].z*0.4)*(1.0-UV.y)*0.045;
}

void fragment() {
	vec4 leaf = texture(leaf_texture, UV);
	if (leaf.a < 0.5) { discard; }
	// Only foliage between the camera and the character is cut away.
	float target_depth = -(VIEW_MATRIX * vec4(target_world, 1.0)).z;
	if (!IN_SHADOW_PASS && cutaway_enabled && -VERTEX.z < target_depth + 0.15) {
		vec2 pixel = floor(SCREEN_UV * VIEWPORT_SIZE / 3.0) * 3.0;
		vec2 target = target_uv * VIEWPORT_SIZE;
		float radius_pixels = radius_ratio * VIEWPORT_SIZE.y;
		float edge = smoothstep(radius_pixels * 0.72, radius_pixels, distance(pixel, target));
		float pattern = mod(floor(FRAGCOORD.x / 3.0) + 2.0 * floor(FRAGCOORD.y / 3.0), 4.0) / 4.0;
		if (edge < 0.05 || pattern > edge) { discard; }
	}
	ALBEDO = leaf.rgb*mix(vec3(0.60,0.73,0.55),vec3(0.88,0.93,0.73),1.0-UV.y);
}
