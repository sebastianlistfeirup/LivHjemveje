extends Control

var store: SaveStore
var runtime: StoryRuntime
var sound: Soundscape
var world: WorldView
var layer: Control
var puzzle: PuzzleView
var farm_view: FarmView
var screen = "title"
var modal = ""
var toast = ""
var toast_time = 0.0
var toast_label: Label
var current_art = ""
var art_rect = Rect2()
var text_rect = Rect2()
var portrait = false
var rebuilding = false
var import_check = 0.0
var garden_seed = 0
var garden_grow_at = -10000
var journal_tab = "fund"
var qa_timer = 0.0
var narration_text = ""
var entering = false
var animated_id = ""
var animated_node = ""
var animated_at = 0
var previous_beat = ""
var dialogue_tween: Tween
var display_css_size = Vector2i.ZERO
var play_rect=Rect2()
var reveal_label: Label
var reveal_button: Button
var reveal_text=""
var reveal_index=0
var reveal_clock=0.0
var reveal_beat=""
var reveal_next_label=""
var fx: TouchMagic
var choice_response=""
var library_runtime: StoryRuntime
var library_view: GrimoireView


func _ready():
	sync_display_scale()
	get_window().size_changed.connect(sync_display_scale)
	UI.init_fonts()
	store=SaveStore.new()
	runtime=StoryRuntime.new(store)
	sound=Soundscape.new();add_child(sound);sound.setup(store)
	world=WorldView.new();add_child(world)
	layer=Control.new();add_child(layer);layer.mouse_filter=Control.MOUSE_FILTER_IGNORE
	fx=TouchMagic.new();add_child(fx);fx.z_index=40;world.fx=fx
	resized.connect(schedule_refresh)
	if OS.has_feature("web") and not store.active().started:
		var reduce=JavaScriptBridge.eval("window.matchMedia('(prefers-reduced-motion: reduce)').matches",true)
		if bool(reduce):store.active().settings.reduced_motion=true
	refresh()

func sync_display_scale():
	if not OS.has_feature("web"):return
	# Render at the device's full pixel density, but lay out and hit-test in CSS
	# pixels. Without this, a 390px iPhone at DPR 3 selects the 1170px desktop UI.
	var dimensions=JSON.parse_string(JavaScriptBridge.eval("JSON.stringify([window.innerWidth,window.innerHeight])",true))
	if not dimensions is Array or dimensions.size()!=2:return
	var logical_size=Vector2i(int(dimensions[0]),int(dimensions[1]))
	if logical_size==display_css_size or logical_size.x<=0 or logical_size.y<=0:return
	display_css_size=logical_size
	get_window().content_scale_mode=Window.CONTENT_SCALE_MODE_CANVAS_ITEMS
	get_window().content_scale_aspect=Window.CONTENT_SCALE_ASPECT_IGNORE
	get_window().content_scale_size=logical_size

func schedule_refresh():
	if rebuilding:return
	rebuilding=true
	call_deferred("refresh")

func viewport_layout():
	var s=size
	portrait=s.y>=s.x
	if screen=="story":
		story_layout();return
	art_rect=Rect2(Vector2.ZERO,s)
	if screen=="garden":
		var top=68.0 if s.y<500 else 138.0
		play_rect=Rect2(20,top,s.x-40,s.y-top-78)
		text_rect=Rect2(130,s.y-62,s.x-330,48) if s.y<500 else Rect2(20,67,s.x-40,60)
	else:
		text_rect=Rect2(18,s.y-125,minf(s.x-36,480),105)

func reading() -> Dictionary:
	var page=runtime.page();var progress=runtime.progress()
	if progress.solved:
		return ending(page,progress)
	if runtime.ready_for_action():return {"speaker":"DIN TUR","text":runtime.config().prompt}
	if int(progress.read)==0:return {"speaker":"LIVS DAGBOG","text":AdventureBook.narrator(page,store.active().choices)}
	return page.dialogue[mini(int(progress.read)-1,page.dialogue.size()-1)]

func ending(page: Dictionary,progress: Dictionary) -> Dictionary:
	var line={"speaker":page.success_text.speaker,"text":progress.get("response",page.success_text.text)}
	for speaker in ["Liv","Noor","Edda","Mos","Frø"]:
		if line.text.begins_with(speaker+": "):
			line.speaker=speaker;line.text=line.text.substr(speaker.length()+2);break
	return line

func story_layout():
	art_rect=Rect2(Vector2.ZERO,size)
	var action=runtime.ready_for_action()
	var text=reading().text
	var text_scale=float(store.active().settings.text_scale)
	var font_size=int((15 if size.y<500 else 18)*text_scale) if action else int((17 if size.y<500 else 20)*text_scale)
	if action:
		var width=minf(size.x-28,760)
		var measure=UI.body.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width-48,font_size).y
		var height=clampf(measure+26,48,94 if size.y<500 else 126)
		text_rect=Rect2((size.x-width)/2,size.y-70-height,width,height)
		play_rect=Rect2(20,72,size.x-40,maxf(80,text_rect.position.y-82))
		return
	var long_text=text.length()>170
	var width=minf(size.x-32,490) if portrait else clampf(size.x*(.59 if long_text else .35),270,660 if long_text else 430)
	var measured=UI.body.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,width-48,font_size).y
	var height=minf(measured+114,size.y-94)
	var anchor=runtime.page().presentation.anchor
	var x=18.0 if anchor!="right" else size.x-width-18
	if portrait:x=(size.x-width)/2 + (0 if width>=size.x-36 else (-9 if int(runtime.progress().read)%2==0 else 9))
	var y=size.y-height-18
	if not portrait and not long_text and size.y>=620:y=size.y*.58
	y=minf(y,size.y-height-18)
	text_rect=Rect2(x,y,width,height)
	play_rect=Rect2(20,86,size.x-40,size.y-160)

