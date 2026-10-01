extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://transient-status-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	await create_timer(.5).timeout
	var b=game.battle
	b.summon(1,"water-shellback-tortoise")
	var m=b.sides[1].board[0]
	var hp=m.hp
	b.deal_damage(0,1,m.uid,1,{"type":"spell","element":"fire"})
	b.silence_minion(1,m.uid)
	b.deal_damage(0,1,m.uid,20,{"type":"spell","element":"fire"}); b.clean(); game.after_action()
	var ghost=game.creature_feedback.get_node("TransientCreature")
	check(ghost.shield_active and ghost.current_health==hp,"Intermediate summon starts with original Shield and stats")
	await create_timer(.36).timeout
	check(not ghost.shield_active and ghost.current_health==hp,"Absorbed hit removes transient Shield without health loss")
	await create_timer(.24).timeout
	check(ghost.status=="SILENCED" and not ghost.card.taunt,"Transient Silence clears abilities in sequence")
	await create_timer(.5).timeout
	check(is_instance_valid(ghost) and ghost.current_health==0,"Final transient death shows zero health")
	await create_timer(.4).timeout
	check(game.creature_feedback.get_child_count()==0,"Transient status sequence clears")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("TRANSIENT STATUS UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
