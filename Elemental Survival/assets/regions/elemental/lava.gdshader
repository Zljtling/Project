shader_type spatial;
uniform float clock = 0.0;
varying vec2 p;
vec2 hash2(vec2 v){ return fract(sin(vec2(dot(v,vec2(127.1,311.7)),dot(v,vec2(269.5,183.3))))*43758.5453); }
float noise(vec2 v){
 vec2 i=floor(v); vec2 f=fract(v); f=f*f*(3.0-2.0*f);
 return mix(mix(hash2(i).x,hash2(i+vec2(1,0)).x,f.x),mix(hash2(i+vec2(0,1)).x,hash2(i+vec2(1,1)).x,f.x),f.y);
}
float fracture(vec2 v){
 vec2 cell=floor(v); vec2 f=fract(v);
 float first=10.0; float second=10.0;
 for(int x=-1;x<=1;x++){
  for(int y=-1;y<=1;y++){
   vec2 offset=vec2(float(x),float(y));
   float d=length(offset+hash2(cell+offset)-f);
   if(d<first){second=first;first=d;}else{second=min(second,d);}
  }
 }
 return second-first;
}
void vertex(){p=VERTEX.xz;}
void fragment(){
 vec2 warp=vec2(noise(p*0.21),noise(p*0.21+17.0));
 vec2 grit=vec2(noise(p*1.1),noise(p*1.1+37.0))-0.5;
 float ridge=fracture(p*0.34+warp*0.5+grit*0.08);
 float activity=smoothstep(0.22,0.82,noise(p*0.16));
 float width=mix(0.025,0.052,activity);
 float crack=(1.0-smoothstep(0.008,width,ridge))*mix(0.25,1.0,activity);
 float warmth=sin(clock*0.65+p.x*0.17+p.y*0.12)*0.5+0.5;
 vec3 hot=mix(vec3(0.55,0.08,0.015),vec3(0.95,0.36,0.065),warmth*0.6+activity*0.4);
 vec3 crust=mix(vec3(0.055,0.060,0.058),vec3(0.13,0.115,0.10),noise(p*1.4));
 crust+=vec3(noise(p*8.0)-0.5)*0.015;
 ALBEDO=mix(crust,hot,crack*0.72);
 EMISSION=hot*crack*0.65;
 ROUGHNESS=0.96;
}
