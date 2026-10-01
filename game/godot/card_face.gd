extends Button
const UIStyle = preload("res://skin.gd")
var card: Dictionary
var compact = false
var status = ""
var current_attack = -1
var current_health = -1
var shield_active=false
var chosen = false
var active_hint = false
var unavailable_in_hand = false
var drag_payload: Dictionary={}
var arm_drag: Callable
var accepts: Callable
var dropped: Callable
var hand_hover=false
var hover_tween: Tween

func set_hand_hover(enabled: bool):
	hand_hover=enabled
	if enabled:
		mouse_entered.connect(func(): animate_hand_hover(true))
		mouse_exited.connect(func(): animate_hand_hover(false))
		focus_entered.connect(func(): animate_hand_hover(true))
		focus_exited.connect(func(): animate_hand_hover(false))

func animate_hand_hover(raised: bool):
	if not hand_hover: return
	if hover_tween!=null: hover_tween.kill()
	pivot_offset=Vector2(size.x/2,size.y)
	z_index=30 if raised else 0
	hover_tween=create_tween()
	hover_tween.tween_property(self,"scale",Vector2(1.3,1.3) if raised else Vector2.ONE,.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func set_hand_available(available: bool):
	unavailable_in_hand=not available
	if material==null:
		material=ShaderMaterial.new()
		material.shader=preload("res://card_unavailable.gdshader")
	material.set_shader_parameter("unavailable",1.0 if unavailable_in_hand else 0.0)
	queue_redraw()

func _ready():
	UIStyle.fonts()
	for event in [mouse_entered,mouse_exited,focus_entered,focus_exited]: event.connect(queue_redraw)
	for state in ["normal","hover","pressed","disabled","focus"]: add_theme_stylebox_override(state,StyleBoxEmpty.new())
	for state in ["font_color","font_disabled_color","font_hover_color","font_pressed_color","font_focus_color"]: add_theme_color_override(state,Color.TRANSPARENT)
	add_theme_font_size_override("font_size",1)
	autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	custom_minimum_size=Vector2(116,108) if compact else Vector2(166,228)
	size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	tooltip_text="%s\n%d mana · %s\n%s%s" % [card.name,card.cost,card.get("rarity","common").capitalize(),card.text,"\n"+status if not status.is_empty() else ""]
	tooltip_text += "\n"+card.get("element","").capitalize()+" · "+card.get("type","minion").capitalize()
	if card.get("taunt",false): tooltip_text += "\nEnemies must attack Taunt creatures first."

func centered(text_value: String, y: float, font: Font, point_size: int, color: Color, width: float):
	draw_string(font,Vector2(0,y),text_value,HORIZONTAL_ALIGNMENT_CENTER,width,point_size,color)

func gem(at: Vector2, value: String, color: Color):
	draw_circle(at+Vector2(0,2),15,Color("152c36"))
	draw_circle(at,14,UIStyle.GOLD)
	draw_circle(at,11,color)
	draw_string(UIStyle.sans,at+Vector2(-14,6),value,HORIZONTAL_ALIGNMENT_CENTER,28,16,Color("fff8eb"))

func _draw():
	if card.is_empty(): return
	var base=Vector2(116,108) if compact else Vector2(166,228)
	draw_set_transform(Vector2.ZERO,0,size/base)
	var border=UIStyle.GOLD if chosen or has_focus() or is_hovered() else (UIStyle.TEAL if active_hint and not disabled else Color("74674e"))
	var frame=UIStyle.box(Color("273d42"),border,12,0)
	frame.set_border_width_all(2)
	frame.shadow_color=Color(0.01,0.025,0.035,.5)
	frame.shadow_size=5
	frame.shadow_offset=Vector2(0,3)
	var texture=UIStyle.art(card.id)
	if compact:
		var center=Vector2(58,46)
		var points=PackedVector2Array()
		for i in range(49): points.append(center+Vector2(cos(i*TAU/48)*54,sin(i*TAU/48)*44))
		draw_colored_polygon(points,border)
		var portrait_points=PackedVector2Array()
		var uv=PackedVector2Array()
		for i in range(49):
			var direction=Vector2(cos(i*TAU/48),sin(i*TAU/48))
			portrait_points.append(center+direction*Vector2(49,39))
			if texture is AtlasTexture: uv.append((texture.region.position+(direction*.5+Vector2(.5,.5))*texture.region.size)/texture.atlas.get_size())
			elif texture: uv.append(direction*.5+Vector2(.5,.5))
		if texture is AtlasTexture: draw_polygon(portrait_points,PackedColorArray([Color.WHITE]),uv,texture.atlas)
		elif texture: draw_polygon(portrait_points,PackedColorArray([Color.WHITE]),uv,texture)
		else: draw_colored_polygon(portrait_points,Color("476765"))
		if shield_active:
			draw_arc(center,51,0,TAU,64,Color("ffe5a0"),4,true)
		if card.get("taunt",false):
			draw_polyline(PackedVector2Array([Vector2(6,17),Vector2(6,71),Vector2(58,104),Vector2(110,71),Vector2(110,17)]),Color("b9c8ca"),4,true)
		draw_style_box(UIStyle.box(Color("20363f"),border,6,0),Rect2(8,65,100,18))
		var token_name_size=16
		while token_name_size>10 and UIStyle.serif.get_string_size(card.name,HORIZONTAL_ALIGNMENT_LEFT,-1,token_name_size).x>96: token_name_size-=1
		centered(card.name,79,UIStyle.serif,token_name_size,UIStyle.TEXT,base.x)
		gem(Vector2(16,89),str(int(current_attack if current_attack>=0 else card.attack)),Color("a87b36"))
		gem(Vector2(base.x-16,89),str(int(current_health if current_health>=0 else card.get("durability",card.get("health",0)))),Color("a64e4b"))
		centered(status if not status.is_empty() else ("TAUNT" if card.get("taunt",false) else ""),100,UIStyle.sans,8,UIStyle.TEAL if active_hint else UIStyle.MUTED,base.x)
	else:
		draw_style_box(frame,Rect2(Vector2(2,2),base-Vector2(4,4)))
		var art_rect=Rect2(8,8,base.x-16,112)
		if texture:
			# Center-crop square illustrations rather than compressing creatures vertically.
			var source_size=texture.get_size()
			var crop_height=source_size.x*art_rect.size.y/art_rect.size.x
			draw_texture_rect_region(texture,art_rect,Rect2(0,(source_size.y-crop_height)/2,source_size.x,crop_height))
		else: draw_rect(art_rect,Color("476765"))
		draw_style_box(UIStyle.box(Color("e8dcc3"),Color("d3bc91"),5,0),Rect2(8,123,base.x-16,96))
		draw_rect(Rect2(8,99,base.x-16,25),Color("20363f"))
		var name_size=21
		while name_size>12 and UIStyle.serif.get_string_size(card.name,HORIZONTAL_ALIGNMENT_LEFT,-1,name_size).x>146: name_size-=1
		centered(card.name,118,UIStyle.serif,name_size,UIStyle.TEXT,base.x)
		var rules_size=13
		var lines=rules_lines(rules_size)
		while rules_size>9 and lines.size()*(rules_size+2)>49:
			rules_size-=1
			lines=rules_lines(rules_size)
		var y=139
		for line in lines:
			centered(line,y,UIStyle.sans,rules_size,UIStyle.INK,base.x)
			y+=rules_size+2
		gem(Vector2(20,21),str(int(card.cost)),Color("317496"))
		if card.get("type","")!="spell":
			gem(Vector2(20,208),str(int(card.attack)),Color("a87b36"))
			gem(Vector2(base.x-20,208),str(int(card.get("durability",card.get("health",0)))),Color("a64e4b"))
			if card.get("type","")=="weapon": centered("WEAPON",211,UIStyle.sans,9,Color("576569"),base.x)
		else: centered("SPELL",211,UIStyle.sans,10,Color("576569"),base.x)
		var diamond=Vector2(base.x/2,190)
		var rarity={"common":Color("9daaa3"),"rare":Color("54a8ea"),"epic":Color("b579ed"),"legendary":UIStyle.GOLD}.get(card.get("rarity","common"),Color.WHITE)
		draw_colored_polygon(PackedVector2Array([diamond+Vector2(0,-5),diamond+Vector2(4,0),diamond+Vector2(0,5),diamond+Vector2(-4,0)]),rarity)
		var element_color={"fire":Color("ee9460"),"water":Color("79c9ef"),"earth":Color("add18c"),"air":Color("d7c5f8")}.get(card.get("element",""),UIStyle.MUTED)
		# A quiet color accent communicates element without text over the illustration.
		draw_line(Vector2(12,122),Vector2(base.x-12,122),element_color,2,true)
		if chosen:
			draw_circle(Vector2(base.x-20,21),11,UIStyle.GOLD)
			draw_string(UIStyle.sans,Vector2(base.x-30,26),"✓",HORIZONTAL_ALIGNMENT_CENTER,20,15,UIStyle.INK)

func rules_lines(point_size: int) -> Array:
	var result=[]
	var line=""
	for word in card.text.split(" "):
		if UIStyle.sans.get_string_size(line+word,HORIZONTAL_ALIGNMENT_LEFT,-1,point_size).x>138:
			result.append(line.strip_edges())
			line=""
		line+=word+" "
	result.append(line.strip_edges())
	return result

func _make_custom_tooltip(_for_text: String) -> Object:
	var container=VBoxContainer.new()
	container.custom_minimum_size.x=250
	container.theme=UIStyle.theme()
	var art=TextureRect.new()
	art.texture=UIStyle.art(card.id)
	art.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	art.custom_minimum_size=Vector2(250,150)
	container.add_child(art)
	var name_label=Label.new()
	name_label.text=card.name
	name_label.add_theme_font_override("font",UIStyle.serif)
	name_label.add_theme_font_size_override("font_size",28)
	container.add_child(name_label)
	var details=Label.new()
	details.text=tooltip_text.substr(card.name.length()+1)
	if card.get("type","")!="spell":
		details.text=("%d attack · %d durability\n" if card.get("type","")=="weapon" else "%d attack · %d health\n") % [current_attack if current_attack>=0 else card.attack,current_health if current_health>=0 else card.get("durability",card.get("health",0))]+details.text
	details.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	details.custom_minimum_size.x=250
	container.add_child(details)
	return container

func _get_drag_data(_at: Vector2):
	if arm_drag.is_valid() or disabled or drag_payload.is_empty(): return null
	var preview=Control.new()
	preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
	var face=get_script().new()
	face.card=card
	face.compact=compact
	face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	preview.add_child(face)
	face.position=Vector2(-65,-90)
	face.custom_minimum_size=Vector2(130,178)
	face.size=face.custom_minimum_size
	face.modulate.a=.85
	set_drag_preview(preview)
	return drag_payload

func _can_drop_data(_at: Vector2,data: Variant) -> bool:
	return accepts.is_valid() and accepts.call(data)

func _drop_data(_at: Vector2,data: Variant):
	if dropped.is_valid(): dropped.call(data)

func _gui_input(event):
	if arm_drag.is_valid() and not disabled and not drag_payload.is_empty() and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and event.pressed:
		arm_drag.call(drag_payload,get_global_transform_with_canvas()*event.position,self)
