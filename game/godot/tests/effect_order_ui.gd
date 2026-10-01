extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://effect-order-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(0,"home-breeze-finch"); game.after_action()
	await create_timer(.6).timeout
	var minion=b.sides[0].board[0]
	minion.hp=1
	b.heal_character(0,minion.uid,1)
	b.deal_damage(1,0,minion.uid,1,{"type":"spell","element":"fire"})
	b.buff_creature(0,minion.uid,1,2)
	game.after_action()
	var labels=game.get_children().filter(func(n): return n is Label and n.text in ["+1","−1","+1/+2"])
	check(labels.size()==3,"All three effects retain their feedback")
	check(labels[0].text=="+1" and labels[0].visible and not labels[1].visible and not labels[2].visible,"Healing precedes damage and buff despite separate event types")
	await create_timer(.28).timeout
	check(labels[1].visible and not labels[2].visible,"Damage starts second")
	await create_timer(.25).timeout
	check(labels[2].visible,"Buff starts third")
	var count=game.get_child_count(); game.show_ordered_effects()
	check(game.get_child_count()==count,"Repeated observation does not duplicate queued feedback")
	game.page="deck"; game.render()
	await create_timer(.6).timeout
	check(game.battle_effects.is_empty() and not game.feedback_busy(),"Leaving cancels delayed feedback and clears busy state")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("EFFECT ORDER UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
