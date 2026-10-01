extends Control
const UIStyle=preload("res://skin.gd")
var game
var hand_faces=[]
var friendly_faces={}
var drag_slot=-1
var field_drag=false
var drag_pointer=Vector2.ZERO
var board_art: Texture2D

func place(node: Control, x: float, y: float, dimensions: Vector2):
	node.custom_minimum_size=dimensions
	node.anchor_left=x
	node.anchor_right=x
	node.offset_left=-dimensions.x/2
	node.offset_right=dimensions.x/2
	node.offset_top=y
	node.offset_bottom=y+dimensions.y
	node.size=dimensions
	return node

func caption(value: String,x: float,y: float,width=220,font_size=12):
	var label=game.label_at(self,value,font_size)
	label.mouse_filter=Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	place(label,x,y,Vector2(width,24))
	if game.stage_active(): game.hud_outline(label)
	return label

func hero(id: String, side: int, y: float):
	var state=game.battle.sides[side]
	var button=preload("res://hero_art_button.gd").new()
	button.name="PlayerHeroPortrait" if side==0 else "EnemyHeroPortrait"
	button.portrait=UIStyle.hero_art(game.battle.job.id) if side==0 else UIStyle.art(id)
	add_child(button)
	button.pressed.connect(func(): game.target_enemy(-1))
	button.disabled=side==0 or not game.target_allowed(-1)
	if side==0:
		button.disabled=game.thinking or game.battle.mulligan_pending or game.battle.attack_targets(0,-1).is_empty()
		button.pressed.disconnect(button.pressed.get_connections()[0].callable)
		button.pressed.connect(func(): game.selection="attack"; game.selected=-1; game.render())
		button.arm_drag=game.arm_card_drag
		button.drag_payload={"kind":"attack","uid":-1}
		friendly_faces[-1]=button
	if side==1:
		button.accepts=func(data): return accepts_enemy(data,-1)
		button.dropped=func(data): drop_enemy(data,-1)
	place(button,.5,y,Vector2(108,88))
	button.tooltip_text=(game.battle.job.name+" hero") if side==0 else game.battle.enemy_name
	if state.get("frozen",false):
		button.modulate=Color("8ecde8")
		button.tooltip_text+="\nFrozen: cannot attack until an attack opportunity is missed."
	if not UIStyle.P.board_art:
		# a name-plate under the portrait keeps health readable in the day and night looks
		var stat_plate=Panel.new()
		var stat_box=UIStyle.box(UIStyle.P.token_plate,UIStyle.P.token_idle,UIStyle.P.plate_r+3,0)
		stat_box.set_border_width_all(UIStyle.P.plate_w)
		stat_plate.add_theme_stylebox_override("panel",stat_box)
		stat_plate.mouse_filter=Control.MOUSE_FILTER_IGNORE
		add_child(stat_plate)
		place(stat_plate,.5,y+75,Vector2(98,23))
	var health=caption("♥ %d   ◇ %d" % [state.hp,state.armor],.5,y+69 if UIStyle.P.board_art else y+75,120,16 if UIStyle.P.board_art else 15)
	health.name="HeroStats%d" % side
	health.set_meta("state",{"hp":state.hp,"armor":state.armor,"frozen":state.get("frozen",false)})
	health.mouse_filter=Control.MOUSE_FILTER_IGNORE
	if UIStyle.P.board_art:
		health.add_theme_color_override("font_color",UIStyle.P.stat_text)
		health.add_theme_constant_override("outline_size",5)
		health.add_theme_color_override("font_outline_color",UIStyle.P.stat_outline)
	else:
		# a name-plate keeps health readable over any portrait
		health.add_theme_color_override("font_color",UIStyle.P.token_plate_text)
	if side==1: game.target_widgets[-1]=button
	update_secrets(side,game.secret_display.get(side,state.get("secrets",[])))
	update_weapon(side,game.weapon_display.get(side,state.get("weapon",{})))

func update_secrets(side: int,secrets: Array):
	for child in get_children():
		if str(child.name).begins_with("SecretMarker%d_" % side): remove_child(child); child.queue_free()
	var y=348 if side==0 else 45
	for i in range(secrets.size()):
		var marker=caption("?",.5,y-18,22,18)
		marker.name="SecretMarker%d_%d" % [side,i]
		marker.position.x+=(i-(secrets.size()-1)/2.0)*25
		marker.mouse_filter=Control.MOUSE_FILTER_STOP
		marker.tooltip_text=game.battle.cards[secrets[i]].name+"\n"+game.battle.cards[secrets[i]].text if side==0 else "Opponent Secret"

