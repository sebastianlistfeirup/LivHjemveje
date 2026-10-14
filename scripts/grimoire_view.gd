class_name GrimoireView
extends PuzzleView

var words: PackedStringArray=[]
var word_lines=[]
var word_index=0
var word_clock=0.0
var age=0.0
var flowing=true
var preview=false
var ink: RichTextLabel
var picture: TextureRect
var read_button: Button
var spread: Dictionary
var illustration_rect=Rect2()

func setup(rt: StoryRuntime,rect: Rect2,canvas_size: Vector2):
	runtime=rt;board=rect;art_rect=rect;size=canvas_size;reduced=rt.state().settings.reduced_motion
	spread=rt.config().spreads[mini(rt.stage_progress().done.size(),rt.config().spreads.size()-1)]
	var portrait=size.y>=size.x
	var short=size.y<500
	var title_rect: Rect2
	var body_rect: Rect2
	var facts_rect: Rect2
	var footer: Rect2
	if portrait:
		title_rect=Rect2(30,86,size.x-60,65)
		illustration_rect=Rect2(size.x*.5-47,144,94,94)
		facts_rect=Rect2(34,239,size.x-68,73)
		body_rect=Rect2(32,316,size.x-64,maxf(80,size.y*.70-316))
		footer=Rect2(22,size.y-64,size.x-44,48)
		if size.y<700:
			title_rect.position.y=76;illustration_rect=Rect2(size.x*.5-36,134,72,72);facts_rect.position.y=207;body_rect.position.y=284;body_rect.size.y=maxf(80,size.y*.70-284)
	else:
		title_rect=Rect2(size.x*.19,78 if short else size.y*.19,size.x*.28,54)
		illustration_rect=Rect2(size.x*.225,title_rect.end.y+8,size.x*.20,minf(size.y*.24,240))
		facts_rect=Rect2(size.x*.18,illustration_rect.end.y+5,size.x*.30,maxf(50,size.y*.18))
		body_rect=Rect2(size.x*.535,78 if short else size.y*.18,size.x*.29,size.y*.57 if not short else size.y-175)
		footer=Rect2(size.x*.53,size.y-65 if short else size.y*.80,size.x*.31,48)
		if size.y<350:
			title_rect=Rect2(size.x*.19,68,size.x*.28,52)
			illustration_rect=Rect2(size.x*.325-21,125,42,42)
			facts_rect=Rect2(size.x*.18,170,size.x*.30,78)
			body_rect=Rect2(size.x*.535,72,size.x*.29,size.y-150)
	UI.label(self,spread.subtitle,title_rect,9,Color("70552e"),UI.bold)
	UI.label(self,spread.title,Rect2(title_rect.position+Vector2(0,20),Vector2(title_rect.size.x,55)),14 if size.y<350 else (18 if short or portrait else 26),Color("3b301e"),UI.serif)
	var frame=4 if spread.image=="breath" else (1 if spread.image=="moon" else 0)
	picture=UI.image(self,UI.dragon(frame),illustration_rect)
	for i in spread.facts.size():
		var fact_size=10 if short else 11
		while fact_size>9 and UI.bold.get_string_size(spread.facts[i],HORIZONTAL_ALIGNMENT_LEFT,-1,fact_size).x>facts_rect.size.x:fact_size-=1
		var fact_step=26 if size.y<350 else 24
		var fact=RichTextLabel.new()
		fact.position=facts_rect.position+Vector2(0,i*fact_step);fact.size=Vector2(facts_rect.size.x,fact_step)
		fact.text=spread.facts[i];fact.scroll_active=false;fact.mouse_filter=Control.MOUSE_FILTER_IGNORE
		fact.add_theme_font_override("normal_font",UI.bold);fact.add_theme_font_size_override("normal_font_size",fact_size)
		fact.add_theme_color_override("default_color",Color("594629"));fact.add_theme_constant_override("line_separation",0)
		add_child(fact)
	ink=RichTextLabel.new();ink.position=body_rect.position;ink.size=body_rect.size;ink.bbcode_enabled=true;ink.scroll_active=true;ink.mouse_filter=Control.MOUSE_FILTER_STOP
	ink.add_theme_font_override("normal_font",UI.serif);ink.add_theme_font_size_override("normal_font_size",int((15 if short else 17)*rt.state().settings.text_scale));ink.add_theme_color_override("default_color",Color("43331f"));ink.add_theme_constant_override("line_separation",5)
	add_child(ink);UI.quiet_scroll(ink.get_v_scroll_bar())
	words=spread.text.split(" ");measure_word_lines(body_rect.size.x-12,int((15 if short else 17)*rt.state().settings.text_scale))
	word_index=clampi(int(rt.stage_progress().get("book_word",0)),0,words.size())
	flowing=not reduced and word_index<words.size();set_words()
	read_button=UI.button(self,"Pause" if flowing else "Læs",Rect2(footer.position,Vector2(footer.size.x*.30,48)),toggle_reading,false,true)
	UI.button(self,"↺",Rect2(footer.position+Vector2(footer.size.x*.30+6,0),Vector2(48,48)),func():word_index=0;word_clock=0;flowing=true;read_button.text="Pause";ink.scroll_to_line(0);set_words(),false,true)
	var x=footer.position.x+footer.size.x*.30+60
	var rect_next=Rect2(x,footer.position.y,footer.end.x-x,48)
	var next_label=("Luk bogen →" if preview else "Pak tasken →") if rt.stage_progress().done.size()==2 else "Næste →"
	if rect_next.size.x<110:next_label="→"
	UI.button(self,next_label,rect_next,func():acted.emit("turn",Vector2(.5,.5)),true,true)
	hits=[{"id":"turn","label":"Næste blad","rect":rect_next}]
	if is_inside_tree():call_deferred("follow_word")
	if not reduced and is_inside_tree():
		modulate.a=0;var tween=create_tween();tween.tween_property(self,"modulate:a",1.0,.55)

