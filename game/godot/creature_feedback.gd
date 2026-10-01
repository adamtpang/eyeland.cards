extends Control
var observed_battle
var previous: Dictionary={}
var animations: Array=[]
var timeline_cursor=0
var summon_times: Dictionary={}
var stat_steps: Dictionary={}
var shown_stats: Dictionary={}
var hero_steps: Dictionary={}
var hero_shown: Dictionary={}
var previous_heroes: Dictionary={}
var movement_tracks: Dictionary={}
var current_game

func _ready():
	mouse_filter=Control.MOUSE_FILTER_IGNORE
	z_index=40

func reset():
	for tween in animations:
		if tween.is_valid(): tween.kill()
	animations.clear(); previous.clear(); summon_times.clear(); stat_steps.clear(); shown_stats.clear(); hero_steps.clear(); hero_shown.clear(); previous_heroes.clear(); movement_tracks.clear(); current_game=null; observed_battle=null; timeline_cursor=0
	for child in get_children(): remove_child(child); child.queue_free()

func capture(game):
	if game.page!="battle" or observed_battle!=game.battle:
		reset(); observed_battle=game.battle if game.page=="battle" else null
		return
	previous.clear()
	for owner in [0,1]:
		var label=game.duel_board.get_node_or_null("HeroStats%d" % owner)
		if label!=null: previous_heroes[owner]=label.get_meta("state").duplicate()
	for uid in game.target_widgets:
		var face=game.target_widgets[uid]
		if uid<0 or not is_instance_valid(face): continue
		previous[uid]={"card":face.card.duplicate(true),"rect":face.get_global_rect(),"attack":face.current_attack,"health":face.current_health,"divine_shield":face.shield_active,"state":face.get_meta("display_state",{})}