func update_weapon(side: int,weapon: Dictionary):
	var old=get_node_or_null("PlayerWeapon" if side==0 else "EnemyWeapon")
	if old!=null: remove_child(old); old.queue_free()
	var y=348 if side==0 else 45

	if not weapon.is_empty():
		if game.battle.cards.has(weapon.get("id","")):
			var weapon_face=game.card_button(self,weapon.id,func():
				game.selection="attack"; game.selected=-1; game.render(),get_node("PlayerHeroPortrait").disabled if side==0 else true,"WEAPON",true)
			weapon_face.name="PlayerWeapon" if side==0 else "EnemyWeapon"
			weapon_face.current_attack=int(weapon.attack)
			weapon_face.current_health=int(weapon.durability)
			weapon_face.tooltip_text+="\n"+("Select your hero or weapon to attack." if side==0 else "Opponent's equipped weapon.")
			if side==0:
				weapon_face.arm_drag=game.arm_card_drag
				weapon_face.drag_payload={"kind":"attack","uid":-1}
			place(weapon_face,.36,y,Vector2(100,94))
		else:
			var weapon_label=caption("⚔ %d / %d" % [weapon.attack,weapon.durability],.36,y+26,130,20)
			weapon_label.name="PlayerWeapon" if side==0 else "EnemyWeapon"
			weapon_label.tooltip_text="%d Attack · %d Durability" % [weapon.attack,weapon.durability]

