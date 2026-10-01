extends Control
const Model = preload("res://model.gd")
const Battle = preload("res://battle.gd")
const Portrait = preload("res://portrait.gd")
const IslandView = preload("res://island_view.gd")
const UIStyle = preload("res://skin.gd")
const CardFace = preload("res://card_face.gd")
const World3DScene = preload("res://world_3d.gd")
const Collection = preload("res://collection.gd")
var collection_filters: Dictionary={}
var collection_page=0
var practice_mode=false
var practice_element="air"
var inspection: Control
var model = Model.new()
var constructed=preload("res://constructed.gd").new(model.cards)
var adventure_deck_view=false
var match_seed=0
var battle
var page = "start"
var body: VBoxContainer
var note = "Welcome home. A small island. A companion. An adventure waiting beyond the shore."
var job_index = 0
var element_index = 0
var selection = ""
var selected = -1
var swap_index = -1
var thinking = false
var clock_left = 75.0
var choice_clock_left=75.0
var choice_clock_battle
var choice_clock_running=false
var choice_timer_label: Label
var timer_label: Label
var save_label: Label
var last_reward = false
var context_title = "A familiar voice"
var toast = ""
var timer_bar: ProgressBar
var help_open = false
var scroll: ScrollContainer
var last_page = ""
var traveling = false
var target_widgets = {}
var retreat_dialog_open = false
var avatar_position=Vector2(-1,-1)
var held_keys={}
var island_view
var route: Array=[]
var step_phase=0.0
var facing=Vector2.DOWN
var world3d
var world_prompt: Label
var world_host: SubViewportContainer
var world_plate: Control
var scroll_filter=Control.MOUSE_FILTER_PASS
var world_hint: Label
var world_action: Button
var mulligan_picks: Array=[]
var suppress_drag_release=false
var drag_candidate: Dictionary={}
var drag_payload: Dictionary={}
var drag_start=Vector2.ZERO
var drag_source
var drag_preview
var duel_board
var battle_audio=preload("res://battle_audio.gd").new()
var secret_reveal=preload("res://secret_reveal.gd").new()
var creature_feedback=preload("res://creature_feedback.gd").new()
var hit_feel=preload("res://hit_feel.gd").new()
var combat_feedback_battle
var combat_feedback_cursor=0
var spell_feedback_battle
var spell_feedback_cursor=0
var healing_feedback_battle
var healing_feedback_cursor=0
var buff_feedback_battle
var buff_feedback_cursor=0
var effect_timeline_battle
var effect_timeline_cursor=0
var effect_schedule_until=0.0
var effect_event_times: Dictionary={}
var weapon_display: Dictionary={}
var secret_display: Dictionary={}
var battle_effects: Array=[]
var battle_effect_tweens: Array=[]
var battle_effect_owner
var settled_battle

## The island keeps its own clock. Day (06:00 to 18:00) uses the Sunlit Cel look and night
## the Inked Relic look. A full day takes 12 real minutes on the island; the clock pauses in
## battles and menus. F5 skips to the next sunset or sunrise; F6 toggles the classic look.
var game_hour=9.0
var clock_speed=0.0   # game hours per real second
var classic_look=false
var look_blend=1.8    # seconds the island takes to change look
var world_clock: Label

func is_daytime() -> bool:
	return game_hour>=6.0 and game_hour<18.0

func clock_text() -> String:
	return "%s %02d:%02d" % ["Day" if is_daytime() else "Night",int(game_hour),int(fmod(game_hour,1.0)*6)*10]

## With no argument the clock decides. Naming a look moves the clock to match it.
func choose_look(next: String=""):
	if next=="classic": classic_look=true
	elif not next.is_empty():
		classic_look=false
		if next=="night" and is_daytime(): game_hour=20.0
		elif next=="day" and not is_daytime(): game_hour=9.0
	UIStyle.set_mode("classic" if classic_look else ("day" if is_daytime() else "night"))
	theme=UIStyle.theme()
	# each look has a matching attack feel; F1 to F4 still override it
	if not OS.get_cmdline_args().has("--script"): hit_feel.variant={"day":2,"night":3}.get(UIStyle.mode,0)

func tick_clock(delta: float):
	if page!="map" or model.profile.is_empty(): return
	game_hour=fmod(game_hour+delta*clock_speed,24.0)
	model.profile.time=game_hour
	if is_instance_valid(world_clock): world_clock.text=clock_text()
	if not classic_look and UIStyle.mode!=("day" if is_daytime() else "night"):
		look_blend=12.0  # sunrise and sunset take their time
		choose_look()
		render()
		look_blend=1.8

func _ready():
	choose_look()
	add_child(battle_audio)
	add_child(secret_reveal)
	add_child(creature_feedback)
	hit_feel.game=self
	add_child(hit_feel)
	theme = UIStyle.theme()
	scroll = ScrollContainer.new()
	scroll.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(scroll)
	scroll_filter=scroll.mouse_filter
	var margin = MarginContainer.new()
	margin.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	for side in ["left","right","top","bottom"]: margin.add_theme_constant_override("margin_"+side,24)
	scroll.add_child(margin)
	body = VBoxContainer.new()
	body.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	body.add_theme_constant_override("separation",12)
	margin.add_child(body)
	if model.load_profile(): page = "map"
	game_hour=float(model.profile.get("time",9.0))
	clock_speed=0.0 if OS.get_cmdline_args().has("--script") else 24.0/720.0
	choose_look()
	if model.save_path!="user://home-v1.json": constructed.path=model.save_path+".deck.json"
	constructed.load_or_create(model.profile.get("element","air"))
	if page=="map" and OS.get_cmdline_user_args().has("--collection"): page="deck"
	render()
	get_window().min_size=Vector2i(1024,720)

func label_at(parent: Node, text: String, size: int = 18) -> Label:
	var l = Label.new()
	l.text=text
	l.add_theme_font_size_override("font_size",size)
	if size>=24: l.add_theme_font_override("font",UIStyle.serif)
	l.autowrap_mode=TextServer.AUTOWRAP_WORD_SMART
	l.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

func button_at(parent: Node, text: String, action: Callable, disabled: bool = false) -> Button:
	var b = Button.new()
	b.text=text
	b.disabled=disabled
	b.pressed.connect(action)
	b.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	b.custom_minimum_size.y=42
	parent.add_child(b)
	return b

func row_at(parent: Node) -> HBoxContainer:
	var r=HBoxContainer.new()
	r.add_theme_constant_override("separation",10)
	r.mouse_filter=Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)
	return r

func panel(parent: Node, color: Color=UIStyle.PANEL) -> VBoxContainer:
	var frame=PanelContainer.new()
	frame.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	frame.add_theme_stylebox_override("panel",UIStyle.plate(color,UIStyle.P.panel_edge,UIStyle.P.panel_r,18))
	parent.add_child(frame)
	var content=VBoxContainer.new()
	content.add_theme_constant_override("separation",12)
	frame.add_child(content)
	return content

func eyebrow(parent: Node, value: String):
	var l=label_at(parent,value,11)
	l.add_theme_color_override("font_color",UIStyle.P.eyebrow)

func muted(parent: Node,value: String,size_value: int=13):
	var l=label_at(parent,value,size_value)
	l.add_theme_color_override("font_color",UIStyle.MUTED)
	return l

