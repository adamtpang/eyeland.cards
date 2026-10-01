extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://effect-queue-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	await create_timer(.5).timeout
	var b=game.battle
	# Two presentation events deliberately isolate scheduling from Secret rules.
	b.record_event("secret",{"owner":0,"id":"earth-pebble-ward"})
	b.record_event("secret",{"owner":1,"id":"air-fresh-breeze"})
	game.after_action()
	b.sides[0].hp=29; b.heal_character(0,-1,1); game.after_action()
	var heal=game.get_children().filter(func(n): return n is Label and n.text=="+1")[0]
	check(not heal.visible,"Follow-up action queues behind pending Secret reveals")
	await create_timer(2.2).timeout
	check(game.secret_reveal.get_child_count()==1 and game.secret_reveal.get_child(0).card.id=="air-fresh-breeze","Second queued reveal runs")
	check(not heal.visible,"Follow-up healing cannot overtake second reveal")
	await create_timer(1.8).timeout
	check(heal.visible,"Follow-up healing starts after both reveals")
	game.page="deck"; game.render()
	check(game.effect_schedule_until==0.0 and not game.feedback_busy(),"Leaving clears queued time and effects")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("EFFECT QUEUE UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
