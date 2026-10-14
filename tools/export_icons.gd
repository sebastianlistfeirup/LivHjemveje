extends SceneTree

func _initialize():
	var args=OS.get_cmdline_user_args()
	var destination=args[0] if not args.is_empty() else ProjectSettings.globalize_path("res://builds/web")
	var original=Image.load_from_file(ProjectSettings.globalize_path("res://assets/ui/app-icon.png"))
	if original==null:
		printerr("App icon could not be loaded")
		quit(1);return
	for entry in [[192,"app-icon-192.png"],[512,"app-icon.png"],[512,"index.icon.png"],[180,"index.apple-touch-icon.png"]]:
		var resized=original.duplicate()
		resized.resize(entry[0],entry[0],Image.INTERPOLATE_LANCZOS)
		if resized.save_png(destination.path_join(entry[1]))!=OK:
			quit(1);return
	var licenses=FileAccess.open(destination.path_join("THIRD-PARTY-LICENSES.txt"),FileAccess.WRITE)
	if licenses==null:
		quit(1);return
	licenses.store_string("GODOT ENGINE\n\n"+Engine.get_license_text())
	licenses.store_string("\n\nGODOT COMPONENT COPYRIGHT NOTICES\n\n"+JSON.stringify(Engine.get_copyright_info(),"\t"))
	for name in Engine.get_license_info():
		licenses.store_string("\n\n"+name+"\n\n"+Engine.get_license_info()[name])
	for source in ["res://assets/fonts/LICENSE.txt","res://assets/fonts/Symbols-LICENSE.txt"]:
		licenses.store_string("\n\n"+source.get_file()+"\n\n"+FileAccess.get_file_as_string(source))
	licenses.close()
	quit()
