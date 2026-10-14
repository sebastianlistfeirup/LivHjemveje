class_name GameButton
extends Button
var shimmer=0.0
var release: Tween

func _ready():
	button_down.connect(func():
		if release and release.is_valid():release.kill()
		modulate=Color(.84,.89,.85))
	button_up.connect(func():
		release=create_tween();release.tween_property(self,"modulate",Color.WHITE,.18))

func _draw():
	if not disabled:
		draw_line(Vector2(15,2),Vector2(size.x-15,2),Color(1,.93,.70,.15 if not button_pressed else .04),1,true)
