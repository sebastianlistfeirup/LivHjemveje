class_name PuzzleView
extends Control

signal acted(id: String, point: Vector2)
var runtime: StoryRuntime
var art_rect = Rect2()
var board = Rect2()
var hits: Array = []
var time = 0.0
var reduced = false
var compare_old = false
var down_id = ""
var down_point = Vector2.ZERO
var drag_point = Vector2.ZERO
var dragging = false
var point_size = 54.0
var highlighted = false
var animated_id = ""
var animation_age = 10.0
var memory_textures: Dictionary = {}

func memory_image(image_id: String) -> Texture2D:
	if not memory_textures.has(image_id):
		memory_textures[image_id]=load("res://assets/chapter_01/"+image_id+".webp")
	return memory_textures[image_id]

func _ready():
	mouse_filter = Control.MOUSE_FILTER_STOP
	set_process(true)

func _has_point(point: Vector2) -> bool:
	return art_rect.has_point(point) or board.has_point(point)

func setup(rt: StoryRuntime, rect: Rect2, canvas_size: Vector2):
	runtime = rt
	art_rect = rect
	size = canvas_size
	reduced = runtime.state().settings.reduced_motion
	var direct = runtime.page().runtime.coordinate_space == "art_rect"
	board = art_rect if direct else Rect2(art_rect.position + art_rect.size*Vector2(.045,.28),art_rect.size*Vector2(.91,.64))
	if runtime.config().kind in ["maze", "difference", "pipes", "choice", "album"]:
		board = Rect2(art_rect.position+art_rect.size*Vector2(.035,.30), art_rect.size*Vector2(.93,.61))
	if not direct and art_rect.size.x<290:
		var portrait=canvas_size.y>=canvas_size.x
		var width=canvas_size.x-28 if portrait else canvas_size.x*.52-28
		var height=art_rect.size.y-20
		var left=(canvas_size.x-width)/2 if portrait else 14.0
		board=Rect2(left,art_rect.position.y+10,width,height)
	point_size = clampf(board.size.x * 0.17, 48, 72)
	build_hits()
	queue_redraw()

func p(uv: Array) -> Vector2:
	return board.position + Vector2(uv[0],uv[1])*board.size

func hit(id: String, at: Vector2, label_text: String, hit_size: Vector2 = Vector2.ZERO):
	if hit_size == Vector2.ZERO: hit_size = Vector2(point_size,point_size)
	var rect = Rect2(at-hit_size/2,hit_size)
	hits.append({"id":id,"rect":rect,"label":label_text})
	var key_button = Button.new()
	key_button.name = "Action_" + id
	key_button.position = rect.position
	key_button.size = rect.size
	key_button.tooltip_text = label_text
	key_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	key_button.add_theme_stylebox_override("normal", StyleBoxEmpty.new())
	key_button.add_theme_stylebox_override("hover", StyleBoxEmpty.new())
	key_button.add_theme_stylebox_override("pressed", StyleBoxEmpty.new())
	key_button.add_theme_stylebox_override("focus", UI.box(Color(1,.85,.5,.08),15,UI.GOLD,3))
	key_button.pressed.connect(func(): acted.emit(id,Vector2((at.x-board.position.x)/board.size.x,(at.y-board.position.y)/board.size.y)))
	add_child(key_button)

