extends Control
## On-screen island controls for phones: a movement stick bottom left and a jump button
## bottom right. Pushing the stick to its edge runs. Works with several fingers at once.
const UIStyle=preload("res://skin.gd")
const REACH=64.0
var world
var finger=-1
var value=Vector2.ZERO

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func stick_center() -> Vector2:
	return Vector2(132,size.y-132)

func jump_center() -> Vector2:
	return Vector2(size.x-118,size.y-150)

func push(at: Vector2):
	value=((at-stick_center())/REACH).limit_length(1.0)
	if is_instance_valid(world): world.stick=value
	queue_redraw()

func release():
	finger=-1
	value=Vector2.ZERO
	if is_instance_valid(world): world.stick=Vector2.ZERO
	queue_redraw()

func _input(event):
	if event is InputEventScreenTouch:
		var at: Vector2=get_global_transform().affine_inverse()*event.position
		if event.pressed:
			if finger==-1 and at.distance_to(stick_center())<REACH*1.7:
				finger=event.index
				push(at)
				get_viewport().set_input_as_handled()
			elif at.distance_to(jump_center())<58:
				if is_instance_valid(world): world.jump_queued=true
				get_viewport().set_input_as_handled()
		elif event.index==finger:
			release()
	elif event is InputEventScreenDrag and event.index==finger:
		push(get_global_transform().affine_inverse()*event.position)
		get_viewport().set_input_as_handled()

func _exit_tree():
	if is_instance_valid(world): world.stick=Vector2.ZERO

func _draw():
	var p=UIStyle.P
	draw_circle(stick_center(),REACH+18,Color(p.panel,.35))
	draw_arc(stick_center(),REACH+18,0,TAU,64,Color(p.panel_edge,.8),3,true)
	draw_circle(stick_center()+value*REACH,30,Color(p.panel,.9))
	draw_arc(stick_center()+value*REACH,30,0,TAU,48,p.panel_edge,3,true)
	draw_circle(jump_center(),50,Color(p.panel,.55))
	draw_arc(jump_center(),50,0,TAU,64,Color(p.panel_edge,.8),3,true)
	var font=get_theme_default_font()
	draw_string(font,jump_center()+Vector2(-50,7),"Jump",HORIZONTAL_ALIGNMENT_CENTER,100,20,p.text)