func _ready():
	board_art=load("res://assets/battle-board.png")
	custom_minimum_size=Vector2(900,626)
	size_flags_horizontal=Control.SIZE_EXPAND_FILL
	resized.connect(queue_redraw)
	var battle=game.battle
	var yours=battle.sides[0]
	var theirs=battle.sides[1]
	for i in range(theirs.hand.size()):
		var back=Panel.new()
		var back_box=UIStyle.box(UIStyle.P.back,UIStyle.P.back_edge,7,0)
		back_box.set_border_width_all(maxi(1,UIStyle.P.edge_w-1))
		back.add_theme_stylebox_override("panel",back_box)
		add_child(back)
		place(back,.5, -18+absf(i-(theirs.hand.size()-1)/2.0)*2,Vector2(44,57))
		back.position.x+= (i-(theirs.hand.size()-1)/2.0)*29
		back.rotation=(i-(theirs.hand.size()-1)/2.0)*.06
		back.mouse_filter=Control.MOUSE_FILTER_IGNORE

	caption(("PRACTICE · " if game.practice_mode else "")+"TURN %d" % ceili(battle.turn/2.0),.13,38,180,12)
	place(game.button_at(self,"Retreat",game.confirm_retreat,game.thinking),.91,14,Vector2(102,36))
	var sound=game.button_at(self,"Sound off" if game.battle_audio.muted else "Sound on",func(): game.battle_audio.toggle(); game.render())
	place(sound,.08,395,Vector2(105,34))
	sound.tooltip_text="Toggle battle sounds for this session."
	hero(game.model.starter(CollectionElement()) if game.practice_mode else "home-resin-crab",1,45)
	var enemy_power=preload("res://hero_art_button.gd").new()
	enemy_power.portrait=UIStyle.hero_art(battle.job.id,true)
	enemy_power.is_power=true
	enemy_power.disabled=true
	enemy_power.used=theirs.power_used
	enemy_power.tooltip_text="Opponent: "+battle.job.power+"\n"+battle.job.description
	add_child(enemy_power)
	place(enemy_power,.63,48,Vector2(66,66))
	for side in [1,0]:
		var board=battle.sides[side].board
		var y=148 if side==1 else 251

		for i in range(board.size()):
			var m=board[i]
			var enabled=game.target_allowed(m.uid) if side==1 else (not game.thinking and not battle.attack_targets(0,m.uid).is_empty() and not battle.mulligan_pending)
			var action=func(): game.target_enemy(m.uid)
			if side==0: action=func(): game.selection="attack"; game.selected=m.uid; game.render()
			if side==0 and game.selection=="spell":
				enabled=game.target_allowed(m.uid)
				action=func(): game.target_enemy(m.uid)
			var face=game.card_button(self,m.id,action,not enabled,"",true)
			face.set_meta("display_state",m.duplicate(true))
			face.current_attack=m.atk
			face.current_health=m.hp
			face.card=face.card.duplicate(true)
			face.card.taunt=m.get("taunt",false)
			if m.get("silenced",false):
				face.status="SILENCED"
				face.tooltip_text="%s\nSilenced: printed abilities and enchantments removed." % face.card.name
			if m.get("aura_attack",0)>0 or m.get("aura_health",0)>0:
				face.tooltip_text+="\nActive auras: +%d Attack / +%d Health." % [m.get("aura_attack",0),m.get("aura_health",0)]
			face.shield_active=m.get("divine_shield",false)
			if m.get("frozen",false):
				face.modulate=Color("8ecde8")
				face.status="FROZEN"
				face.tooltip_text+="\nFrozen: misses its next attack."
			if m.get("stealth",false): face.modulate.a=0.55
			place(face,.5,y,Vector2(100,94))
			face.position.x+=(i-(board.size()-1)/2.0)*105
			if side==1:
				game.target_widgets[m.uid]=face
				face.accepts=func(data): return accepts_enemy(data,m.uid)
				face.dropped=func(data): drop_enemy(data,m.uid)
			else:
				friendly_faces[m.uid]=face
				face.drag_payload={"kind":"attack","uid":m.uid}
				face.arm_drag=game.arm_card_drag
				game.target_widgets[m.uid]=face
				face.accepts=func(data): return accepts_enemy(data,m.uid)
				face.dropped=func(data): drop_enemy(data,m.uid)
			if side==0 and game.selection=="attack" and game.selected==m.uid: face.chosen=true
	hero(game.model.starter(game.model.profile.element),0,348)
	var power_button=preload("res://hero_art_button.gd").new()
	power_button.name="HeroPower"
	power_button.portrait=UIStyle.hero_art(battle.job.id,true)
	power_button.is_power=true
	power_button.disabled=game.thinking or yours.mana<2 or yours.power_used or battle.mulligan_pending
	power_button.available=not power_button.disabled
	power_button.used=yours.power_used
	power_button.text=battle.job.power
	power_button.tooltip_text=battle.job.power+"\n"+battle.job.description+"\nOnce per turn."
	if yours.power_used: power_button.tooltip_text+="\nAlready used this turn."
	elif game.thinking: power_button.tooltip_text+="\nWait for your turn."
	elif yours.mana<2: power_button.tooltip_text+="\nYou need %d more mana." % (2-yours.mana)
	power_button.pressed.connect(game.use_power)
	add_child(power_button)
	place(power_button,.63,348,Vector2(82,82))


	var end=game.button_at(self,"Opponent's turn" if game.thinking else "End turn",game.end_turn,game.thinking or battle.mulligan_pending)
	place(end,.91,236,Vector2(132,52))
	if not end.disabled: UIStyle.primary(end)
	for side in [1,0]:
		var pile=Panel.new()
		var pile_box=UIStyle.box(UIStyle.P.pile,UIStyle.P.pile_edge,7,0)
		pile_box.set_border_width_all(UIStyle.P.edge_w)
		pile_box.shadow_color=UIStyle.P.shadow; pile_box.shadow_size=UIStyle.P.shadow_size; pile_box.shadow_offset=UIStyle.P.shadow_offset
		pile.add_theme_stylebox_override("panel",pile_box)
		add_child(pile)
		place(pile,.91,110 if side==1 else 330,Vector2(72,96))
		var pile_count=caption(str(battle.sides[side].deck.size()),.91,143 if side==1 else 363,70,18)
		pile_count.add_theme_color_override("font_color",UIStyle.P.stat_text)
		pile_count.add_theme_constant_override("outline_size",5)
		pile_count.add_theme_color_override("font_outline_color",UIStyle.P.stat_outline)
		pile.tooltip_text="%d cards remaining" % battle.sides[side].deck.size()
	var locked=int(yours.get("locked_mana",0))
	var mana_label=caption("◆".repeat(yours.mana)+"◇".repeat(maxi(0,yours.max_mana-yours.mana-locked))+"▣".repeat(locked)+"  %d/%d" % [yours.mana,yours.max_mana],.84,438,260,15)
	mana_label.add_theme_color_override("font_color",UIStyle.P.mana_text)
	mana_label.mouse_filter=Control.MOUSE_FILTER_STOP
	mana_label.tooltip_text="%d mana locked this turn.\nOverload: %d mana locked next turn." % [locked,int(yours.get("overload",0))]
	if yours.get("overload",0)>0: caption("Overload %d" % yours.overload,.84,460,180,13).modulate=Color("e8ba76")
	game.timer_bar=ProgressBar.new()
	game.timer_bar.max_value=75
	game.timer_bar.value=game.clock_left
	game.timer_bar.show_percentage=false
	add_child(game.timer_bar)
	place(game.timer_bar,.5,241,Vector2(640,3))
	game.timer_bar.add_theme_stylebox_override("background",UIStyle.box(UIStyle.P.timer_bg,Color.TRANSPARENT,1,0))
	game.timer_bar.add_theme_stylebox_override("fill",UIStyle.box(UIStyle.GOLD if UIStyle.P.board_art else Color(UIStyle.P.board_edge,.55),Color.TRANSPARENT,1,0))
	game.timer_label=caption("",.91,292,100,12)
	var count=yours.hand.size()
	for i in range(count):
		var combo_ready=battle.cards[yours.hand[i]].has("combo") and yours.get("cards_played",0)>0
		var face=game.card_button(self,yours.hand[i],func(): game.play_card(i),game.thinking or not battle.can_play(0,i),"COMBO READY" if combo_ready else "IN HAND")
		face.active_hint=combo_ready
		place(face,.5,446,Vector2(130,178))
		face.position.x+=(i-(count-1)/2.0)*minf(137,720.0/maxi(1,count-1))
		face.set_hand_available(not face.disabled)
		face.set_hand_hover(not battle.mulligan_pending and battle.pending_choice.is_empty() and game.selection!="choice")
		face.drag_payload={"kind":"hand","index":i}
		face.arm_drag=game.arm_card_drag
		hand_faces.append(face)
	var history=game.button_at(self,"⋯",game.show_battle_history)
	place(history,.08,290,Vector2(88,36))
	history.tooltip_text="\n".join(battle.log.slice(maxi(0,battle.log.size()-8))) if not battle.log.is_empty() else "No actions yet."
	var report=game.button_at(self,"Report bug",func(): game.save_bug_snapshot())
	place(report,.08,340,Vector2(105,36))
	report.tooltip_text="F8 saves the current match state and recent actions locally. Tell Codex what felt wrong."
	if battle.mulligan_pending: opening_hand()
	elif game.player_choice_ready(): discover_screen()
	elif game.selection=="choice": choice_screen()

