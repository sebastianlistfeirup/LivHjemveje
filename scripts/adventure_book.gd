class_name AdventureBook
extends RefCounted

static var data: Dictionary = {}

static func content() -> Dictionary:
	if data.is_empty():data=JSON.parse_string(FileAccess.get_file_as_string("res://content/runtime/adventure_01.json"))
	return data

static func enrich(source: Dictionary) -> Dictionary:
	var additions=content()
	for page in source.chapter.pages:
		var patch=additions.patches.get(page.id,{})
		for key in patch:
			if key=="stages":page.runtime.stages=patch[key].duplicate(true)
			elif key=="append_stages":page.runtime.stages.append_array(patch[key].duplicate(true))
			else:page[key]=patch[key].duplicate(true) if patch[key] is Dictionary or patch[key] is Array else patch[key]
		if not page.has("presentation"):page.presentation={"anchor":["left","right","lower"][int(page.page)%3],"focus":[.5,.40]}
		page.music="wonder"
		for mood in additions.music:
			if int(page.page) in additions.music[mood]:page.music=mood
	source.chapter.pages.append_array(additions.extra.duplicate(true))
	return source

static func narrator(page: Dictionary, choices: Dictionary) -> String:
	var callback=content().callbacks.get(page.id,{})
	if not callback.is_empty():return callback["values"].get(choices.get(callback.key,""),page.narrator)
	return page.narrator

static func altered(id: String) -> bool:
	var patch=content().patches.get(id,{})
	return patch.has("stages") or patch.has("append_stages")