func set_art(image_id: String):
	var actual=image_id
	if screen=="title":actual="mist"
	if screen=="story" and not portrait:actual=runtime.page().get("wide_image",image_id)
	if screen=="story" and runtime.config().kind=="potion":
		var brew_step=runtime.stage_progress().done.size()
		var variant="alchemy-done" if runtime.progress().solved else ("alchemy-stir" if brew_step>=3 else "alchemy")
		if ResourceLoader.exists("res://assets/adventure/"+variant+".webp"):actual=variant
	var path="res://assets/adventure/"+actual+".webp" if ResourceLoader.exists("res://assets/adventure/"+actual+".webp") else "res://assets/chapter_01/"+actual+".webp"
	world.steaming=actual.begins_with("alchemy")
	world.steam_color=Color(1,.87,.49) if actual=="alchemy-done" else Color(.65,.94,.89)
	world.eyes=[]
	if actual.begins_with("alchemy"):world.eyes=[Vector4(.611,.321,.016,.013),Vector4(.648,.321,.015,.013),Vector4(.719,.305,.016,.014),Vector4(.767,.323,.016,.013)]
	if actual=="well-meeting":world.eyes=[Vector4(.730,.817,.014,.017),Vector4(.810,.841,.014,.018)]
	if current_art!=path:
		world.change_art(load(path),current_art.get_file().begins_with("alchemy") and actual.begins_with("alchemy"));current_art=path
	world.framing=Rect2(.51,.13,.38,.84) if actual=="book" and portrait else Rect2(0,0,1,1)
	if screen=="story":
		var f=runtime.page().presentation.focus
		world.focus=Vector2(f[0],f[1]);world.mood=runtime.page().music
		if runtime.config().kind=="book":world.focus=Vector2(.5,.5)
	else:world.focus=Vector2(.5,.4)

func refresh():
	rebuilding=false
	if not is_inside_tree():return
	if dialogue_tween and dialogue_tween.is_valid():dialogue_tween.kill()
	for child in layer.get_children():
		# A touch release may still be dispatching through its pressed button.
		# Hide now and free at frame end, keeping the event's node in the tree.
		child.hide()
		child.queue_free()
	puzzle=null;farm_view=null;toast_label=null;reveal_label=null;reveal_button=null;library_view=null
	layer.size=size;world.size=size
	viewport_layout()
	world.art_rect=art_rect
	world.reduced=store.active().settings.reduced_motion
	world.cover=screen=="title"
	world.solved=false
	world.still=screen=="story" and runtime.ready_for_action() and runtime.config().kind in ["search","difference","book"]
	fx.reduced=store.active().settings.reduced_motion;fx.size=size
	match screen:
		"title":draw_title()
		"story":draw_story()
		"farm":draw_farm(false)
		"garden":draw_farm(true)
	if not modal.is_empty():draw_modal()
	if toast_time>0:show_toast_label()
	if not store.last_error.is_empty():
		UI.label(layer,store.last_error,Rect2(16,size.y-24,size.x-32,24),11,Color("f1d5aa"))
	world.queue_redraw()

func draw_title():
	set_art("K01_B26")
	world.page_number=26
	if not portrait and size.y<620:
		draw_short_title()
		return
	var left=36.0 if portrait else maxf(60,size.x*.085)
	var width=size.x-72 if portrait else size.x*.45
	var top=size.y*.13 if portrait else size.y*.19
	var compact=portrait and size.y<740
	if compact:top=24
	if portrait:
		var shade=ColorRect.new();shade.color=Color(.025,.08,.06,.50);shade.size=size;shade.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(shade)
	UI.label(layer,"ET EVENTYR TIL LIV",Rect2(left,top,width,30),12,UI.GOLD,UI.bold)
	UI.label(layer,"Liv",Rect2(left-4,top+30,width,124),68 if compact else (92 if not portrait else 80),UI.CREAM,UI.serif)
	UI.label(layer,"og de ti hjemveje",Rect2(left,top+(129 if compact else 151),width,100),36 if not portrait else 29,UI.CREAM,UI.serif)
	var y=top+(202 if compact else 241)
	UI.label(layer,"En lille drage. En glemt vej.\nEt hjem, der begynder med dig.",Rect2(left,y,width,100),18,Color("d2d3b8"))
	y+=92 if compact else 108
	UI.panel(layer,Rect2(left,y,minf(width,355),65),Color(.08,.18,.13,.8),14)
	UI.image(layer,UI.icon("leaf"),Rect2(left+12,y+12,40,40))
	UI.label(layer,"KAPITEL 01",Rect2(left+68,y+11,width-72,18),10,UI.GOLD,UI.bold)
	UI.label(layer,"Mos og brønden, der holdt vejret",Rect2(left+68,y+28,minf(width,350)-76,32),13)
	y+=87
	var started=store.active().started
	UI.button(layer,"Fortsæt dit eventyr  →" if started else "Begynd eventyret  →",Rect2(left,y,minf(width,355),56),begin,true)
	UI.button(layer,"Indstillinger",Rect2(left,y+70,162,48),func():open_modal("settings"),false,true)
	if width>=310 and store.data.chapters.get("chapter_01",{}).get("complete",false):
		UI.button(layer,"Besøg farmen",Rect2(left+174,y+70,minf(181,width-174),48),go_farm,false,true)
	var bottom_text="Dit eventyr gemmes automatisk på denne enhed."
	if portrait:bottom_text="Prøv liggende format. Spillet gemmer selv."
	UI.label(layer,bottom_text,Rect2(left,minf(y+142,size.y-35),width,35),11,Color("b0b69d"))
	if not portrait:
		UI.label(layer,"DEN STILLE LUND",Rect2(size.x-240,34,210,22),11,UI.GOLD,UI.bold)
		UI.label(layer,"01 / 10",Rect2(size.x-114,size.y-47,90,24),13,UI.CREAM)

func draw_short_title():
	var x=38.0;var width=size.x*.49
	var short=size.y<360
	UI.label(layer,"ET EVENTYR TIL LIV",Rect2(x,12 if short else 22,width,22),10,UI.GOLD,UI.bold)
	UI.label(layer,"Liv",Rect2(x,31 if short else 45,width,80),54 if short else 60,UI.CREAM,UI.serif)
	UI.label(layer,"og de ti hjemveje",Rect2(x,106 if short else 128,width,42),22 if short else 25,UI.CREAM,UI.serif)
	UI.label(layer,"En lille drage. En glemt vej.\nEt hjem, der begynder med dig.",Rect2(x,151 if short else 185,width,50),13 if short else 14,Color("d2d3b8"))
	UI.label(layer,"KAPITEL 01 · MOS OG DEN STILLE LUND",Rect2(x,size.y-108,width,24),10,UI.GOLD,UI.bold)
	UI.button(layer,"Fortsæt eventyret →" if store.active().started else "Begynd eventyret →",Rect2(x,size.y-75,235,52),begin,true,true)
	UI.button(layer,"Indstillinger",Rect2(x+247,size.y-75,125,52),func():open_modal("settings"),false,true)