func discover_screen():
	var veil=ColorRect.new()
	veil.color=Color(.025,.06,.065,.96)
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption("Discover",.5,100,600,34)
	if game.battle.active==1:
		game.choice_timer_label=caption("75s",.5,145,100,16)
		game.choice_timer_label.tooltip_text="Choose a card before time expires. The first option is selected automatically."
	var offers=game.battle.pending_choice.offers
	for i in range(offers.size()):
		var index=i
		var card=game.card_button(self,offers[i],func(): game.choose_presented_card(index))
		card.name="DiscoverOption%d" % index
		place(card,.5,195,Vector2(166,228))
		card.position.x+=(i-(offers.size()-1)/2.0)*195

func choice_screen():
	var veil=ColorRect.new()
	veil.color=Color(.025,.06,.065,.96)
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption("Choose One",.5,110,600,34)
	var card=game.battle.cards[game.battle.sides[0].hand[game.selected]]
	for i in range(card.choices.size()):
		var option=card.choices[i]
		var index=i
		var button=preload("res://card_face.gd").new()
		button.name="ChooseOneOption%d" % index
		button.card=card.duplicate(true)
		button.card.name=option.name
		button.card.text=option.text
		button.pressed.connect(func():
			if game.battle.play(0,game.selected,-1,-1,index): game.after_action())
		add_child(button)
		place(button,.5,190,Vector2(166,228))
		button.position.x+=(i-(card.choices.size()-1)/2.0)*210
	var cancel=game.button_at(self,"Cancel",func(): game.selection=""; game.render())
	place(cancel,.5,445,Vector2(160,44))

