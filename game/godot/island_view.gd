extends Control
signal tile_clicked(x: int,y: int)
const UIStyle = preload("res://skin.gd")
var model
var background: Texture2D
var hover_cell=Vector2i(-1,-1)
var player_position=Vector2.ZERO
var step_phase=0.0
var facing=Vector2.DOWN
const ZOOM=1.65

func camera_offset() -> Vector2:
	var desired=player_position/Vector2(13,8)*size*ZOOM-size/2
	return desired.clamp(Vector2.ZERO,size*(ZOOM-1.0))

func _ready():
	background=load("res://assets/island.png")
	clip_contents=true
	mouse_default_cursor_shape=Control.CURSOR_POINTING_HAND
	mouse_exited.connect(func(): hover_cell=Vector2i(-1,-1); queue_redraw())

func _gui_input(event):
	var tile=Vector2(size.x/13.0,size.y/8.0)
	if event is InputEventMouseMotion:
		hover_cell=Vector2i(((event.position+camera_offset())/ZOOM)/tile)
		queue_redraw()
	if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_LEFT:
		var at=(event.position+camera_offset())/ZOOM/tile
		tile_clicked.emit(int(at.x),int(at.y))
		accept_event()

func _draw():
	if model==null: return
	UIStyle.fonts()
	var tile=Vector2(size.x/13.0,size.y/8.0)
	draw_set_transform(-camera_offset(),0,Vector2.ONE*ZOOM)
	if background: draw_texture_rect(background,Rect2(Vector2.ZERO,size),false)
	else: draw_rect(Rect2(Vector2.ZERO,size),UIStyle.PANEL)
	# The illustration is scenery; highlighted cells and pins indicate navigation.
	if model.land(hover_cell.x,hover_cell.y):
		var center=(Vector2(hover_cell)+Vector2(.5,.5))*tile
		draw_arc(center,12,0,TAU,32,Color(1,.9,.64,.8),2,true)
	for mark in model.world.landmarks:
		var center=(Vector2(mark.x,mark.y)+Vector2(.5,.5))*tile
		var text_value=mark.symbol.capitalize()
		var measured=UIStyle.sans.get_string_size(text_value,HORIZONTAL_ALIGNMENT_LEFT,-1,11)
		var rect=Rect2(center+Vector2(-measured.x/2-9,14),Vector2(measured.x+18,23))
		draw_style_box(UIStyle.box(Color(.04,.12,.16,.92),UIStyle.GOLD if model.nearby(mark.id) else Color("73887c"),7,0),rect)
		draw_string(UIStyle.sans,rect.position+Vector2(0,16),text_value,HORIZONTAL_ALIGNMENT_CENTER,rect.size.x,11,UIStyle.TEXT)
		if mark.id=="encounter" and model.profile.won:
			draw_circle(center+Vector2(0,4),4,UIStyle.TEAL)
	var player=player_position*tile
	var stride=sin(step_phase)*3.0
	draw_set_transform(-camera_offset()+player*ZOOM,0,Vector2.ONE*ZOOM)
	draw_style_box(UIStyle.box(Color(.03,.10,.10,.30),Color(0,0,0,0),10,0),Rect2(-11,-1,22,9))
	# A little cloaked adventurer, grounded by feet and a walking cycle.
	draw_line(Vector2(-4,-7),Vector2(-5,2+stride),Color("473d35"),4,true)
	draw_line(Vector2(4,-7),Vector2(5,2-stride),Color("473d35"),4,true)
	draw_colored_polygon(PackedVector2Array([Vector2(-5,-24),Vector2(5,-24),Vector2(10,-5),Vector2(0,-2),Vector2(-10,-5)]),Color("294e61"))
	draw_line(Vector2(-5,-21),Vector2(-10,-12-stride),Color("d8b483"),3,true)
	draw_line(Vector2(5,-21),Vector2(10,-12+stride),Color("d8b483"),3,true)
	draw_circle(Vector2(0,-28),6,Color("e9c99d"))
	draw_arc(Vector2(0,-29),6,PI,TAU,20,Color("4e4438"),3,true)
	if facing.y<-.1:
		draw_style_box(UIStyle.box(Color("aa8150"),Color("694c35"),3,0),Rect2(-6,-23,12,14))
	else:
		var shift=signf(facing.x)*2
		draw_circle(Vector2(-2+shift,-28),.9,Color("20313a"))
		draw_circle(Vector2(2+shift,-28),.9,Color("20313a"))
		draw_line(Vector2(-5,-21),Vector2(5,-20),UIStyle.GOLD,2,true)
