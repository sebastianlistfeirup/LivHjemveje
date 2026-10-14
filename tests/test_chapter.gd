extends SceneTree

var checks = 0
var failures: Array = []

func check(condition: bool, message: String):
	checks += 1
	if not condition:
		failures.append(message)
		printerr("FAIL: " + message)

func _initialize():
	var all_visited = {}
	DirAccess.make_dir_recursive_absolute("res://test-results/checkpoints")
	for route in ["AA","AB","BA","BB"]:
		var save = SaveStore.new(true)
		var rt = StoryRuntime.new(save)
		rt.enter()
		var visited = []
		var snapshots = {}
		while rt.state().mode == "STORY" and visited.size() < 56:
			var page = rt.page()
			visited.append(page.id);all_visited[page.id]=true
			var fixture=FileAccess.open("res://test-results/checkpoints/"+page.id+".json",FileAccess.WRITE)
			fixture.store_string(save.serialize());fixture.close()
			check(not rt.next_page(), route + ": cannot skip " + page.id)
			check(not rt.perform("ring_1"), "Reading consumes input")
			for i in page.dialogue.size()+1: rt.read_next()
			var guard=0
			while not rt.progress().solved and guard < 220:
				guard+=1
				var c=rt.config()
				var sp=rt.stage_progress()
				if c.kind=="choice":
					var value=c.items[0].id
					if c.key=="k01_rute":value=route[0]
					if c.key=="k01_redning":value=route[1]
					if c.key=="k01_hjem":value="piledam" if route[0]=="A" else "moslund"
					rt.perform(value)
				elif c.kind=="album":rt.perform("K01_S17")
				elif c.kind=="maze":
					check(not rt.perform("D"),"Maze cannot jump to goal")
					for point in ["E","A","E","F","J","F","B","C","G","K","L","K","G","H","D"]:rt.perform(point)
				else:
					if c.kind=="place" and not c.items.is_empty() and not c.targets.is_empty() and sp.done.is_empty():
						check(not rt.perform(c.targets[0].id),"No target without selecting object")
					rt.demonstrate()
				# Simulate losing the process after every physical action.
				var copy=SaveStore.new(true)
				check(copy.accept_envelope(JSON.parse_string(save.serialize())),route+": resume " + page.id)
				check(copy.active().node_progress == JSON.parse_string(save.serialize()).data.node_progress,"All subgoals survive serialization")
				save=copy
				rt=StoryRuntime.new(save)
			check(rt.progress().solved,route+": scene solved " + page.id)
			if guard>=220:break
			if int(page.page) in [32,35,38,40]:snapshots[str(int(page.page))]=save.active().duplicate(true)
			rt.next_page()
		check(visited.size()==49,route+": exactly 49 scenes")
		check(rt.state().mode=="FARM_FREE",route+": ends at free farm")
		check(snapshots.get("32",{}).get("dragons",{}).get("dragon_01",{}).get("rescued",false),route+": Mos rescued before home")
		check(snapshots.get("35",{}).get("houses",{}).get("house_01",{}).get("built",false),route+": house built at S35")
		check(save.data.houses.size()==1,route+": exactly one house")
		check(save.data.houses.house_01.position==[.18,.30],"Canonical lot anchor")
		check(save.data.houses.house_01.gift==("vindblad" if route[0]=="A" else "dugkop"),route+": correct exclusive gift")
		check(save.data.houses.house_01.rescue==route[1],route+": rescue decoration")
		check(save.data.chapters.chapter_01.complete,"Chapter marked complete")
		check(save.data.chapters.chapter_02.unlocked and not save.data.chapters.chapter_02.available,"Next chapter never auto-starts")
		check(save.data.flags.album_01.photo=="K01_S17","Album chooses a visited memory")
		check(save.data.flags.froe_reddet==3,"All three seed capsules rescued")
		check(save.data.journal.has("iben_naevnt") and save.data.journal.has("blaa_kridt"),"Common story clues on every route")
		check(not visited.has("K01_S11") if route[0]=="A" else not visited.has("K01_S09"),"Exclusive route scenes")
		# Replay isolation: progress and house remain exactly as before.
		var before=JSON.stringify(save.data)
		save.start_replay();var replay_rt=StoryRuntime.new(save);replay_rt.enter()
		for i in 3:replay_rt.read_next()
		replay_rt.perform("ring_1")
		check(JSON.stringify(save.data)==before,"Replay cannot alter the farm")
		save.end_replay(false)
		check(JSON.stringify(save.data)==before,"Abandoned replay preserves the farm")
		# Gardening is a physical, persistent play loop across all three levels.
		var garden=GardenModel.new(save)
		for level in 3:
			check(not garden.grow(),"Water and three seeds required")
			for i in garden.available_cells():garden.plant(i,i%3)
			check(not garden.grow(),"Disconnected water cannot grow")
			for i in 3:
				while garden.state().pipes[i]!=0:garden.rotate_pipe(i)
			check(garden.grow(),"Connected water grows all selected flowers")
			check(garden.keep(level),"Save garden slot "+str(level))
			check(not save.data.houses.house_01.flowers.is_empty(),"Flowers persist beside house")
			if level<2:garden.new_bed()
		check(garden.available_cells()==16,"Free drawing has 4 by 4 cells")
		check(garden.load_arrangement(0),"Load first saved garden")
		check(garden.state().plots.size()==3,"First arrangement restored")
		var path="res://test-results/"+route+"-complete.json"
		var file=FileAccess.open(path,FileAccess.WRITE)
		if file:file.store_string(save.serialize());file.close()
		print("PASS route "+route+" · 49 scenes · save/replay · permanent farm · 3 garden levels")
	check(all_visited.size()==53,"All 53 authored nodes are covered")
	var invalid=SaveStore.new(true)
	var initial=invalid.serialize()
	check(not invalid.import_save('{"data":{}}'),"Reject invalid save")
	check(initial==invalid.serialize(),"Bad import does not mutate live state")
	check(not SaveStore.valid_state({"save_version":99}),"Reject unknown save version")
	print(str(checks)+" assertions; "+str(failures.size())+" failures")
	quit(0 if failures.is_empty() else 1)