func opening_hand():
	var veil=ColorRect.new()
	veil.color=Color(.025,.06,.065,.96)
	add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	caption("Your opening hand",.5,90,600,38)
	caption("You play first" if game.battle.first_player==0 else "You play second · The Coin is yours",.5,145,600,18)
	tooltip_text="Select cards to replace. The Coin cannot be replaced."
	var hand=game.battle.sides[0].hand
	for i in range(hand.size()):
		var index=i
		var coin=hand[i]=="the-coin"
		var action=func():
			if game.mulligan_picks.has(index): game.mulligan_picks.erase(index)
			elif game.mulligan_picks.size()<game.battle.sides[0].deck.size(): game.mulligan_picks.append(index)
			game.render()
		var card=game.card_button(self,hand[i],action,coin,"SELECTED" if game.mulligan_picks.has(i) else "KEEP")
		place(card,.5,199,Vector2(166,228))
		card.position.x+=(i-(hand.size()-1)/2.0)*175
	var begin=game.button_at(self,"Replace %d & begin" % game.mulligan_picks.size() if not game.mulligan_picks.is_empty() else "Keep hand & begin",game.confirm_opening)
	place(begin,.5,463,Vector2(240,48))
	UIStyle.primary(begin)

func _draw():
	var p=UIStyle.P
	if p.board_art and board_art:
		draw_texture_rect(board_art,Rect2(0,0,size.x,626),false)
	elif game.stage_active():
		# On the island stage the table disappears: two soft lanes hold the creatures and the
		# 3D scene shows through everywhere else.
		var day=UIStyle.mode=="day"
		for lane_y in [140,247]:
			var lane=UIStyle.box(Color(p.panel if day else p.ink,.2 if day else .42),Color(p.board_edge,.3 if day else .35),22 if day else 6,0)
			lane.set_border_width_all(2 if day else 1)
			draw_style_box(lane,Rect2(size.x*.14,lane_y,size.x*.69,104))
	else:
		var table=UIStyle.box(p.board,p.board_edge,p.board_r,0)
		table.set_border_width_all(p.board_edge_w)
		table.shadow_color=p.shadow; table.shadow_size=p.shadow_size; table.shadow_offset=p.shadow_offset*1.5
		draw_style_box(table,Rect2(2,0,size.x-4,622))
		var middle=Vector2(size.x/2,241)
		if UIStyle.mode=="night":
			# engraved chart: faint diagonal hatching and two compass rings
			var step=18.0
			var x=-622.0
			while x<size.x:
				draw_line(Vector2(maxf(x,6),maxf(6,-x)),Vector2(minf(x+616,size.x-6),minf(616,size.x-6-x)),Color(p.board_edge,.035),1)
				x+=step
			draw_circle(middle,210,Color(0.56,0.5,0.96,.05))
			draw_arc(middle,196,0,TAU,96,p.board_mark,1.5,true)
			draw_arc(middle,206,0,TAU,96,Color(p.board_mark,.14),1,true)
			for i in range(8): draw_line(middle+Vector2.from_angle(i*TAU/8)*196,middle+Vector2.from_angle(i*TAU/8)*214,p.board_mark,1.5,true)
		else:
			# sunlit table: a pale play circle and a soft sky band behind the opponent
			draw_style_box(UIStyle.box(Color(1,1,1,.32),Color(1,1,1,0),p.board_r-6,0),Rect2(8,6,size.x-16,118))
			draw_circle(middle,204,Color(1,1,1,.36))
			draw_arc(middle,204,0,TAU,96,p.board_mark,3,true)
	draw_line(Vector2(size.x*.16,241),Vector2(size.x*.81,241),p.board_mark,1 if p.board_art else 2)



	if field_drag:
		draw_style_box(UIStyle.box(Color(.3,.8,.65,.06),UIStyle.TEAL,30,0),Rect2(size.x*.12,135,size.x*.73,300))
	if drag_slot>=0:
		var x=size.x/2+(drag_slot-game.battle.sides[0].board.size()/2.0)*105
		draw_style_box(UIStyle.box(Color(.3,.8,.65,.18),UIStyle.TEAL,20,0),Rect2(x-47,249,94,98))
	draw_targeting()

func accepts_enemy(data: Variant,uid: int) -> bool:
	if not data is Dictionary or game.thinking or game.battle.mulligan_pending: return false
	if data.get("kind")=="attack":
		return game.battle.attack_targets(0,data.uid).has(uid)
	if data.get("kind")=="hand" and game.battle.can_play(0,data.index):
		var card=game.battle.cards[game.battle.sides[0].hand[data.index]]
		return card.get("targeting","")=="optionalCreature" and game.battle.card_targets(0,card).has(uid)
	return false

