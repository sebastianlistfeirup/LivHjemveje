class_name SaveStore
extends RefCounted
## Every physical subgoal is committed before its visual response.
const VERSION = 1
const PATH = "user://liv-save.json"
var data: Dictionary
var replay: Dictionary = {}
var last_error = ""
var memory_only = false
static var scene_rules: Dictionary = {}

static func fresh() -> Dictionary:
	return {"save_version": VERSION, "mode": "STORY", "current_node": "K01_S01", "started": false,
		"choices": {}, "node_progress": {}, "inventory": [], "journal": [], "flags": {},
		"dragons": {}, "houses": {}, "chapters": {}, "minigames": {"G01": {"level": 0, "plots": {}, "pipes": [1,2,3], "grown": false, "arrangements": []}},
		"settings": {"text_scale": 1.0, "reduced_motion": false, "music": true, "effects": true, "vibration": false, "narration": false}, "visited": []}

func _init(in_memory: bool = false):
	memory_only = in_memory
	data = fresh()
	if not memory_only:
		load_save()

func active() -> Dictionary:
	return replay if not replay.is_empty() else data

static func valid_state(value: Variant) -> bool:
	if scene_rules.is_empty():
		var source=JSON.parse_string(FileAccess.get_file_as_string("res://content/runtime/chapter_01.json"))
		for page in source.chapter.pages:scene_rules[page.id]=page.runtime.stages
	if not value is Dictionary or value.get("save_version") != VERSION:
		return false
	for key in ["choices", "node_progress", "flags", "dragons", "houses", "chapters", "minigames", "settings"]:
		if not value.get(key) is Dictionary:
			return false
	for key in ["inventory", "journal", "visited"]:
		if not value.get(key) is Array:
			return false
	if not value.get("current_node") is String or not value.get("mode") in ["STORY", "FARM_FREE", "MINIGAME"]:
		return false
	var node = value.current_node
	if not valid_node(node):
		return false
	if not value.get("started") is bool:
		return false
	for id in value.visited:
		if not valid_node(id): return false
	if not value.settings.get("text_scale") in [1.0, 1.25, 1.5]:
		return false
	for key in ["music", "effects", "reduced_motion", "vibration", "narration"]:
		if not value.settings.get(key) is bool:
			return false
	for key in ["k01_rute", "k01_redning"]:
		if value.choices.has(key) and not value.choices[key] in ["A", "B"]:
			return false
	for id in value.node_progress:
		if not valid_node(id): return false
		var progress = value.node_progress[id]
		if not progress is Dictionary or not progress.get("stages", {}) is Dictionary:
			return false
		if not whole_number(progress.get("stage"), 0, 2) or not whole_number(progress.get("read"), 0, 3):
			return false
		if not progress.get("solved") is bool or not whole_number(progress.get("hint"), 0, 3):
			return false
		if int(progress.stage)>=scene_rules[id].size(): return false
		if progress.solved and (not value.flags.get(id) is bool or not value.flags[id]): return false
		for key in progress.stages:
			if not key in ["0", "1", "2"]: return false
			if int(key)>=scene_rules[id].size(): return false
			var config=scene_rules[id][int(key)]
			var stage = progress.stages[key]
			if not stage is Dictionary or not stage.get("done", []) is Array or not stage.get("placed", {}) is Dictionary:
				return false
			if not stage.get("selected") is String or not stage.get("position") in ["A","B","C","D","E","F","G","H","I","J","K","L"]:
				return false
			if not stage.get("rotations") is Array or stage.rotations.size() > 3 or not stage.get("trail") is Array:
				return false
			if stage.rotations.size()!=config.get("initial",[]).size():return false
			for rotation in stage.rotations:
				if not whole_number(rotation, 0, 3): return false
			for done in stage.done:
				if not done is String: return false
			for pos in stage.placed.values():
				if not normalized_pair(pos): return false
	var game = value.minigames.get("G01")
	if not game is Dictionary or not whole_number(game.get("level"), 0, 2) or not game.get("grown") is bool:
		return false
	if not game.get("plots") is Dictionary or not game.get("pipes") is Array or game.pipes.size() != 3:
		return false
	for pipe in game.pipes:
		if not whole_number(pipe, 0, 3): return false
	for cell in game.plots:
		if not cell is String or not cell.is_valid_int() or int(cell) < 0 or int(cell) > 15 or not whole_number(game.plots[cell], 0, 2): return false
	if not game.get("arrangements") is Array or game.arrangements.size() > 3: return false
	for arrangement in game.arrangements:
		if not arrangement is Dictionary: return false
		if not arrangement.is_empty():
			if not arrangement.get("plots") is Dictionary or not whole_number(arrangement.get("level"), 0, 2): return false
			for flower in arrangement.plots.values():
				if not whole_number(flower, 0, 2): return false
	if value.houses.has("house_01"):
		var house = value.houses.house_01
		if not house is Dictionary or not house.get("built") is bool or not house.built or not house.get("variant") in ["piledam","moslund"]: return false
		if not normalized_pair(house.get("position")) or not house.get("rescue") in ["A","B"]: return false
		if not house.get("gift") in ["","vindblad","dugkop"] or not house.get("flowers") is Dictionary: return false
		if not house.get("decoration") is Dictionary and house.get("decoration") != []: return false
		if house.decoration is Dictionary:
			if not house.decoration.get("ornament") in ["stone","leaf"] or not house.decoration.get("cushions") is Dictionary:return false
			for cushion in house.decoration.cushions.values():
				if not normalized_pair(cushion):return false
		if not house.flowers.is_empty():
			if not house.flowers.get("plots") is Dictionary or not whole_number(house.flowers.get("level"),0,2):return false
			for flower in house.flowers.plots.values():
				if not whole_number(flower,0,2):return false
	if value.mode in ["FARM_FREE", "MINIGAME"]:
		if not value.houses.has("house_01") or not value.houses.house_01.decoration is Dictionary: return false
		if not value.chapters.get("chapter_01", {}) is Dictionary or not value.chapters.get("chapter_01", {}).get("complete", false): return false
	if value.flags.has("album_01"):
		var album = value.flags.album_01
		if not album is Dictionary or not valid_node(album.get("photo")) or not normalized_pair(album.get("stamp")): return false
	if value.started:
		if not value.current_node in value.visited or not value.node_progress.has(value.current_node):return false
		var page_number=int(value.current_node.substr(5))
		if page_number>=9 and not value.choices.has("k01_rute"):return false
		if page_number>=23 and not value.choices.has("k01_redning"):return false
		if page_number>=33 and not value.dragons.get("dragon_01",{}) is Dictionary:return false
		if page_number>=33 and not value.dragons.get("dragon_01",{}).get("rescued",false):return false
		if page_number>=36 and not value.houses.has("house_01"):return false
		if page_number>=37 and not value.houses.house_01.decoration is Dictionary:return false
	return true