func begin():
	sound.play_music()
	if store.active().mode in ["FARM_FREE","MINIGAME"]:
		screen="garden" if store.active().mode=="MINIGAME" else "farm"
	else:
		screen="story";runtime.enter()
	modal="";refresh();speak_current()

func draw_hud():
	UI.button(layer,"✧",Rect2(16,12,48,44),func():open_modal("map"),false)
	var title="KAPITEL 01  ·  DEN STILLE LUND" if screen=="story" else "LIVS DRAGEFARM"
	if portrait:title="KAPITEL 01" if screen=="story" else "LIVS FARM"
	if not store.replay.is_empty():title="GENBESØG  ·  DIN FARM ER GEMT"
	UI.label(layer,title,Rect2(77,17,maxf(50,size.x-260),30),10 if portrait else 12,UI.GOLD,UI.bold)
	UI.button(layer,"Dagbog",Rect2(size.x-177,12,91,44),func():open_modal("journal"),false,true)
	UI.button(layer,"☰",Rect2(size.x-73,12,56,44),func():open_modal("settings"),false)

func draw_story():
	var page=runtime.page();var progress=runtime.progress()
	set_art(page.image_id);world.page_number=int(page.page);world.solved=progress.solved
	sound.set_mood(page.music)
	if runtime.ready_for_action():
		puzzle=GrimoireView.new() if runtime.config().kind=="book" else AdventureView.new() if runtime.config().kind in AdventureGame.KINDS or runtime.config().kind=="choice" else PuzzleView.new()
		layer.add_child(puzzle);puzzle.setup(runtime,play_rect,size)
		if animated_node==page.id:
			puzzle.animated_id=animated_id;puzzle.animation_age=(Time.get_ticks_msec()-animated_at)/1000.0
		puzzle.highlighted=int(progress.get("hint",0))>=1
		puzzle.acted.connect(on_action)
	draw_hud()
	if runtime.ready_for_action() and runtime.config().kind=="book":
		narration_text=puzzle.spread.text;return
	var line=reading();narration_text=line.text
	var r=text_rect;var action=runtime.ready_for_action()
	var root=Control.new();root.mouse_filter=Control.MOUSE_FILTER_IGNORE;layer.add_child(root)
	# A small translucent veil sits inside the scene. No separate reading column.
	var panel=Panel.new();panel.position=r.position;panel.size=r.size;panel.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var ink=Color(.09,.13,.19,.91 if action else .88)
	if line.speaker=="Noor":ink=Color(.23,.13,.095,.90)
	if line.speaker=="Mos":ink=Color(.08,.20,.16,.91)
	var style=UI.box(ink,18,Color(.93,.76,.45,.48),1)
	style.shadow_color=Color(0,.025,.02,.32);style.shadow_size=18;style.shadow_offset=Vector2(0,5)
	panel.add_theme_stylebox_override("panel",style);root.add_child(panel)
	var glint=ColorRect.new();glint.position=r.position+Vector2(20,0);glint.size=Vector2(minf(60,r.size.x*.18),2);glint.color=UI.GOLD;glint.mouse_filter=Control.MOUSE_FILTER_IGNORE;root.add_child(glint)
	var font_size=int((15 if size.y<500 else 18)*store.active().settings.text_scale) if action else int((17 if size.y<500 else 20)*store.active().settings.text_scale)
	var y=r.position.y+10 if action else r.position.y+41
	if not action:
		UI.label(root,line.speaker.to_upper(),Rect2(r.position.x+20,r.position.y+13,r.size.x-40,21),10,UI.GOLD,UI.bold)
	var scroll=ScrollContainer.new();scroll.position=Vector2(r.position.x+20,y);scroll.size=Vector2(r.size.x-40,r.size.y-20 if action else maxf(35,r.size.y-112));scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;root.add_child(scroll)
	var measured=UI.body.get_multiline_string_size(line.text,HORIZONTAL_ALIGNMENT_LEFT,scroll.size.x-8,font_size).y
	var label=UI.label(scroll,line.text,Rect2(0,0,scroll.size.x-8,measured),font_size,Color("fff2d9"))
	label.custom_minimum_size.y=0;label.size_flags_vertical=Control.SIZE_SHRINK_BEGIN
	UI.quiet_scroll(scroll.get_v_scroll_bar())
	label.add_theme_color_override("font_shadow_color",Color(0,0,0,.4));label.add_theme_constant_override("shadow_offset_y",1)
	if action and runtime.config().kind!="journey":
		UI.button(root,"✧ Hint",Rect2(16,size.y-60,80 if size.x<500 else 96,48),hint,false,true)
		UI.button(root,"Genlæs",Rect2(size.x-(96 if size.x<500 else 112),size.y-60,80 if size.x<500 else 96,48),reread,false,true)
	elif not action:
		var next_text="Videre  →" if progress.solved else ("Udforsk  →" if int(progress.read)==page.dialogue.size() else "Læs videre  →")
		if progress.solved and int(page.page)==40:next_text="Hjem til Mos  →"
		reveal_button=UI.button(root,next_text,Rect2(r.position.x+16,r.end.y-64,r.size.x-32,48),next_scene if progress.solved else read_next,true,true)
		reveal_next_label=next_text
	var beat=page.id+":"+str(progress.read)+":"+str(progress.solved)+":"+str(progress.stage)
	start_reveal(label,line.text,beat,action)
	if beat!=previous_beat and not store.active().settings.reduced_motion:
		root.modulate.a=0;root.position.y=9
		dialogue_tween=root.create_tween().set_parallel(true)
		dialogue_tween.tween_property(root,"modulate:a",1.0,.32)
		dialogue_tween.tween_property(root,"position:y",0.0,.38).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	previous_beat=beat
	if not action:
		var title=UI.label(layer,page.title,Rect2(78,43,maxf(60,size.x-235),26),10,Color(1,.9,.68,.85),UI.serif)
		title.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS

