shader_type canvas_item;
render_mode unshaded;
uniform float clock=0.0;
uniform bool awake=false;
uniform vec4 eye_a=vec4(0.0);
uniform vec4 eye_b=vec4(0.0);
uniform vec4 eye_c=vec4(0.0);
uniform vec4 eye_d=vec4(0.0);
varying vec4 draw_color;
void vertex(){draw_color=COLOR;}
float eye_mask(vec2 at, vec4 eye){
 if(eye.z<=0.0)return 0.0;
 return 1.0-smoothstep(.35,1.0,length((at-eye.xy)/eye.zw));
}
void fragment(){
 vec2 at=UV;
 float mask=max(max(eye_mask(at,eye_a),eye_mask(at,eye_b)),max(eye_mask(at,eye_c),eye_mask(at,eye_d)));
 vec2 gaze=vec2(smoothstep(-.5,.5,sin(clock*.34))*2.0-1.0,sin(clock*.23)*.25);
 if(awake)at-=gaze*vec2(.0018,.0012)*mask;
 COLOR=draw_color*texture(TEXTURE,at);
}
