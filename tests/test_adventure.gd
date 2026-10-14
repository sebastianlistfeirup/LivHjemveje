extends SceneTree
var checks=0
var failures=[]
class BlockedStore extends SaveStore:
	func persist() -> bool:
		last_error="Test storage blocked"
		return false
func check(ok: bool, message: String):
	checks+=1
	if not ok:failures.append(message);printerr("FAIL: "+message)
func at(id: String) -> StoryRuntime:
	var save=SaveStore.new(true)
	var rt=StoryRuntime.new(save);save.data.current_node=id;rt.enter();rt.progress().read=rt.page().dialogue.size()+1
	return rt
func roundtrip(rt: StoryRuntime) -> StoryRuntime:
	var restored=SaveStore.new(true)
	check(restored.accept_envelope(JSON.parse_string(rt.store.serialize())),"Valid partial challenge resumes")
	return StoryRuntime.new(restored)
func _initialize():
	var rt=at("K01_S44")
	for id in ["key_0","key_1","key_2"]:
		rt.perform(id);check(int(rt.stage_progress().get("attempts",0))<3,"Studying a key is free")
		rt.perform("test_key")
	check(rt.stage_progress().attempts==3,"Exactly three attempts consumed")
	rt=roundtrip(rt);rt.perform("key_6");rt.perform("test_key")
	check(not rt.progress().solved and rt.progress().stage==0,"Reload cannot bypass exhausted attempts")
	rt.perform("reset_keys");rt.perform("key_6");rt.perform("test_key")
	check(rt.progress().stage==1,"Correct key opens the physical lock stage")
	rt.perform("stop",Vector2(.95,.5));check(rt.stage_progress().done.is_empty(),"Mistimed lock cannot advance")
	for i in 3:rt.perform("stop",Vector2(.5,.5))
	check(rt.progress().solved,"Three correctly timed pins release the sluice")
	rt=at("K01_S52");rt.perform("book");rt.perform("cell_0")
	rt.perform("rope");check(not rt.perform("cell_0"),"Overlapping packing is refused")
	rt.perform("turn");rt.perform("cell_15")
	check(not "rope" in rt.stage_progress().done,"An object cannot protrude beyond the bag")
	rt=roundtrip(rt);check(rt.stage_progress().bag.book.x==0,"Packed placement survives reload")
	var malformed=JSON.parse_string(rt.store.serialize());malformed.data.node_progress.K01_S52.stages["0"].bag.book.turn="sideways"
	check(not SaveStore.valid_state(malformed.data),"Malformed packing rejected before rendering")
	rt=at("K01_S52");rt.perform("spoon");rt.perform("turn");rt.demonstrate();rt.demonstrate()
	check("spoon" in rt.stage_progress().done,"Packing help rotates a selected object before placing it")
	rt=at("K01_S03");rt.perform("piece_2");rt.perform("slot_1")
	check(rt.stage_progress().done.is_empty(),"Wrong jigsaw placement does not snap")
	rt.perform("slot_2");check(rt.stage_progress().done==["piece_2"],"Matching jigsaw piece snaps")
	rt=at("K01_S45");rt.perform("flower");rt.perform("cauldron")
	check(rt.stage_progress().done.is_empty(),"Wrong potion ingredient does not change recipe position")
	for id in ["dew","dew","flower","stir","stir","stir","bottle"]:
		if id!="stir":rt.perform(id)
		rt.perform("cauldron");rt=roundtrip(rt)
	check(rt.progress().solved,"Complete ordered potion persists")
	rt=at("K01_S04");rt.perform("fire")
	check(rt.stage_progress().get("index",0)==0,"Wrong rune does not advance")
	for id in rt.config().sequences[0]:rt.perform(id)
	rt.perform("leaf")
	check(rt.stage_progress().round==1 and rt.stage_progress().index==0,"Wrong second melody keeps first earned melody")
	rt=at("K01_S41");rt.perform("right");check(rt.stage_progress().steps.is_empty(),"Memory path cannot skip a turn")
	rt.perform("up");rt=roundtrip(rt);check(rt.stage_progress().steps==["up"],"Memory path resumes from the last turn")
	rt=at("K01_S11");check(not rt.perform("node_62"),"Maze cannot jump across walls to the exit")
	var moves=0
	while not rt.progress().solved and moves<100:rt.demonstrate();moves+=1
	check(moves>20 and rt.progress().solved,"Maze has a substantial reachable route")
	rt=at("K01_S49");rt.perform("hold")
	for i in 17:rt.perform("tick",Vector2(.25,0))
	check(rt.stage_progress().mistakes>0 and not rt.stage_progress().held,"Guard notices a held key after waking")
	rt=at("K01_S43");rt.perform("lane_1")
	for i in 7:rt.perform("tick",Vector2(.5,0))
	check(rt.stage_progress().elapsed<3.5 and rt.stage_progress().mistakes==1,"Runner root collision rewinds fairly")
	var source=JSON.parse_string(FileAccess.get_file_as_string("res://content/runtime/chapter_01.json"))
	var pages=AdventureBook.enrich(source).chapter.pages
	for page in pages:
		if page.id=="K01_S17":check(AdventureBook.narrator(page,{"samtaletone":"joke"}).contains("latter"),"Later narration remembers the chosen conversation")
	var old=SaveStore.fresh();old.save_version=1;old.current_node="K01_S01"
	var migrated=SaveStore.new(true);check(migrated.accept_envelope({"data":old}),"Unstarted legacy save is accepted")
	check(migrated.data.current_node=="K01_S51","Unstarted legacy save receives the new book opening")
	rt=at("K01_S03");old=rt.state().duplicate(true);old.save_version=1;old.node_progress.K01_S03.read=3
	check(migrated.accept_envelope({"data":old}),"Changed legacy challenge is accepted")
	check(migrated.data.node_progress.K01_S03.read==0 and migrated.data.node_progress.K01_S03.stages.is_empty(),"Changed unfinished challenge restarts safely")
	old.node_progress.K01_S03.solved=true;old.flags.K01_S03=true
	check(migrated.accept_envelope({"data":old}) and migrated.data.node_progress.K01_S03.solved,"Migration preserves already earned completion")
	var blocked=BlockedStore.new(true)
	var before=blocked.serialize()
	check(not blocked.import_save(rt.store.serialize()),"Import reports blocked storage")
	check(blocked.serialize()==before,"Failed import preserves the current adventure")
	rt=at("K01_S19")
	rt.state().settings.effects=false
	var ui=load("res://scripts/main.gd").new();ui.store=rt.store;ui.runtime=rt
	ui.sound=Soundscape.new();ui.sound.store=rt.store;ui.add_child(ui.sound)
	var clues=rt.config().items.duplicate(true)
	for i in clues.size()-1:rt.perform(clues[i].id)
	ui.on_action(clues.back().id,Vector2(-1,-1))
	check(rt.progress().solved and ui.reading().text==rt.page().success_text.text,"Finding a clue preserves the authored closing dialogue")
	ui.free()
	rt=at("K01_S02");rt.progress().stage=1;rt.state().settings.effects=false
	ui=load("res://scripts/main.gd").new();ui.store=rt.store;ui.runtime=rt
	ui.sound=Soundscape.new();ui.sound.store=rt.store;ui.add_child(ui.sound)
	var answer=rt.config().items[0]
	ui.on_action(answer.id,Vector2(-1,-1))
	check(rt.progress().response==answer.response,"Story choices retain their particular reply")
	check(ui.reading().speaker=="Edda" and not ui.reading().text.begins_with("Edda:"),"A chosen reply is spoken by its actual character")
	ui.free()
	malformed=JSON.parse_string(rt.store.serialize());malformed.data.node_progress.K01_S02.response={"bad":"value"}
	check(not SaveStore.valid_state(malformed.data),"Malformed dialogue response is rejected")
	print(str(checks)+" adventure assertions; "+str(failures.size())+" failures")
	quit(0 if failures.is_empty() else 1)