func primary(parent: Node,value: String,action: Callable) -> Button:
	var b=button_at(parent,value,action)
	UIStyle.primary(b)
	return b

func art_at(parent: Node,id: String,height: float) -> TextureRect:
	var image=TextureRect.new()
	image.texture=UIStyle.art(id)
	image.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_COVERED
	image.custom_minimum_size=Vector2(100,height)
	parent.add_child(image)
	return image

func render():
	if page!="battle" or battle_effect_owner!=battle:
		clear_battle_effects()
		battle_effect_owner=battle if page=="battle" else null
	creature_feedback.capture(self)
	if page!="battle": secret_reveal.reset()
	elif secret_reveal.observed_battle!=battle: secret_reveal.reset(battle)
	# Preserve the established battle geometry while containers queue their next layout.
	# Targeting can happen immediately after a hand/selection refresh.
	var previous_battle_rect=Rect2()
	if is_instance_valid(duel_board) and duel_board.get_parent()==body:
		previous_battle_rect=duel_board.get_rect()
	close_inspection()
	cancel_card_drag()
	# Staying on the island keeps the same world, so only the HUD is rebuilt and a change
	# of look can blend instead of popping.
	var keep_world=page=="map" and is_instance_valid(world3d) and is_instance_valid(world_host)
	if is_instance_valid(world3d):
		save_world_position(world3d.player.position)
		world3d.stop_input()
		if not keep_world: world3d=null
	if not keep_world:
		if is_instance_valid(world_host): world_host.queue_free()
		world_host=null
	# On the island the page is a HUD floating over a full-window 3D view, so the empty
	# parts of the page must let the mouse through to the world.
	var over_world=page=="map"
	scroll.mouse_filter=Control.MOUSE_FILTER_IGNORE if over_world else scroll_filter
	for layer in [body,body.get_parent()]:
		layer.mouse_filter=Control.MOUSE_FILTER_IGNORE if over_world else Control.MOUSE_FILTER_PASS
		layer.size_flags_vertical=Control.SIZE_EXPAND_FILL if over_world else Control.SIZE_FILL
	if page!="map": held_keys.clear(); route.clear(); traveling=false
	body.add_theme_constant_override("separation",6 if page=="battle" else 12)
	for side in ["top","bottom"]: body.get_parent().add_theme_constant_override("margin_"+side,12 if page=="battle" else 24)
	for node in body.get_children():
		body.remove_child(node)
		node.queue_free()
	timer_label=null
	timer_bar=null
	target_widgets={}
	var header=row_at(body)
	var title=label_at(header,"eyeland.cards",28 if page=="battle" else 34)
	if page=="map": hud_outline(title)
	if page!="start":
		if page in ["map","deck"]:
			var nav=button_at(header,"Collection" if page=="map" else "Back to island",func(): page="deck" if page=="map" else "map"; swap_index=-1; render())
			nav.size_flags_horizontal=Control.SIZE_SHRINK_END
	if page=="map":
		var sound=button_at(header,"Sound off" if battle_audio.muted else "Sound on",func(): battle_audio.toggle(); render())
		sound.size_flags_horizontal=Control.SIZE_SHRINK_END
		sound.tooltip_text="Toggle island and battle sounds for this session."
	var help=button_at(header,"?" if not help_open else "Close",func(): help_open=not help_open; render())
	help.size_flags_horizontal=Control.SIZE_SHRINK_END
	help.tooltip_text="WASD: move | Shift: run | Space: jump\nRight-drag: camera | Wheel: zoom | E: interact\nDrag cards onto the battlefield. Drag attacks and damage spells onto enemies.\nHover cards for details. Click ? for the full guide."
	if help_open:
		var guide=panel(body)
		label_at(guide,"Explore. Befriend. Build your deck.",26)
		muted(guide,"Walk with WASD or arrows, run with Shift, jump with Space. Right-drag to orbit the camera; wheel to zoom. E interacts nearby. In battle, drag a card onto the field; release where you want your creature. Drag damage spells and ready creatures onto enemies. Dropping outside the field cancels. Clicking remains available. Creatures can attack next turn. Taunt creatures protect their hero. Blue gems are mana, gold is attack, red is health. Use your class power once per turn. An empty deck causes increasing fatigue damage. Escape cancels targeting.")
	if page == "start":
		start_screen()
		return
	var p=model.profile
	if page == "map": map_screen()
	elif page == "deck": deck_screen()
	elif page == "battle": battle_screen()
	elif page == "result": result_screen()
	if page=="battle" and previous_battle_rect.size.x>0:
		duel_board.position=previous_battle_rect.position
		duel_board.size=previous_battle_rect.size
	creature_feedback.present(self)
	save_label=label_at(body,model.error if not model.error.is_empty() else (toast if not toast.is_empty() else "Adventure saved on this device"),11)
	if page=="map": hud_outline(save_label)
	if not constructed.error.is_empty(): save_label.text=constructed.error
	save_label.visible=not model.error.is_empty() or not constructed.error.is_empty()
	save_label.modulate=UIStyle.MUTED
	if not model.error.is_empty(): save_label.modulate=Color("f5b16b")
	if page!=last_page:
		scroll.scroll_vertical=0
		body.modulate.a=.4
		create_tween().tween_property(body,"modulate:a",1.0,.18)
		last_page=page

func start_screen():
	var split=row_at(body)
	var intro=panel(split)
	intro.get_parent().custom_minimum_size.x=330
	intro.get_parent().size_flags_horizontal=Control.SIZE_FILL
	label_at(intro,"Your companion",32)
	var portrait=art_at(intro,model.world.elements[element_index].starter,230)
	portrait.mouse_filter=Control.MOUSE_FILTER_STOP
	portrait.tooltip_text=model.cards[model.world.elements[element_index].starter].text
	label_at(intro,model.cards[model.world.elements[element_index].starter].name,30)
	var choices=panel(split,UIStyle.P.panel2)
	eyebrow(choices,"CLASS")
	label_at(choices,"Your adventure",32)
	var jobs=row_at(choices)
	for i in range(model.world.classes.size()):
		var j=model.world.classes[i]
		var b=button_at(jobs,("✓ " if i==job_index else "")+j.name,func(): job_index=i; render())
		b.icon=UIStyle.hero_art(j.id)
		b.expand_icon=true
		b.add_theme_constant_override("icon_max_width",44)
		b.custom_minimum_size.y=64
		b.tooltip_text=j.power+"\n"+j.description
		if i==job_index: UIStyle.primary(b)
	eyebrow(choices,"COMPANION")
	var elements=row_at(choices)
	for i in range(model.world.elements.size()):
		var e=model.world.elements[i]
		var c=card_button(elements,e.starter,func(): element_index=i; render(),false,"SELECTED" if i==element_index else "")
		c.text=e.name+" "+c.text
		c.custom_minimum_size=Vector2(136,202)
		c.active_hint=false
	primary(choices,"Begin at home",begin)
	if model.save_blocked: label_at(body,model.error,16)

func begin():
	model.new_profile(model.world.classes[job_index].id,model.world.elements[element_index].id)
	game_hour=9.0
	choose_look()
	if not FileAccess.file_exists(constructed.path): constructed.preset(model.profile.element)
	model.save()
	page="map"
	render()

## Text that sits directly on the 3D world gets an outline in the panel colour.
func hud_outline(label: Label):
	label.add_theme_constant_override("outline_size",8)
	label.add_theme_color_override("font_outline_color",UIStyle.P.panel)

