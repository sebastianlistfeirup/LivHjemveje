class_name WorldView
extends Control

var art: Texture2D
var previous_art: Texture2D
var art_rect=Rect2()
var time=0.0
var scene_time=0.0
var previous_time=0.0
var scene_fade=1.0
var reduced=false
var still=false
var page_number=0
var cover=false
var solved=false
var focus=Vector2(.5,.40)
var old_focus=Vector2(.5,.40)
var framing=Rect2(0,0,1,1)
var previous_framing=Rect2(0,0,1,1)
var mood="wonder"
var particles=[]
var shade: ColorRect
var glow: GradientTexture2D
var eyes=[]
var steaming=false
var steam_color=Color(.65,.94,.89)
var fx: TouchMagic

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	var living=ShaderMaterial.new();living.shader=preload("res://shaders/living_picture.gdshader");self.material=living
	var rng=RandomNumberGenerator.new();rng.seed=4101
	for i in 28:particles.append(Vector4(rng.randf(),rng.randf(),rng.randf_range(.25,1),rng.randf_range(0,TAU)))
	var gradient=Gradient.new();gradient.colors=PackedColorArray([Color(1,.82,.38,.2),Color(1,.75,.3,0)])
	glow=GradientTexture2D.new();glow.gradient=gradient;glow.fill=GradientTexture2D.FILL_RADIAL;glow.fill_from=Vector2(.5,.5);glow.fill_to=Vector2(1,.5);glow.width=64;glow.height=64
	shade=ColorRect.new();shade.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var material=ShaderMaterial.new();material.shader=preload("res://shaders/atmosphere.gdshader");shade.material=material;add_child(shade)

func _process(delta):
	scene_fade=minf(1,scene_fade+delta/1.1)
	if not reduced:
		time+=minf(delta,.08)
		if not still:scene_time+=minf(delta,.08)
	if material:
		material.set_shader_parameter("clock",time)
		material.set_shader_parameter("awake",not reduced and not still and scene_fade>=1)
		for i in 4:material.set_shader_parameter(["eye_a","eye_b","eye_c","eye_d"][i],eyes[i] if i<eyes.size() else Vector4.ZERO)
	if shade:
		shade.size=size
		shade.material.set_shader_parameter("clock",0.0 if reduced or still else time)
		shade.material.set_shader_parameter("title",cover)
		shade.material.set_shader_parameter("motion",not reduced and not still)
		shade.material.set_shader_parameter("mist",mood=="danger" or page_number in [11,41,47])
	queue_redraw()

func change_art(texture: Texture2D, keep_camera: bool=false):
	previous_art=art;previous_time=scene_time;old_focus=focus;previous_framing=framing
	art=texture
	if not keep_camera:scene_time=0.0
	scene_fade=1.0 if reduced or previous_art==null else 0.0

func touch(at: Vector2):
	if fx:fx.touch(at)

func burst(at: Vector2):
	if fx:fx.burst(at)

func source_region(texture: Texture2D, rect: Rect2, age: float, focal: Vector2, crop: Rect2=Rect2()) -> Rect2:
	if crop==Rect2():crop=framing
	var source_size=texture.get_size()
	var dimensions=source_size*crop.size
	var zoom=1.0 if reduced else 1.035+.022*sin(age*.045)
	var factor=maxf(rect.size.x/dimensions.x,rect.size.y/dimensions.y)*zoom
	var extent=rect.size/factor
	var drift=0.0 if reduced else sin(age*.032)*.045
	var centre=Vector2(clampf(focal.x+drift,.1,.9),focal.y)
	return Rect2(crop.position*source_size+(dimensions-extent)*centre,extent)

func draw_cover(texture: Texture2D, rect: Rect2, tint: Color, age: float=0.0, focal: Vector2=Vector2(.5,.4), crop: Rect2=Rect2()):
	if texture:draw_texture_rect_region(texture,rect,source_region(texture,rect,age,focal,crop),tint)

func _draw():
	var full=Rect2(Vector2.ZERO,size)
	draw_rect(full,Color("102b28"))
	if art==null:return
	if previous_art and scene_fade<1:draw_cover(previous_art,full,Color.WHITE,previous_time,old_focus,previous_framing)
	var fade=scene_fade*scene_fade*(3-2*scene_fade)
	draw_cover(art,full,Color(1,1,1,fade),scene_time,focus)
	if reduced or still:return
	if steaming:
		var region=source_region(art,full,scene_time,focus)
		var origin=(art.get_size()*Vector2(.745,.49)-region.position)/region.size*size
		var unit=size.y*.15
		for ribbon in 7:
			var phase=fposmod(time*.15+ribbon*.143,1.0)
			var at=origin+Vector2(sin(time*.55+ribbon*2.0)*unit*.22,-phase*unit*1.6)
			var points=PackedVector2Array()
			for j in 9:points.append(at+Vector2(sin(j*.5+time+ribbon)*unit*.12,-j*unit*.035))
			draw_polyline(points,Color(steam_color,(1-phase)*.10),maxf(2,unit*.04),true)
			if glow:draw_texture_rect(glow,Rect2(at-Vector2.ONE*unit*.30,Vector2.ONE*unit*.6),false,Color(steam_color,(1-phase)*.32))
	for i in particles.size():
		var p=particles[i]
		var at=Vector2(fposmod(p.x+sin(time*.08+p.w)*.04,1),fposmod(p.y-time*.006*p.z,1))*size
		var alpha=(.35+.25*sin(time*.8+p.w))*p.z
		if i%4==0 and glow:draw_texture_rect(glow,Rect2(at-Vector2.ONE*12,Vector2.ONE*24),false,Color(1,1,1,alpha))
		draw_circle(at,1.4*p.z,Color(1,.86,.51,alpha))
	if page_number not in [1,2,3,34,50]:
		for i in 2:
			var at=Vector2(.18+i*.58+sin(time*.17+i)*.045,.22+sin(time*.23+i*3)*.04)*size
			var wing=2+absf(sin(time*6+i))*3
			draw_colored_polygon(PackedVector2Array([at,at+Vector2(-wing,-3),at+Vector2(-wing*.7,3)]),Color(.98,.85,.5,.6))
			draw_colored_polygon(PackedVector2Array([at,at+Vector2(wing,-3),at+Vector2(wing*.7,3)]),Color(.98,.85,.5,.6))
