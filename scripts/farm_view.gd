class_name FarmView
extends Control
signal touched(id: String)
var store: SaveStore
var rect = Rect2()
var time = 0.0
var garden = false
var seed_type = 0
var model: GardenModel
var hits: Array = []
var mos_reaction = 0.0
var reduced = false
var selected_seed = 0
var compact_garden = false
var wide_garden = false
var growth_age = 10.0
var art_scale=250.0
var bed_rect=Rect2()
var cell_step=52.0
var background: Texture2D = preload("res://assets/farm/farm.webp")

func _ready(): mouse_filter = Control.MOUSE_FILTER_STOP

func _has_point(point: Vector2) -> bool:
	return rect.has_point(point)

func setup(save: SaveStore, area: Rect2, canvas_size: Vector2, is_garden: bool = false):
	store=save; rect=area; size=canvas_size; garden=is_garden
	compact_garden=garden and rect.size.y<460
	wide_garden=garden and canvas_size.x>canvas_size.y
	art_scale=clampf(minf(canvas_size.x*.8,canvas_size.y*.55),170,450)
	if not garden and canvas_size.x>canvas_size.y and ResourceLoader.exists("res://assets/adventure/farm-wide.webp"):background=load("res://assets/adventure/farm-wide.webp")
	model=GardenModel.new(store)
	reduced=store.active().settings.reduced_motion
	if garden:
		var columns=4 if model.available_cells()==16 else 3
		var rows=4 if columns==4 else (2 if model.available_cells()==6 else 1)
		var available=rect.size-Vector2(185 if wide_garden else 24,0 if wide_garden else 156)
		cell_step=clampf(minf(available.x/columns,available.y/rows),40,76)
		var center=rect.get_center()+Vector2(18 if wide_garden else 0,0)
		bed_rect=Rect2(center-Vector2(columns,rows)*cell_step/2,Vector2(columns,rows)*cell_step).grow(10)
	build_hits()
	queue_redraw()

func p(uv: Vector2) -> Vector2: return rect.position+uv*rect.size

func hit(id: String, point: Vector2, radius: float = 30):
	var r=Rect2(point-Vector2.ONE*radius,Vector2.ONE*radius*2)
	hits.append({"id":id,"rect":r})
	var b=Button.new()
	b.name="Farm_"+id
	b.position=r.position;b.size=r.size
	b.mouse_filter=Control.MOUSE_FILTER_IGNORE
	b.add_theme_stylebox_override("normal",StyleBoxEmpty.new())
	b.add_theme_stylebox_override("focus",UI.box(Color.TRANSPARENT,12,UI.GOLD,3))
	b.pressed.connect(func():touched.emit(id))
	add_child(b)

func cell_pos(i: int) -> Vector2:
	var columns=4 if model.available_cells()==16 else 3
	return bed_rect.position+Vector2(10,10)+Vector2(i%columns+.5,int(i/columns)+.5)*cell_step

func seed_pos(i: int) -> Vector2:
	if wide_garden:return Vector2(rect.position.x+36,rect.position.y+32+i*maxf(60,(rect.size.y-64)/2))
	return Vector2(rect.position.x+rect.size.x*(i+.5)/3,rect.position.y+27)

func pipe_pos(i: int) -> Vector2:
	if wide_garden:return Vector2(rect.end.x-35,rect.position.y+27+i*maxf(52,(rect.size.y-95)/3))
	return Vector2(rect.position.x+rect.size.x*(.13+i*.23),rect.end.y-38)

func grow_pos() -> Vector2:
	if wide_garden:return Vector2(rect.end.x-35,rect.end.y-29)
	return Vector2(rect.end.x-28,rect.end.y-38)

func anchor(id: String) -> Vector2:
	var wide=size.x>size.y
	var points={"house":Vector2(.25,.29),"mos":Vector2(.40,.34),"garden":Vector2(.64,.60),"map":Vector2(.51,.42),"album":Vector2(.12,.53),"dock":Vector2(.13,.72)} if wide else {"house":Vector2(.25,.26),"mos":Vector2(.49,.30),"garden":Vector2(.60,.61),"map":Vector2(.535,.43),"album":Vector2(.16,.42),"dock":Vector2(.12,.69)}
	return p(points[id])

