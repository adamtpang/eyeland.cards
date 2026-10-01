extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	create_timer(20).timeout.connect(func(): printerr("Secret choice UI timeout"); quit(1))
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://secret-choice-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	var trap=b.cards["earth-pebble-ward"].duplicate(true)
	trap.id="test-choice"; trap.name="Choice Trap"
	trap.secret.effects=[{"effect":"discover"},{"effect":"gainArmor","amount":2}]
	b.cards[trap.id]=trap
	b.sides[0].secrets=[trap.id,"earth-pebble-ward"]
	b.active=1; b.sides[1].hand=[]; b.sides[1].mana=0
	b.sides[1].weapon={"attack":2,"durability":2}
	game.run_opponent_turn()
	await create_timer(.8).timeout
	check(not b.pending_choice.is_empty() and not b.pending_attack.is_empty() and game.thinking,"Opponent attack opens player choice and waits")
	check(b.sides[1].weapon.durability==2 and b.sides[0].armor==0,"Combat has not spent durability or resolved remaining effects")
	if b.pending_choice.is_empty(): quit(1); return
	check(game.duel_board.get_node_or_null("DiscoverOption0")==null and not game.choice_clock_running,"Choice and its clock wait for Secret reveal")
	game.choose_presented_card(0)
	check(not b.pending_choice.is_empty(),"Early choice callback cannot skip presentation")
	var choice_deadline=Time.get_ticks_msec()+5000
	while game.duel_board.get_node_or_null("DiscoverOption0")==null and Time.get_ticks_msec()<choice_deadline:
		await create_timer(.05).timeout
	var offered=b.pending_choice.offers.duplicate()
	var faces=[]
	for node in game.duel_board.get_children():
		if node.get_script()==preload("res://card_face.gd") and offered.has(node.card.id): faces.append(node)
	check(faces.size()==3,"Three illustrated choice cards displayed")
	await process_frame; await process_frame
	if faces.size()!=3: quit(1); return
	var point=faces[1].get_global_rect().get_center()
	var motion=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion)
	await create_timer(.15).timeout
	for down in [true,false]:
		var event=InputEventMouseButton.new()
		event.position=point; event.button_index=MOUSE_BUTTON_LEFT; event.pressed=down
		event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
		root.push_input(event)
		await process_frame
	check(b.pending_choice.is_empty() and b.pending_attack.is_empty() and b.sides[0].hand.has(offered[1]),"Native mouse selection resumes attack during opponent turn")
	check(b.sides[0].armor==8 and b.sides[1].weapon.durability==1,"Remaining effects and combat resolve once")
	var deadline=Time.get_ticks_msec()+6000
	while game.thinking and Time.get_ticks_msec()<deadline:
		await create_timer(.1).timeout
	check(b.active==0 and not game.thinking,"Opponent finishes turn after resumed attack")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("SECRET CHOICE UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
