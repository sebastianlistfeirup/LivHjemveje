class_name WorldView
extends Control

var art: Texture2D
var art_rect = Rect2()
var time = 0.0
var reduced = false
var page_number = 0
var cover = false
var pulse = 0.0
var burst_origin = Vector2.ZERO
var burst_age = 10.0
var solved = false
var particles: Array = []
var previous_art: Texture2D
var scene_fade = 1.0
var touches: Array = []

func _ready():
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var rng = RandomNumberGenerator.new()
	rng.seed = 4101
	for i in 35:
		particles.append(Vector4(rng.randf(), rng.randf(), rng.randf_range(0.2,1), rng.randf_range(0,TAU)))

func _process(delta):
	scene_fade=minf(1,scene_fade+delta*2.8)
	for touch in touches:touch.age+=delta
	touches=touches.filter(func(t):return t.age<.42)
	if not reduced:
		time += minf(delta, 0.05)
		burst_age += delta
	pulse = move_toward(pulse, 0, delta * 1.4)
	queue_redraw()

func change_art(texture: Texture2D):
	previous_art=art
	art=texture
	scene_fade=1.0 if reduced or previous_art==null else 0.0

func touch(at: Vector2):
	if not reduced:touches.append({"at":at,"age":0.0})

func burst(at: Vector2):
	burst_origin = at
	burst_age = 0.0
	pulse = 1.0

func draw_cover(texture: Texture2D, rect: Rect2, tint: Color):
	if texture == null: return
	var tex_size = texture.get_size()
	var factor = maxf(rect.size.x / tex_size.x, rect.size.y / tex_size.y)
	var region_size = rect.size / factor
	var region = Rect2((tex_size - region_size) / 2, region_size)
	draw_texture_rect_region(texture, rect, region, tint)

func _draw():
	draw_rect(Rect2(Vector2.ZERO, size), Color("0a1815"))
	if art == null: return
	draw_cover(art, Rect2(Vector2.ZERO,size), Color(0.24,0.30,0.25,1))
	# A still full-bleed painting frames the uncropped interactive illustration.
	for i in 18:
		var width = size.x * 0.5 * (1.0-float(i)/18)
		draw_rect(Rect2(0,0,width,size.y), Color(0.02,0.07,0.06,0.035))
	if cover:
		var frame = Rect2(size.x * 0.38, 0, size.x * 0.62, size.y)
		draw_cover(art, frame, Color(0.9,0.91,0.83,1))
		for i in 35:
			var alpha = 0.047 * (1-float(i)/35)
			draw_rect(Rect2(0,0,size.x*(0.35+float(i)/50),size.y),Color(0.025,0.07,0.06,alpha))
	else:
		draw_style_box(UI.box(Color(0,0,0,0.4),4), art_rect.grow(8))
		if previous_art and scene_fade<1:draw_texture_rect(previous_art,art_rect,false)
		draw_texture_rect(art, art_rect, false,Color(1,1,1,scene_fade))
		draw_rect(art_rect.grow(1), Color("ae9969"), false, 1)
		if solved:
			draw_rect(art_rect, Color(0.8,0.69,0.28,pulse * 0.055))
	var area = Rect2(Vector2.ZERO,size) if cover else art_rect
	if not reduced:
		if not cover and page_number<30:
			for i in 2:
				var origin=area.position+Vector2(.16+i*.20,0)*area.size
				var sway=sin(time*.18+i)*.018
				draw_colored_polygon(PackedVector2Array([origin,origin+Vector2(.06,0)*area.size,origin+Vector2(.48+sway,.72)*area.size,origin+Vector2(.25+sway,.72)*area.size]),Color(1,.91,.58,.024+sin(time*.25+i)*.009))
			for i in 2:
				var at=area.position+Vector2(.21+i*.56+sin(time*.23+i)*.075,.18+sin(time*.31+i*3)*.05)*area.size
				var wing=2.5+absf(sin(time*7+i))*4
				draw_colored_polygon(PackedVector2Array([at,at+Vector2(-wing,-3),at+Vector2(-wing*.7,3)]),Color(.96,.76,.37,.70))
				draw_colored_polygon(PackedVector2Array([at,at+Vector2(wing,-3),at+Vector2(wing*.7,3)]),Color(.96,.84,.53,.65))
		for i in particles.size():
			var p = particles[i]
			var u = fposmod(p.x + sin(time*0.09+p.w)*0.035,1)
			var v = fposmod(p.y - time*0.008*p.z,1)
			var point = area.position + Vector2(u,v)*area.size
			var alpha = (0.15+0.30*(0.5+sin(time*.7+p.w)*.5))*p.z
			var color = Color(1,0.85,0.48,alpha)
			if page_number in [11,12,17,27,28,32]: color = Color(.68,1,.65,alpha)
			draw_circle(point, 2.2*p.z, color)
			if i%5 == 0: draw_circle(point,6*p.z,Color(color,alpha*.12))
		if page_number >= 30 or cover:
			for i in 5:
				var origin = area.position + Vector2(.18+i*.16,.76+sin(i*4.0)*.13)*area.size
				var radius = fposmod(time*9+i*11,45)
				draw_arc(origin,radius,0,TAU,32,Color(.82,.91,.72,(1-radius/45)*.18),1,true)
		if burst_age < 1.0:
			for i in 18:
				var angle = i*TAU/18
				var at = burst_origin + Vector2.from_angle(angle)*burst_age*100
				draw_circle(at, (1-burst_age)*3, Color(1,.85,.45,1-burst_age))
		for tap in touches:
			var phase=tap.age/.42
			draw_arc(tap.at,8+phase*25,0,TAU,32,Color(1,.85,.51,(1-phase)*.75),2,true)
	# Thin ornaments keep the world warm without covering the painting.
	if not cover:
		for corner in [art_rect.position,art_rect.position+Vector2(art_rect.size.x,0),art_rect.end,art_rect.position+Vector2(0,art_rect.size.y)]:
			draw_circle(corner,3,UI.GOLD)