func start_reveal(label: Label, text: String, beat: String, action: bool):
	reveal_label=label
	if beat!=reveal_beat:
		reveal_index=text.length() if action or store.active().settings.reduced_motion else 0
		reveal_clock=0.0;reveal_beat=beat
	reveal_text=text;reveal_index=mini(reveal_index,text.length());label.visible_characters=reveal_index
	if store.active().settings.reduced_motion:reveal_all()
	elif reveal_button and reveal_index<text.length():reveal_button.text="Vis hele replikken  ···"

func reveal_all() -> bool:
	if not is_instance_valid(reveal_label) or reveal_index>=reveal_text.length():return false
	reveal_index=reveal_text.length();reveal_label.visible_characters=-1
	if is_instance_valid(reveal_button):reveal_button.text=reveal_next_label
	return true

func read_next():
	if reveal_all():return
	sound.cue();runtime.read_next();refresh();speak_current()

func reread():
	runtime.progress().read=0;store.persist();refresh();speak_current()

func on_action(id: String, pos: Vector2):
	if not modal.is_empty():return
	var was_stage=int(runtime.progress().stage)
	var kind=runtime.config().kind
	var selected=runtime.stage_progress().selected
	var success=runtime.perform(id,pos)
	if kind=="potion" and success:set_art(runtime.page().image_id)
	var changed_stage=int(runtime.progress().stage)!=was_stage or runtime.progress().solved
	if success and id not in ["tick","hold","release"] and not id.begins_with("lane_"):
		animated_id=selected if not selected.is_empty() else id;animated_node=runtime.page().id;animated_at=Time.get_ticks_msec()
		sound.cue("success" if runtime.progress().solved else ("water" if kind=="potion" else "place"))
		if puzzle and pos.x>=0 and pos.x<=1 and pos.y>=0 and pos.y<=1:world.burst(puzzle.board.position+pos*puzzle.board.size)
	if not runtime.feedback.is_empty() and not runtime.progress().solved:notify_user(runtime.feedback)
	if runtime.progress().solved:
		toast_time=0
		if is_instance_valid(toast_label):toast_label.hide()
	if kind=="choice" and runtime.progress().solved and not runtime.feedback.is_empty():runtime.progress().response=runtime.feedback;store.persist()
	if puzzle is AdventureView and not changed_stage:
		puzzle.sync_state();return
	if puzzle and puzzle.dragging and not success:puzzle.queue_redraw()
	else:schedule_refresh()
	if kind=="book" and not runtime.progress().solved:call_deferred("speak_current")
	if runtime.progress().solved:speak_text(reading().text)

func next_scene():
	if reveal_all():return
	if entering:return
	entering=true
	toast_time=0
	if runtime.next_page():
		sound.cue()
		if store.active().mode=="FARM_FREE":
			screen="farm";modal="welcome";sound.play_music(true)
		refresh()
		if not store.active().settings.reduced_motion:
			layer.modulate.a=0
			var tween=create_tween();tween.tween_property(layer,"modulate:a",1.0,.24)
		speak_current()
	entering=false

func hint():
	var progress=runtime.progress()
	progress.hint=mini(3,int(progress.hint)+1)
	store.persist()
	match int(progress.hint):
		1:
			var help={"choice":"Der er ikke et forkert valg her. Vælg det, du har lyst til.","keymatch":"Noor: Sammenlign tænderne fra venstre. Nogle nøgler har kun én tand, der er anderledes.","riddle":"Se på de tre ting. Hvilken passer til alle dele af gåden?","truth":"Husk vandet bag slusen og den lås, I fandt.","runes":"Se og lyt igen. Begynd med den første rune, og tag én ad gangen.","potion":"Træk den næste ingrediens hen i gryden. Når opskriften siger rør, laver du en cirkel — eller trykker på gryden.","runner":"Hold øje med, hvilket spor ildfluen kommer ned ad. Rødderne kan ikke flytte sig til et andet spor.","stealth":"Slip allerede, når beskeden siger, at vogteren vågner. Vent på, at den sover igen."}
			notify_user(help.get(runtime.config().kind,"Se efter den gyldne ring. Den viser noget, du kan prøve."))
		2:
			var c=runtime.config();var sp=runtime.stage_progress()
			if c.kind=="place":
				for item in c.items:
					if not item.get("decoy",false) and not item.id in sp.done:
						notify_user("Vælg "+item.label.to_lower()+", og se efter det lysende sted.");break
			else:notify_user(c.prompt+" Tryk på hint igen, så viser Liv ét lille trin.")
		3:
			var changed=runtime.demonstrate()
			if changed:sound.cue("place")
			notify_user("Vi gør det sammen. Nu er det din tur igen." if changed else runtime.feedback)
	refresh()

func go_farm():
	if not store.replay.is_empty():
		store.end_replay(false)
	store.data.mode="FARM_FREE";store.persist();screen="farm";modal="";sound.play_music(true);refresh()

func draw_farm(garden: bool):
	set_art("K01_B29" if garden else "K01_B30")
	world.page_number=40
	farm_view=FarmView.new();layer.add_child(farm_view)
	farm_view.setup(store,play_rect if garden else art_rect,size,garden)
	farm_view.selected_seed=garden_seed
	farm_view.growth_age=(Time.get_ticks_msec()-garden_grow_at)/1000.0
	farm_view.touched.connect(farm_action)
	draw_hud()
	var r=text_rect
	UI.panel(layer,r,Color(.025,.10,.075,.87),16)
	if garden:
		var text="Vælg frø → plant i jorden → drej de tre vandrødder → kald på Mos."
		if size.y<500:text="Frø · vand · naturpust"
		if GardenModel.new(store).state().grown:text="Haven blomstrer · gem dit bed" if size.y<500 else "Din have blomstrer! Gem bedet ved Rodhytten, eller dyrk et nyt."
		UI.label(layer,text,Rect2(r.position+Vector2(14,7),r.size-Vector2(28,14)),14 if size.y<500 else 16,UI.CREAM)
		UI.button(layer,"← Farm",Rect2(16,size.y-62,100,48),leave_garden,false,true)
		if GardenModel.new(store).state().grown:
			UI.button(layer,"Gem blomsterne",Rect2(size.x-181,size.y-62,165,48),func():open_modal("arrangements"),true,true)
	else:
		UI.label(layer,"MOS ER HJEMME  ·  FARMEN ER DIN",Rect2(r.position+Vector2(16,10),Vector2(r.size.x-32,23)),10,UI.GOLD,UI.bold)
		var button_width=(r.size.x-44)*.5
		UI.button(layer,"Leg i haven",Rect2(r.position+Vector2(16,42),Vector2(button_width,48)),enter_garden,true,true)
		UI.button(layer,"Rodhytten",Rect2(r.position+Vector2(28+button_width,42),Vector2(button_width,48)),func():open_modal("house"),false,true)

