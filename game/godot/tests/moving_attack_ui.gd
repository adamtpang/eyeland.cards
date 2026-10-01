extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://moving-attack-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(0,"water-reef-otter"); b.summon(1,"home-breeze-finch"); game.after_action()
	await create_timer(1.0).timeout
	var attacker=b.sides[0].board[0]; attacker.ready=true; attacker.summoning_sick=false
	var target=b.sides[1].board[0].uid
	var before=game.target_widgets[target].get_global_rect().get_center()
	b.summon(1,"home-breeze-finch"); b.attack(0,attacker.uid,target); game.after_action()
	var lunge=game.get_node("AttackLunge")
	check(not lunge.visible,"Attack waits for preceding summon")
	await create_timer(.35).timeout
	var path=lunge.get_meta("path")
	var departed=game.creature_feedback.get_children().filter(func(n): return n.get_meta("uid",-1)==target)[0]
	check(path.to.distance_to(departed.get_global_rect().get_center())<2 and path.to.distance_to(before)>40,"Lunge aims at relocated departing defender")
	check(path.from.distance_to(game.duel_board.friendly_faces[attacker.uid].get_global_rect().get_center())<2,"Lunge starts at current attacker location")
	game.page="deck"; game.render(); await create_timer(.4).timeout
	check(game.battle_effects.is_empty(),"Queued attack clears on leaving")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("MOVING ATTACK UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