func build_hits():
	hits=[]
	for child in get_children(): child.queue_free()
	if garden:
		for i in 3:
			hit("seed_"+str(i),seed_pos(i),27)
			hit("pipe_"+str(i),pipe_pos(i),24 if compact_garden else 27)
		for i in model.available_cells(): hit("cell_"+str(i),cell_pos(i),cell_step*.48)
		hit("grow",grow_pos(),28 if compact_garden else 38)
	else:
		for id in ART_ANCHORS:
			hit(id,anchor(id),36 if id=="house" else 30)

func _gui_input(event):
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		var closest=""
		var distance=INF
		for h in hits:
			var d=h.rect.get_center().distance_squared_to(event.position)
			if h.rect.has_point(event.position) and d<distance:
				closest=h.id;distance=d
		if closest!="":
			touched.emit(closest)
			accept_event()

func _process(delta):
	growth_age+=delta
	if not reduced: time += minf(delta,.05)
	mos_reaction=maxf(0,mos_reaction-delta)
	queue_redraw()

func sprite(icon_name: String, at: Vector2, side: float, angle: float=0.0, tint: Color=Color.WHITE):
	draw_set_transform(at,angle)
	var texture=UI.icon(icon_name)
	if icon_name=="mos":
		var frame=0
		if not reduced and fposmod(time,5.7)>.0 and fposmod(time,5.7)<.18:frame=2
		elif not reduced and fposmod(time,11)>8:frame=1
		if mos_reaction>1.6:frame=3
		elif mos_reaction>0:frame=5
		if garden and model.state().grown:frame=4
		texture=UI.dragon(frame)
	draw_texture_rect(texture,Rect2(-Vector2.ONE*side/2,Vector2.ONE*side),false,tint)
	draw_set_transform(Vector2.ZERO)

func caption(text: String, at: Vector2, color: Color=UI.CREAM):
	var w=UI.body.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,12).x
	draw_style_box(UI.box(Color(.04,.12,.08,.85),8),Rect2(at-Vector2(w/2+10,15),Vector2(w+20,25)))
	draw_string(UI.body,at-Vector2(w/2,-2),text,HORIZONTAL_ALIGNMENT_LEFT,-1,12,color)

# Rendering projection for the oblique painting. Save positions remain the canonical
# farm.lots anchors; every view uses these fixed screen anchors, never player choices.
const ART_ANCHORS = {"house": Vector2(.18,.205), "mos": Vector2(.36,.25),
 "garden": Vector2(.40,.695), "map": Vector2(.535,.405),
 "album": Vector2(.13,.345), "dock": Vector2(.10,.69)}

func _draw():
	if store==null:return
	if garden:
		draw_garden()
		return
	draw_texture_rect(background,rect,false)

	var home=store.active().houses.get("house_01",{})
	var house_at=anchor("house")
	var garden_at=house_at+Vector2(art_scale*.11,rect.size.y*.035)
	sprite("pond" if home.get("variant","")=="piledam" else "moss_garden",garden_at,art_scale*.24)
	sprite("house",house_at,art_scale*.32)
	if rect.size.x>=290:caption("Rodhytten",house_at+Vector2(0,art_scale*.145),UI.GOLD)
	if home.get("rescue","")=="B":
		sprite("plank",house_at+Vector2(-art_scale*.105,art_scale*.09),32,-.1)
	else:sprite("rope",house_at+Vector2(-art_scale*.105,art_scale*.05),26)
	var ornament=home.get("decoration",{})
	if ornament is Dictionary:
		sprite(ornament.get("ornament","stone"),house_at+Vector2(art_scale*.10,art_scale*.09),21)
	var gift=home.get("gift","")
	if gift!="":sprite("leaf" if gift=="vindblad" else "cup",house_at+Vector2(art_scale*.12,-art_scale*.03),28,sin(time)*.12 if gift=="vindblad" else 0)
	var mos_at=anchor("mos")
	if not reduced:
		mos_at.y+=sin(time*1.3)*.8
		if mos_reaction>0:mos_at.x+=sin((3-mos_reaction)*2)*14
	var mos_side=clampf(art_scale*.27,58,116)
	sprite("mos",mos_at,mos_side*(1.0 if reduced else 1.0+sin(time*1.3)*.008))
	if rect.size.x>=290:caption("Mos",mos_at+Vector2(0,mos_side*.43))
	if mos_reaction>0:
		for i in 9:
			var at=mos_at+Vector2.from_angle(i*TAU/9+time)*((3-mos_reaction)*20)
			draw_circle(at,2,Color("d7df91"))
	sprite("book",anchor("map")-Vector2(0,10),34)
	if rect.size.x>=290:
		caption("Rejsekort",anchor("map")+Vector2(0,20))
		caption("Eddas værksted",anchor("album")+Vector2(0,35))
	var bed_at=anchor("garden")
	sprite("garden_bed",bed_at,art_scale*.24)
	var flowers=home.get("flowers",{})
	if flowers.is_empty():
		for i in 3:sprite("garden_flower_"+str(i),bed_at+Vector2((i-1)*19,-9),35)
	else:
		for key in flowers.plots:
			var i=int(key)
			sprite("garden_flower_"+str(int(flowers.plots[key])),bed_at+Vector2((i%4-1.5)*14,(int(i/4)-1)*9-8),25)
	caption("Mos’ levende have",bed_at+Vector2(0,art_scale*.12),UI.GOLD)
	if not reduced:
		for i in 16:
			var at=p(Vector2(fposmod(i*.68+sin(time*.12+i)*.03,1),fposmod(i*.37-time*.003,1)))
			draw_circle(at,1.7,Color(1,.88,.53,.35+sin(time+i)*.2))
		for i in 4:
			var at=p(Vector2(.03+i*.045,.84+i*.02))
			draw_arc(at,8+fposmod(time*4+i*5,15),0,PI,22,Color(.8,.95,.8,.3),1,true)

