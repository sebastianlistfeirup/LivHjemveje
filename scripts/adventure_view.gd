class_name AdventureView
extends PuzzleView

var age=0.0
var paused=false
var accumulator=0.0
var reveal_until=0.0
var last_round=0
var last_mistakes=0
var lens_on=false
var lens: ColorRect
var lens_at=Vector2.ZERO
var stirring=0.0
var last_angle=0.0
var map_rect=Rect2()
var tray_rect=Rect2()
var card_boxes=[]
var flight_from=Vector2.ZERO
var flight_id=""
var flight_age=10.0
var last_done=[]
var last_rune=""
var rune_flash=0.0
var map_texture: Texture2D
var heard_rune=""
var soft_glow: GradientTexture2D

func setup(rt: StoryRuntime, rect: Rect2, canvas_size: Vector2):
	runtime=rt;art_rect=rect;board=rect;size=canvas_size
	reduced=rt.state().settings.reduced_motion
	point_size=clampf(minf(board.size.x,board.size.y)*.24,48,104)
	last_done=rt.stage_progress().done.duplicate()
	last_round=int(rt.stage_progress().get("round",0));last_mistakes=int(rt.stage_progress().get("mistakes",0))
	lens_at=board.get_center()
	if rt.config().kind=="jigsaw":map_texture=load("res://assets/adventure/map.webp")
	var gradient=Gradient.new();gradient.colors=PackedColorArray([Color(1,.85,.4,.32),Color(.7,1,.7,0)])
	soft_glow=GradientTexture2D.new();soft_glow.gradient=gradient;soft_glow.fill=GradientTexture2D.FILL_RADIAL;soft_glow.fill_from=Vector2(.5,.5);soft_glow.fill_to=Vector2(1,.5);soft_glow.width=64;soft_glow.height=64
	if rt.config().kind=="stealth":rt.stage_progress().held=false
	set_reveal()
	build_hits()
	if rt.config().kind=="search":make_lens()
	queue_redraw()

func set_reveal():
	if runtime.config().kind=="runes":
		var seq=runtime.config().sequences[mini(int(runtime.stage_progress().get("round",0)),runtime.config().sequences.size()-1)]
		reveal_until=age+seq.size()*.78+.9
	elif runtime.config().kind=="memory_map":reveal_until=age+5.0

func _has_point(point: Vector2) -> bool:return board.has_point(point) or not at_point(point).is_empty()

func hit(id: String, at: Vector2, label_text: String, hit_size: Vector2=Vector2.ZERO):
	if hit_size==Vector2.ZERO:hit_size=Vector2.ONE*point_size
	var r=Rect2(at-hit_size/2,hit_size)
	hits.append({"id":id,"rect":r,"label":label_text})
	var key=Button.new();key.name="Action_"+id;key.position=r.position;key.size=r.size;key.tooltip_text=label_text;key.mouse_filter=Control.MOUSE_FILTER_IGNORE
	for state in ["normal","hover","pressed"]:key.add_theme_stylebox_override(state,StyleBoxEmpty.new())
	key.add_theme_stylebox_override("focus",UI.box(Color(1,.8,.3,.12),12,UI.GOLD,3))
	key.pressed.connect(func():input_action(id,at));add_child(key)

