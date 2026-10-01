extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://status-timing-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	var b=game.battle
	b.summon(1,"water-shellback-tortoise"); game.after_action()
	await create_timer(.6).timeout
	var uid=b.sides[1].board[0].uid
	b.record_event("secret",{"owner":1,"id":"earth-pebble-ward"})
	b.resolve_effects(0,[{"effect":"freezeEnemies"}],b.cards["home-spark"])
	b.silence_minion(1,uid); game.after_action()
	check(game.target_widgets[uid].status=="" and game.target_widgets[uid].shield_active,"Status retains pre-effect appearance during Secret")
	game.render()
	check(not "Silenced:" in game.target_widgets[uid].tooltip_text,"Hover does not reveal future Silence early")
	await create_timer(2.0).timeout
	check(game.target_widgets[uid].status=="FROZEN" and game.target_widgets[uid].modulate==Color("8ecde8"),"Freeze tint and label appear in sequence")
	await create_timer(.3).timeout
	check(game.target_widgets[uid].status=="SILENCED" and not game.target_widgets[uid].shield_active and game.target_widgets[uid].modulate==Color.WHITE,"Silence removes Shield and Freeze at its scheduled step")
	check("Silenced:" in game.target_widgets[uid].tooltip_text,"Hover matches displayed Silence")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("STATUS TIMING UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