func map_screen():
	var p=model.profile
	if not is_instance_valid(world3d):
		world_host=SubViewportContainer.new()
		world_host.name="WorldView"
		world_host.stretch=true
		world_host.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		world_host.mouse_filter=Control.MOUSE_FILTER_STOP
		add_child(world_host)
		move_child(world_host,0)
		var viewport=SubViewport.new()
		viewport.own_world_3d=true
		viewport.msaa_3d=Viewport.MSAA_4X
		viewport.render_target_update_mode=SubViewport.UPDATE_ALWAYS
		world_host.add_child(viewport)
		world3d=World3DScene.new()
		world3d.element=p.element
		world3d.job=p.get("job","warrior")
		world3d.restored_garden=p.won
		world3d.muted=battle_audio.muted
		if p.has("world_position"):
			world3d.spawn_position=Vector3(p.world_position[0],p.world_position[1],p.world_position[2])
		else: world3d.spawn_position=Vector3((p.x-6)*6,2,(p.y-4)*6)
		viewport.add_child(world3d)
		world_host.gui_input.connect(func(event):
			if is_instance_valid(world3d) and not event is InputEventKey: world3d.input_event(event))
		world3d.position_saved.connect(save_world_position)
		world3d.interact_requested.connect(world_interact)
		world3d.nearby_changed.connect(update_world_prompt)
	world3d.set_muted(battle_audio.muted)
	world3d.set_night(UIStyle.mode=="night",look_blend)
	# HUD plates float over the world: place and health top left, the nearby action bottom centre.
	var top=row_at(body)
	var info=panel(top)
	info.get_parent().size_flags_horizontal=Control.SIZE_SHRINK_BEGIN
	info.add_theme_constant_override("separation",0)
	label_at(info,"Home Island",24).autowrap_mode=TextServer.AUTOWRAP_OFF
	muted(info,"♥ %d / 30   ◆ %d resin" % [p.hp,p.resin],14).autowrap_mode=TextServer.AUTOWRAP_OFF
	world_clock=muted(info,clock_text(),14)
	world_clock.autowrap_mode=TextServer.AUTOWRAP_OFF
	var gap=Control.new()
	gap.size_flags_vertical=Control.SIZE_EXPAND_FILL
	gap.mouse_filter=Control.MOUSE_FILTER_IGNORE
	body.add_child(gap)
	var hud=row_at(body)
	hud.alignment=BoxContainer.ALIGNMENT_CENTER
	var prompt=row_at(panel(hud))
	world_plate=prompt.get_parent().get_parent()
	world_plate.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	world_plate.visible=false
	prompt.add_theme_constant_override("separation",18)
	world_prompt=label_at(prompt,"",22)
	world_prompt.autowrap_mode=TextServer.AUTOWRAP_OFF
	world_prompt.mouse_filter=Control.MOUSE_FILTER_STOP
	world_action=primary(prompt,"Interact · E",func():
		if is_instance_valid(world3d): world_interact(world3d.current_landmark))
	world_action.size_flags_horizontal=Control.SIZE_SHRINK_END
	world_action.visible=false
	update_world_prompt(world3d.current_landmark)

func save_world_position(at: Vector3):
	if model.profile.is_empty(): return
	model.profile.world_position=[at.x,at.y,at.z]
	model.save()

func near_location(id: String) -> bool:
	if is_instance_valid(world3d):
		var at=world3d.landmarks[id]
		return Vector2(at.x,at.z).distance_to(Vector2(world3d.player.position.x,world3d.player.position.z))<4.1
	return model.nearby(id)

func update_world_prompt(id: String):
	if not is_instance_valid(world_prompt): return
	world_action.visible=not id.is_empty()
	if is_instance_valid(world_plate): world_plate.visible=not id.is_empty()
	var names={"home":"Home","friend":"Mira","crop":"Garden","encounter":"Resin Crab","camp":"Campfire","dock":"Lookout"}
	world_prompt.text=names.get(id,"")
	world_prompt.tooltip_text=note
	for mark in model.world.landmarks:
		if mark.id==id: world_prompt.tooltip_text=mark.dialogue
	world_action.text="Battle Resin Crab · E" if id=="encounter" else ("Rest · E" if id=="camp" else "Interact · E")

func world_interact(id: String):
	if page!="map" or id.is_empty() or not near_location(id): return
	if id=="encounter": enter_battle(); return
	if id=="camp":
		model.profile.hp=30
		model.save()
		note="The fire warms your hands. You and your companion are ready again. Health restored to 30."
	else:
		for mark in model.world.landmarks:
			if mark.id==id: note=mark.dialogue
		if id=="home": model.profile.met_home=true; model.save()
		if id=="crop" and model.profile.won: note="The garden is flowering again. Your family has already replanted the beds you protected."
	render()

func travel_to(x: int,y: int):
	if page!="map" or not model.land(x,y): return
	# Breadth-first search respects the same collision map as keyboard movement.
	var origin=Vector2i(model.profile.x,model.profile.y)
	var destination=Vector2i(x,y)
	var queue=[origin]
	var previous={origin:origin}
	while not queue.is_empty():
		var at=queue.pop_front()
		if at==destination: break
		for offset in [Vector2i.LEFT,Vector2i.RIGHT,Vector2i.UP,Vector2i.DOWN]:
			var next=at+offset
			if model.land(next.x,next.y) and not previous.has(next):
				previous[next]=at
				queue.append(next)
	if not previous.has(destination): return
	var path=[]
	var at=destination
	while at!=origin:
		path.push_front(at)
		at=previous[at]
	route=path
	traveling=not route.is_empty()

func walk(dx: int,dy: int):
	if page!="map": return
	travel_to(int(model.profile.x)+dx,int(model.profile.y)+dy)

func move_avatar(delta: float):
	if avatar_position.x<0: avatar_position=Vector2(model.profile.x+.5,model.profile.y+.5)
	var direction=Vector2(float(held_keys.has(KEY_D) or held_keys.has(KEY_RIGHT))-float(held_keys.has(KEY_A) or held_keys.has(KEY_LEFT)),float(held_keys.has(KEY_S) or held_keys.has(KEY_DOWN))-float(held_keys.has(KEY_W) or held_keys.has(KEY_UP)))
	if direction!=Vector2.ZERO:
		route.clear()
		direction=direction.normalized()
	elif not route.is_empty():
		var destination=Vector2(route[0])+Vector2(.5,.5)
		var distance=avatar_position.distance_to(destination)
		if distance<.025:
			avatar_position=destination
			route.pop_front()
		else: direction=(destination-avatar_position).normalized()*minf(1.0,distance/(3.6*maxf(delta,.0001)))
	traveling=not route.is_empty()
	var old=avatar_position
	# Small substeps prevent crossing coastline cells during slow frames.
	var steps=maxi(1,ceili(delta/.016))
	for i in range(steps):
		var movement=direction*3.6*delta/steps
		var next=avatar_position+Vector2(movement.x,0)
		if walkable(next): avatar_position=next
		next=avatar_position+Vector2(0,movement.y)
		if walkable(next): avatar_position=next
	if old!=avatar_position:
		step_phase+=delta*13.0
		facing=direction
		var cell=Vector2i(avatar_position.floor())
		if cell!=Vector2i(model.profile.x,model.profile.y):
			model.profile.x=cell.x
			model.profile.y=cell.y
			model.save()
			render()
	else: step_phase=0
	if is_instance_valid(island_view):
		island_view.player_position=avatar_position
		island_view.facing=facing
		island_view.step_phase=step_phase
		island_view.queue_redraw()