func farm_description(garden: bool) -> String:
	if garden and GardenModel.new(store).state().grown:
		return "Se, hvad I har fået til at gro! Gem blomsterne ved Rodhytten, eller prøv et større bed. De visner aldrig, mens du er væk."
	return "Vælg et frø og tryk på jorden. Plant mindst tre frø, drej rødderne, så vandet kan løbe, og kald på Mos." if garden else "Mos har fundet sin plads. Besøg ham, indret Rodhytten eller dyrk noget, der kun findes i din have. Her er ingen, der har travlt."

func farm_action(id: String):
	if screen=="garden":
		var model=GardenModel.new(store)
		if id.begins_with("seed_"):
			garden_seed=int(id.substr(5));sound.cue()
		elif id.begins_with("cell_"):
			model.plant(int(id.substr(5)),garden_seed);sound.cue("place")
		elif id.begins_with("pipe_"):
			model.rotate_pipe(int(id.substr(5)));sound.cue("water")
		elif id=="grow":
			if model.grow():
				garden_grow_at=Time.get_ticks_msec()
				sound.cue("success");notify_user("Mos: Det her er vores slags have.")
			else:notify_user("Plant mindst tre frø, og forbind alle tre rødder. Vandet viser, hvor forbindelsen stopper.")
		schedule_refresh();return
	match id:
		"mos":
			farm_view.mos_reaction=3.0
			sound.cue("success")
			notify_user(["Mos: Døren er stadig åben. Godt.","Mos: Kan vi lave flere blomster?","Mos: Liv. Stadig lidt bolle."][randi()%3])
		"house":open_modal("house")
		"garden":enter_garden()
		"map":open_modal("map")
		"album":open_modal("album")
		"dock":notify_user("Vandet er roligt. På den anden side venter fyret. I dag er der også tid til at blive hjemme.")

func enter_garden():
	store.active().mode="MINIGAME";store.persist();screen="garden";modal="";refresh()

func leave_garden():
	store.active().mode="FARM_FREE";store.persist();screen="farm";modal="";toast_time=0;refresh()

func open_modal(which: String):
	if puzzle is AdventureView:puzzle.release_hold()
	toast_time=0
	if which=="dragon_book" and not library_runtime:
		var library_store=SaveStore.new(true)
		library_store.data.settings=store.active().settings.duplicate(true)
		library_runtime=StoryRuntime.new(library_store);library_runtime.enter()
	modal=which;sound.cue();refresh()

func close_modal():
	var was_book=modal=="dragon_book"
	modal="";library_runtime=null;refresh()
	if was_book:speak_current()

func modal_shell(title: String, height: float = 620) -> Dictionary:
	var dim=ColorRect.new();dim.color=Color(0.015,.04,.03,.85);dim.size=size;dim.mouse_filter=Control.MOUSE_FILTER_STOP;layer.add_child(dim)
	var width=minf(size.x-28,580);height=minf(size.y-32,height)
	var r=Rect2((size.x-width)/2,(size.y-height)/2,width,height)
	UI.panel(layer,r,Color("152e26"),22)
	UI.label(layer,title,Rect2(r.position.x+24,r.position.y+20,r.size.x-98,45),25 if not portrait else 21,UI.CREAM,UI.serif)
	UI.button(layer,"×",Rect2(r.end.x-64,r.position.y+16,46,44),close_modal,false)
	var scroll=ScrollContainer.new();scroll.position=r.position+Vector2(20,82);scroll.size=r.size-Vector2(40,103);scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED;layer.add_child(scroll)
	var content=Control.new();content.custom_minimum_size=Vector2(scroll.size.x-12,1);scroll.add_child(content)
	return {"rect":r,"scroll":scroll,"content":content,"width":scroll.size.x-12}

func draw_modal():
	match modal:
		"settings":settings_modal()
		"journal":journal_modal()
		"dragon_book":dragon_book_modal()
		"map":map_modal()
		"house":house_modal()
		"album":album_modal()
		"welcome":welcome_modal()
		"arrangements":arrangements_modal()
		"import":import_modal()

func settings_modal():
	var m=modal_shell("Gør eventyret til dit");var c=m.content;var w=m.width;var y=0.0
	UI.label(c,"TEKSTSTØRRELSE",Rect2(0,y,w,26),11,UI.GOLD,UI.bold);y+=33
	for i in 3:
		var value=[1.0,1.25,1.5][i]
		var current=store.active().settings.text_scale==value
		UI.button(c,["100 %","125 %","150 %"][i],Rect2(i*(w+10)/3,y,(w-20)/3,48),func():set_setting("text_scale",value),current,true)
	y+=68
	for row in [["reduced_motion","Rolig bevægelse"],["music","Musik og stemning"],["effects","Lyde ved handlinger"],["narration","Dansk oplæsning"],["vibration","Små vibrationer"]]:
		var key=row[0];var enabled=store.active().settings[key]
		UI.label(c,row[1],Rect2(2,y+13,w-102,34),15)
		UI.button(c,"Til" if enabled else "Fra",Rect2(w-86,y,82,48),func():set_setting(key,not enabled),enabled,true)
		y+=60
	UI.label(c,"Oplæsning bruger en dansk stemme på din enhed, hvis den findes. Du kan altid læse videre uden lyd.",Rect2(0,y,w,65),12,UI.MUTED);y+=75
	if OS.has_feature("web"):
		UI.button(c,"Føj spillet til hjemmeskærmen",Rect2(0,y,w,48),func():JavaScriptBridge.eval("window.livInstall()",true),true,true);y+=60
		UI.button(c,"Fuldskærm",Rect2(0,y,w,48),func():JavaScriptBridge.eval("window.livFullscreen()",true),false,true);y+=60
	UI.button(c,"Eksportér mit eventyr",Rect2(0,y,w,48),export_save,false,true);y+=60
	UI.button(c,"Importér en sikkerhedskopi",Rect2(0,y,w,48),func():open_modal("import"),false,true);y+=64
	if not store.replay.is_empty():
		UI.button(c,"Afslut genbesøg og gå hjem",Rect2(0,y,w,48),go_farm,false,true);y+=60
	if screen!="title":
		UI.button(c,"Til titelskærmen",Rect2(0,y,w,48),func():screen="title";modal="";refresh(),false,true);y+=60
	UI.label(c,"Kapitel 1 · Udgave "+str(ProjectSettings.get_setting("application/config/version"))+"\nHistorie og originale illustrationer fra LivHjemveje. Musik og interaktive lag skabt til spillet.",Rect2(0,y,w,75),11,UI.MUTED);y+=80
	c.custom_minimum_size.y=y