static func whole_number(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floorf(float(value)) and value >= low and value <= high

static func valid_node(value: Variant) -> bool:
	return value is String and value.length() == 7 and value.begins_with("K01_S") and value.substr(5).is_valid_int() and int(value.substr(5)) >= 1 and int(value.substr(5)) <= 40 and value == "K01_S%02d" % int(value.substr(5))

static func normalized_pair(value: Variant) -> bool:
	if not value is Array or value.size() != 2: return false
	for number in value:
		if not (number is float or number is int) or not is_finite(float(number)) or number < 0 or number > 1: return false
	return true

func load_save() -> void:
	# Web filesystem sync is asynchronous. The synchronous journal is authoritative
	# on reload; an older IndexedDB snapshot must not replace newer subgoals.
	if OS.has_feature("web"):
		var raw = JavaScriptBridge.eval("localStorage.getItem('liv-hjemveje-v1')", true)
		if raw is String and accept_envelope(JSON.parse_string(raw)):
			return
	for path in [PATH, PATH + ".bak"]:
		if FileAccess.file_exists(path):
			var parsed = JSON.parse_string(FileAccess.get_file_as_string(path))
			if accept_envelope(parsed):
				return

func accept_envelope(parsed: Variant) -> bool:
	if not parsed is Dictionary or not valid_state(parsed.get("data")):
		return false
	var saved_replay = parsed.get("replay", {})
	if not saved_replay is Dictionary or (not saved_replay.is_empty() and not valid_state(saved_replay)):
		return false
	data = parsed.data
	replay = saved_replay
	return true

func serialize() -> String:
	return JSON.stringify({"data": data, "replay": replay}, "\t")

func persist() -> bool:
	if memory_only:
		return true
	var raw = serialize()
	var file = FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "Spillet kan ikke gemme på enheden. Eksportér din dagbog i indstillinger."
		return false
	file.store_string(raw)
	file.close()
	var check = JSON.parse_string(FileAccess.get_file_as_string(PATH + ".tmp"))
	if not check is Dictionary or not valid_state(check.get("data")):
		last_error = "Gemningen kunne ikke kontrolleres. Den gamle kopi er bevaret."
		return false
	if FileAccess.file_exists(PATH):
		DirAccess.copy_absolute(PATH, PATH + ".bak")
	var result = DirAccess.rename_absolute(PATH + ".tmp", PATH)
	if OS.has_feature("web"):
		# JSON.stringify's result is a JS string literal, not shell code.
		var ok = JavaScriptBridge.eval("(function(){try{localStorage.setItem('liv-hjemveje-v1'," + JSON.stringify(raw) + ");return true;}catch(e){return false;}})()", true)
		if not bool(ok):
			last_error = "Browserens lager er fuldt eller blokeret. Eksportér en sikkerhedskopi."
			return false
	if result != OK:
		last_error = "Gemningen mislykkedes. Eksportér din dagbog."
		return false
	last_error = ""
	return true

func import_save(raw: String) -> bool:
	if raw.length() > 2000000:
		return false
	if not accept_envelope(JSON.parse_string(raw)):
		return false
	return persist()

func start_replay() -> void:
	replay = fresh()
	replay.settings = data.settings.duplicate(true)
	persist()

func end_replay(keep_decoration: bool = false) -> void:
	if keep_decoration and replay.houses.has("house_01") and data.houses.has("house_01"):
		data.houses.house_01 = replay.houses.house_01.duplicate(true)
		data.choices = replay.choices.duplicate(true)
	replay = {}
	persist()
