class_name AdventureGame
extends RefCounted
## Deterministic rules, separate from animation and pointer handling.
const KINDS=["keymatch","jigsaw","riddle","truth","potion","runes","lock","elements","aim","runner","stealth","memory_map","balance","labyrinth","search","book","packing","journey"]
const DIRECTIONS={"up":Vector2i(0,-1),"right":Vector2i(1,0),"down":Vector2i(0,1),"left":Vector2i(-1,0)}
const RUN_STARS=[[2.0,0],[5.0,2],[8.0,1],[11.0,0],[14.0,2]]
const RUN_ROOTS=[[3.5,1],[6.5,0],[9.5,2],[12.5,1]]

static func initial() -> Dictionary:
	return {"round":0,"index":0,"elapsed":0.0,"meter":0.0,"lane":1,"cell":0,"mistakes":0,"wrong":[],"held":false,"steps":[],"stars":[]}

static func result(changed: bool=false, feedback: String="") -> Dictionary:
	return {"changed":changed,"feedback":feedback}

static func apply(c: Dictionary, p: Dictionary, id: String, pos: Vector2, choices: Dictionary) -> Dictionary:
	for key in initial():
		if not p.has(key):p[key]=initial()[key]
	match c.kind:
		"keymatch":
			if id=="reset_keys" and int(p.get("attempts",0))>=3:
				p.attempts=0;p.wrong=[];p.selected="";p.round+=1;return result(true,"Stjernerne vågner igen. Sammenlign de fire tænder fra venstre — nu har du tre nye forsøg.")
			if int(p.get("attempts",0))>=3:return result(false,"Tre forsøg er brugt. Undersøg låsen igen, før du prøver flere nøgler.")
			for key in c.items:
				if id==key.id and not id in p.wrong:p.selected=id;return result(true)
			if id=="test_key" and not p.selected.is_empty():
				p.attempts=int(p.get("attempts",0))+1
				if p.selected==c.answer:p.done=[p.selected];return result(true,"Nøglen glider ind! Nu skal de tre stifter drejes i takt med lyset.")
				p.wrong.append(p.selected);p.selected=""
				return result(true,"Den passer ikke. "+str(3-p.attempts)+" forsøg tilbage." if p.attempts<3 else "Låsens stjerner slukkes. Noor: Lad den hvile, mens vi undersøger rillerne igen.")
		"book":
			if id=="turn":p.done.append("page_"+str(p.done.size()));p.book_word=0;return result(true)
		"journey":
			if id=="depart":p.done=["ready"];return result(true)
		"packing":
			if not p.has("bag"):p.bag={};p.turn=0
			if id=="unpack":p.bag={};p.done=[];p.selected="";return result(true)
			if id=="turn":p.turn=(int(p.turn)+1)%2;return result(true)
			for thing in c.items:
				if thing.id==id:
					p.selected=id;p.turn=0
					if p.bag.has(id):p.bag.erase(id);p.done.erase(id)
					return result(true)
			if id.begins_with("cell_") and id.substr(5).is_valid_int() and not p.selected.is_empty():
				var cell=int(id.substr(5));var x=cell%4;var y=int(cell/4)
				var shape=packing_shape(c,p.selected,int(p.turn))
				if x<0 or y<0 or x+shape.x>4 or y+shape.y>4:return result(false,"Den stikker ud af tasken. Prøv at dreje den.")
				var target=Rect2i(x,y,shape.x,shape.y)
				for key in p.bag:
					var old=p.bag[key];var dimensions=packing_shape(c,key,int(old.turn))
					if target.intersects(Rect2i(int(old.x),int(old.y),dimensions.x,dimensions.y)):return result(false,"Der ligger allerede noget. Flyt det, eller find et andet rum.")
				p.bag[p.selected]={"x":x,"y":y,"turn":p.turn};p.done.append(p.selected);p.selected="";return result(true)
		"search":
			for clue in c.items:
				if clue.id==id and not id in p.done:
					p.done.append(id);return result(true,clue.label)
		"jigsaw":
			if id.begins_with("piece_") and id.substr(6).is_valid_int():
				if int(id.substr(6)) in range(6) and not id in p.done:p.selected=id;return result(true)
			if id.begins_with("slot_") and not p.selected.is_empty():
				if p.selected.substr(6)==id.substr(5):
					p.done.append(p.selected);p.placed[p.selected]=[pos.x,pos.y];p.selected="";return result(true)
				return result(false,"Se på stien og billedets kanter. Den brik hører til et andet sted.")
		"riddle","truth":
			for card in c.items:
				if card.id==id:
					if id==c.answer:p.done=[id]
					else:
						if not id in p.wrong:p.wrong.append(id)
						p.mistakes+=1
					return result(true,card.get("response","Prøv at tænke på sporene igen."))
		"potion":
			var expected=c.recipe[mini(p.done.size(),c.recipe.size()-1)]
			if id in ["dew","flower","bottle"]:
				p.selected=id;return result(true)
			if id in ["cauldron","stir"]:
				var ingredient="stir" if expected=="stir" else p.selected
				if ingredient.is_empty():return result(false,"Vælg en ingrediens og træk den hen i gryden.")
				if ingredient!=expected:
					p.selected="";p.mistakes+=1;return result(true,"Gryden bobler lilla. Se på opskriften — den venter på noget andet.")
				p.done.append("step_"+str(p.done.size()));p.selected="";return result(true)
		"runes":
			var sequence=c.sequences[mini(int(p.round),c.sequences.size()-1)]
			if not id in ["leaf","moon","fire","water"]:return result()
			if id!=sequence[int(p.index)]:
				p.index=0;p.mistakes+=1;return result(true,"Runerne hvisker: Prøv melodien igen. Du kan altid lytte én gang til.")
			p.index+=1
			if int(p.index)==sequence.size():
				p.done.append("melody_"+str(p.round));p.round+=1;p.index=0
			return result(true)
		"lock","balance":
			if id!="stop":return result()
			var tolerance=.16 if c.kind=="lock" else .13
			if absf(pos.x-.5)>tolerance:
				p.mistakes+=1;return result(true,"Næsten! Vent til lyset er inde i det gyldne felt.")
			p.done.append("lock_"+str(p.done.size()));return result(true)
		"aim":
			if id!="send":return result()
			if pos.distance_to(Vector2(.5,.5))>.17:
				p.mistakes+=1;return result(true,"Lyset kredser tilbage. Send det, når det er inde i blomstens ring.")
			p.done.append("light_"+str(p.done.size()));return result(true)
		"elements":
			if not id in ["water","fire","stone"]:return result()
			var other=c.opponents[mini(p.done.size(),c.opponents.size()-1)]
			var answer={"fire":"water","water":"stone","stone":"fire"}[other]
			if id!=answer:
				p.mistakes+=1;return result(true,{"fire":"Mos: Vandet kan dæmpe den flamme.","water":"Mos: Jorden kan samle vandet.","stone":"Mos: Ilden kan løsne den hårde jord."}[other])
			p.done.append("balance_"+str(p.done.size()));return result(true)
		"labyrinth":
			var current=int(p.cell);var goal=-1;var width=int(c.maze.width)
			if id in DIRECTIONS:
				var at=Vector2i(current%width,current/width)+DIRECTIONS[id]
				if at.x>=0 and at.x<width and at.y>=0 and at.y<int(c.maze.height):goal=at.y*width+at.x
			elif id.begins_with("node_") and id.substr(5).is_valid_int():goal=int(id.substr(5))
			for edge in c.maze.edges:
				if (int(edge[0])==current and int(edge[1])==goal) or (int(edge[1])==current and int(edge[0])==goal):
					p.cell=goal;p.steps.append(goal);return result(true)
			return result(false,"En rod spærrer her. Find en åbning i væggen.")
		"memory_map":
			if not id in DIRECTIONS:return result()
			var expected=c.route[mini(p.steps.size(),c.route.size()-1)]
			if id!=expected:
				p.mistakes+=1;return result(true,"Tågen er tæt her. Lyset bliver stående. Se kortet igen, hvis du vil.")
			p.steps.append(id);return result(true)
		"runner":
			if id.begins_with("lane_") and id.substr(5).is_valid_int():
				p.lane=clampi(int(id.substr(5)),0,2);return result(true)
			if id!="tick" or pos.x<=0 or pos.x>.65:return result()
			var before=float(p.elapsed);p.elapsed+=pos.x
			for root in RUN_ROOTS:
				if before<root[0] and p.elapsed>=root[0] and int(p.lane)==root[1]:
					p.elapsed=maxf(0,root[0]-1.3);p.mistakes+=1
					return result(true,"En rod på stien! Skift spor — ildfluerne venter på dig.")
			for i in RUN_STARS.size():
				var star=RUN_STARS[i]
				if before<star[0] and p.elapsed>=star[0] and int(p.lane)==star[1] and not i in p.stars:p.stars.append(i)
			if p.elapsed>=float(c.duration) and p.stars.size()<3:
				p.elapsed=0;return result(true,"Find tre ildfluer. Dem, du allerede fandt, lyser stadig for dig.")
			return result(true)
		"stealth":
			if id in ["hold","release"]:p.held=id=="hold";return result(true)
			if id!="tick" or pos.x<=0 or pos.x>.4:return result()
			p.elapsed+=pos.x
			var phase=fposmod(p.elapsed,5.2)/5.2
			if p.held:
				if phase<.62:p.meter=minf(1,p.meter+pos.x*.14)
				elif phase>.78:
					p.meter=maxf(0,p.meter-.15);p.held=false;p.mistakes+=1
					return result(true,"Vogteren åbner øjet! Slip nøglen, og vent på den næste snorken.")
			return result(true)
	return result()

