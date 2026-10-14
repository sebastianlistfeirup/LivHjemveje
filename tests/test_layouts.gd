extends SceneTree

var checks=0
var failures=[]

func check(ok: bool, message: String):
	checks+=1
	if not ok:
		failures.append(message)
		printerr("FAIL: "+message)

func _initialize():
	UI.init_fonts()
	for dimensions in [Vector2(568,320),Vector2(667,375),Vector2(844,390),Vector2(1024,768),Vector2(1180,820),Vector2(320,568),Vector2(390,844),Vector2(820,1180)]:
		var save=SaveStore.new(true)
		var rt=StoryRuntime.new(save)
		var layout=load("res://scripts/main.gd").new()
		layout.store=save;layout.runtime=rt;layout.screen="story";layout.size=dimensions
		for id in rt.pages:
			save.data.current_node=id
			rt.progress().read=3
			layout.viewport_layout()
			check(layout.portrait==(dimensions.y>=dimensions.x),str(dimensions)+": orientation")
			for stage in rt.page().runtime.stages.size():
				rt.progress().stage=stage
				var puzzle=PuzzleView.new()
				puzzle.setup(rt,layout.art_rect,dimensions)
				for hit in puzzle.hits:
					var center=hit.rect.get_center()
					var label=str(dimensions)+" "+id+" stage "+str(stage)+" "+hit.id
					check(Rect2(Vector2.ZERO,dimensions).has_point(center),label+": on screen")
					check(not layout.text_rect.has_point(center),label+": outside reading panel")
					check(puzzle.at_point(center)==hit.id,label+": centre selects this object")
				puzzle.free()
		layout.free()
	print(str(checks)+" layout assertions; "+str(failures.size())+" failures")
	quit(0 if failures.is_empty() else 1)