func build_hits():
	hits.clear()
	for child in get_children():
		if child!=lens:child.queue_free()
	if not runtime.ready_for_action():return
	var c=runtime.config();var sp=runtime.stage_progress()
	match c.kind:
		"keymatch":
			var wide=size.x>size.y
			map_rect=Rect2(board.position,Vector2(board.size.x*.34,board.size.y)) if wide else Rect2(board.position,Vector2(board.size.x,minf(190,board.size.y*.38)))
			tray_rect=Rect2(map_rect.end.x+16,board.position.y,board.end.x-map_rect.end.x-16,board.size.y) if wide else Rect2(board.position.x,map_rect.end.y+12,board.size.x,board.end.y-map_rect.end.y-12)
			for i in 10:
				var columns=5 if wide else 2
				var cell=tray_rect.size/Vector2(columns,10/columns)
				hit(c.items[i].id,tray_rect.position+Vector2(i%columns+.5,int(i/columns)+.5)*cell,c.items[i].label,cell-Vector2(5,5))
			hit("reset_keys" if int(sp.get("attempts",0))>=3 else "test_key",Vector2(board.get_center().x,size.y-36),"Undersøg igen" if int(sp.get("attempts",0))>=3 else "Prøv nøglen",Vector2(minf(190,size.x-240),48))
		"choice","riddle","truth","elements":
			card_boxes.clear()
			var count=c.items.size();var gap=12.0 if board.size.x>400 else 8.0
			var width=minf(220,(board.size.x-(count-1)*gap)/count)
			var height=minf(board.size.y-(54 if c.kind=="elements" else 0),width*1.48)
			var top=board.position.y+(board.size.y-height)/2+(22 if c.kind=="elements" else 0)
			for i in count:
				var r=Rect2(board.get_center().x-(width*count+gap*(count-1))/2+i*(width+gap),top,width,height)
				card_boxes.append(r);hit(c.items[i].id,r.get_center(),c.items[i].label,r.size)
		"jigsaw","packing":
			var packing=c.kind=="packing"
			if board.size.x>board.size.y*1.35:
				var height=minf(board.size.y,board.size.x*(.43 if packing else .59/1.5))
				var width=height*(1.0 if packing else 1.5)
				map_rect=Rect2(board.position+Vector2(8,(board.size.y-height)/2),Vector2(width,height))
				tray_rect=Rect2(map_rect.end.x+22,map_rect.position.y,board.end.x-map_rect.end.x-30,height)
			else:
				var width=minf(board.size.x-16,(board.size.y-138)*(1.0 if packing else 1.5))
				map_rect=Rect2(board.get_center().x-width/2,board.position.y,width,width/(1.0 if packing else 1.5))
				tray_rect=Rect2(board.position.x,map_rect.end.y+12,board.size.x,maxf(96,board.end.y-map_rect.end.y-12))
			if packing:
				for i in 16:
					var cell=map_rect.size.x/4
					hit("cell_"+str(i),map_rect.position+Vector2(i%4+.5,int(i/4)+.5)*cell,"Rum i tasken",Vector2.ONE*cell)
				for i in c.items.size():hit(c.items[i].id,tray_slot(i).get_center(),c.items[i].label,tray_slot(i).size)
				var foot_width=minf(106,(size.x-224)/2)
				hit("turn",Vector2(board.get_center().x-foot_width/2-4,size.y-36),"Drej tingen",Vector2(foot_width,48))
				hit("unpack",Vector2(board.get_center().x+foot_width/2+4,size.y-36),"Pak om",Vector2(foot_width,48))
			else:
				for i in 6:
					hit("slot_"+str(i),piece_slot(i).get_center(),"Plads til kortbrik",piece_slot(i).size)
					if not "piece_"+str(i) in sp.done:hit("piece_"+str(i),tray_slot([3,0,5,1,4,2].find(i)).get_center(),"Kortbrik",tray_slot(i).size)
		"potion":
			for i in 3:hit(c.items[i].id,ingredient_at(i),c.items[i].label,Vector2.ONE*clampf(board.size.x*.21,50,94))
			hit("cauldron",potion_at(),"Gryden — tilsæt eller rør",Vector2(minf(board.size.x*.52,260),board.size.y*.57))
		"runes":
			var wide=board.size.x>board.size.y*1.4
			for i in 4:
				var uv=[.16+i*.226,.42] if wide else [.30+(i%2)*.4,.25+int(i/2)*.40]
				hit(c.items[i].id,p(uv),c.items[i].label,Vector2.ONE*minf(point_size*1.2,board.size.y*(.64 if wide else .31)))
			hit("repeat",Vector2(board.get_center().x,board.end.y-24),"Hør igen",Vector2(154,48))
		"lock","balance","aim":
			hit("send" if c.kind=="aim" else "stop",Vector2(board.get_center().x,board.end.y-24),"Send lys" if c.kind=="aim" else "Stop lyset",Vector2(minf(210,board.size.x*.6),48))
		"labyrinth","memory_map":
			var wide=board.size.x>board.size.y*1.3
			var available=board.size-Vector2(174 if wide else 0,0 if wide else 114)
			var cols=9 if c.kind=="labyrinth" else 5;var rows=7 if c.kind=="labyrinth" else 5
			var unit=minf(available.x/cols,available.y/rows)
			map_rect=Rect2(board.position+Vector2((available.x-unit*cols)/2,0),Vector2(unit*cols,unit*rows))
			var center=Vector2(board.end.x-78,board.get_center().y) if wide else Vector2(board.get_center().x,board.end.y-55)
			for dir in AdventureGame.DIRECTIONS:
				var d=AdventureGame.DIRECTIONS[dir]
				hit(dir,center+Vector2(d)*50,dir,Vector2(48,48))
			if c.kind=="memory_map":
				hit("repeat",center,"Se kortet",Vector2(48,48))
		"runner":
			for i in 3:hit("lane_"+str(i),Vector2(board.position.x+board.size.x*(i+.5)/3,board.end.y-26),"Spor "+str(i+1),Vector2(board.size.x/3-8,52))
		"stealth":
			hit("hold",p([.50,.58]),"Hold og slip nøglen",Vector2(minf(240,board.size.x*.65),maxf(64,board.size.y*.40)))
		"search":
			for clue in c.items:
				if not clue.id in sp.done:hit(clue.id,p(clue.pos),clue.label,Vector2.ONE*(42 if highlighted else 28))
			hit("lens",Vector2(board.get_center().x,size.y-36),"Lup til eller fra",Vector2(84,48))
		"journey":
			map_rect=Rect2(Vector2.ZERO,size)
			hit("depart",Vector2(board.get_center().x,size.y-36),"Følg eventyret",Vector2(210,48))

func tray_slot(i: int) -> Rect2:
	var cell=Vector2(tray_rect.size.x/3,tray_rect.size.y/2)
	var side=minf(cell.x-8,cell.y-8)
	return Rect2(tray_rect.position+Vector2((i%3+.5)*cell.x,(int(i/3)+.5)*cell.y)-Vector2.ONE*side/2,Vector2.ONE*side)

func piece_slot(i: int) -> Rect2:
	var cell=map_rect.size/Vector2(3,2)
	return Rect2(map_rect.position+Vector2(i%3,int(i/3))*cell,cell)

func input_action(id: String, at: Vector2):
	if not runtime.ready_for_action() or paused:return
	var c=runtime.config()
	if id=="repeat":set_reveal();last_rune="";return
	if id=="lens" and c.kind=="search":lens_on=not lens_on;update_lens();return
	if c.kind=="search" and not lens_on:return
	if c.kind=="runes":
		if age<reveal_until:return
		last_rune=id;rune_flash=.35
	if c.kind=="memory_map" and age<reveal_until:return
	var point=normalized(at)
	if c.kind in ["lock","balance"]:point=Vector2(marker(),.5)
	if c.kind=="aim":point=aim_position()
	if c.kind=="stealth":
		acted.emit("release" if runtime.stage_progress().get("held",false) else "hold",point);return
	acted.emit(id,point)

func sync_state():
	var sp=runtime.stage_progress()
	if runtime.config().kind=="jigsaw" and sp.done.size()>last_done.size():
		flight_id=sp.done.back();flight_from=drag_point if dragging else tray_slot([3,0,5,1,4,2].find(int(flight_id.substr(6)))).get_center();flight_age=0
	last_done=sp.done.duplicate()
	if runtime.config().kind=="runes" and (last_round!=int(sp.get("round",0)) or last_mistakes!=int(sp.get("mistakes",0))):set_reveal()
	last_round=int(sp.get("round",0));last_mistakes=int(sp.get("mistakes",0))
	build_hits();queue_redraw()