func build_hits():
	hits.clear()
	for child in get_children(): child.queue_free()
	if not runtime.ready_for_action(): return
	var c = runtime.config()
	var sp = runtime.stage_progress()
	match c.kind:
		"maze":
			for id in runtime.source.maze.nodes:
				hit(id,p(runtime.source.maze.nodes[id]),"Rodsti " + id,Vector2(48,48))
		"difference":
			hit("compare",board.position+Vector2(board.size.x/2,14),"Skift mellem gammel plan og ankomst",Vector2(board.size.x-20,48))
			for target in runtime.page().puzzle_spec.targets:
				var r = target.rect_xywh
				hit(target.id,p([r[0]+r[2]/2,r[1]+r[3]/2]),target.label,Vector2(maxf(48,r[2]*board.size.x),maxf(48,r[3]*board.size.y)))
		"album":
			for i in 3:
				hit(["K01_S01","K01_S17","K01_S32"][i],p([.2+i*.3,.53]),["Kompasset","Mødet med Mos","Vores hjemvej"][i],Vector2(board.size.x*.26,board.size.y*.55))
		"choice":
			for item in c.items:
				hit(item.id,p(item.pos),item.label,Vector2(board.size.x*.42,board.size.y*.66))
		_:
			if c.kind == "decorate":
				var z = c.zone
				hit("zone",p([z[0]+z[2]/2,z[1]+z[3]/2]),"Placér i den frie zone",Vector2(z[2],z[3])*board.size)
			for item in c.items + c.targets:
				if not item.id in sp.done:
					hit(item.id,p(item.pos),item.label)

func at_point(point: Vector2) -> String:
	for i in range(hits.size()-1,-1,-1):
		if hits[i].rect.has_point(point): return hits[i].id
	return ""

func normalized(point: Vector2) -> Vector2:
	return (point-board.position)/board.size

func _gui_input(event):
	if runtime == null or not runtime.ready_for_action(): return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			down_id = at_point(event.position)
			down_point = event.position
			drag_point = event.position
			dragging = false
		else:
			var id = at_point(event.position)
			if id == "compare":
				compare_old = not compare_old
				queue_redraw()
			elif id != "":
				acted.emit(id,normalized(event.position))
			down_id = ""
			dragging = false
		accept_event()
	elif event is InputEventMouseMotion:
		drag_point = event.position
		if not down_id.is_empty() and event.position.distance_to(down_point) > 9 and not dragging:
			dragging = true
			if runtime.config().kind in ["place","decorate"]:
				acted.emit(down_id,normalized(down_point))
		if dragging and runtime.config().kind in ["wipe","maze","sequence"]:
			var id = at_point(event.position)
			if id != "": acted.emit(id,normalized(event.position))
		mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND if at_point(event.position) != "" else Control.CURSOR_ARROW
		queue_redraw()

func _process(delta):
	animation_age += delta
	if not reduced:
		time += minf(delta,.05)
		queue_redraw()

func sprite(name: String, at: Vector2, side: float, rotation_angle: float = 0.0, tint: Color = Color.WHITE):
	var actual = name
	if name == "gift": actual = "leaf" if runtime.state().choices.get("k01_rute","A") == "A" else "cup"
	if name in ["bag", "water", "paw", "lift"]: actual = {"bag":"book","water":"bowl","paw":"hand","lift":"plank"}[name]
	draw_set_transform(at,rotation_angle)
	draw_texture_rect(UI.icon(actual),Rect2(Vector2(-side/2,-side/2),Vector2(side,side)),false,tint)
	draw_set_transform(Vector2.ZERO)

