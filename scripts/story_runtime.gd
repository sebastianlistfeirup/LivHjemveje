class_name StoryRuntime
extends RefCounted

const CONTENT = "res://content/runtime/chapter_01.json"
const KINDS = ["inspect", "sequence", "place", "rotate", "pipes", "choice", "maze", "wipe", "difference", "decorate", "album"]
var store: SaveStore
var source: Dictionary
var pages: Dictionary = {}
var feedback = ""
var changed = false

func _init(save: SaveStore):
	store = save
	source = JSON.parse_string(FileAccess.get_file_as_string(CONTENT))
	for page in source.chapter.pages:
		pages[page.id] = page
		for config in page.runtime.stages:
			assert(config.kind in KINDS, "Unknown interaction: " + config.kind)

func state() -> Dictionary:
	return store.active()

func page() -> Dictionary:
	return pages[state().current_node]

func progress() -> Dictionary:
	var s = state()
	var id = s.current_node
	if not s.node_progress.has(id):
		s.node_progress[id] = {"stage": 0, "stages": {}, "read": 0, "solved": false, "hint": 0}
	return s.node_progress[id]

func config() -> Dictionary:
	var index = mini(int(progress().stage), page().runtime.stages.size() - 1)
	return page().runtime.stages[index]

func stage_progress() -> Dictionary:
	var p = progress()
	var index = str(int(p.stage))
	if not p.stages.has(index):
		p.stages[index] = {"done": [], "selected": "", "placed": {}, "rotations": config().get("initial", []).duplicate(), "position": "I", "trail": ["I"]}
	return p.stages[index]

func enter() -> void:
	var s = state()
	s.started = true
	if not s.current_node in s.visited:
		s.visited.append(s.current_node)
	progress()
	store.persist()

func read_next() -> void:
	progress().read = mini(int(progress().read) + 1, page().dialogue.size() + 1)
	store.persist()

func ready_for_action() -> bool:
	return int(progress().read) > page().dialogue.size() and not progress().solved

func perform(id: String, pos: Vector2 = Vector2(-1, -1)) -> bool:
	feedback = ""
	changed = false
	if not ready_for_action():
		return false
	var c = config()
	var p = stage_progress()
	var item: Dictionary = {}
	for candidate in c.items + c.targets:
		if candidate.id == id:
			item = candidate
			break
	if item.get("decoy", false):
		feedback = item.label
		return false
	match c.kind:
		"inspect", "wipe":
			if item.is_empty() or id in p.done:
				return false
			p.done.append(id)
			feedback = item.label
			changed = true
		"sequence":
			var index = p.done.size()
			if index >= c.items.size() or c.items[index].id != id:
				feedback = "Følg det lysende spor. Vi tager ét skridt ad gangen."
				return false
			p.done.append(id)
			changed = true
		"place":
			if item.is_empty() or id in p.done:
				return false
			if item.has("target"):
				p.selected = id
				feedback = item.label + " er valgt. Tryk på stedet, hvor den skal hen."
				store.persist()
				return false
			var chosen = find_item(p.selected)
			if chosen.is_empty():
				feedback = "Vælg først den ting, du vil flytte."
				return false
			if chosen.target != id:
				feedback = "Den passer ikke helt her. Prøv et andet sted."
				return false
			if chosen.has("requires") and not chosen.requires in p.done:
				feedback = "Der mangler noget nedenunder. Byg fra bunden."
				return false
			p.done.append(chosen.id)
			p.placed[chosen.id] = item.pos
			p.selected = ""
			changed = true
		"rotate", "pipes":
			var index = -1
			for i in c.items.size():
				if c.items[i].id == id:
					index = i
			if index < 0:
				return false
			p.rotations[index] = (int(p.rotations[index]) + 1) % 4
			changed = true
		"choice":
			if item.is_empty():
				return false
			state().choices[c.key] = id
			p.done = [id]
			changed = true
			if c.key == "samtaletone":
				feedback = "Mos løfter øret og lytter." if id == "ask" else "Mos slapper af, mens I venter sammen."
		"maze":
			if not source.maze.nodes.has(id):
				return false
			var connected = false
			for edge in source.maze.edges:
				if (edge[0] == p.position and edge[1] == id) or (edge[1] == p.position and edge[0] == id):
					connected = true
			if not connected:
				feedback = "Her er ingen åben rodsti. Lyset bliver på den sikre sten."
				return false
			p.position = id
			p.trail.append(id)
			changed = true
		"difference":
			var found = false
			for difference in page().puzzle_spec.targets:
				if difference.id == id:
					found = true
					feedback = difference.label.capitalize()
			if not found or id in p.done:
				return false
			p.done.append(id)
			changed = true
		"decorate":
			if not item.is_empty() and not id in p.done:
				p.selected = id
				store.persist()
				return false
			if id != "zone" or p.selected.is_empty():
				return false
			var z = c.zone
			if not Rect2(z[0], z[1], z[2], z[3]).has_point(pos):
				feedback = "Læg den inden for den bløde ramme."
				return false
			p.placed[p.selected] = [pos.x, pos.y]
			p.done.append(p.selected)
			p.selected = ""
			changed = true
		"album":
			if not id in ["K01_S01", "K01_S17", "K01_S32"] or not id in state().visited:
				return false
			state().flags.album_photo = id
			p.done = [id]
			changed = true
		_:
			push_error("Unmapped controller: " + c.kind)
			return false
	if changed:
		if stage_complete():
			finish_stage()
		store.persist()
	return changed