func release_hold():
	if runtime and runtime.config().kind=="stealth" and runtime.stage_progress().get("held",false):acted.emit("release",Vector2.ZERO)
	dragging=false;down_id=""

func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:paused=true;release_hold()
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:paused=false;accumulator=0.0

func _process(delta):
	if not runtime:return
	var host=get_parent().get_parent() if get_parent() else null
	if paused or (host and host.get("modal")!=null and not host.modal.is_empty()):return
	if runtime.config().kind=="runes":
		var note=lit_rune()
		if not note.is_empty() and note!=heard_rune and host and host.get("sound"):host.sound.rune_note(note)
		heard_rune=note
	var dt=minf(delta,.08);age+=dt;flight_age+=dt;rune_flash=maxf(0,rune_flash-dt)
	if not reduced:time+=dt
	if runtime.ready_for_action():
		var kind=runtime.config().kind
		if kind=="journey" and host and host.get("world"):
			var c=runtime.config();var progress=clampf(age/1.15,0,c.stops.size()-1)
			var index=mini(int(progress),c.stops.size()-2);var a=c.stops[index];var b=c.stops[index+1]
			var destination=Vector2(a[1],a[2]).lerp(Vector2(b[1],b[2]),progress-index)
			host.world.focus=host.world.focus.lerp(destination,.025) if not reduced else Vector2(.5,.5)
		if kind in ["runner","stealth"]:
			accumulator+=dt
			var step=.5 if kind=="runner" else .25
			if accumulator>=step:
				accumulator-=step;acted.emit("tick",Vector2(step,0))
	queue_redraw()

func _gui_input(event):
	if not runtime.ready_for_action():return
	var kind=runtime.config().kind
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed:
			down_id=at_point(event.position);down_point=event.position;drag_point=event.position;dragging=false
			if kind=="search":lens_at=event.position;update_lens()
			if kind=="stealth" and down_id=="hold":acted.emit("hold",normalized(event.position))
			if kind in ["jigsaw","packing","potion"] and not down_id.is_empty() and not down_id.begins_with("slot_") and not down_id.begins_with("cell_") and not down_id in ["turn","unpack","cauldron"]:input_action(down_id,event.position)
			if kind=="potion":last_angle=(event.position-potion_at()).angle();stirring=0
		else:
			var id=at_point(event.position)
			if kind=="stealth":acted.emit("release",Vector2.ZERO)
			elif kind=="search":
				if id=="lens":input_action(id,event.position)
				elif lens_on:
					for clue in runtime.config().items:
						if event.position.distance_to(p(clue.pos))<(22 if highlighted else 15):input_action(clue.id,event.position);break
			elif not id.is_empty():
				if not (kind in ["jigsaw","packing","potion"] and id==down_id and not id in ["turn","unpack","cauldron"] and not id.begins_with("cell_") and not id.begins_with("slot_")):input_action(id,event.position)
			down_id="";dragging=false
		accept_event()
	elif event is InputEventMouseMotion:
		drag_point=event.position
		if not down_id.is_empty() and event.position.distance_to(down_point)>6:dragging=true
		if kind=="search" and (event.button_mask&MOUSE_BUTTON_MASK_LEFT):lens_at=event.position;update_lens()
		if kind=="runner" and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
			var lane=clampi(int((event.position.x-board.position.x)/board.size.x*3),0,2)
			if lane!=int(runtime.stage_progress().get("lane",1)):acted.emit("lane_"+str(lane),Vector2.ZERO)
		if kind in ["labyrinth","memory_map"] and event.button_mask&MOUSE_BUTTON_MASK_LEFT and map_rect.has_point(event.position):
			map_drag(event.position)
		if kind=="potion" and down_id=="cauldron" and runtime.stage_progress().done.size() in [3,4,5]:
			var angle=(event.position-potion_at()).angle();var change=wrapf(angle-last_angle,-PI,PI)
			stirring+=absf(change);last_angle=angle
			if stirring>TAU*.85:stirring=0;acted.emit("stir",Vector2(.5,.37))
		queue_redraw();accept_event()

func map_drag(at: Vector2):
	var c=runtime.config();var sp=runtime.stage_progress();var width=int(c.maze.width) if c.kind=="labyrinth" else 5
	var cell_size=map_rect.size.x/width
	var cell=Vector2i((at-map_rect.position)/cell_size)
	if c.kind=="labyrinth":
		var index=cell.y*width+cell.x
		if index!=int(sp.get("cell",0)):acted.emit("node_"+str(index),Vector2.ZERO)
	else:
		if age<reveal_until:return
		var current=Vector2i(0,4)
		for dir in sp.get("steps",[]):current+=AdventureGame.DIRECTIONS[dir]
		var diff=cell-current
		for dir in AdventureGame.DIRECTIONS:
			if diff==AdventureGame.DIRECTIONS[dir]:acted.emit(dir,Vector2.ZERO);break

func marker() -> float:
	var speed=1.65 if runtime.config().kind=="lock" else 1.3
	if reduced:speed*=.55
	return .5+.46*sin(age*speed)

func aim_position() -> Vector2:
	var t=age*(.65 if reduced else 1.0)
	return Vector2(.5+sin(t*1.6)*.31,.5+sin(t*1.6+sin(t*.35)*.4)*.22)

func draw_control(id: String, label: String):
	for h in hits:
		if h.id==id:
			var style=UI.box(Color(.045,.14,.12,.93),13,Color("bca778"),1);style.shadow_color=Color(0,0,0,.3);style.shadow_size=6
			draw_style_box(style,h.rect);text_center(label,h.rect.get_center()+Vector2(0,5),13);return

func glow(at: Vector2, extent: float, tint: Color=Color.WHITE):
	if soft_glow:draw_texture_rect(soft_glow,Rect2(at-Vector2.ONE*extent/2,Vector2.ONE*extent),false,tint)

