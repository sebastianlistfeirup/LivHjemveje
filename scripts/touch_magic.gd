class_name TouchMagic
extends Control
var reduced=false
var points=[]
var sparks=[]

func _ready():mouse_filter=Control.MOUSE_FILTER_IGNORE

func touch(at: Vector2):
	if not reduced:points.append({"at":at,"age":0.0})

func burst(at: Vector2):
	if not reduced:sparks.append({"at":at,"age":0.0})

func _process(delta):
	for p in points:p.age+=delta
	for s in sparks:s.age+=delta
	points=points.filter(func(p):return p.age<.5)
	sparks=sparks.filter(func(s):return s.age<1.2)
	queue_redraw()

func _draw():
	if reduced:return
	for p in points:
		var a=p.age/.5
		draw_arc(p.at,7+24*a,0,TAU,32,Color(1,.85,.55,(1-a)*.6),1.6,true)
	for s in sparks:
		var phase=s.age/1.2
		for i in 16:
			var at=s.at+Vector2.from_angle(i*TAU/16)*(1-pow(1-phase,3))*64+Vector2(0,phase*phase*22)
			draw_circle(at,(1-phase)*2.8,Color(1,.83,.43,1-phase))