func toggle_reading():
	if word_index>=words.size():word_index=0;ink.scroll_to_line(0)
	flowing=not flowing;read_button.text="Pause" if flowing else "Læs";set_words()

func measure_word_lines(width: float,font_size: int):
	var line=0;var used=0.0
	for word in words:
		var length=UI.serif.get_string_size(word+" ",HORIZONTAL_ALIGNMENT_LEFT,-1,font_size).x
		if used+length>width and used>0:line+=1;used=0
		word_lines.append(line);used+=length

func follow_word():
	if word_lines.is_empty():return
	var visible_lines=maxi(3,int(ink.size.y/((15 if size.y<500 else 17)*runtime.state().settings.text_scale+10)))
	ink.scroll_to_line(maxi(0,word_lines[mini(word_index,word_lines.size()-1)]-visible_lines+2))

func set_words():
	var text=""
	for i in words.size():
		if i==word_index and flowing:text+="[bgcolor=#e2bd6c][color=#68401b]"+words[i]+"[/color][/bgcolor] "
		elif i<word_index:text+="[color=#755027]"+words[i]+"[/color] "
		else:text+=words[i]+" "
	ink.text=text

func _process(delta):
	if not runtime:return
	var host=get_parent().get_parent() if get_parent() else null
	if host and host.get("modal")!=null and not host.modal.is_empty() and not (preview and host.modal=="dragon_book"):return
	if not reduced:
		age+=minf(delta,.08)
		if picture:picture.position.y=illustration_rect.position.y+sin(age*.85)*1.5
	if flowing:
		word_clock+=delta
		if word_clock>.36:
			word_clock=0;word_index+=1
			runtime.stage_progress().book_word=word_index
			if word_index%8==0:runtime.store.persist()
			if word_index>=words.size():word_index=words.size();flowing=false;read_button.text="Læs"
			else:
				if word_index==0 or word_lines[word_index]!=word_lines[word_index-1]:follow_word()
			set_words()

func _has_point(_point: Vector2) -> bool:return false
func _draw():pass