func present(game):
	if game.page!="battle": return
	current_game=game
	animations=animations.filter(func(t): return t.is_valid() and t.is_running())
	var events=game.battle.timeline.slice(timeline_cursor)
	timeline_cursor=game.battle.timeline.size()
	queue_stat_updates(game,events)
	queue_board_movement(game,events)
	var transient_events=events.filter(func(event): return event.kind=="summon" and not previous.has(event.uid) and not game.target_widgets.has(event.uid))
	if not transient_events.is_empty(): show_transients(game,transient_events,events)
	for event in events:
		if event.kind=="summon": summon_times[event.uid]=game.effect_event_times.get(event.sequence,0.0)
	for uid in game.target_widgets:
		var delay=maxf(0.0,summon_times.get(uid,0.0)-Time.get_ticks_usec()/1000000.0)
		if uid<0 or (previous.has(uid) and delay<=0): continue
		var face=game.target_widgets[uid]
		face.pivot_offset=face.size/2
		face.scale=Vector2(.65,.65)
		var tween=face.create_tween()
		animations.append(tween)
		if delay>0:
			face.hide()
			tween.tween_interval(delay)
			tween.tween_callback(face.show)
		tween.tween_property(face,"scale",Vector2.ONE,.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	for uid in previous:
		if game.target_widgets.has(uid): continue
		var state=previous[uid]
		var ghost=preload("res://card_face.gd").new()
		ghost.name="DepartingCreature"
		ghost.set_meta("uid",uid)
		ghost.card=state.card; ghost.compact=true
		ghost.current_attack=state.attack; ghost.current_health=state.health
		ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE; ghost.focus_mode=Control.FOCUS_NONE
		ghost.position=state.rect.position-global_position; ghost.size=state.rect.size
		add_child(ghost)
		ghost.pivot_offset=ghost.size/2
		schedule_portrait_layouts(game,{uid:ghost},events)
		var tween=create_tween()
		animations.append(tween)
		var delay=0.0
		for event in events:
			if event.kind=="death" and event.uid==uid:
				delay=maxf(0.0,game.effect_event_times.get(event.sequence,0.0)-Time.get_ticks_usec()/1000000.0)
		if delay>0: tween.tween_interval(delay)
		tween.tween_callback(func(): ghost.current_health=0; ghost.queue_redraw())
		tween.set_parallel(true)
		tween.tween_property(ghost,"scale",Vector2(.75,.75),.35)
		tween.tween_property(ghost,"modulate:a",0.0,.35)
		tween.tween_property(ghost,"position:y",ghost.position.y+20,.35)
		tween.chain().tween_callback(ghost.queue_free)

func queue_board_movement(game,events: Array):
	var now=Time.get_ticks_usec()/1000000.0
	for owner in [0,1]:
		for m in game.battle.sides[owner].board:
			var face=game.target_widgets.get(m.uid)
			if not is_instance_valid(face): continue
			var origin=previous[m.uid].rect.position-face.get_parent().global_position if previous.has(m.uid) else face.position
			if not movement_tracks.has(m.uid): movement_tracks[m.uid]=[]
			var track=movement_tracks[m.uid]
			var cursor=now if track.is_empty() else track[-1].finish
			var point=origin if track.is_empty() else track[-1].to
			var born=previous.has(m.uid)
			for event in events:
				if event.kind not in ["summon","death"] or event.owner!=owner or not event.get("layout",[]).has(m.uid): continue
				var layout=event.layout
				var destination=Vector2(game.duel_board.size.x/2-face.size.x/2+(layout.find(m.uid)-(layout.size()-1)/2.0)*105,face.position.y)
				if not born:
					origin=destination; point=destination; face.position=destination; born=true
					continue
				var at=maxf(cursor,game.effect_event_times.get(event.sequence,now)+(.35 if event.kind=="death" else 0.0))
				if point.distance_to(destination)<1: continue
				track.append({"start":at,"finish":at+.22,"from":point,"to":destination})
				cursor=at+.22; point=destination
			if not track.is_empty():
				face.set_meta("layout_active",true)
				face.position=origin
			else: movement_tracks.erase(m.uid)
	_process(0)

func queue_stat_updates(game,events: Array):
	for event in events:
		if event.kind=="hero_state":
			var owner=event.owner
			if not hero_shown.has(owner): hero_shown[owner]=previous_heroes.get(owner,event).duplicate()
			if not hero_steps.has(owner): hero_steps[owner]=[]
			hero_steps[owner].append({"at":game.effect_event_times.get(event.sequence,0.0),"state":event.duplicate()})
		var updates=[]
		if event.kind in ["buff","heal","spell_hit","minion_state"] and not event.get("state",{}).is_empty():
			updates.append({"uid":event.uid,"state":event.state})
		elif event.kind=="combat":
			if not event.get("source_state",{}).is_empty(): updates.append({"uid":event.uid,"state":event.source_state})
			if not event.get("target_state",{}).is_empty(): updates.append({"uid":event.target,"state":event.target_state})
		for update in updates:
			var uid=update.uid
			if not game.target_widgets.has(uid): continue
			if not shown_stats.has(uid):
				var initial=previous.get(uid,{"attack":update.state.atk,"health":update.state.hp,"divine_shield":update.state.get("divine_shield",false)})
				for born in events:
					if born.kind=="summon" and born.uid==uid: initial={"attack":born.minion.atk,"health":born.minion.hp,"divine_shield":born.minion.get("divine_shield",false),"state":born.minion}
				shown_stats[uid]=initial.get("state",{}).duplicate(true)
				shown_stats[uid].merge({"atk":initial.attack,"hp":initial.health,"divine_shield":initial.get("divine_shield",false)},true)
			if not stat_steps.has(uid): stat_steps[uid]=[]
			var at=game.effect_event_times.get(event.sequence,0.0)+(.14 if event.kind=="combat" else 0.0)
			stat_steps[uid].append({"at":at,"state":update.state.duplicate(true)})
	_process(0)

func _process(_delta):
	if not is_instance_valid(current_game) or current_game.page!="battle": return
	var now=Time.get_ticks_usec()/1000000.0
	for uid in movement_tracks.keys():
		var track=movement_tracks[uid]
		var face=current_game.target_widgets.get(uid)
		if not is_instance_valid(face): movement_tracks.erase(uid); continue
		while not track.is_empty() and track[0].finish<=now:
			face.position=track.pop_front().to
		if track.is_empty():
			movement_tracks.erase(uid); face.remove_meta("layout_active")
		else:
			var step=track[0]
			var progress=clampf((now-step.start)/.22,0,1)
			face.position=step.from.lerp(step.to,1-pow(1-progress,2))
	for owner in hero_steps.keys():
		var steps=hero_steps[owner]
		while not steps.is_empty() and steps[0].at<=now: hero_shown[owner]=steps.pop_front().state
		var label=current_game.duel_board.get_node_or_null("HeroStats%d" % owner)
		if label!=null:
			label.text="♥ %d   ◇ %d" % [hero_shown[owner].hp,hero_shown[owner].armor]
			label.set_meta("state",hero_shown[owner].duplicate())
			var portrait=current_game.target_widgets.get(-1) if owner==1 else current_game.duel_board.friendly_faces.get(-1)
			if is_instance_valid(portrait):
				portrait.modulate=Color("8ecde8") if hero_shown[owner].get("frozen",false) else Color.WHITE
				portrait.tooltip_text=(current_game.battle.job.name+" hero") if owner==0 else current_game.battle.enemy_name
				if hero_shown[owner].get("frozen",false): portrait.tooltip_text+="\nFrozen: cannot attack until an attack opportunity is missed."
		if steps.is_empty(): hero_steps.erase(owner); hero_shown.erase(owner)
	for uid in stat_steps.keys():
		var steps=stat_steps[uid]
		while not steps.is_empty() and steps[0].at<=now:
			shown_stats[uid]=steps.pop_front().state
		var face=current_game.target_widgets.get(uid)
		if is_instance_valid(face):
			face.current_attack=shown_stats[uid].atk
			face.current_health=shown_stats[uid].hp
			face.shield_active=shown_stats[uid].get("divine_shield",false)
			face.card.taunt=shown_stats[uid].get("taunt",false)
			face.status="FROZEN" if shown_stats[uid].get("frozen",false) else ("SILENCED" if shown_stats[uid].get("silenced",false) else "")
			face.modulate=Color("8ecde8") if shown_stats[uid].get("frozen",false) else Color.WHITE
			if shown_stats[uid].get("stealth",false): face.modulate.a=.55
			face.tooltip_text=face.card.name+"\n"+("Silenced: printed abilities and enchantments removed." if shown_stats[uid].get("silenced",false) else face.card.get("text",""))
			if shown_stats[uid].get("frozen",false): face.tooltip_text+="\nFrozen: misses its next attack."
			if shown_stats[uid].get("aura_attack",0)>0 or shown_stats[uid].get("aura_health",0)>0:
				face.tooltip_text+="\nActive auras: +%d Attack / +%d Health." % [shown_stats[uid].get("aura_attack",0),shown_stats[uid].get("aura_health",0)]
			face.set_meta("display_state",shown_stats[uid].duplicate(true))
			face.queue_redraw()
		if steps.is_empty(): stat_steps.erase(uid); shown_stats.erase(uid)

# One sequence preserves cross-creature order instead of racing per-creature tweens.
func schedule_portrait_layouts(game,ghosts: Dictionary,events: Array):
	for event in events:
		if event.kind not in ["summon","death"]: continue
		var layout=event.get("layout",[])
		for uid in ghosts:
			if uid==event.uid or not layout.has(uid): continue
			var ghost=ghosts[uid]
			var delay=maxf(0.0,game.effect_event_times.get(event.sequence,0.0)+(.35 if event.kind=="death" else 0.0)-Time.get_ticks_usec()/1000000.0)
			var x=game.duel_board.global_position.x+game.duel_board.size.x/2+(layout.find(uid)-(layout.size()-1)/2.0)*105-50-global_position.x
			var movement=create_tween()
			animations.append(movement)
			if delay>0: movement.tween_interval(delay)
			movement.tween_property(ghost,"position:x",x,.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func show_transients(game,summons: Array,events: Array):
	var ghosts={}
	for summoned in summons: ghosts[summoned.uid]=make_transient(game,summoned)
	schedule_portrait_layouts(game,ghosts,events)
	for event in events:
		var uid=event.get("uid",-1)
		if not ghosts.has(uid): continue
		var ghost=ghosts[uid]
		var tween=create_tween()
		animations.append(tween)
		var delay=maxf(0.0,game.effect_event_times.get(event.sequence,0.0)-Time.get_ticks_usec()/1000000.0)
		if delay>0: tween.tween_interval(delay)
		if event.kind=="summon":
			tween.tween_callback(ghost.show)
			tween.tween_property(ghost,"scale",Vector2.ONE,.28)
		else:
			tween.tween_callback(apply_transient.bind(ghost,event))
			if event.kind=="death":
				tween.tween_property(ghost,"modulate:a",0.0,.35)
				tween.tween_callback(ghost.queue_free)

func make_transient(game,summoned: Dictionary):
	var ghost=preload("res://card_face.gd").new()
	ghost.name="TransientCreature"
	ghost.card=game.battle.cards[summoned.id].duplicate(true); ghost.compact=true
	set_transient_state(ghost,summoned.minion)
	ghost.mouse_filter=Control.MOUSE_FILTER_IGNORE; ghost.focus_mode=Control.FOCUS_NONE
	ghost.size=Vector2(100,94)
	var count=summoned.get("layout",[]).size()
	if count==0: count=int(summoned.position)+1
	var local_point=Vector2(game.duel_board.size.x/2+(summoned.position-(count-1)/2.0)*105-50,148 if summoned.owner==1 else 251)
	ghost.position=game.duel_board.global_position+local_point-global_position
	add_child(ghost)
	ghost.set_meta("uid",summoned.uid)
	ghost.pivot_offset=ghost.size/2; ghost.scale=Vector2(.65,.65)
	ghost.visible=false
	return ghost

func apply_transient(ghost,event: Dictionary):
	if not is_instance_valid(ghost): return
	if event.kind in ["minion_state","spell_hit","heal","buff"] and not event.get("state",{}).is_empty():
		set_transient_state(ghost,event.state)
	elif event.kind=="death":
		ghost.current_health=0; ghost.status=""
	ghost.queue_redraw()

func set_transient_state(ghost,state: Dictionary):
	ghost.current_attack=state.atk; ghost.current_health=maxi(0,int(state.hp))
	ghost.shield_active=state.get("divine_shield",false)
	ghost.card.taunt=state.get("taunt",false)
	ghost.status="FROZEN" if state.get("frozen",false) else ("SILENCED" if state.get("silenced",false) else "")
	ghost.modulate=Color("8ecde8") if state.get("frozen",false) else Color.WHITE
	if state.get("stealth",false): ghost.modulate.a=.55
