extends "res://tests/friendly_targets.gd"
func run():
	create_timer(30).timeout.connect(func(): quit(1))
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://discover-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.sides[0].hand=["air-windfall"]; b.sides[0].mana=2
	game.render(); game.play_card(0)
	check(not b.pending_choice.is_empty() and b.sides[0].mana==0,"Paid Discover opens")
	var offered=b.pending_choice.offers.duplicate()
	b.summon(0,offered[1]); game.render()
	var deadline=Time.get_ticks_msec()+5000
	while not game.player_choice_ready() and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout
	game.render()
	var option_faces=[]
	for node in game.duel_board.get_children():
		if node.get_script()==preload("res://card_face.gd") and str(node.name).begins_with("DiscoverOption"): option_faces.append(node)
	check(option_faces.size()==3,"Three illustrated offers visible")
	game.end_turn()
	check(b.active==0 and not game.thinking,"End turn blocked during paid choice")
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/discover.png"))
	option_faces[1].pressed.emit()
	check(b.pending_choice.is_empty() and b.sides[0].hand==[offered[1]],"Selected offer enters hand and closes modal")
	b.sides[0].hand=["air-windfall"]; b.sides[0].mana=2; game.play_card(0)
	var timed_offer=b.pending_choice.offers[0]
	deadline=Time.get_ticks_msec()+5000
	while not game.player_choice_ready() and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout
	game.clock_left=0
	game._process(.1)
	check(b.pending_choice.is_empty() and b.sides[0].hand.has(timed_offer) and b.active==1,"Rope resolves outstanding choice before passing turn")
	game.page="deck"
	game.queue_free(); await process_frame
	print("DISCOVER UI: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