func walkable(at: Vector2) -> bool:
	for offset in [Vector2(-.12,0),Vector2(.12,0),Vector2(0,-.10),Vector2(0,.10)]:
		var p=at+offset
		if not model.land(int(floor(p.x)),int(floor(p.y))): return false
	return true

func interact_nearest():
	var nearest={}
	var distance=INF
	for mark in model.world.landmarks:
		var d=avatar_position.distance_to(Vector2(mark.x+.5,mark.y+.5))
		if model.nearby(mark.id) and d<distance: nearest=mark; distance=d
	if nearest.is_empty(): return
	if nearest.id=="encounter": enter_battle()
	elif nearest.id=="camp": rest()
	else: interact(nearest.id)

func interact(id: String):
	if page!="map" or not model.nearby(id): return
	for mark in model.world.landmarks:
		if mark.id==id: note=mark.dialogue; context_title=mark.name
	if id=="home": model.profile.met_home=true; model.save()
	render()

func rest():
	if page!="map" or not model.nearby("camp"): return
	model.profile.hp=30
	model.save()
	note="Rested. Your companions are ready for another adventure."
	render()

func card_button(parent: Node,id: String,action: Callable,disabled: bool=false,extra: String="",compact: bool=false) -> Button:
	var c=CardFace.new()
	c.card=battle.cards[id] if page=="battle" else model.cards[id]
	c.compact=compact
	c.status=extra
	c.chosen=extra=="SELECTED"
	c.active_hint=not disabled
	c.text=c.card.name+" "+extra
	c.disabled=disabled
	c.pressed.connect(action)
	parent.add_child(c)
	return c

func deck_screen():
	Collection.build(self)

func start_practice(element: String,featured: String="",custom_deck=false,starting_player: int=-1):
	if page!="deck": return
	practice_mode=true
	practice_element=element
	var deck=constructed.deck.duplicate() if custom_deck else Collection.practice_deck(model.cards,element)
	if not constructed.valid(deck): return
	var other=Collection.ELEMENTS[(Collection.ELEMENTS.find(element)+1)%4]
	var enemy=Collection.practice_deck(model.cards,other)
	var class_data=model.world.classes.filter(func(c): return c.id==model.profile.job)[0]
	match_seed=int(Time.get_ticks_msec()%1000000)
	battle=Battle.new(model.cards,deck,enemy,30,30,class_data,match_seed,true,starting_player)
	battle.enemy_name=other.capitalize()+" keeper"
	# Explicit inspection practice guarantees the chosen card, without duplicating it.
	if featured!="" and not battle.sides[0].hand.has(featured):
		var index=battle.sides[0].deck.find(featured)
		if index>=0:
			battle.sides[0].deck[index]=battle.sides[0].hand[0]
			battle.sides[0].hand[0]=featured
	mulligan_picks=[]
	page="battle"
	clock_left=75
	selection=""
	thinking=false
	render()

func replace_card(id: String):
	if page!="deck" or swap_index<0: return
	var candidate=model.profile.deck.duplicate()
	candidate[swap_index]=id
	if not model.deck_valid(candidate,model.profile): return
	model.profile.deck=candidate
	model.save()
	toast=model.cards[id].name+" added to your deck. Changes saved."
	swap_index=-1
	render()

func enter_battle(starting_player: int=-1):
	if page!="map" or not near_location("encounter"): return
	if not constructed.valid(constructed.deck):
		page="deck"; adventure_deck_view=false; render(); return
	practice_mode=false
	var p=model.profile
	p.battle_pending=true
	p.seed = (int(p.seed)%1000000)+1
	model.save()
	var class_data=model.world.classes.filter(func(c): return c.id==p.job)[0]
	match_seed=p.seed
	battle=Battle.new(model.cards,constructed.deck,Collection.practice_deck(model.cards,"earth"),30,30,class_data,p.seed,true,starting_player)
	mulligan_picks=[]
	page="battle"
	clock_left=75
	selection=""
	thinking=false
	render()

func battle_screen():
	duel_board=preload("res://duel_board.gd").new()
	duel_board.game=self
	body.add_child(duel_board)

func confirm_retreat():
	if retreat_dialog_open or page!="battle" or thinking: return
	retreat_dialog_open=true
	var dialog=ConfirmationDialog.new()
	dialog.title="Leave practice?" if practice_mode else "Return to camp?"
	dialog.dialog_text="Leave practice? Your adventure is unchanged." if practice_mode else "You will return with 1 health. Your collected cards and resin are safe."
	dialog.ok_button_text="Leave practice" if practice_mode else "Return to camp"
	dialog.cancel_button_text="Keep battling"
	dialog.confirmed.connect(func(): retreat_dialog_open=false; retreat(); dialog.queue_free())
	dialog.canceled.connect(func(): retreat_dialog_open=false; dialog.queue_free())
	add_child(dialog)
	dialog.popup_centered(Vector2i(430,160))

func target_allowed(uid: int) -> bool:
	if battle.active!=0 or thinking or selection.is_empty(): return false
	if selection=="attack": return battle.attack_targets(0,selected).has(uid)
	if selection=="spell": return battle.card_targets(0,battle.cards[battle.sides[0].hand[selected]]).has(uid)
	return battle.targets(0,false).has(uid)

func play_card(i: int):
	if page!="battle" or thinking or not battle.can_play(0,i): return
	var c=battle.cards[battle.sides[0].hand[i]]
	if c.has("choices"):
		selection="choice"; selected=i; render(); return
	if c.get("targeting","")=="optionalCreature": selection="spell"; selected=i; render()
	else: battle.play(0,i); after_action()

func use_power():
	if page!="battle" or thinking or battle.sides[0].mana<2 or battle.sides[0].power_used: return
	if battle.job.effect=="target": selection="power"; render()
	else: battle.power(); after_action()

func target_enemy(uid: int):
	if page!="battle" or not target_allowed(uid): return
	var spell_action=selection=="spell" and battle.cards[battle.sides[0].hand[selected]].get("type","")=="spell"
	var attack_action=selection=="attack"
	var target_side=0 if selection=="spell" and battle.cards[battle.sides[0].hand[selected]].get("targetSide","")=="friendly" else 1
	var point=target_widgets[uid].get_global_rect().get_center() if target_widgets.has(uid) else size/2
	var before=battle.sides[target_side].hp+battle.sides[target_side].armor if uid==-1 else battle.minion(target_side,uid).hp
	if selection=="attack":
		battle.attack(0,selected,uid)
	elif selection=="spell": battle.play(0,selected,uid)
	elif selection=="power": battle.power(uid)
	var remaining=battle.minion(target_side,uid)
	var after=battle.sides[target_side].hp+battle.sides[target_side].armor if uid==-1 else remaining.get("hp",0)
	after_action()
	if before>after and not spell_action and not attack_action: float_feedback("−%d" % (before-after),point)

