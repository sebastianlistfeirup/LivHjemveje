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
	quit()