func set_setting(key: String,value: Variant):
	store.active().settings[key]=value
	store.data.settings[key]=value
	store.persist();sound.apply_settings();refresh()
	if key=="narration" and value:speak_text("Velkommen til Liv og de ti hjemveje.")
	if key=="narration" and not value and OS.has_feature("web"):JavaScriptBridge.eval("if(window.speechSynthesis)speechSynthesis.cancel()",true)

func export_save():
	var raw=store.serialize()
	if OS.has_feature("web"):
		JavaScriptBridge.eval("window.livExport("+JSON.stringify(raw)+")",true)
		notify_user("Dit eventyr er klar som fil. Gem det et trygt sted.")
	else:
		var path="user://Livs-hjemveje-backup.json"
		var file=FileAccess.open(path,FileAccess.WRITE);file.store_string(raw);file.close()
		DisplayServer.clipboard_set(raw)
		notify_user("Sikkerhedskopien er gemt og kopieret til udklipsholderen.")

func import_modal():
	var m=modal_shell("Hent dit gemte eventyr",370);var c=m.content;var w=m.width
	UI.label(c,"En gyldig sikkerhedskopi erstatter fremgangen på denne enhed. Eksportér først dit nuværende eventyr, hvis du vil beholde det.",Rect2(0,0,w,100),16)
	UI.button(c,"Eksportér nuværende eventyr",Rect2(0,120,w,48),export_save,false,true)
	UI.button(c,"Vælg sikkerhedskopi",Rect2(0,184,w,52),func():
		if OS.has_feature("web"):JavaScriptBridge.eval("window.livImport()",true)
		else:
			var file_dialog=FileDialog.new();file_dialog.file_mode=FileDialog.FILE_MODE_OPEN_FILE;file_dialog.access=FileDialog.ACCESS_FILESYSTEM;file_dialog.filters=PackedStringArray(["*.json ; Eventyr"]);add_child(file_dialog);file_dialog.file_selected.connect(func(path):finish_import(FileAccess.get_file_as_string(path)));file_dialog.popup_centered_ratio(.7)
	,true,true)
	c.custom_minimum_size.y=245

func finish_import(raw: String):
	if store.import_save(raw):
		runtime=StoryRuntime.new(store);screen="title";modal="";refresh();notify_user("Dit eventyr er hentet. Velkommen tilbage.")
	else:notify_user("Den fil er ikke en gyldig sikkerhedskopi. Dit nuværende eventyr er bevaret.")

func journal_modal():
	var m=modal_shell("Livs dagbog");var c=m.content;var w=m.width;var y=0.0
	UI.button(c,"✧ Åbn dragebogen",Rect2(0,0,w,52),func():open_modal("dragon_book"),true,true)
	UI.button(c,"Fund og spor",Rect2(0,66,(w-12)/2,48),func():journal_tab="fund";refresh(),journal_tab=="fund",true)
	UI.button(c,"Tidligere replikker",Rect2((w+12)/2,66,(w-12)/2,48),func():journal_tab="story";refresh(),journal_tab=="story",true);y=134
	if journal_tab=="fund":
		var entries={"vaadt_blad":["Det våde blad","Under frøens vandkande var et vådt bladmærke. Vandet findes stadig et sted.","leaf"],"maerke_01":["Hånden og stjernen","Det samme mærke findes på kompasset og den lukkede sluse.","hand"],"blaa_kridt":["Blåt kridt","Nogen har streget over hånden. Vi ved endnu ikke hvorfor.","stone"],"iben_naevnt":["Navnet Iben","Edda siger, at Iben tegnede de gamle veje og ville holde alle trygge. Hvorfor er de så lukkede?","book"],"hjemvej_01":["Mos’ hjemvej","Mos valgte selv at komme med. Den første af ti hjemveje lyser grønt.","compass"],"gnist_02":["En varm gnist","Et fyr uden lys. Mos siger, at en ven fryser. Næste eventyr venter.","spark"]}
		if store.active().journal.is_empty():
			UI.label(c,"Her gemmer vi de ting, vi finder. Der er god plads til spørgsmål endnu.",Rect2(0,y,w,120),17);y+=140
		for key in store.active().journal:
			if not entries.has(key):continue
			var e=entries[key]
			UI.image(c,UI.icon(e[2]),Rect2(0,y,44,44))
			UI.label(c,e[0],Rect2(60,y,w-60,33),18,UI.GOLD,UI.serif)
			UI.label(c,e[1],Rect2(60,y+36,w-60,108),15);y+=160
	else:
		for id in store.active().visited:
			var page=runtime.pages[id]
			UI.label(c,page.title,Rect2(0,y,w,65),19,UI.GOLD,UI.serif);y+=64
			var text=AdventureBook.narrator(page,store.active().choices)+"\n\n"
			for line in page.dialogue:text+=line.speaker+": "+line.text+"\n\n"
			if store.active().node_progress.get(id,{}).get("solved",false):
				var line=ending(page,store.active().node_progress[id]);text+=line.speaker+": "+line.text
			var h=UI.body.get_multiline_string_size(text,HORIZONTAL_ALIGNMENT_LEFT,w,15).y+30
			UI.label(c,text,Rect2(0,y,w,h),15);y+=h+30
	c.custom_minimum_size.y=maxf(y,200)