func clear_battle_effects():
	effect_schedule_until=0.0
	effect_event_times.clear()
	weapon_display.clear()
	secret_display.clear()
	for tween in battle_effect_tweens:
		if tween.is_valid(): tween.kill()
	battle_effect_tweens.clear()
	for effect in battle_effects:
		if is_instance_valid(effect):
			remove_child(effect)
			effect.queue_free()
	battle_effects.clear()

func track_battle_effect(effect: Node,tween: Tween):
	battle_effects=battle_effects.filter(func(node): return is_instance_valid(node))
	battle_effect_tweens=battle_effect_tweens.filter(func(t): return t.is_valid() and t.is_running())
	battle_effects.append(effect); battle_effect_tweens.append(tween)

func float_feedback(value: String,point: Vector2,color: Color=Color("ffe0a0"),delay: float=0.0,anchor: Callable=Callable()):
	if page!="battle": return
	var feedback=Label.new()
	feedback.name="DamageFeedback"
	feedback.z_index=60
	feedback.text=value
	feedback.position=get_global_transform().affine_inverse()*point-Vector2(25,20)
	feedback.mouse_filter=Control.MOUSE_FILTER_IGNORE
	feedback.add_theme_font_size_override("font_size",30)
	feedback.add_theme_color_override("font_color",color)
	feedback.add_theme_color_override("font_outline_color",UIStyle.INK)
	feedback.add_theme_constant_override("outline_size",5)
	add_child(feedback)
	var tween=create_tween()
	if delay>0:
		feedback.hide()
		tween.tween_interval(delay)
		tween.tween_callback(feedback.show)
	if anchor.is_valid():
		tween.tween_callback(func(): feedback.position=get_global_transform().affine_inverse()*anchor.call()-Vector2(25,20))
	tween.set_parallel(true)
	track_battle_effect(feedback,tween)
	tween.tween_property(feedback,"position:y",-45.0,.65).as_relative().set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tween.tween_property(feedback,"modulate:a",0.0,.4).set_delay(.25)
	tween.chain().tween_callback(feedback.queue_free)

func after_action():
	if battle==settled_battle: return
	while not battle.pending_choice.is_empty() and battle.pending_choice.owner==1 and battle.outcome==-1:
		if not battle.ai_step(1): break
	battle_audio.observe(battle,true)
	show_ordered_effects()
	secret_reveal.observe(battle)
	selection=""
	if battle.outcome!=-1:
		settled_battle=battle
		if not practice_mode:
			last_reward=model.finish(battle.outcome==0,battle.sides[0].hp)
			if battle.outcome!=0:
				model.profile.world_position=[0,2,6]
				model.save()
			avatar_position=Vector2(model.profile.x+.5,model.profile.y+.5)
		var has_effect=battle_effects.any(func(node): return is_instance_valid(node))
		has_effect=has_effect or secret_reveal.showing or battle.timeline.slice(creature_feedback.timeline_cursor).any(func(event): return event.kind in ["summon","death"])
		if has_effect:
			thinking=true
			finish_after_feedback(battle)
		else: page="result"
	render()

func feedback_busy() -> bool:
	return battle_effect_tweens.any(func(tween): return tween.is_valid() and tween.is_running()) or creature_feedback.animations.any(func(tween): return tween.is_valid() and tween.is_running()) or secret_reveal.showing or not creature_feedback.stat_steps.is_empty() or not creature_feedback.hero_steps.is_empty() or not creature_feedback.movement_tracks.is_empty()

func finish_after_feedback(completed):
	await get_tree().create_timer(.7).timeout
	while battle==completed and page=="battle":
		if not feedback_busy():
			thinking=false; page="result"; render()
			return
		await get_tree().create_timer(.05).timeout

func confirm_opening():
	if page!="battle" or not battle.mulligan(mulligan_picks): return
	clock_left=75
	thinking=battle.active==1
	render()
	if thinking: run_opponent_turn()

func end_turn():
	if page!="battle" or thinking or battle.mulligan_pending or battle.active!=0 or battle.outcome!=-1: return
	if not battle.pending_choice.is_empty(): return
	selection=""
	thinking=true
	battle.end_turn(0)
	after_action()
	run_opponent_turn()

func run_opponent_turn():
	var current_battle=battle
	thinking=true
	while page=="battle" and battle.active==1 and battle.outcome==-1:
		await get_tree().create_timer(0.55).timeout
		if battle!=current_battle or page!="battle" or battle.outcome!=-1: return
		if feedback_busy(): continue
		if not battle.pending_choice.is_empty() and battle.pending_choice.owner==0: continue
		if not battle.ai_step(1):
			battle.end_turn(1)
			break
		after_action()
	if battle.outcome!=-1: return
	thinking=false
	clock_left=75
	after_action()

func retreat():
	if page!="battle" or thinking: return
	battle.outcome=1
	after_action()

func result_screen():
	battle_audio.present_result(battle)
	if practice_mode:
		var center=CenterContainer.new()
		center.custom_minimum_size.y=520
		body.add_child(center)
		var summary=panel(center)
		summary.get_parent().custom_minimum_size.x=430
		var portrait=TextureRect.new()
		portrait.texture=UIStyle.hero_art(battle.job.id)
		portrait.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
		portrait.stretch_mode=TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		portrait.custom_minimum_size=Vector2(200,200)
		summary.add_child(portrait)
		var heading=label_at(summary,"Practice draw" if battle.outcome==2 else ("Practice victory" if battle.outcome==0 else "Practice complete"),38)
		heading.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		var detail=muted(summary,"Adventure unchanged",14)
		detail.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
		primary(summary,"Play again",func(): page="deck"; start_practice(constructed.element,"",true))
		button_at(summary,"Edit deck",func(): practice_mode=false; adventure_deck_view=false; page="deck"; render())
		return
	var victory=battle.outcome==0
	var layout=row_at(body)
	var spacer=Control.new()
	spacer.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	layout.add_child(spacer)
	var content=panel(layout)
	content.get_parent().custom_minimum_size.x=600
	content.get_parent().size_flags_horizontal=Control.SIZE_FILL
	label_at(content,"Draw" if battle.outcome==2 else ("Victory" if victory else "Defeat"),38)
	if last_reward:
		var reward_row=row_at(content)
		reward_row.alignment=BoxContainer.ALIGNMENT_CENTER
		card_button(reward_row,"home-resin-crab",func(): pass,true,"ADDED TO COLLECTION")
		var reward_text=VBoxContainer.new()
		reward_text.custom_minimum_size.x=230
		reward_row.add_child(reward_text)
		label_at(reward_text,"+1 Resin Crab",28)
		label_at(reward_text,"+2 luminous resin",25)
		primary(content,"Make room in your deck",func(): page="deck"; swap_index=-1; render())
	else:
		art_at(content,model.starter(model.profile.element),230)
		if not victory: primary(content,"Rest at camp",func(): page="map"; rest()).tooltip_text="You returned with 1 health. Rest restores you to 30."
	button_at(content,"Continue to island",func(): page="map"; note="Your adventure is saved."; render())
	var right=Control.new()
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	layout.add_child(right)

func player_choice_ready() -> bool:
	return page=="battle" and battle.outcome==-1 and not battle.pending_choice.is_empty() and battle.pending_choice.owner==0 and not feedback_busy() and Time.get_ticks_msec()/1000.0>=effect_schedule_until

func choose_presented_card(index: int):
	if player_choice_ready() and battle.choose_discover(0,index): after_action()