func find_item(id: String) -> Dictionary:
	for item in config().items:
		if item.id == id:
			return item
	return {}

func stage_complete() -> bool:
	var c = config()
	var p = stage_progress()
	match c.kind:
		"rotate", "pipes":
			for i in c.goal.size():
				if int(p.rotations[i]) != int(c.goal[i]): return false
			return true
		"choice", "album":
			return p.done.size() == 1
		"maze":
			return p.position == source.maze.goal
		"difference":
			return p.done.size() == 5
		_:
			var count = 0
			for item in c.items:
				if not item.get("decoy", false):
					count += 1
			return p.done.size() >= count

func finish_stage() -> void:
	var p = progress()
	if int(p.stage) + 1 < page().runtime.stages.size():
		p.stage = int(p.stage) + 1
	else:
		p.solved = true
		commit_page()

func add_unique(key: String, value: String) -> void:
	if not value in state()[key]:
		state()[key].append(value)

func commit_page() -> void:
	var s = state()
	var n = int(page().page)
	s.flags[page().id] = true
	match n:
		1: add_unique("inventory", "compass")
		3:
			for item in ["rope", "spoon", "lantern"]: add_unique("inventory", item)
		5: s.flags.arrival_frozen = true
		6: add_unique("journal", "vaadt_blad")
		10: add_unique("inventory", "vindblad")
		12: add_unique("inventory", "dugkop")
		17: s.flags.forstaa_drager = true
		18: s.flags.behov = "vinge_fri"
		19: add_unique("inventory", "hook")
		20:
			add_unique("journal", "maerke_01")
			add_unique("journal", "blaa_kridt")
		26: s.flags.stoettebygget = true
		27: s.flags.froe_set = true
		28: s.flags.froe_reddet = 2
		29: s.flags.froe_reddet = 3
		31: s.flags.ven_med_mos = true
		32:
			s.dragons.dragon_01 = {"rescued": true}
			s.flags.mos_reddet = true
			s.flags.hjemvej_01 = true
			add_unique("journal", "hjemvej_01")
		34: add_unique("journal", "iben_naevnt")
		35:
			s.houses.house_01 = {"built": true, "variant": s.choices.k01_hjem, "position": [0.18,0.30], "decoration": [], "gift": "", "rescue": s.choices.k01_redning, "flowers": {}}
			s.flags.hus_01_bygget = true
		36:
			s.houses.house_01.decoration = {"cushions": progress().stages["0"].placed.duplicate(true), "ornament": s.choices.decoration}
		37:
			s.flags.bed_01 = true
			s.flags.naturpust = true
		38:
			s.houses.house_01.gift = "vindblad" if s.choices.k01_rute == "A" else "dugkop"
		39:
			s.flags.album_01 = {"photo": s.flags.album_photo, "stamp": progress().stages["1"].placed.stamp}
		40:
			s.chapters.chapter_01 = {"complete": true}
			s.chapters.chapter_02 = {"unlocked": true, "available": false}
			add_unique("journal", "gnist_02")

func next_page() -> bool:
	if not progress().solved:
		return false
	var next = page().next
	var dest = next.get("success", "")
	if dest.is_empty():
		var key = "k01_rute" if int(page().page) == 8 else "k01_redning"
		dest = next[state().choices[key]]
	if dest == "FARM_FREE":
		state().mode = "FARM_FREE"
	else:
		state().current_node = dest
		enter()
	store.persist()
	return true

func demonstrate() -> bool:
	var c = config()
	var p = stage_progress()
	match c.kind:
		"choice", "album":
			feedback = "Det er dit valg. Begge muligheder giver plads til historien."
			return false
		"rotate", "pipes":
			for i in c.items.size():
				var wrong = int(p.rotations[i]) != int(c.goal[i])
				if wrong:
					return perform(c.items[i].id)
		"maze":
			# Breadth-first search from the actual current node, including dead ends.
			var queue = [[p.position]]
			var visited = [p.position]
			while not queue.is_empty():
				var path = queue.pop_front()
				var at = path.back()
				if at == source.maze.goal:
					return perform(path[1]) if path.size() > 1 else false
				for edge in source.maze.edges:
					var neighbor = edge[1] if edge[0] == at else (edge[0] if edge[1] == at else "")
					if neighbor != "" and not neighbor in visited:
						visited.append(neighbor)
						queue.append(path + [neighbor])
		"difference":
			for target in page().puzzle_spec.targets:
				if not target.id in p.done: return perform(target.id)
		"place":
			for item in c.items:
				if not item.get("decoy", false) and not item.id in p.done and (not item.has("requires") or item.requires in p.done):
					perform(item.id)
					return perform(item.target)
		"decorate":
			for item in c.items:
				if not item.id in p.done:
					perform(item.id)
					return perform("zone", Vector2(0.3 + p.done.size() * 0.18, 0.4))
		_:
			for item in c.items:
				if not item.get("decoy", false) and not item.id in p.done:
					return perform(item.id)
	return false