func text_center(value: String, at: Vector2, font_size: int = 14, color: Color = UI.CREAM):
	var width = UI.body.get_string_size(value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
	draw_string(UI.body,at-Vector2(width/2,0),value,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size,color)

func _draw():
	if runtime == null: return
	var c = runtime.config()
	var sp = runtime.stage_progress()
	var solved = runtime.progress().solved
	var direct = runtime.page().runtime.coordinate_space == "art_rect"
	if not direct:
		draw_style_box(UI.box(Color(.035,.075,.055,1.0 if c.kind=="difference" else .90),18,Color("baa16b"),1),board.grow(8))
		# Fine engraved grain, static so comparison diagrams remain pixel-stable.
		for i in 14:
			var y = board.position.y + board.size.y*(i+1)/15
			draw_line(Vector2(board.position.x+8,y),Vector2(board.end.x-8,y+sin(i)*4),Color(.72,.65,.40,.055),1,true)
	if c.kind == "maze":
		draw_maze(sp)
	elif c.kind == "difference":
		draw_difference(sp)
	elif c.kind == "pipes":
		draw_pipes(sp)
	elif c.kind == "rotate":
		draw_compass(sp)
	elif c.kind == "choice":
		for item in c.items:
			var center = p(item.pos)
			var rect = Rect2(center-Vector2(board.size.x*.21,board.size.y*.33),Vector2(board.size.x*.42,board.size.y*.66))
			var chosen = item.id in sp.done
			draw_style_box(UI.box(Color("35523a") if chosen else Color("213a2c"),14,UI.GOLD if chosen else Color("7e8258"),2),rect)
			sprite(item.icon,center-Vector2(0,25),minf(board.size.x*.29,115),sin(time*.7)*.035 if not reduced else 0)
			var parts = item.label.split(" · ")
			var words = parts[0].split(" ")
			var line = ""
			var lines: Array = []
			for word in words:
				if UI.body.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,14).x > rect.size.x-14:
					lines.append(line.strip_edges()); line = ""
				line += word + " "
			lines.append(line.strip_edges())
			for i in lines.size(): text_center(lines[i],center+Vector2(0,board.size.y*.17+i*20),14)
			if parts.size() > 1: text_center(parts[1],center+Vector2(0,board.size.y*.17+lines.size()*20),11,UI.GOLD)
	elif c.kind == "album":
		for i in 3:
			var id = ["K01_S01","K01_S17","K01_S32"][i]
			var image_id = runtime.pages[id].image_id
			var texture = memory_image(image_id)
			var center = p([.2+i*.3,.5])
			var r = Rect2(center-Vector2(board.size.x*.13,board.size.y*.23),Vector2(board.size.x*.26,board.size.y*.46))
			draw_style_box(UI.box(UI.CREAM,3),r.grow(5))
			draw_texture_rect(texture,r,false)
			if id in sp.done: draw_rect(r.grow(6),UI.GOLD,false,4)
			text_center(["Kompasset","Mos","Hjemvejen"][i],center+Vector2(0,board.size.y*.31),13)
	else:
		draw_objects(c,sp,direct)
	if solved:
		draw_success()
	if dragging and runtime.config().kind in ["place","decorate"]:
		var selected = runtime.find_item(down_id)
		if not selected.is_empty(): sprite(selected.icon,drag_point,point_size*1.4)