func _process(delta: float):
	tick_clock(delta)
	var choice_ready=player_choice_ready()
	if choice_ready and is_instance_valid(duel_board) and duel_board.get_node_or_null("DiscoverOption0")==null:
		render()
	var offturn_choice=choice_ready and battle.active==1
	if offturn_choice:
		if not choice_clock_running or choice_clock_battle!=battle:
			choice_clock_left=75.0; choice_clock_battle=battle; choice_clock_running=true
		choice_clock_left=maxf(0,choice_clock_left-delta)
		if is_instance_valid(choice_timer_label): choice_timer_label.text="%ds" % ceili(choice_clock_left)
		if choice_clock_left<=0 and battle.choose_discover(0,0): after_action()
	else: choice_clock_running=false
	if page=="battle" and not thinking and not retreat_dialog_open and battle.outcome==-1 and not battle.mulligan_pending and battle.active==0:
		clock_left-=delta
		if is_instance_valid(timer_label): timer_label.text="%ds" % ceili(clock_left)
		if is_instance_valid(timer_bar): timer_bar.value=clock_left
		if clock_left<=0 and (battle.pending_choice.is_empty() or choice_ready):
			if not battle.pending_choice.is_empty():
				if battle.pending_choice.owner==0 and battle.choose_discover(0,0): after_action()
				elif battle.pending_choice.owner==1: after_action()
			if battle.outcome==-1 and battle.pending_choice.is_empty(): end_turn()

func show_battle_history():
	close_inspection()
	inspection=ColorRect.new()
	inspection.color=Color(.02,.05,.06,.94)
	inspection.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(inspection)
	var center=CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	inspection.add_child(center)
	var box=VBoxContainer.new()
	box.custom_minimum_size=Vector2(600,480)
	center.add_child(box)
	label_at(box,"Battle history",30)
	var list=ScrollContainer.new()
	list.custom_minimum_size=Vector2(600,380)
	list.size_flags_vertical=Control.SIZE_EXPAND_FILL
	box.add_child(list)
	var entries=VBoxContainer.new()
	entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	list.add_child(entries)
	if battle.log.is_empty(): label_at(entries,"No actions yet.",16)
	for i in range(battle.log.size()-1,-1,-1):
		label_at(entries,battle.log[i],16)
	button_at(box,"Close",close_inspection)

func close_inspection():
	if is_instance_valid(inspection):
		inspection.hide()
		inspection.queue_free()
	inspection=null

func save_bug_snapshot() -> String:
	var directory=constructed.path.get_base_dir()+"/playtest-reports"
	DirAccess.make_dir_recursive_absolute(directory)
	var path=directory+"/match-%d-%d.json" % [Time.get_unix_time_from_system(),Time.get_ticks_msec()]
	var report={"format":1,"page":page,"seed":match_seed,"deck":constructed.deck.duplicate(),"practice":practice_mode,"catalog":model.cards.duplicate(true)}
	if battle!=null:
		report.battle={"active":battle.active,"turn":battle.turn,"outcome":battle.outcome,"sides":battle.sides.duplicate(true),"log":battle.log.duplicate(),"job":battle.job.duplicate(),"mulligan":battle.mulligan_pending,"first_player":battle.first_player,"pending_choice":battle.pending_choice.duplicate(true),"pending_attack":battle.pending_attack.duplicate(true),"death_queue":battle.death_queue.duplicate(true),"weapon_deaths":battle.weapon_deaths.duplicate(true),"resolving_death":battle.resolving_death.duplicate(true),"timeline":battle.timeline.duplicate(true)}
		report.presentation={"effect_cursor":effect_timeline_cursor,"creature_cursor":creature_feedback.timeline_cursor,"schedule_remaining_seconds":maxf(0.0,effect_schedule_until-Time.get_ticks_usec()/1000000.0),"pending_creature_stats":creature_feedback.stat_steps.duplicate(true),"pending_hero_stats":creature_feedback.hero_steps.duplicate(true),"secret_showing":secret_reveal.showing,"queued_secret_reveals":secret_reveal.queued.duplicate(true)}
	var file=FileAccess.open(path,FileAccess.WRITE)
	if file==null: return ""
	file.store_string(JSON.stringify(report,"\t")); file.close()
	var notice=Label.new()
	notice.text="Match snapshot saved · F8"
	notice.position=Vector2(32,12)
	notice.add_theme_color_override("font_color",UIStyle.GOLD)
	notice.mouse_filter=Control.MOUSE_FILTER_IGNORE
	add_child(notice)
	get_tree().create_timer(3).timeout.connect(notice.queue_free)
	return path

func _input(event):
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F8:
		save_bug_snapshot()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F5:
		choose_look("night" if is_daytime() else "day")
		if not is_daytime(): game_hour=18.0
		else: game_hour=6.0
		render()
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode==KEY_F6:
		classic_look=not classic_look
		choose_look()
		render()
		get_viewport().set_input_as_handled()
		return
	if page=="battle" and event is InputEventKey and event.pressed and not event.echo and event.keycode in [KEY_F1,KEY_F2,KEY_F3,KEY_F4]:
		hit_feel.set_variant(event.keycode-KEY_F1)
		get_viewport().set_input_as_handled()
		return
	if is_instance_valid(inspection):
		if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE:
			close_inspection()
			get_viewport().set_input_as_handled()
		return
	if card_drag_input(event):
		get_viewport().set_input_as_handled()
		return
	if page=="map" and is_instance_valid(world3d) and event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_RIGHT and not event.pressed:
		world3d.orbiting=false
	if page=="map" and is_instance_valid(world3d) and event is InputEventKey:
		world3d.input_event(event)
		get_viewport().set_input_as_handled()
		return
	if event is InputEventKey and not event.pressed:
		held_keys.erase(event.keycode)
		return
	if event is InputEventKey and event.is_pressed() and event.keycode==KEY_ESCAPE and page=="battle" and not selection.is_empty():
		selection=""
		render()
		get_viewport().set_input_as_handled()
		return
	if page!="map" or not event is InputEventKey or not event.is_pressed() or event.is_echo(): return
	match event.keycode:
		KEY_W,KEY_UP,KEY_S,KEY_DOWN,KEY_A,KEY_LEFT,KEY_D,KEY_RIGHT: held_keys[event.keycode]=true
		KEY_E: interact_nearest()
		_: return
	get_viewport().set_input_as_handled()

func _notification(what):
	if what==NOTIFICATION_APPLICATION_FOCUS_OUT:
		cancel_card_drag()
		if is_instance_valid(world3d): world3d.stop_input()
		held_keys.clear()
		route.clear()
		traveling=false

