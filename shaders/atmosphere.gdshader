shader_type canvas_item;
render_mode unshaded;
uniform float clock=0.0;
uniform bool title=false;
uniform bool motion=true;
uniform bool mist=false;
void fragment(){
	vec2 p=UV;
	float edge=pow(length((p-.5)*vec2(1.05,1.12)),2.0)*.30;
	float top=(1.0-smoothstep(0.0,.19,p.y))*.34;
	float bottom=smoothstep(.77,1.0,p.y)*.26;
	float title_shade=title ? (1.0-smoothstep(.05,.8,p.x))*.64 : 0.0;
	float fog=mist ? (sin(p.x*6.0+p.y*2.0+clock*.09)*.5+.5)*smoothstep(.35,1.0,p.y)*.035 : 0.0;
	float ray_path=p.x*1.6+p.y*.36+sin(clock*.08)*.055;
	float ray=pow(max(0.0,sin(ray_path*12.0)),22.0)*(1.0-p.y)*.065;
	float leaves=sin(p.x*22.0+clock*.09)*sin(p.y*18.0+sin(clock*.13))*.012;
	vec3 tint=mix(vec3(.012,.035,.027),vec3(.12,.28,.28),fog*3.0);
	if(motion){tint=mix(tint,vec3(1.0,.76,.38),ray*5.0);edge+=leaves;}
	COLOR=vec4(mix(tint,tint,0.0),clamp(edge+top+bottom+title_shade+fog,0.0,.78));
}