func draw_objects(c: Dictionary, sp: Dictionary, direct: bool):
	var n = int(runtime.page().page)
	if int(runtime.progress().get("hint",0))>=2 and c.kind=="place":
		for item in c.items:
			if item.get("decoy",false) or item.id in sp.done:continue
			if item.has("requires") and not item.requires in sp.done:continue
			for target in c.targets:
				if target.id==item.target:
					var a=p(item.pos);var b=p(target.pos)
					for dash in 10:
						draw_line(a.lerp(b,dash/10.0),a.lerp(b,(dash+.5)/10.0),Color(1,.85,.5,.75),2,true)
			break
	if c.kind == "decorate":
		var z = c.zone
		var zone = Rect2(p([z[0],z[1]]),Vector2(z[2],z[3])*board.size)
		draw_style_box(UI.box(Color("a58b59") if n == 39 else Color("536548"),22,Color("d4bd83"),2),zone)
		if n == 39:
			var photo = runtime.state().flags.get("album_photo","K01_S17")
			var tex = memory_image(runtime.pages[photo].image_id)
			var r = Rect2(zone.position+Vector2(12,12),Vector2(zone.size.y*.55,zone.size.y-24))
			draw_texture_rect(tex,r,false)
	if n == 20:
		draw_style_box(UI.box(Color("887e55"),12,UI.GOLD,3),Rect2(p([.14,.17]),board.size*Vector2(.72,.65)))
		sprite("hand",p([.5,.48]),board.size.x*.46)
		draw_line(p([.24,.66]),p([.79,.27]),Color("81b7c5"),11,true)
	if c.kind == "sequence" and c.items.size()>1:
		for i in c.items.size()-1:
			var a=p(c.items[i].pos); var b=p(c.items[i+1].pos)
			draw_line(a,b,Color(.08,.17,.11,.8),10,true)
			draw_line(a,b,UI.GOLD if i<sp.done.size() else Color(.6,.65,.45,.45),3,true)
	if n == 7:
		draw_line(p([.1,.23]),p([.88,.62]),Color(.07,.18,.17,.85),board.size.x*.22,true)
	if n in [23,24,25,26,29]:
		var height = .3 - sp.done.size()*.045
		draw_line(p([.04,height+.1]),p([.94,height]),Color("7d643d"),19,true)
		draw_line(p([.04,height+.08]),p([.94,height-.02]),Color("c5b67b"),3,true)
	if n == 6 and sp.done.size()>0: sprite("leaf",p([.5,.7]),80)
	for target in c.targets:
		var at=p(target.pos)
		draw_circle(at,point_size*.54,Color(.07,.17,.13,.78))
		draw_arc(at,point_size*.49,0,TAU,40,Color("c3bd83"),2,true)
		var occupied = false
		for item in c.items:
			if item.id in sp.done and item.get("target","") == target.id: occupied=true
		if not occupied:
			var factor=(.7 if target.id.begins_with("short") else (1.0 if target.id.begins_with("medium") else 1.3)) if n==7 else 1.0
			sprite(target.icon,at,point_size*.86*factor,0,Color(1,1,1,.34))
			if not sp.selected.is_empty():
				var item = runtime.find_item(sp.selected)
				if item.get("target","") == target.id:
					draw_arc(at,point_size*.58,0,TAU,40,Color(1,.85,.5,.6+sin(time*2)*.2),2,true)
	for item in c.items:
		var at = p(item.pos)
		var done = item.id in sp.done
		var is_selected = sp.selected == item.id
		if c.kind in ["place","decorate"] and done:
			at = p(sp.placed[item.id])
			if item.id == animated_id and animation_age < .5 and not reduced:
				var amount = 1-pow(1-clampf(animation_age/.5,0,1),3)
				at = p(item.pos).lerp(at,amount)-Vector2(0,sin(amount*PI)*18)
			if n == 28: draw_line(p(item.pos),at,Color("83a663"),12,true)
		if c.kind == "wipe" and done: continue
		if c.kind == "sequence" and done:
			draw_circle(at,point_size*.34,Color("37593c"))
			text_center("✓",at+Vector2(0,8),22,UI.GOLD)
			continue
		if item.icon == "ring":
			draw_circle(at,point_size*.48,Color(.18,.12,.06,.13))
			draw_arc(at,point_size*(.32 if done else .38+sin(time*1.7+at.x)*.025),0,TAU,40,Color(1,.87,.61,.95 if done else .7),3,true)
			if done: text_center("✓",at+Vector2(0,7),20,UI.GOLD)
			continue
		if not done:
			draw_circle(at+Vector2(0,7),point_size*.44,Color(0,0,0,.20))
			if direct: draw_circle(at,point_size*.49,Color(.045,.10,.065,.55))
		var angle = 0.0
		if n == 9 and done: angle = time*.8
		if n in [23,26] and c.kind == "sequence": angle=sin(time)*.05
		var factor=(.7 if item.id=="short" else (1.0 if item.id=="medium" else 1.3)) if n==7 else 1.0
		sprite(item.icon,at,point_size*(1.15 if is_selected else 1.04)*factor,angle,Color(1,1,1,.5) if done and c.kind == "inspect" else Color.WHITE)
		if done and c.kind == "inspect":
			draw_circle(at+Vector2(point_size*.28,-point_size*.28),12,UI.INK)
			text_center("✓",at+Vector2(point_size*.28,-point_size*.28+6),18,UI.GOLD)
		if is_selected or (highlighted and not done and not item.get("decoy",false)):
			draw_arc(at,point_size*.6,0,TAU,40,UI.GOLD,2,true)
		if c.kind == "sequence" and c.items[mini(sp.done.size(),c.items.size()-1)].id == item.id:
			draw_arc(at,point_size*.58,0,TAU,40,UI.GOLD,2,true)
	if n == 1 and int(runtime.progress().stage)>0:
		var at=p([.53,.76])
		if runtime.progress().solved:
			draw_style_box(UI.box(Color("25362c"),3,Color("ceb57a"),2),Rect2(at-Vector2(48,38),Vector2(96,76)))
			sprite("compass",at,65)
		else: sprite("plank",at,90)