func draw_garden():
	draw_style_box(UI.box(Color("453524"),12,Color("be9b63"),7),bed_rect)
	for i in 75:
		var at=bed_rect.position+Vector2(.04+fposmod(i*.619,1)*.92,.07+fposmod(i*.433,1)*.86)*bed_rect.size
		draw_circle(at,1+fposmod(i*2.5,2),Color(.7,.52,.3,.18))
	for i in 3:
		var at=seed_pos(i)
		draw_circle(at+Vector2(0,3),28,Color(0,.02,.01,.4))
		draw_circle(at,27,Color("193c32"));draw_arc(at,26,0,TAU,36,Color("88764e"),1.4,true)
		sprite("garden_seed_"+str(i),at,60)
		if i==selected_seed:draw_arc(at,29,0,TAU,36,UI.GOLD,3,true)
		caption(["Solfrø","Stjernefrø","Rosafrø"][i],at+Vector2(0,35 if compact_garden else 42))
	for i in model.available_cells():
		var at=cell_pos(i)
		draw_style_box(UI.box(Color("594735"),9,Color("8e7e50"),2),Rect2(at-Vector2(23,23),Vector2(46,46)))
		if model.state().plots.has(str(i)):
			var plant=int(model.state().plots[str(i)])
			var growth=1.0 if reduced else 1-pow(1-clampf((growth_age-i*.025)/.65,0,1),3)
			sprite(("garden_flower_" if model.state().grown else "garden_seed_")+str(plant),at-Vector2(0,6*growth if model.state().grown else 0),cell_step*1.02*growth if model.state().grown else 38,sin(time+i)*.035 if model.state().grown and not reduced else 0)
			if model.state().grown and growth_age<1.6 and not reduced:
				for spark in 4:
					var phase=clampf((growth_age-spark*.08)/1.2,0,1)
					draw_circle(at+Vector2(sin(spark*2.4+i)*22,-phase*42),2.4,Color(1,.91,.62,(1-phase)*.75))
	var connected=true
	for i in 3:
		var at=pipe_pos(i)
		var direction=Vector2.from_angle(float(model.state().pipes[i])*PI/2)*24
		draw_circle(at,28,Color("172e23"))
		draw_line(at-direction,at+direction,Color("af9966"),17,true)
		draw_line(at-direction,at+direction,Color("51452f"),10,true)
		connected=connected and int(model.state().pipes[i])%2==0
		if connected:draw_line(at-direction,at+direction,Color("8ed2be"),6,true)
		else:
			draw_circle(at-direction,4,Color("e8c081"))
			draw_circle(at+direction,4,Color("e8c081"))

	sprite("mos",grow_pos(),58 if compact_garden else 70)
	caption("Naturpust",grow_pos()+Vector2(0,27 if compact_garden else 41),UI.GOLD)
