extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures+=1; push_error(label)
func _initialize(): call_deferred("run")
func drag(from: Vector2,to: Vector2):
	await create_timer(.15).timeout
	var motion=InputEventMouseMotion.new(); motion.position=from; root.push_input(motion)
	await process_frame
	var down=InputEventMouseButton.new(); down.position=from; down.button_index=MOUSE_BUTTON_LEFT; down.button_mask=MOUSE_BUTTON_MASK_LEFT; down.pressed=true
	root.push_input(down)
	for i in range(1,11):
		motion=InputEventMouseMotion.new(); motion.position=from.lerp(to,i/10.0); motion.relative=(to-from)/10; motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion); await create_timer(.025).timeout
	var up=InputEventMouseButton.new(); up.position=to; up.button_index=MOUSE_BUTTON_LEFT; up.pressed=false; root.push_input(up)
	await process_frame; await process_frame
func run():
	create_timer(30).timeout.connect(func(): quit(1))
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://friendly-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.sides[0].hand=["air-feather-ward"]; b.sides[0].mana=1
	check(not b.can_play(0,0),"Buff unavailable without friendly creature")
	b.summon(0,"fire-cinder-moth"); b.summon(1,"home-breeze-finch")
	var friendly=b.sides[0].board[0]; var enemy=b.sides[1].board[0]
	check(b.card_targets(0,b.cards["air-feather-ward"])==[friendly.uid],"Friendly Stealth can be targeted")
	check(not b.play(0,0,enemy.uid) and not b.play(0,0,-1) and b.sides[0].mana==1 and b.sides[0].hand.size()==1,"Illegal enemy and hero targets preserve resources")
	game.render(); game.play_card(0)
	check(game.target_allowed(friendly.uid) and not game.target_allowed(enemy.uid) and not game.target_allowed(-1),"Click targeting matches engine")
	check(game.duel_board.accepts_enemy({"kind":"hand","index":0},friendly.uid) and not game.duel_board.accepts_enemy({"kind":"hand","index":0},enemy.uid),"Drag targeting matches engine")
	game.duel_board.drop_enemy({"kind":"hand","index":0},friendly.uid)
	check(friendly.atk==3 and friendly.hp==3 and b.sides[0].hand.is_empty(),"Friendly drop applies buff and spends card")
	check(friendly.stealth,"Buff does not break friendly Stealth")
	check(game.get_children().any(func(n): return n is Label and n.text=="+1/+2"),"Targeted buff displays stat gain")
	b.sides[0].hand=["air-feather-ward"]; b.sides[0].mana=1; game.render()
	await process_frame; await process_frame
	await drag(game.duel_board.hand_faces[0].get_global_rect().get_center(),game.target_widgets[enemy.uid].get_global_rect().get_center())
	check(b.sides[0].hand.size()==1 and b.sides[0].mana==1 and enemy.atk==2,"Physical enemy drop is rejected")
	await drag(game.duel_board.hand_faces[0].get_global_rect().get_center(),game.target_widgets[friendly.uid].get_global_rect().get_center())
	check(b.sides[0].hand.is_empty() and friendly.atk==4 and friendly.hp==5,"Physical friendly drop applies buff")
	await create_timer(.75).timeout
	b.resolve_effects(1,[{"effect":"buffAll","attack":2,"health":3}],b.cards["air-feather-ward"]); game.after_action()
	check(game.get_children().any(func(n): return n is Label and n.text=="+2/+3"),"Opponent board buff displays stat gain")
	var event_count=b.buff_events.size()
	enemy.hp=0
	b.buff_creature(1,enemy.uid,1,2)
	check(enemy.hp==0 and b.buff_events.size()==event_count,"Buff does not revive a mortally wounded creature")
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/friendly-buff.png"))
	game.queue_free(); await process_frame
	await create_timer(.1).timeout
	print("FRIENDLY TARGETS: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
