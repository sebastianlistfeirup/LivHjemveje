shader_type canvas_item;
render_mode unshaded;
uniform sampler2D screen_texture : hint_screen_texture, repeat_disable, filter_linear;
uniform vec2 source_uv=vec2(.5);
uniform vec2 extent=vec2(.15);
void fragment(){
	vec2 p=(UV-.5)*2.0;
	float radius=length(p);
	vec4 glass=textureLod(screen_texture,source_uv+(UV-.5)*extent/3.0,0.0);
	float rim=smoothstep(.86,.90,radius)*(1.0-smoothstep(.98,1.0,radius));
	vec3 brass=mix(vec3(.35,.22,.08),vec3(1.0,.84,.49),clamp(.65-p.y*.55,0.0,1.0));
	COLOR=vec4(mix(glass.rgb,brass,rim),1.0-smoothstep(.98,1.0,radius));
}
