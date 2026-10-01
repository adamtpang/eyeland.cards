extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	create_timer(15).timeout.connect(func(): quit(1))
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://offturn-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(0,"air-wispwing")
	b.sides[0].board[0].deathrattle=[{"effect":"discover"}]
	b.sides[0].board[0].hp=0
	b.active=1; b.sides[1].hand=[]; b.sides[1].mana=0
	b.clean(); game.after_action(); game.run_opponent_turn()
	await create_timer(.7).timeout
	check(not b.pending_choice.is_empty() and b.pending_choice.owner==0 and b.active==1,"Opponent waits for player's death choice")
	var deadline=Time.get_ticks_msec()+5000
	while game.duel_board.get_node_or_null("DiscoverOption0")==null and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout
	var id=b.pending_choice.offers[0]
	var chosen=false
	for node in game.duel_board.get_children():
		if node.get_script()==preload("res://card_face.gd") and node.card.id==id:
			node.pressed.emit(); chosen=true; break
	check(chosen and b.pending_choice.is_empty(),"Player can select during opponent turn")
	await create_timer(.7).timeout
	check(b.active==0 and not game.thinking,"Opponent resumes and passes turn")
	b.summon(1,"air-wispwing"); b.sides[1].board[0].deathrattle=[{"effect":"discover"}]; b.sides[1].board[0].hp=0
	b.clean(); game.after_action()
	check(b.pending_choice.is_empty() and b.sides[1].hand.size()==1,"Opponent resolves its choice during player's turn")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("OFFTURN CHOICE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