func show_ordered_effects():
	if effect_timeline_battle!=battle:
		effect_timeline_battle=battle; effect_timeline_cursor=0; effect_schedule_until=0.0
	if secret_reveal.observed_battle!=battle: secret_reveal.reset(battle)
	var now=Time.get_ticks_usec()/1000000.0
	var delay=maxf(secret_reveal.remaining_seconds(),effect_schedule_until-now)
	for event in battle.timeline.slice(effect_timeline_cursor):
		effect_event_times[event.sequence]=now+delay
		if event.kind=="secret_state":
			schedule_secret_state(event,delay)
			continue
		if event.kind=="weapon_state":
			schedule_weapon(event,delay)
			delay+=.18
			continue
		if event.kind=="minion_state":
			delay+=.22
			continue
		if event.kind=="summon":
			delay+=.28
			continue
		if event.kind=="death":
			effect_event_times[event.sequence]=now+delay
			delay+=.35
			continue
		if event.kind=="secret":
			schedule_secret(event,delay)
			delay+=secret_reveal.REVEAL_SECONDS
			continue
		if event.kind not in ["combat","spell_hit","heal","buff"]: continue
		if event.kind=="combat": present_combat(event,delay)
		else: present_effect(event.kind,event,delay)
		delay+=hit_feel.SPACING[hit_feel.variant] if event.kind=="combat" else .22
	effect_schedule_until=now+delay
	effect_timeline_cursor=battle.timeline.size()
	secret_reveal.cursor=battle.revealed_secrets.size()
	combat_feedback_battle=battle; combat_feedback_cursor=battle.combat_events.size()
	spell_feedback_battle=battle; spell_feedback_cursor=battle.spell_hits.size()
	healing_feedback_battle=battle; healing_feedback_cursor=battle.healing_events.size()
	buff_feedback_battle=battle; buff_feedback_cursor=battle.buff_events.size()

func schedule_weapon(event: Dictionary,delay: float):
	if not weapon_display.has(event.owner): weapon_display[event.owner]=event.before.duplicate(true)
	var apply=func():
		weapon_display[event.owner]=event.weapon.duplicate(true)
		if is_instance_valid(duel_board): duel_board.update_weapon(event.owner,event.weapon)
	if delay<=0: apply.call(); return
	var marker=Node.new(); marker.name="PendingWeaponState"; add_child(marker)
	var tween=create_tween(); track_battle_effect(marker,tween)
	tween.tween_interval(delay)
	tween.tween_callback(apply)
	tween.tween_callback(marker.queue_free)

func schedule_sound(cue: String,delay: float):
	var owner_battle=battle
	var marker=Node.new()
	marker.name="PendingBattleSound"
	add_child(marker)
	var tween=create_tween()
	track_battle_effect(marker,tween)
	if delay>0: tween.tween_interval(delay)
	tween.tween_callback(func():
		if battle==owner_battle and page=="battle": battle_audio.play_cue(cue)
		marker.queue_free())

func schedule_secret_state(event: Dictionary,delay: float):
	if not secret_display.has(event.owner): secret_display[event.owner]=event.before.duplicate()
	var apply=func():
		secret_display[event.owner]=event.secrets.duplicate()
		if is_instance_valid(duel_board): duel_board.update_secrets(event.owner,event.secrets)
	if delay<=0: apply.call(); return
	var marker=Node.new(); add_child(marker)
	var tween=create_tween(); track_battle_effect(marker,tween)
	tween.tween_interval(delay); tween.tween_callback(apply); tween.tween_callback(marker.queue_free)

func begin_secret_reveal(event: Dictionary):
	var remaining=event.get("remaining",secret_display.get(event.owner,[])).duplicate()
	remaining.erase(event.id)
	secret_display[event.owner]=remaining
	if is_instance_valid(duel_board): duel_board.update_secrets(event.owner,remaining)
	secret_reveal.enqueue_event(battle,event)
	battle_audio.play_cue("secret")

func schedule_secret(event: Dictionary,delay: float):
	if not secret_display.has(event.owner): secret_display[event.owner]=event.get("before",battle.sides[event.owner].get("secrets",[])).duplicate()
	if delay<=0:
		begin_secret_reveal(event)
		return
	var owner_battle=battle
	var marker=Node.new()
	marker.name="PendingSecretReveal"
	add_child(marker)
	var tween=create_tween()
	track_battle_effect(marker,tween)
	tween.tween_interval(delay)
	tween.tween_callback(func():
		if battle==owner_battle and page=="battle":
			begin_secret_reveal(event)
		marker.queue_free())

func show_buffs():
	if buff_feedback_battle!=battle:
		buff_feedback_battle=battle; buff_feedback_cursor=0
	while buff_feedback_cursor<battle.buff_events.size():
		var event=battle.buff_events[buff_feedback_cursor]
		buff_feedback_cursor+=1
		present_effect("buff",event)

func show_healing():
	if healing_feedback_battle!=battle:
		healing_feedback_battle=battle; healing_feedback_cursor=0
	while healing_feedback_cursor<battle.healing_events.size():
		var event=battle.healing_events[healing_feedback_cursor]
		healing_feedback_cursor+=1
		present_effect("heal",event)

func show_spell_hits():
	if spell_feedback_battle!=battle:
		spell_feedback_battle=battle; spell_feedback_cursor=0
	while spell_feedback_cursor<battle.spell_hits.size():
		var event=battle.spell_hits[spell_feedback_cursor]
		spell_feedback_cursor+=1
		present_effect("spell_hit",event)

func effect_point(owner: int,uid: int,fallback: Vector2) -> Vector2:
	if not is_instance_valid(duel_board): return fallback
	var face=target_widgets.get(uid) if owner==1 else duel_board.friendly_faces.get(uid)
	if is_instance_valid(face): return face.get_global_rect().get_center()
	for ghost in creature_feedback.get_children():
		if ghost.get_meta("uid",-2)==uid: return ghost.get_global_rect().get_center()
	return fallback

func present_effect(kind: String,event: Dictionary,delay: float=0.0):
	if not is_instance_valid(duel_board): return
	if kind!="spell_hit":
		var target=target_widgets.get(event.uid) if event.owner==1 else duel_board.friendly_faces.get(event.uid)
		var point=target.get_global_rect().get_center() if is_instance_valid(target) else duel_board.get_global_rect().get_center()
		var anchor=effect_point.bind(event.owner,event.uid,point)
		if kind=="heal": float_feedback("+%d" % event.amount,point,Color("a8e8b0"),delay,anchor)
		else: float_feedback("%+d/%+d" % [event.attack,event.health],point,Color("c6b8ff"),delay,anchor)
		return
	var target=target_widgets.get(event.uid) if event.target_owner==1 else duel_board.friendly_faces.get(event.uid)
	var source=target_widgets.get(-1) if event.owner==1 else duel_board.friendly_faces.get(-1)
	if not is_instance_valid(source): return
	var point=target.get_global_rect().get_center() if is_instance_valid(target) else duel_board.get_global_rect().get_center()
	var source_point=source.get_global_rect().get_center()
	var bolt=Line2D.new()
	bolt.name="SpellHit"
	bolt.width=5
	bolt.default_color={"fire":Color("f7a36c"),"water":Color("79c9ef"),"earth":Color("add18c"),"air":Color("d7c5f8")}.get(event.element,Color.WHITE)
	bolt.points=PackedVector2Array([get_global_transform().affine_inverse()*source.get_global_rect().get_center(),get_global_transform().affine_inverse()*point])
	bolt.z_index=45
	add_child(bolt)
	var tween=create_tween()
	if delay>0:
		bolt.hide()
		tween.tween_interval(delay)
		tween.tween_callback(bolt.show)
	tween.tween_callback(func(): bolt.points=PackedVector2Array([get_global_transform().affine_inverse()*effect_point(event.owner,-1,source_point),get_global_transform().affine_inverse()*effect_point(event.target_owner,event.uid,point)]))
	track_battle_effect(bolt,tween)
	tween.tween_property(bolt,"modulate:a",0.0,.35)
	tween.tween_callback(bolt.queue_free)
	if event.damage>0: float_feedback("−%d" % event.damage,point,Color("ffe0a0"),delay,effect_point.bind(event.target_owner,event.uid,point))

