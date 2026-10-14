class_name Soundscape
extends Node
var music: AudioStreamPlayer
var fading: AudioStreamPlayer
var effect: AudioStreamPlayer
var rune: AudioStreamPlayer
var store: SaveStore
var tracks: Dictionary = {}
var active_track=""
var in_background=false
var crossfade: Tween

func setup(save: SaveStore):
	store=save
	music=AudioStreamPlayer.new();add_child(music)
	fading=AudioStreamPlayer.new();add_child(fading)
	effect=AudioStreamPlayer.new();add_child(effect)
	rune=AudioStreamPlayer.new();add_child(rune)
	music.volume_db=-17;fading.volume_db=-60;effect.volume_db=-9;rune.volume_db=-10

func play_music(night: bool=false):set_mood("evening" if night else "wonder")

func set_mood(mood: String):
	var name={"wonder":"woodland","playful":"playful","danger":"danger","evening":"evening"}.get(mood,"woodland")
	if active_track==name:
		if not music.playing:music.play()
		apply_settings();return
	if crossfade and crossfade.is_valid():crossfade.kill()
	var previous=music;music=fading;fading=previous
	if not tracks.has(name):tracks[name]=load("res://assets/audio/"+name+".ogg")
	active_track=name;music.stream=tracks[name];music.stream.loop=true;music.volume_db=-50;music.play()
	crossfade=create_tween().set_parallel(true)
	crossfade.tween_property(music,"volume_db",-17.0,2.3).set_trans(Tween.TRANS_SINE)
	crossfade.tween_property(fading,"volume_db",-55.0,2.3).set_trans(Tween.TRANS_SINE)
	crossfade.chain().tween_callback(func():fading.stop())
	apply_settings()

func apply_settings():
	for player in [music,fading]:
		if player:player.stream_paused=in_background or not store.active().settings.music
	if effect and not store.active().settings.effects:effect.stop()
	if rune and not store.active().settings.effects:rune.stop()

func cue(name: String="touch"):
	if not store.active().settings.effects:return
	var path="res://assets/audio/"+name+".wav"
	if not ResourceLoader.exists(path):path="res://assets/audio/touch.wav"
	effect.stream=load(path);effect.pitch_scale=1.0;effect.play()
	if store.active().settings.vibration:Input.vibrate_handheld(25)

func rune_note(id: String):
	if not store.active().settings.effects:return
	rune.stream=preload("res://assets/audio/place.wav")
	rune.pitch_scale={"leaf":1.0,"moon":1.25,"water":1.5,"fire":2.0}.get(id,1.0);rune.play()

func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		in_background=true
		for player in [music,fading]:
			if player:player.stream_paused=true
		if effect:effect.stop()
		if rune:rune.stop()
		if OS.has_feature("web"):JavaScriptBridge.eval("if(window.speechSynthesis)speechSynthesis.cancel()",true)
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
		in_background=false
		if store:apply_settings()