func wrapped(text: String, rect: Rect2, font_size: int=15, color: Color=UI.CREAM):
	var words=text.split(" ");var rows=[];var line=""
	for word in words:
		if UI.body.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x>rect.size.x and not line.is_empty():rows.append(line.strip_edges());line=""
		line+=word+" "
	rows.append(line.strip_edges())
	for i in rows.size():text_center(rows[i],Vector2(rect.get_center().x,rect.position.y+(i+1)*font_size*1.35),font_size,color)

func _draw():
	if not runtime:return
	var c=runtime.config();var sp=runtime.stage_progress()
	match c.kind:
		"keymatch":draw_keys(c,sp)
		"choice","riddle","truth","elements":draw_cards(c,sp)
		"jigsaw":draw_jigsaw(sp)
		"packing":draw_packing(c,sp)
		"potion":draw_potion(c,sp)
		"runes":draw_runes(c,sp)
		"labyrinth","memory_map":draw_map(c,sp)
		"lock","balance":draw_timing(c,sp)
		"aim":draw_aim(sp)
		"runner":draw_runner(sp)
		"stealth":draw_stealth(sp)
		"search":draw_search(c,sp)
		"journey":draw_journey(c)
	if highlighted and c.kind in ["jigsaw","packing","labyrinth","memory_map","elements","lock","balance","aim"]:
		var hint=AdventureGame.hint_step(c,sp)
		if c.kind=="labyrinth" and hint.get("id","").begins_with("node_"):
			var step=int(hint.id.substr(5))-int(sp.get("cell",0))
			hint.id="right" if step==1 else ("left" if step==-1 else ("down" if step==int(c.maze.width) else "up"))
		for h in hits:
			if h.id==hint.get("id",""):draw_style_box(UI.box(Color(1,.84,.4,.06),12,UI.GOLD,2),h.rect.grow(3))

func draw_cards(c: Dictionary,sp: Dictionary):
	if c.kind=="elements":
		var opponent=c.opponents[mini(sp.done.size(),2)]
		sprite(opponent,Vector2(board.get_center().x,board.position.y+25),50)
		text_center("FIND BALANCEN  ·  "+str(sp.done.size()+1)+" / 3",Vector2(board.get_center().x,board.position.y+57),10,UI.GOLD)
	for i in card_boxes.size():
		var r=card_boxes[i];var card=c.items[i]
		var progress=1.0 if reduced else clampf((age-i*.11)/.48,0,1)
		var eased=1-pow(1-progress,3)
		var offset=Vector2(0,(1-eased)*35)
		r.position+=offset
		var alpha=eased
		var wrong=card.id in sp.get("wrong",[])
		var bg=Color(.055,.16,.14,.95) if i%2==0 else Color(.12,.13,.16,.95)
		var style=UI.box(Color(bg,alpha),16,Color(.85,.69,.39,alpha*.85),2)
		style.shadow_color=Color(0,.015,.01,alpha*.5);style.shadow_size=12;style.shadow_offset=Vector2(0,6)
		draw_style_box(style,r)
		draw_style_box(UI.box(Color(1,.90,.63,alpha*.04),12,Color(1,.91,.66,alpha*.15)),r.grow(-6))
		var at=r.position+Vector2(r.size.x/2,r.size.y*.37)
		glow(at,r.size.x*.90,Color(1,1,1,alpha))
		var side=minf(r.size.x*.83,r.size.y*.64)
		sprite(card.icon,at,side,0 if reduced else sin(time*.85+i)*.027,Color(1,1,1,alpha*(.55 if wrong else 1)))
		var title=card.label.split(" · ")[0]
		var fs=12 if r.size.x<125 else 16
		wrapped(title,Rect2(r.position+Vector2(8,r.size.y*.68),Vector2(r.size.x-16,r.size.y*.3)),fs,Color(UI.CREAM,alpha))
		if card.label.contains(" · ") and r.size.y>180:wrapped(card.label.split(" · ")[1],Rect2(r.position+Vector2(8,r.size.y*.86),Vector2(r.size.x-16,28)),10,Color(UI.GOLD,alpha))
		for corner in [r.position+Vector2(12,12),r.position+Vector2(r.size.x-12,12)]:draw_circle(corner,2,Color(UI.GOLD,alpha*.8))
		if wrong:text_center("Prøv et andet spor",Vector2(r.get_center().x,r.end.y-9),9,UI.GOLD)

func draw_jigsaw(sp: Dictionary):
	var texture=map_texture
	draw_style_box(UI.box(Color(.11,.10,.065,.82),8,UI.GOLD,2),map_rect.grow(4))
	draw_texture_rect(texture,map_rect,false,Color(.65,.63,.51,.32))
	for i in 6:
		var slot=piece_slot(i);draw_rect(slot,Color(1,.88,.64,.22),false,1)
		var id="piece_"+str(i)
		var r=slot if id in sp.done else tray_slot([3,0,5,1,4,2].find(i))
		if dragging and down_id==id:continue
		if id==flight_id and flight_age<.32 and not reduced:r.position=flight_from.lerp(slot.get_center(),1-pow(1-flight_age/.32,3))-r.size/2
		draw_piece(texture,i,r.grow(-2),sp.selected==id)
	if dragging and down_id.begins_with("piece_"):
		var i=int(down_id.substr(6));draw_piece(texture,i,Rect2(drag_point-map_rect.size/Vector2(6,4),map_rect.size/Vector2(3,2)),true)

func draw_piece(texture: Texture2D,index: int,r: Rect2,selected: bool):
	var cell=texture.get_size()/Vector2(3,2)
	var style=UI.box(Color(.1,.07,.035,1),4,UI.GOLD if selected else Color("9e7940"),2);style.shadow_color=Color(0,0,0,.45);style.shadow_size=8;style.shadow_offset=Vector2(0,4)
	draw_style_box(style,r.grow(2))
	draw_texture_rect_region(texture,r,Rect2(Vector2(index%3,int(index/3))*cell,cell))
	draw_line(r.position,r.position+Vector2(r.size.x,0),Color(1,.95,.74,.5),1,true)