func draw_maze(sp: Dictionary):
	var graph=runtime.source.maze
	for edge in graph.edges:
		var a=p(graph.nodes[edge[0]]);var b=p(graph.nodes[edge[1]])
		draw_line(a+Vector2(0,3),b+Vector2(0,3),Color("17251c"),18,true)
		draw_line(a,b,Color("796d46"),13,true)
		draw_line(a-Vector2(0,2),b-Vector2(0,2),Color("ada275"),2,true)
	for id in graph.nodes:
		var at=p(graph.nodes[id])
		draw_circle(at,17,Color("3e5844"))
		draw_arc(at,16,0,TAU,24,Color("a2a271"),2,true)
		if id in sp.trail: draw_circle(at,6,Color("cabd6e"))
		if id == graph.goal: sprite("cup",at,48)
		elif id == graph.start: sprite("leaf",at,31)
	var here=p(graph.nodes[sp.position])
	draw_circle(here,18,Color(.9,.96,.5,.13))
	draw_circle(here,10,Color("ecdfa3"))
	draw_circle(here,5,Color("fff8d5"))

func draw_pipes(sp: Dictionary):
	var water=true
	var template=[Vector2(-.2,0),Vector2(-.10,0),Vector2(-.044,.014),Vector2(-.014,.044),Vector2(0,.10),Vector2(0,.2)]
	for i in 3:
		var uv=runtime.config().items[i].pos
		var center=Vector2(uv[0],uv[1])
		var angle=float(sp.rotations[i])*PI/2
		var points=PackedVector2Array()
		for local in template:points.append(board.position+(center+local.rotated(angle))*board.size)
		draw_circle(p(uv),point_size*.55,Color("1b3025"))
		draw_polyline(points,Color("b29862"),22,true)
		draw_polyline(points,Color("574831"),14,true)
		water=water and int(sp.rotations[i])==int(runtime.config().goal[i])
		if water:
			draw_polyline(points,Color("7cc5ba"),8,true)
			var part=fposmod(time*.6,1)*(points.size()-1)
			var segment=mini(int(part),points.size()-2)
			draw_circle(points[segment].lerp(points[segment+1],fposmod(part,1)),3,Color("d4f2d4"))
		else:
			draw_circle(points[0],5,Color("d5a26b"))
			draw_circle(points[-1],5,Color("d5a26b"))
		draw_arc(p(uv),16,0,TAU,24,Color("d1b67c"),1,true)
		text_center("↻",p(uv)+Vector2(0,6),19,UI.GOLD)
	draw_line(p([.68,.47]),p([.68,.19]),Color("b29862"),16,true)
	draw_line(p([.68,.47]),p([.68,.19]),Color("7cc5ba") if water else Color("574831"),8,true)
	sprite("cup",p([.055,.27]),40)
	sprite("bowl",p([.68,.15]),48)
	text_center("KILDE",p([.09,.10]),11,UI.GOLD)
	text_center("BRØND",p([.68,.045]),11,UI.GOLD)