func show_opponent_attacks():
	if combat_feedback_battle!=battle:
		combat_feedback_battle=battle; combat_feedback_cursor=0
	while combat_feedback_cursor<battle.combat_events.size():
		var event=battle.combat_events[combat_feedback_cursor]
		combat_feedback_cursor+=1
		present_combat(event)

func effect_face(owner: int,uid: int):
	if not is_instance_valid(duel_board): return null
	var face=target_widgets.get(uid) if owner==1 else duel_board.friendly_faces.get(uid)
	if is_instance_valid(face): return face
	for ghost in creature_feedback.get_children():
		if ghost.get_meta("uid",-2)==uid: return ghost
	return null

func present_combat(event: Dictionary,delay: float=0.0):
	var feel=hit_feel.variant
	var hit=hit_feel.IMPACT[feel]
	schedule_sound(hit_feel.CUES[feel],delay+hit-hit_feel.CUE_LEAD[feel])
	if not is_instance_valid(duel_board): return
	var source=target_widgets.get(event.uid) if event.owner==1 else duel_board.friendly_faces.get(event.uid)
	var target=duel_board.friendly_faces.get(event.target) if event.owner==1 else target_widgets.get(event.target)
	var from=source.get_global_rect().get_center() if is_instance_valid(source) else duel_board.get_global_rect().get_center()
	var point=target.get_global_rect().get_center() if is_instance_valid(target) else duel_board.get_global_rect().get_center()
	var source_anchor=effect_point.bind(event.owner,event.uid,from)
	var target_anchor=effect_point.bind(1-event.owner,event.target,point)
	if feel!=0:
		var art=source.portrait if event.uid==-1 and is_instance_valid(source) else (UIStyle.hero_art(battle.job.id) if event.uid==-1 else UIStyle.art(event.card))
		if event.get("retaliation",0)>0: hit_feel.number("−%d" % event.retaliation,from,delay+hit,source_anchor)
		hit_feel.strike(art,from,point,delay,source_anchor,target_anchor,effect_face.bind(event.owner,event.uid),effect_face.bind(1-event.owner,event.target),event.uid!=-1)
		if event.damage>0: hit_feel.number("−%d" % event.damage,point,delay+hit,target_anchor)
		return
	if event.get("retaliation",0)>0:
		float_feedback("−%d" % event.retaliation,from,Color("ffe0a0"),delay+.14,source_anchor)
	attack_lunge(event.card if event.uid!=-1 else "",from,point,source.portrait if event.uid==-1 and is_instance_valid(source) else null,delay,source_anchor,target_anchor)
	if event.damage>0: float_feedback("−%d" % event.damage,point,Color("ffe0a0"),delay+.14,target_anchor)

func attack_lunge(card_id: String,from: Vector2,to: Vector2,portrait: Texture2D=null,delay: float=0.0,source_anchor: Callable=Callable(),target_anchor: Callable=Callable()):
	if page!="battle": return
	var ghost=TextureRect.new()
	ghost.name="AttackLunge"
	ghost.texture=portrait if portrait!=null else (UIStyle.hero_art(battle.job.id) if card_id.is_empty() else UIStyle.art(card_id))
	ghost.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
	ghost.size=Vector2(66,66)
	ghost.position=from-ghost.size/2
	ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE
	ghost.z_index=50
	add_child(ghost)
	var tween=create_tween()
	track_battle_effect(ghost,tween)
	if delay>0:
		ghost.hide()
		tween.tween_interval(delay)
		tween.tween_callback(ghost.show)
	var path={"from":from,"to":to}
	tween.tween_callback(func():
		path.from=source_anchor.call() if source_anchor.is_valid() else from
		path.to=target_anchor.call() if target_anchor.is_valid() else to
		ghost.set_meta("path",path.duplicate())
		ghost.position=get_global_transform().affine_inverse()*path.from-ghost.size/2)
	tween.tween_method(func(progress): ghost.position=get_global_transform().affine_inverse()*path.from.lerp(path.to,progress)-ghost.size/2,0.0,1.0,.14).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_property(ghost,"modulate:a",0,.12)
	tween.tween_callback(ghost.queue_free)

func arm_card_drag(data: Dictionary,at: Vector2,source):
	if page!="battle" or thinking or battle.mulligan_pending: return
	drag_candidate=data.duplicate()
	drag_start=at
	drag_source=source

func cancel_card_drag():
	if not drag_payload.is_empty(): suppress_drag_release=true
	if is_instance_valid(drag_source):
		drag_source.modulate.a=1.0
		drag_source.set_pressed_no_signal(false)
	if is_instance_valid(drag_preview): drag_preview.queue_free()
	drag_preview=null
	drag_source=null
	drag_candidate={}
	drag_payload={}

func card_drag_input(event) -> bool:
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT:
		if event.pressed: suppress_drag_release=false
		elif suppress_drag_release:
			suppress_drag_release=false
			return true
	if event is InputEventKey and event.pressed and event.keycode==KEY_ESCAPE and not drag_payload.is_empty():
		cancel_card_drag()
		return true
	if drag_candidate.is_empty() and drag_payload.is_empty(): return false
	if event is InputEventMouseMotion and event.button_mask&MOUSE_BUTTON_MASK_LEFT:
		if drag_payload.is_empty() and event.position.distance_to(drag_start)>8 and is_instance_valid(drag_source):
			drag_payload=drag_candidate.duplicate()
			selection=""
			drag_source.modulate.a=.35
			drag_source.set_pressed_no_signal(false)
			if drag_payload.get("kind")=="attack" and drag_payload.get("uid")==-1:
				drag_preview=TextureRect.new()
				drag_preview.texture=drag_source.portrait
				drag_preview.expand_mode=TextureRect.EXPAND_IGNORE_SIZE
				drag_preview.custom_minimum_size=Vector2(90,74)
			else:
				drag_preview=CardFace.new()
				drag_preview.card=drag_source.card
				drag_preview.compact=drag_source.compact
				drag_preview.custom_minimum_size=Vector2(130,178) if not drag_preview.compact else Vector2(100,94)
			drag_preview.mouse_filter=Control.MOUSE_FILTER_IGNORE
			drag_preview.z_index=100
			add_child(drag_preview)
			drag_preview.size=drag_preview.custom_minimum_size
		if not drag_payload.is_empty():
			drag_preview.position=event.position-drag_preview.size/2
			duel_board.drag_pointer=event.position-duel_board.global_position
			return true
	if event is InputEventMouseButton and event.button_index==MOUSE_BUTTON_LEFT and not event.pressed:
		if drag_payload.is_empty():
			drag_candidate={}
			drag_source=null
			return false
		var data=drag_payload.duplicate()
		cancel_card_drag()
		suppress_drag_release=false
		if page!="battle" or thinking: return true
		var at=event.position-duel_board.global_position
		if duel_board.untargeted_drag(data):
			if duel_board._can_drop_data(at,data): duel_board._drop_data(at,data)
		else:
			for uid in target_widgets:
				if target_widgets[uid].get_global_rect().has_point(event.position) and duel_board.accepts_enemy(data,uid):
					duel_board.drop_enemy(data,uid)
					break
		return true
	return false