func drop_enemy(data: Dictionary,uid: int):
	game.selection="attack" if data.kind=="attack" else "spell"
	game.selected=data.uid if data.kind=="attack" else data.index
	game.target_enemy(uid)

func _can_drop_data(at: Vector2,data: Variant) -> bool:
	if not data is Dictionary or data.get("kind")!="hand" or game.thinking: return false
	if at.y<135 or at.y>435 or at.x<size.x*.12 or at.x>size.x*.85 or not game.battle.can_play(0,data.index): return false
	return game.battle.cards[game.battle.sides[0].hand[data.index]].get("targeting","")!="optionalCreature"

func _drop_data(at: Vector2,data: Variant):
	if not _can_drop_data(at,data): return
	if game.battle.cards[game.battle.sides[0].hand[data.index]].has("choices"):
		game.play_card(data.index); return
	if game.battle.play(0,data.index,-1,insertion_slot(at.x)): game.after_action()

func insertion_slot(x: float) -> int:
	var count=game.battle.sides[0].board.size()
	return clampi(roundi((x-size.x/2)/105.0+count/2.0),0,count)

func untargeted_drag(data: Variant) -> bool:
	if not data is Dictionary or data.get("kind")!="hand" or game.thinking: return false
	if not game.battle.can_play(0,data.index): return false
	return game.battle.cards[game.battle.sides[0].hand[data.index]].get("targeting","")!="optionalCreature"

func _process(_delta):
	var data=game.drag_payload
	var can_drop=untargeted_drag(data)
	field_drag=can_drop
	var creature=can_drop and game.battle.cards[game.battle.sides[0].hand[data.index]].get("type","")=="minion"
	drag_slot=insertion_slot(drag_pointer.x) if creature and _can_drop_data(drag_pointer,data) else -1
	var count=game.battle.sides[0].board.size()
	for i in range(count):
		var face=friendly_faces[game.battle.sides[0].board[i].uid]
		if face.has_meta("layout_active"):
			if drag_slot<0: continue
			game.creature_feedback.movement_tracks.erase(game.battle.sides[0].board[i].uid)
			face.remove_meta("layout_active")
		var offset=(i-(count-1)/2.0)*105
		if drag_slot>=0: offset=(i+(1 if i>=drag_slot else 0)-count/2.0)*105
		face.position.x=size.x/2-face.size.x/2+offset
	for uid in game.target_widgets:
		var widget=game.target_widgets[uid]
		var valid=accepts_enemy(data,uid)
		if widget.get_script()==preload("res://card_face.gd"):
			widget.chosen=valid
			widget.queue_redraw()
		else:
			var frozen=get_node("HeroStats1").get_meta("state").get("frozen",false)
			widget.modulate=Color(1.2,1.2,.9) if valid else (Color("8ecde8") if frozen else Color.WHITE)
	queue_redraw()

func draw_targeting():
	var origin=Vector2.ZERO
	var active=false
	var data=game.drag_payload
	if data is Dictionary and data.get("kind")=="attack" and friendly_faces.has(data.uid):
		origin=friendly_faces[data.uid].position+friendly_faces[data.uid].size/2
		active=true
	elif data is Dictionary and data.get("kind")=="hand" and data.index<hand_faces.size():
		origin=hand_faces[data.index].position+hand_faces[data.index].size/2
		active=not untargeted_drag(data)
	elif game.selection=="attack" and friendly_faces.has(game.selected):
		origin=friendly_faces[game.selected].position+friendly_faces[game.selected].size/2
		active=true
	elif game.selection in ["spell","power"]:
		origin=Vector2(size.x/2,420)
		active=true
	if active:
		var destination=drag_pointer if not game.drag_payload.is_empty() else get_local_mouse_position()
		var direction=(destination-origin).normalized()
		draw_line(origin,destination,UIStyle.P.arrow,5,true)
		draw_colored_polygon(PackedVector2Array([destination,destination-direction.rotated(.5)*20,destination-direction.rotated(-.5)*20]),UIStyle.P.arrow)


func CollectionElement() -> String:
	var elements=["air","water","fire","earth"]
	return elements[(elements.find(game.practice_element)+1)%4]