func dragon_book_modal():
	var backdrop=ColorRect.new();backdrop.color=Color("121b18");backdrop.size=size;backdrop.mouse_filter=Control.MOUSE_FILTER_STOP;layer.add_child(backdrop)
	var book_world=WorldView.new();book_world.size=size;book_world.art_rect=Rect2(Vector2.ZERO,size);book_world.focus=Vector2(.5,.5);book_world.still=true;book_world.reduced=store.active().settings.reduced_motion
	book_world.framing=Rect2(.51,.13,.38,.84) if portrait else Rect2(0,0,1,1)
	layer.add_child(book_world);book_world.change_art(load("res://assets/adventure/book.webp"))
	library_view=GrimoireView.new();library_view.preview=true;layer.add_child(library_view);library_view.setup(library_runtime,Rect2(Vector2.ZERO,size),size)
	library_view.acted.connect(func(id: String,pos: Vector2):
		library_runtime.perform(id,pos);sound.cue("place")
		if library_runtime.progress().solved:close_modal()
		else:refresh()
	)
	UI.label(layer,"DRAGEBOGEN  ·  MOS",Rect2(26,24,size.x-108,28),11,UI.GOLD,UI.bold)
	UI.button(layer,"×",Rect2(size.x-68,12,48,44),close_modal,false)
	speak_text(library_view.spread.text)

func map_modal():
	var m=modal_shell("De ti hjemveje",570);var c=m.content;var w=m.width
	UI.image(c,UI.icon("compass"),Rect2(w/2-65,0,130,130))
	UI.label(c,"01 · Den stille lund",Rect2(0,145,w,40),23,UI.GOLD,UI.serif)
	var complete=store.active().chapters.get("chapter_01",{}).get("complete",false)
	UI.label(c,"Mos er hjemme. Du kan blive på farmen eller genbesøge eventyret og opdage den anden vej." if complete else "Et grønt lys peger mod lunden. Nogen har brug for en vej hjem.",Rect2(0,193,w,94),16)
	if store.data.chapters.get("chapter_01",{}).get("complete",false):
		UI.button(c,"Genbesøg kapitel 1",Rect2(0,297,w,50),func():store.start_replay();runtime=StoryRuntime.new(store);screen="story";modal="";runtime.enter();sound.play_music();refresh(),true,true)
	else:
		UI.button(c,"Tilbage til eventyret",Rect2(0,297,w,50),close_modal,true,true)
	UI.label(c,"02 · Fyret uden lys",Rect2(0,370,w,36),20,UI.MUTED,UI.serif)
	UI.label(c,"Hjemvejen er opdaget. Kapitel 2 er endnu ikke udgivet." if complete else "En ny hjemvej viser sig, når Mos er hjemme.",Rect2(0,412,w,65),14,UI.MUTED)
	c.custom_minimum_size.y=490

func house_modal():
	var m=modal_shell("Rodhytten",590);var c=m.content;var w=m.width
	var home=store.active().houses.house_01
	UI.image(c,UI.icon("house"),Rect2(w/2-66,0,132,132))
	UI.label(c,"Døren bliver altid åben. Haven og pynten kan du ændre, når du har lyst.",Rect2(0,146,w,82),16)
	for i in 2:
		var variant=["piledam","moslund"][i]
		UI.button(c,["Piledam","Moslund"][i],Rect2(i*(w+12)/2,242,(w-12)/2,50),func():home.variant=variant;store.active().choices.k01_hjem=variant;store.persist();sound.cue("place");refresh(),home.variant==variant,true)
	UI.label(c,"EN LILLE TING VED DØREN",Rect2(0,317,w,28),11,UI.GOLD,UI.bold)
	for i in 2:
		var ornament=["stone","leaf"][i]
		UI.button(c,["Glat sten","Bladskilt"][i],Rect2(i*(w+12)/2,359,(w-12)/2,48),func():home.decoration.ornament=ornament;store.persist();sound.cue("place");refresh(),home.decoration.get("ornament","")==ornament,true)
	UI.button(c,"Leg med Mos",Rect2(0,429,w,50),enter_garden,true,true)
	c.custom_minimum_size.y=490

func album_modal():
	var m=modal_shell("Kære dagbog: Ikke en kat",630);var c=m.content;var w=m.width
	var album=store.active().flags.get("album_01",{})
	if album.is_empty():
		UI.label(c,"Den første side venter på vores hjemkomst.",Rect2(0,0,w,100),17);return
	var page=runtime.pages[album.photo]
	var photo_h=minf(335,w*1.1);var photo_w=photo_h/1.5
	UI.panel(c,Rect2((w-photo_w)/2-8,0,photo_w+16,photo_h+16),UI.CREAM,5)
	UI.image(c,load("res://assets/chapter_01/"+page.image_id+".webp"),Rect2((w-photo_w)/2,8,photo_w,photo_h))
	UI.image(c,UI.icon("leaf"),Rect2((w-photo_w)/2+float(album.stamp[0])*photo_w-19,20+float(album.stamp[1])*photo_h-19,38,38))
	UI.label(c,page.title,Rect2(0,photo_h+38,w,58),22,UI.GOLD,UI.serif)
	UI.label(c,"Vi fandt en drage. Vi gav ham plads. Og han valgte os.\n\n— Liv",Rect2(0,photo_h+101,w,115),16)
	c.custom_minimum_size.y=photo_h+225

func welcome_modal():
	var m=modal_shell("Et hjem til Mos",570);var c=m.content;var w=m.width
	UI.image(c,UI.icon("mos"),Rect2(w/2-87,-5,174,174))
	UI.label(c,"Den første hjemvej lyser.",Rect2(0,186,w,58),25,UI.GOLD,UI.serif)
	UI.label(c,"Mos er fri. Lunden har fået vand. Og på farmen står en lille hytte med en dør, som ingen låser.\n\nDet her er jeres sted nu.",Rect2(0,252,w,143),17)
	if not store.replay.is_empty():
		UI.button(c,"Behold den nye have og gave",Rect2(0,418,w,48),func():store.end_replay(true);go_farm(),true,true)
		UI.button(c,"Gå hjem til min oprindelige farm",Rect2(0,478,w,48),go_farm,false,true)
		c.custom_minimum_size.y=540
	else:
		UI.button(c,"Bliv lidt på farmen  →",Rect2(0,418,w,52),close_modal,true)
		c.custom_minimum_size.y=480