func draw_packing(c: Dictionary,sp: Dictionary):
	var unit=map_rect.size.x/4
	var leather=UI.box(Color(.20,.095,.04,.94),16,Color("c29554"),3);leather.shadow_color=Color(0,0,0,.5);leather.shadow_size=16
	draw_style_box(leather,map_rect.grow(8))
	for i in 16:
		var r=Rect2(map_rect.position+Vector2(i%4,int(i/4))*unit,Vector2.ONE*unit)
		draw_rect(r.grow(-2),Color(.9,.72,.42,.09));draw_rect(r.grow(-2),Color(.9,.72,.42,.18),false,1)
	for id in sp.get("bag",{}):
		var placed=sp.bag[id];var shape=AdventureGame.packing_shape(c,id,int(placed.turn))
		var r=Rect2(map_rect.position+Vector2(placed.x,placed.y)*unit,Vector2(shape)*unit).grow(-3)
		draw_style_box(UI.box(Color(.12,.25,.16,.84),8,Color("d8b875")),r)
		sprite(id,r.get_center(),minf(r.size.x,r.size.y)*.94)
	for i in c.items.size():
		var item=c.items[i];var r=tray_slot(i)
		if not item.id in sp.done:
			if sp.selected==item.id:draw_style_box(UI.box(Color(1,.8,.3,.12),10,UI.GOLD,2),r)
			sprite(item.icon,r.get_center()-Vector2(0,6),r.size.x*.87)
			plaque(str(int(item.shape[0]))+" × "+str(int(item.shape[1])),r.get_center()+Vector2(0,r.size.y*.43),10)
		else:text_center("✓",r.get_center()+Vector2(0,6),24,UI.GOLD)
	if dragging and not sp.selected.is_empty():sprite(sp.selected,drag_point,unit*1.4)
	draw_control("turn","↻" if size.x<360 else "↻ Drej");draw_control("unpack","Om" if size.x<360 else "Pak om")

func plaque(text: String, at: Vector2, font_size: int=11):
	var width=UI.body.get_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x+16
	draw_style_box(UI.box(Color(.06,.10,.13,.86),7,Color(.82,.68,.43,.35)),Rect2(at-Vector2(width/2,font_size+3),Vector2(width,font_size+10)))
	text_center(text,at,font_size,UI.CREAM)

func ingredient_at(i: int) -> Vector2:
	return p([.12+i*.18,.70]) if size.x>size.y else p([.16+i*.34,.80])

func potion_at() -> Vector2:
	var world=get_parent().get_parent().get("world") if get_parent() and get_parent().get_parent() else null
	if world and world.art:
		var region=world.source_region(world.art,Rect2(Vector2.ZERO,size),world.scene_time,world.focus)
		return (world.art.get_size()*Vector2(.745,.57)-region.position)/region.size*size
	return p([.74,.56])

func lit_rune() -> String:
	var c=runtime.config();var sp=runtime.stage_progress()
	var seq=c.sequences[mini(int(sp.get("round",0)),c.sequences.size()-1)]
	var start=reveal_until-seq.size()*.78-.9
	if age<reveal_until and age>start+.4:
		var index=int((age-start-.4)/.78)
		if index<seq.size() and fposmod(age-start-.4,.78)<.58:return seq[index]
	elif rune_flash>0:return last_rune
	return ""

func draw_potion(c: Dictionary,sp: Dictionary):
	var at=potion_at();var side=minf(size.x*.24,size.y*.30)
	glow(at,side*1.45,Color(.5,1,.84,.8))
	# The painted cauldron is the actual target; steam and liquid light live above it.
	if not reduced:
		for i in 9:
			var phase=fposmod(time*.35+i*.13,1)
			var dot=at+Vector2(sin(i*3.0+time)*side*.13,-side*.2-phase*side*.42)
			draw_circle(dot,2.5*(1-phase),Color(.55,1,.87,(1-phase)*.7))
	for i in c.recipe.size():
		var center=Vector2(board.get_center().x+(i-3)*12,size.y-54)
		draw_circle(center,5,UI.GOLD if i<sp.done.size() else Color(1,1,1,.24))
	var next=c.recipe[mini(sp.done.size(),c.recipe.size()-1)]
	if next=="stir":
		draw_arc(at,side*.29,time*.7,time*.7+PI*1.65,40,Color(1,.89,.58,.8),2,true)
		plaque("Rør i gryden 3×",Vector2(board.get_center().x,size.y-25),11)
	else:
		plaque("Nu: "+{"dew":"dugdråbe","flower":"stjerneblomst","bottle":"månemos"}.get(next,""),Vector2(board.get_center().x,size.y-25),12)
	for i in c.items.size():
		var item=c.items[i];var center=ingredient_at(i);var r=minf(72,minf(board.size.x*.21,board.size.y*.38))
		if sp.selected==item.id:glow(center,r*1.8)
		sprite(item.icon,center,r,0 if reduced else sin(time+i)*.035)
		plaque(item.label,center+Vector2(0,r*.54),10)
	if dragging and not sp.selected.is_empty():sprite(sp.selected,drag_point,72)

