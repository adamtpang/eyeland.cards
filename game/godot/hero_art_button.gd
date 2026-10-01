extends "res://duel_target.gd"
## Illustrated battle hero / hero-power control. Retains native button and drop behavior.
const UIStyle=preload("res://skin.gd")
var portrait: Texture2D
var is_power=false
var available=false
var used=false
var arm_drag: Callable
var drag_payload: Dictionary={}

func _gui_input(event):
	if arm_drag.is_valid() and not disabled and not drag_payload.is_empty() and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		arm_drag.call(drag_payload,get_global_transform_with_canvas()*event.position,self)

func _ready():
	for state in ["normal","hover","pressed","disabled","focus"]:
		add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_disabled_color","font_hover_color","font_pressed_color","font_focus_color"]:
		add_theme_color_override(state,Color.TRANSPARENT)
	for event in [mouse_entered,mouse_exited,focus_entered,focus_exited]: event.connect(queue_redraw)
	if is_power:
		material=ShaderMaterial.new()
		material.shader=preload("res://card_unavailable.gdshader")
		material.set_shader_parameter("unavailable",1.0 if disabled else 0.0)

func ellipse(center: Vector2,radius: Vector2) -> PackedVector2Array:
	var points=PackedVector2Array()
	for i in range(65): points.append(center+Vector2(cos(i*TAU/64),sin(i*TAU/64))*radius)
	return points

func _draw():
	var center=size/2
	var radius=size/2-Vector2(5,5)
	if is_power: radius=Vector2.ONE*(minf(size.x,size.y)/2-6)
	var frame=UIStyle.GOLD if is_hovered() or has_focus() else Color("b49b6c")
	if is_power and available: frame=UIStyle.TEAL
	draw_colored_polygon(ellipse(center+Vector2(0,3),radius+Vector2(4,4)),Color("10282d"))
	draw_colored_polygon(ellipse(center,radius+Vector2(2,2)),frame)
	var points=ellipse(center,radius-Vector2(3,3))
	var uv=PackedVector2Array()
	for point in points:
		var local_uv=(point-center)/(radius-Vector2(3,3))*.5+Vector2(.5,.5)
		if portrait is AtlasTexture: local_uv=(portrait.region.position+local_uv*portrait.region.size)/portrait.atlas.get_size()
		uv.append(local_uv)
	if portrait:
		draw_polygon(points,PackedColorArray([Color.WHITE]),uv,portrait.atlas if portrait is AtlasTexture else portrait)
	else: draw_colored_polygon(points,Color("35545a"))
	if is_power:
		var gem=Vector2(14,14)
		draw_circle(gem,14,UIStyle.GOLD)
		draw_circle(gem,11,Color("286d94"))
		draw_string(UIStyle.sans,gem+Vector2(-12,6),"2",HORIZONTAL_ALIGNMENT_CENTER,24,17,Color.WHITE)
		if used:
			draw_style_box(UIStyle.box(Color("19333d"),UIStyle.GOLD,5,0),Rect2(center.x-25,size.y-25,50,19))
			draw_string(UIStyle.sans,Vector2(center.x-25,size.y-11),"USED",HORIZONTAL_ALIGNMENT_CENTER,50,11,UIStyle.TEXT)
func _make_custom_tooltip(for_text: String) -> Object:
	var content=VBoxContainer.new()
	content.theme=UIStyle.theme()
	content.custom_minimum_size.x=210
	var art=TextureRect.new()
	art.texture=portrait
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size=Vector2(210,210)
	content.add_child(art)
	var description=Label.new()
	description.text=for_text
	description.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	content.add_child(description)
	return content
