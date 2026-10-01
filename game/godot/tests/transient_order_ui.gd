extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://transient-order-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	await process_frame; await process_frame
	await create_timer(.5).timeout
	var b=game.battle
	b.resolve_effects(0,[{"effect":"summon","card":"home-breeze-finch","amount":2},{"effect":"damageBoard","amount":4}],b.cards["home-spark"])
	b.clean(); game.after_action()
	var ghosts=game.creature_feedback.get_children()
	check(ghosts.size()==2,"Both intermediate creatures retained for playback")
	var center=game.duel_board.global_position.x+game.duel_board.size.x/2-game.duel_board.token_size().x/2-game.creature_feedback.global_position.x
	check(absf(ghosts[0].position.x-center)<1,"First transient starts centered in its one-creature layout")
	await create_timer(.1).timeout
	check(ghosts[0].visible and not ghosts[1].visible,"Second summon waits for first summon animation")
	await create_timer(.2).timeout
	check(ghosts[1].visible and ghosts[0].current_health==2 and ghosts[1].current_health==2,"Both summons precede either hit")
	await create_timer(.35).timeout
	check(ghosts[0].current_health==0 and ghosts[1].current_health==2,"Hits follow recorded cross-creature order")
	check(absf(ghosts[0].position.x-(center-game.duel_board.gap()/2))<1 and absf(ghosts[1].position.x-(center+game.duel_board.gap()/2))<1,"Transient portraits follow two-creature intermediate layout")
	game.render()
	check(game.creature_feedback.get_child_count()==2,"Redraw preserves single shared sequence")
	await create_timer(1.5).timeout
	check(game.creature_feedback.get_child_count()==0,"Both deaths finish and remove their portraits")
	b.resolve_effects(0,[{"effect":"summon","card":"home-breeze-finch","amount":2},{"effect":"damageBoard","amount":4}],b.cards["home-spark"])
	b.clean(); game.after_action(); game.page="deck"; game.render()
	await create_timer(.5).timeout
	check(game.creature_feedback.get_child_count()==0 and game.creature_feedback.animations.is_empty(),"Leaving cancels queued cross-creature callbacks")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("TRANSIENT ORDER UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