func draw_runes(c: Dictionary,sp: Dictionary):
	var lit=lit_rune()
	var seq=c.sequences[mini(int(sp.get("round",0)),c.sequences.size()-1)]
	for h in hits:
		if h.id=="repeat":continue
		var at=h.rect.get_center();var radius=h.rect.size.x*.5
		draw_circle(at+Vector2(0,5),radius,Color(0,0,0,.4))
		draw_circle(at,radius,Color(.06,.17,.15,.9))
		draw_arc(at,radius-2,0,TAU,48,UI.GOLD if h.id==lit else Color("7a7860"),2,true)
		if h.id==lit:glow(at,radius*3)
		sprite(h.id,at,radius*1.5,0,Color.WHITE if h.id==lit else Color(.65,.72,.68))
	text_center("Lyt og se …" if age<reveal_until else "Din tur · "+str(int(sp.get("index",0)))+" / "+str(seq.size()),Vector2(board.get_center().x,board.end.y-60),12,UI.GOLD)
	draw_control("repeat","↻ Hør igen")

func draw_map(c: Dictionary,sp: Dictionary):
	var maze=c.kind=="labyrinth";var cols=9 if maze else 5;var rows=7 if maze else 5;var unit=map_rect.size.x/cols
	var style=UI.box(Color(.025,.10,.085,.92),10,Color("b19b62"),2);style.shadow_color=Color(0,0,0,.4);style.shadow_size=12;draw_style_box(style,map_rect.grow(7))
	if maze:
		var open={}
		for edge in c.maze.edges:open[str(int(edge[0]))+":"+str(int(edge[1]))]=true;open[str(int(edge[1]))+":"+str(int(edge[0]))]=true
		for index in cols*rows:
			var a=map_rect.position+Vector2(index%cols,int(index/cols))*unit
			var center=a+Vector2.ONE*unit/2
			if index in sp.get("steps",[]):draw_circle(center,unit*.12,Color(.8,.72,.43,.45))
			if index%cols==0:draw_line(a,a+Vector2(0,unit),Color("99a26b"),2,true)
			if int(index/cols)==0:draw_line(a,a+Vector2(unit,0),Color("99a26b"),2,true)
			if not open.has(str(index)+":"+str(index+1)) or index%cols==cols-1:draw_line(a+Vector2(unit,0),a+Vector2(unit,unit),Color("99a26b"),2,true)
			if not open.has(str(index)+":"+str(index+cols)):draw_line(a+Vector2(0,unit),a+Vector2(unit,unit),Color("99a26b"),2,true)
		var cell=int(sp.get("cell",0));var at=map_rect.position+Vector2(cell%cols+.5,int(cell/cols)+.5)*unit
		glow(at,unit*1.8);draw_circle(at,unit*.24,Color("ffe5a2"))
		sprite("dew",map_rect.position+Vector2(8.5,6.5)*unit,unit*.8)
	else:
		for y in rows+1:draw_line(map_rect.position+Vector2(0,y*unit),map_rect.position+Vector2(map_rect.size.x,y*unit),Color(.8,.85,.7,.13),1,true)
		for x in cols+1:draw_line(map_rect.position+Vector2(x*unit,0),map_rect.position+Vector2(x*unit,map_rect.size.y),Color(.8,.85,.7,.13),1,true)
		var current=Vector2i(0,4);var at=map_rect.position+(Vector2(current)+Vector2.ONE*.5)*unit
		var route=c.route if age<reveal_until else sp.get("steps",[])
		for dir in route:
			current+=AdventureGame.DIRECTIONS[dir];var next=map_rect.position+(Vector2(current)+Vector2.ONE*.5)*unit
			draw_line(at,next,Color("f4cf83"),4,true);draw_circle(next,3,UI.GOLD);at=next
		if age>=reveal_until:glow(at,unit*1.7);draw_circle(at,unit*.23,Color("ffebae"))
		else:text_center("Se godt efter · "+str(maxi(1,int(ceil(reveal_until-age))))+" s",Vector2(map_rect.get_center().x,map_rect.end.y+20),11,UI.GOLD)
	for dir in AdventureGame.DIRECTIONS:draw_control(dir,{"up":"↑","down":"↓","left":"←","right":"→"}[dir])
	if not maze:draw_control("repeat","↻")

func draw_timing(c: Dictionary,sp: Dictionary):
	var width=minf(board.size.x*.88,540);var center=p([.5,.41]);var span=Rect2(center-Vector2(width/2,25),Vector2(width,50))
	if c.kind=="lock":
		for i in 3:
			var at=center+Vector2((i-1)*width*.23,-minf(64,board.size.y*.29))
			sprite("key" if i<sp.done.size() else "rune",at,minf(54,board.size.y*.30),0,Color.WHITE if i<sp.done.size() else Color(.7,.8,.75))
	else:
		var pivot=center-Vector2(0,minf(45,board.size.y*.25));var lean=(marker()-.5)*.20
		draw_line(pivot+Vector2(0,-18),pivot+Vector2(0,28),UI.GOLD,4,true)
		draw_line(pivot+Vector2(-80,-lean*120),pivot+Vector2(80,lean*120),UI.GOLD,4,true)
		for i in 2:
			var at=pivot+Vector2(-80+i*160,(-1 if i==0 else 1)*lean*120)
			draw_arc(at+Vector2(0,13),23,0,PI,24,UI.GOLD,3,true)
	draw_style_box(UI.box(Color(.035,.10,.09,.96),23,Color("b7a16a"),2),span)
	var target=Rect2(center-Vector2(width*.13,21),Vector2(width*.26,42));draw_style_box(UI.box(Color(.43,.50,.23,.8),16,UI.GOLD,1),target)
	var light=Vector2(span.position.x+marker()*span.size.x,center.y)
	glow(light,66);draw_circle(light,10,Color("ffdf94"));draw_circle(light,4,Color("fff8df"))
	text_center(str(sp.done.size())+" / 3",Vector2(board.get_center().x,board.end.y-64),13,UI.GOLD)
	draw_control("stop","Stop lyset")

func draw_aim(sp: Dictionary):
	var center=p([.5,.39]);var radius=minf(board.size.y*.30,board.size.x*.28)
	glow(center,radius*2.5);sprite("flower",center,radius*2)
	draw_arc(center,radius*.35,0,TAU,48,UI.GOLD,2,true)
	var spot=aim_position();var at=center+(spot-Vector2(.5,.5))*radius*2.5
	glow(at,38);draw_circle(at,6,Color("fff2b7"))
	text_center("✦  "+str(sp.done.size())+" / 3",Vector2(board.get_center().x,board.end.y-63),14,UI.GOLD)
	draw_control("send","Send lys")

