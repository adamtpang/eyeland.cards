extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://creature-fx-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	await process_frame; await process_frame
	var b=game.battle
	b.summon(0,"home-breeze-finch"); b.summon(1,"home-breeze-finch")
	game.after_action()
	check(game.target_widgets[b.sides[0].board[0].uid].scale.x<1 and game.target_widgets[b.sides[1].board[0].uid].scale.x<1,"Both sides animate newly summoned creatures")
	await create_timer(.65).timeout
	check(game.target_widgets[b.sides[0].board[0].uid].scale==Vector2.ONE,"Summon settles at exact token size")
	game.render()
	check(game.target_widgets[b.sides[0].board[0].uid].scale==Vector2.ONE,"Selection redraw does not replay summon")
	b.sides[0].board[0].hp=0; b.sides[1].board[0].hp=0; b.clean(); game.after_action()
	check(game.creature_feedback.get_child_count()==2,"Both dead creatures leave departing portraits")
	for ghost in game.creature_feedback.get_children():
		check(ghost.mouse_filter==Control.MOUSE_FILTER_IGNORE,"Departing portrait cannot intercept targeting")
	await create_timer(.85).timeout
	check(game.creature_feedback.get_child_count()==0,"Death portraits clear after animation")
	b.resolve_effects(0,[{"effect":"summon","card":"home-breeze-finch","amount":1},{"effect":"damageBoard","amount":4}],b.cards["home-spark"])
	b.clean(); game.after_action()
	var transient=game.creature_feedback.get_node_or_null("TransientCreature")
	check(transient!=null and transient.current_health==2 and b.sides[0].board.is_empty(),"Same-action summon/death shows original creature despite empty final board")
	await create_timer(.35).timeout
	check(is_instance_valid(transient) and transient.current_health==0,"Recorded hit updates transient creature after summon")
	game.render()
	check(game.creature_feedback.get_child_count()==1,"Redraw does not duplicate transient playback")
	await create_timer(.7).timeout
	check(game.creature_feedback.get_child_count()==0,"Transient creature disappears after its death sequence")
	game.page="deck"; game.render()
	check(game.creature_feedback.observed_battle==null,"Leaving battle clears feedback context")
	game.queue_free(); await process_frame; await create_timer(.1).timeout
	print("CREATURE FEEDBACK UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