func draw_compass(sp: Dictionary):
	var at=p([.5,.53]);var diameter=board.size.x*.75
	sprite("compass",at,diameter)
	var angle=float(sp.rotations[0])*PI/2-PI/2
	var marker=at+Vector2.from_angle(angle)*diameter*.35
	draw_circle(at+Vector2(0,-diameter*.35),22,Color(.95,.86,.4,.25))
	sprite("leaf",marker,45,angle+PI/2)
	text_center("Tryk for at dreje",p([.5,.92]),14,UI.GOLD)

func draw_difference(sp: Dictionary):
	# One fixed master. Only these five bounded object layers change.
	text_center("GAMMEL PLAN  ↔  ANKOMST" if compare_old else "ANKOMST  ↔  GAMMEL PLAN",board.position+Vector2(board.size.x/2,18),12,UI.GOLD)
	var well=Rect2(p([.31,.30]),board.size*Vector2(.38,.37))
	draw_style_box(UI.box(Color("6f755a"),14,Color("b5ae80"),4),well)
	draw_circle(well.get_center(),board.size.x*.115,Color("243f34"))
	for i in 8:
		var angle=i*TAU/8
		draw_line(well.get_center()+Vector2.from_angle(angle)*board.size.x*.12,well.get_center()+Vector2.from_angle(angle)*board.size.x*.17,Color("bcb78b"),2,true)
	# Static vegetation and channels are identical in both views.
	for coords in [[.08,.42],[.9,.48],[.37,.83],[.64,.10]]:
		sprite("moss",p(coords),34)
	draw_line(p([.24,.28]),p([.38,.4]),Color("9caa7e"),8,true)
	draw_line(p([.6,.65]),p([.8,.78]),Color("9caa7e"),8,true)
	var index=0
	for target in runtime.page().puzzle_spec.targets:
		var r=target.rect_xywh
		var at=p([r[0]+r[2]/2,r[1]+r[3]/2])
		var side=minf(board.size.x*r[2],board.size.y*r[3])
		match index:
			0:
				draw_style_box(UI.box(Color("59442c"),3,Color("b19b62"),2),Rect2(at-Vector2(side*.45,side*.4),Vector2(side*.9,side*.8)))
				if compare_old: draw_rect(Rect2(at-Vector2(side*.2,side*.3),Vector2(side*.4,side*.6)),Color("7dbaad"))
				else: draw_line(at-Vector2(0,side*.35),at+Vector2(0,side*.35),Color("b3935b"),9,true)
			1:
				if compare_old: sprite("plank",at,side)
				else: draw_circle(at,side*.15,Color("332d21"))
			2:
				sprite("root",at,side,0 if compare_old else PI/2)
			3:
				sprite("bowl",at,side,0 if compare_old else -PI/2)
			4:
				sprite("lantern",at,side,0,Color.WHITE if compare_old else Color(.4,.4,.32,1))
		if target.id in sp.done:
			draw_arc(at,maxf(24,side*.65),0,TAU,32,UI.GOLD,3,true)
			text_center("✓",at+Vector2(side*.45,-side*.35),18,UI.GOLD)
		index+=1

func draw_success():
	var n=int(runtime.page().page)
	if n in [23,24,26]:
		var at=p([.68,.70]);var side=board.size.x*.44
		draw_texture_rect(UI.dragon(3),Rect2(at-Vector2.ONE*side/2,Vector2.ONE*side),false)
	if n in [4,10,12,32,33]:
		var at=art_rect.position+art_rect.size*Vector2(.5,.72)
		draw_arc(at,34,0,TAU,48,Color(.9,.92,.5,.8),2,true)
	if n in [15,30]:
		for i in 3:
			var a=p([.2+i*.27,.35+i*.18]);var b=a+Vector2(35,34)
			draw_line(a,b,Color(.55,.85,.78,.8),9,true)
	if n in [27,28,29,37,38]:
		for i in 3:
			sprite("flower" if n>=37 else "seed",p([.28+i*.22,.55]),point_size*.9,sin(time+i)*.03 if not reduced else 0)
	if n in [25,26,35,36]:
		sprite("house" if n>=35 else "plank",p([.5,.4]),board.size.x*.4)