func draw_runner(sp: Dictionary):
	var elapsed=float(sp.get("elapsed",0))+accumulator
	var top=board.position.y+12;var bottom=board.end.y-63;var centre=board.get_center().x
	for i in 4:
		var x=board.position.x+i*board.size.x/3
		draw_line(Vector2(centre+(x-centre)*.42,top),Vector2(x,bottom),Color(.9,.83,.48,.35),2,true)
	var all=[]
	for root in AdventureGame.RUN_ROOTS:all.append({"t":root[0],"lane":root[1],"icon":"root"})
	for i in AdventureGame.RUN_STARS.size():
		var star=AdventureGame.RUN_STARS[i]
		if not i in sp.get("stars",[]):all.append({"t":star[0],"lane":star[1],"icon":"spark"})
	for thing in all:
		var phase=1-(float(thing.t)-elapsed)/3.0
		if phase<0 or phase>1.15:continue
		var spread=lerpf(.42,1,phase);var x=centre+((thing.lane+.5)/3-.5)*board.size.x*spread
		var at=Vector2(x,lerpf(top,bottom,phase))
		if thing.icon=="spark":glow(at,55);sprite("fire",at,28+phase*20)
		else:sprite("root",at,45+phase*32)
	var lane=int(sp.get("lane",1));var hero=Vector2(board.position.x+(lane+.5)*board.size.x/3,bottom)
	glow(hero,90);sprite("compass",hero+Vector2(0,-12 if reduced else sin(time*9)*2-12),58)
	for i in 3:draw_control("lane_"+str(i),"←" if i==0 else ("•" if i==1 else "→"))
	text_center("ILDFLUER  "+str(sp.get("stars",[]).size())+" / 3",Vector2(board.get_center().x,board.position.y+8),11,UI.GOLD)

func draw_stealth(sp: Dictionary):
	var phase=fposmod(float(sp.get("elapsed",0)),5.2)/5.2
	var awake=phase>.78;var warning=phase>.62 and not awake
	var at=p([.5,.22]);var eye_width=minf(100,board.size.x*.25)
	draw_style_box(UI.box(Color(.025,.10,.07,.9),25,UI.GOLD),Rect2(at-Vector2(eye_width/2,23),Vector2(eye_width,46)))
	if awake:
		draw_arc(at,19,0,TAU,32,Color("edb67b"),2,true);draw_circle(at,8,Color("edb67b"))
	else:draw_arc(at-Vector2(0,7),20,.2,PI-.2,24,UI.GOLD,3,true)
	text_center("SLIP — DEN VÅGNER" if warning or awake else "VOGTEREN SOVER",at+Vector2(0,45),11,Color("ffd39a") if warning else UI.GOLD)
	var key_at=p([.5,.58]);var amount=float(sp.get("meter",0))
	glow(key_at,140,Color(1,1,1,.4+amount*.6));sprite("key",key_at-Vector2(0,amount*18),minf(100,board.size.y*.37),-.2)
	var bar=Rect2(board.get_center().x-minf(130,board.size.x*.38),board.end.y-20,minf(260,board.size.x*.76),10)
	draw_style_box(UI.box(Color(.04,.12,.1,.8),5,UI.GOLD),bar)
	draw_style_box(UI.box(Color("cbb873"),5),Rect2(bar.position,Vector2(bar.size.x*amount,bar.size.y)))
	text_center("Hold nøglen · slip før øjet åbner",Vector2(board.get_center().x,board.end.y-34),12,UI.CREAM)

func draw_search(c: Dictionary,sp: Dictionary):
	for clue in c.items:
		var at=p(clue.pos)
		if clue.id in sp.done:
			draw_arc(at,19,0,TAU,32,UI.GOLD,2,true);text_center("✓",at+Vector2(0,6),18,UI.GOLD);continue
		match clue.icon:
			"scratch":
				for i in 3:draw_line(at+Vector2(i*3-4,-6),at+Vector2(i*3-7,5),Color(.18,.11,.05,.8),1.3,true)
			"thread":draw_polyline(PackedVector2Array([at-Vector2(7,4),at+Vector2(-2,3),at+Vector2(5,-4),at+Vector2(8,2)]),Color(.30,.61,.73,.8),1.6,true)
			"scale":draw_arc(at,5,.2,PI*1.8,14,Color(.32,.51,.25,.85),2,true)
			_:sprite(clue.icon,at,13,0,Color(.77,.8,.61,.8))
		if highlighted:draw_arc(at,23,0,TAU,32,Color(1,.84,.4,.65),1.5,true)
	if lens_on:
		draw_line(lens_at-Vector2(7,0),lens_at+Vector2(7,0),Color(1,.95,.7,.8),1,true)
		draw_line(lens_at-Vector2(0,7),lens_at+Vector2(0,7),Color(1,.95,.7,.8),1,true)
	draw_control("lens","Lup  ×3" if lens_on else "⌕  Lup")

func make_lens():
	lens=ColorRect.new();lens.mouse_filter=Control.MOUSE_FILTER_IGNORE;lens.z_index=2
	var material=ShaderMaterial.new();material.shader=preload("res://shaders/magnifier.gdshader");lens.material=material;add_child(lens)
	update_lens()

func update_lens():
	if not lens:return
	lens.visible=lens_on
	var side=clampf(minf(size.x,size.y)*.30,104,180)
	var at=lens_at+Vector2(side*.7,-side*.68)
	at.x=clampf(at.x,side*.5+10,size.x-side*.5-10);at.y=clampf(at.y,board.position.y+side*.5,board.end.y-side*.5)
	lens.position=at-Vector2.ONE*side*.5;lens.size=Vector2.ONE*side
	lens.material.set_shader_parameter("source_uv",lens_at/size)
	lens.material.set_shader_parameter("extent",lens.size/size)