func arrangements_modal():
	var m=modal_shell("Blomster til Rodhytten",560);var c=m.content;var w=m.width;var model=GardenModel.new(store)
	UI.label(c,"Gem dit bed i en af tre pladser. Det valgte bed blomstrer også hjemme ved Rodhytten.",Rect2(0,0,w,95),16)
	for i in 3:
		var has=model.state().arrangements.size()>i and not model.state().arrangements[i].is_empty()
		UI.button(c,"Gem i bed "+str(i+1),Rect2(0,114+i*68,w*.6,50),func():model.keep(i);sound.cue("success");notify_user("Blomsterne er gemt ved Rodhytten.");refresh(),false,true)
		if has:UI.button(c,"Vis bed",Rect2(w*.64,114+i*68,w*.36,50),func():model.load_arrangement(i);refresh(),false,true)
	UI.button(c,"Prøv et større bed" if model.state().level<2 else "Lav en ny blomstertegning",Rect2(0,337,w,52),func():model.new_bed();modal="";refresh(),true,true)
	UI.button(c,"Tilbage til farmen",Rect2(0,405,w,50),leave_garden,false,true)
	c.custom_minimum_size.y=470

func speak_current():
	if screen=="story":speak_text(narration_text)

func speak_text(text: String):
	if not store.active().settings.narration:return
	if OS.has_feature("web"):
		var result=JavaScriptBridge.eval("window.livSpeak("+JSON.stringify(text)+")",true)
		if not bool(result):notify_user("Der er ingen dansk stemme på denne enhed. Teksten bliver stående, så du kan læse i dit eget tempo.")
	else:
		var voices=DisplayServer.tts_get_voices_for_language("da")
		if voices.is_empty():notify_user("Ingen dansk oplæsningsstemme er tilgængelig på denne enhed.")
		else:DisplayServer.tts_speak(text,voices[0],70,1.0,.9,0,true)

func notify_user(text: String):
	toast=text;toast_time=3.8
	show_toast_label()

func show_toast_label():
	if is_instance_valid(toast_label):toast_label.queue_free()
	var in_scene=(screen=="story" and runtime.ready_for_action()) or screen=="garden"
	var width=text_rect.size.x if in_scene else minf(size.x-28,500)
	toast_label=Label.new()
	var text_height=UI.body.get_multiline_string_size(toast,HORIZONTAL_ALIGNMENT_LEFT,width-36,14).y
	var height=clampf(text_height+24,48,120)
	toast_label.position=Vector2(text_rect.position.x,text_rect.end.y-height) if in_scene else Vector2((size.x-width)/2,70)
	if screen=="farm":toast_label.position.y=maxf(70,size.y-137-height)
	toast_label.size=Vector2(width,height)
	toast_label.text=toast
	toast_label.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_font_override("font",UI.body)
	toast_label.add_theme_font_size_override("font_size",14)
	toast_label.add_theme_color_override("font_color",UI.CREAM)
	toast_label.add_theme_stylebox_override("normal",UI.box(Color(.07,.16,.15,1),13,UI.GOLD))
	toast_label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	toast_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	toast_label.vertical_alignment=VERTICAL_ALIGNMENT_CENTER
	layer.add_child(toast_label)

func _process(delta):
	if is_instance_valid(reveal_label) and reveal_index<reveal_text.length() and modal.is_empty():
		reveal_clock-=delta
		while reveal_clock<=0 and reveal_index<reveal_text.length():
			var character=reveal_text[reveal_index];reveal_index+=1
			reveal_clock+=.024 + (.13 if character in [".","?","!"] else (.055 if character=="," else 0.0))
		reveal_label.visible_characters=reveal_index
		if reveal_index>=reveal_text.length() and is_instance_valid(reveal_button):reveal_button.text=reveal_next_label

	if toast_time>0:
		toast_time-=delta
		if toast_time<=0 and is_instance_valid(toast_label):toast_label.queue_free()
	if OS.has_feature("web"):
		import_check+=delta;qa_timer+=delta
		if import_check>.5:
			import_check=0
			sync_display_scale()
			var imported=JavaScriptBridge.eval("window.livImported || ''",true)
			if imported is String and not imported.is_empty():
				JavaScriptBridge.eval("window.livImported=''",true);finish_import(imported)
		if OS.is_debug_build() and qa_timer>.2:
			qa_timer=0;publish_qa()

func publish_qa():
	# Read-only diagnostics in debug exports; no skip/solve/debug buttons in release.
	var buttons=[]
	for node in layer.find_children("*","Button",true,false):
		if node.is_visible_in_tree():
			var r=node.get_global_rect()
			buttons.append({"text":node.text,"name":node.name,"rect":[r.position.x,r.position.y,r.size.x,r.size.y]})
	var actions=[]
	if puzzle:
		for h in puzzle.hits:actions.append({"id":h.id,"label":h.label,"rect":[h.rect.position.x,h.rect.position.y,h.rect.size.x,h.rect.size.y]})
	if farm_view:
		for h in farm_view.hits:actions.append({"id":h.id,"rect":[h.rect.position.x,h.rect.position.y,h.rect.size.x,h.rect.size.y]})
	if library_view:
		actions=[]
		for h in library_view.hits:actions.append({"id":h.id,"label":h.label,"rect":[h.rect.position.x,h.rect.position.y,h.rect.size.x,h.rect.size.y]})
	var view_data={}
	if puzzle is AdventureView:
		view_data={"age":puzzle.age,"reveal_until":puzzle.reveal_until,"marker":puzzle.marker(),"aim":[puzzle.aim_position().x,puzzle.aim_position().y],"map":[puzzle.map_rect.position.x,puzzle.map_rect.position.y,puzzle.map_rect.size.x,puzzle.map_rect.size.y],"lens":puzzle.lens_on}
	elif puzzle is GrimoireView:view_data={"word":puzzle.word_index,"flowing":puzzle.flowing}
	var payload={"view":view_data,"screen":screen,"modal":modal,"node":store.active().current_node,"progress":runtime.progress(),"buttons":buttons,"actions":actions,"size":[size.x,size.y],"portrait":portrait,"state":store.active(),"kind":runtime.config().kind,"typing":reveal_index<reveal_text.length(),"text_rect":[text_rect.position.x,text_rect.position.y,text_rect.size.x,text_rect.size.y],"play_rect":[play_rect.position.x,play_rect.position.y,play_rect.size.x,play_rect.size.y]}
	if library_view:payload.library={"word":library_view.word_index,"spread":library_runtime.stage_progress().done.size()}
	JavaScriptBridge.eval("window.__livQA="+JSON.stringify(payload),true)

func _unhandled_key_input(event):
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
		if not modal.is_empty():close_modal()
		else:open_modal("settings")

func _input(event):
	if world and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		world.touch(event.position)