static func complete(c: Dictionary,p: Dictionary) -> bool:
	match c.kind:
		"keymatch":return c.answer in p.done
		"book":return p.done.size()>=c.spreads.size()
		"packing":return p.done.size()==c.items.size()
		"journey":return not p.done.is_empty()
		"search":return p.done.size()==c.items.size()
		"jigsaw":return p.done.size()==6
		"riddle","truth":return c.answer in p.done
		"potion":return p.done.size()==c.recipe.size()
		"runes":return p.done.size()==c.sequences.size()
		"lock","balance","aim":return p.done.size()>=int(c.goal)
		"elements":return p.done.size()==c.opponents.size()
		"labyrinth":return int(p.get("cell",0))==int(c.maze.goal)
		"memory_map":return p.get("steps",[]).size()==c.route.size()
		"runner":return p.get("elapsed",0)>=c.duration and p.get("stars",[]).size()>=3
		"stealth":return p.get("meter",0)>=1
	return false

static func hint_step(c: Dictionary,p: Dictionary) -> Dictionary:
	match c.kind:
		"keymatch":
			if int(p.get("attempts",0))>=3:return {"id":"reset_keys"}
			return {"id":"test_key" if p.selected==c.answer else c.answer}
		"book":return {"id":"turn"}
		"journey":return {"id":"depart"}
		"packing":
			var places={"book":0,"spoon":3,"lantern":2,"rope":8,"bottle":10,"lens":12}
			# The hint clears only a conflicting layout, never the story's inventory.
			for key in p.get("bag",{}):
				var old=p.bag[key]
				if int(old.y)*4+int(old.x)!=places[key] or int(old.turn)!=0:return {"id":"unpack"}
			if not p.selected.is_empty():return {"id":"turn" if int(p.get("turn",0))!=0 else "cell_"+str(places[p.selected])}
			for thing in c.items:
				if not thing.id in p.done:return {"id":thing.id}
		"riddle","truth":return {"id":c.answer}
		"potion":return {"id":"cauldron" if p.get("selected","")!="" or c.recipe[p.done.size()]=="stir" else c.recipe[p.done.size()]}
		"jigsaw":
			if not p.selected.is_empty():return {"id":"slot_"+p.selected.substr(6),"pos":Vector2(.5,.5)}
			for i in 6:
				if not "piece_"+str(i) in p.done:return {"id":"piece_"+str(i)}
		"runes":return {"id":c.sequences[int(p.get("round",0))][int(p.get("index",0))]}
		"lock","balance":return {"id":"stop","pos":Vector2(.5,.5)}
		"aim":return {"id":"send","pos":Vector2(.5,.5)}
		"elements":return {"id":{"fire":"water","water":"stone","stone":"fire"}[c.opponents[p.done.size()]]}
		"memory_map":return {"id":c.route[p.get("steps",[]).size()]}
		"search":
			for clue in c.items:
				if not clue.id in p.done:return {"id":clue.id}
		"labyrinth":
			var queue=[[int(p.get("cell",0))]];var seen=[int(p.get("cell",0))]
			while not queue.is_empty():
				var path=queue.pop_front();var at=path.back()
				if at==int(c.maze.goal):return {"id":"node_"+str(path[1])}
				for edge in c.maze.edges:
					var nxt=int(edge[1]) if int(edge[0])==at else (int(edge[0]) if int(edge[1])==at else -1)
					if nxt>=0 and not nxt in seen:seen.append(nxt);queue.append(path+[nxt])
		"runner":
			var at=float(p.get("elapsed",0));var lane=int(p.get("lane",1));var target=lane
			for star in RUN_STARS:
				if star[0]>at and star[0]<=at+.6:target=star[1]
			for root in RUN_ROOTS:
				if root[0]>at and root[0]<=at+.6 and target==root[1]:target=(target+1)%3
			if lane!=target:return {"id":"lane_"+str(target)}
			return {"id":"tick","pos":Vector2(.5,0)}
		"stealth":
			var phase=fposmod(float(p.get("elapsed",0))+.25,5.2)/5.2
			var hold=phase<.62
			if hold!=p.get("held",false):return {"id":"hold" if hold else "release"}
			return {"id":"tick","pos":Vector2(.25,0)}
	return {}

static func packing_shape(c: Dictionary,id: String,turn: int) -> Vector2i:
	for thing in c.items:
		if thing.id==id:return Vector2i(thing.shape[turn%2],thing.shape[1-turn%2])
	return Vector2i.ONE