func draw_journey(c: Dictionary):
	var progress=float(c.stops.size()-1) if reduced else clampf(age/1.15,0,c.stops.size()-1)
	for i in c.stops.size()-1:
		var first=c.stops[i];var second=c.stops[i+1]
		var a=journey_point(Vector2(first[1],first[2]));var b=journey_point(Vector2(second[1],second[2]))
		if progress>i:
			draw_line(a,b if progress>=i+1 else a.lerp(b,progress-i),Color(.13,.10,.04,.7),6,true)
			draw_line(a,b if progress>=i+1 else a.lerp(b,progress-i),Color("ffe4a1"),3,true)
	for i in c.stops.size():
		var stop=c.stops[i];var at=journey_point(Vector2(stop[1],stop[2]))
		if progress>=i:draw_circle(at,5,UI.GOLD)
	var index=mini(int(progress),c.stops.size()-1);var spot=c.stops[index];var at=journey_point(Vector2(spot[1],spot[2]))
	if index<c.stops.size()-1:
		var next=c.stops[index+1];at=at.lerp(journey_point(Vector2(next[1],next[2])),progress-index)
	glow(at,65);sprite("compass",at,30)
	var label=Rect2(Vector2(size.x*.5-115,74),Vector2(230,32))
	draw_style_box(UI.box(Color(.04,.11,.09,.9),8),label);text_center(spot[0],label.get_center()+Vector2(0,5),13,UI.CREAM)
	draw_control("depart","Følg eventyret  →")

func key_shape(rect: Rect2, teeth: Array, color: Color, hollow: bool=false):
	var unit=rect.size.x/9.0
	var center=Vector2(rect.position.x+unit,rect.get_center().y)
	if not hollow:
		draw_circle(center+Vector2(0,2),unit*.83,Color(.13,.07,.03,.8))
		draw_arc(center,unit*.76,0,TAU,32,color,unit*.22,true)
		draw_arc(center,unit*.53,0,TAU,32,Color("f5d794"),1,true)
		draw_circle(center,unit*.21,Color("54b9a2"))
	var start=center+Vector2(unit*.72,-unit*.22)
	var points=PackedVector2Array([start,start+Vector2(unit*6.3,0),start+Vector2(unit*6.3,unit*.45)])
	for j in range(3,-1,-1):
		var x=unit*(2.2+j*.95)
		points.append(start+Vector2(x+unit*.74,unit*.45))
		points.append(start+Vector2(x+unit*.74,unit*(.45+float(teeth[j])*.36)))
		points.append(start+Vector2(x,unit*(.45+float(teeth[j])*.36)))
		points.append(start+Vector2(x,unit*.45))
	points.append(start+Vector2(0,unit*.45))
	draw_colored_polygon(points,color)
	points.append(points[0]);draw_polyline(points,Color("ba9862") if hollow else Color("f6d392"),1.2,true)
	if not hollow:draw_line(start+Vector2(2,1),start+Vector2(unit*6.3-2,1),Color("fff1c2"),1,true)

func draw_keys(c: Dictionary,sp: Dictionary):
	var brass=UI.box(Color(.24,.15,.07,.94),16,Color("d4ab65"),3)
	brass.shadow_color=Color(0,0,0,.5);brass.shadow_size=12
	draw_style_box(brass,map_rect.grow(-4))
	for corner in [map_rect.position+Vector2(14,14),map_rect.position+Vector2(map_rect.size.x-14,14),map_rect.end-Vector2(14,14)]:draw_circle(corner,3,UI.GOLD)
	plaque("LÅSENS FIRE RILLER",Vector2(map_rect.get_center().x,map_rect.position.y+24),10)
	var profile=Rect2(map_rect.position+Vector2(16,28),Vector2(map_rect.size.x-32,map_rect.size.y*.34))
	for key in c.items:
		if key.id==c.answer:key_shape(profile,key.teeth,Color("101f1b"),true)
	var chosen={}
	for key in c.items:
		if key.id==sp.selected:chosen=key
	if not chosen.is_empty():
		key_shape(Rect2(profile.position+Vector2(0,map_rect.size.y*.32),profile.size),chosen.teeth,Color("b78a3e"))
	else:text_center("Vælg en nøgle",Vector2(map_rect.get_center().x,map_rect.position.y+map_rect.size.y*.72),11,UI.CREAM)
	for i in 3:
		var at=Vector2(map_rect.get_center().x+(i-1)*22,map_rect.end.y-17)
		draw_circle(at,5,UI.GOLD if i<3-int(sp.get("attempts",0)) else Color(.12,.09,.04))
	for i in 10:
		var h=hits[i];var r=h.rect;var key=c.items[i];var wrong=key.id in sp.get("wrong",[])
		var style=UI.box(Color(.035,.115,.10,.88),10,UI.GOLD if key.id==sp.selected else Color(.66,.57,.39,.6),2 if key.id==sp.selected else 1)
		draw_style_box(style,r)
		key_shape(r.grow(-6),key.teeth,Color("615b44") if wrong else Color("cda153"))
		text_center("×" if wrong else str(i+1),Vector2(r.get_center().x,r.end.y-7),10,UI.GOLD)
	draw_control("reset_keys" if int(sp.get("attempts",0))>=3 else "test_key","Se på låsen igen" if int(sp.get("attempts",0))>=3 else "Prøv nøglen")

func journey_point(uv: Vector2) -> Vector2:
	var world=get_parent().get_parent().get("world") if get_parent() and get_parent().get_parent() else null
	if world and world.art:
		var region=world.source_region(world.art,Rect2(Vector2.ZERO,size),world.scene_time,world.focus)
		return (world.art.get_size()*uv-region.position)/region.size*size
	return uv*size
