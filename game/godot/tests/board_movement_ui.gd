extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://board-movement-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	for i in range(3): b.summon(0,"home-breeze-finch")
	game.after_action(); await create_timer(1.2).timeout
	var uid=b.sides[0].board[0].uid
	var before=game.target_widgets[uid].position.x
	b.record_event("secret",{"owner":0,"id":"earth-pebble-ward"})
	b.sides[0].board[1].hp=0; b.clean(); game.after_action()
	check(absf(game.target_widgets[uid].position.x-before)<1,"Neighbor retains its old location during Secret")
	game.render(); await create_timer(.5).timeout
	check(absf(game.target_widgets[uid].position.x-before)<1,"Redraw preserves pending movement")
	await create_timer(1.9).timeout
	check(game.target_widgets[uid].position.x>before and game.target_widgets[uid].position.x<before+52.5,"Neighbor slides after departure instead of snapping")
	await create_timer(.3).timeout
	check(absf(game.target_widgets[uid].position.x-before-52.5)<1,"Neighbor settles in centered two-creature row")
	check(not game.target_widgets[uid].has_meta("layout_active"),"Completed movement releases drag layout")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("BOARD MOVEMENT UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
