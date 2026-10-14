class_name Soundscape
extends Node
var music: AudioStreamPlayer
var effect: AudioStreamPlayer
var store: SaveStore
var tracks: Dictionary = {}
var active_track = ""
var in_background = false

func setup(save: SaveStore):
	store=save
	music=AudioStreamPlayer.new();add_child(music)
	effect=AudioStreamPlayer.new();add_child(effect)
	music.volume_db=-12
	effect.volume_db=-9

func play_music(night: bool=false):
	var name="evening" if night else "woodland"
	if active_track != name:
		active_track=name
		music.stream=load("res://assets/audio/"+name+".ogg")
		music.stream.loop=true
		music.play()
	elif not music.playing:music.play()
	apply_settings()

func apply_settings():
	if music:music.stream_paused=in_background or not store.active().settings.music
	if effect and not store.active().settings.effects:effect.stop()

func cue(name: String="touch"):
	if not store.active().settings.effects:return
	var path="res://assets/audio/"+name+".wav"
	if not ResourceLoader.exists(path):path="res://assets/audio/touch.wav"
	effect.stream=load(path)
	effect.play()
	if store.active().settings.vibration:Input.vibrate_handheld(25)

func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		in_background=true
		if music:music.stream_paused=true
		if effect:effect.stop()
		if OS.has_feature("web"):JavaScriptBridge.eval("if(window.speechSynthesis)speechSynthesis.cancel()",true)
	elif what==NOTIFICATION_APPLICATION_FOCUS_IN:
		in_background=false
		if store:apply_settings()
