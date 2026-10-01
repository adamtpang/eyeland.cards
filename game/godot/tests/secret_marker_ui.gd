extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://secret-marker-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","earth"); game.page="deck"
	game.start_practice("earth","",false,0); game.confirm_opening()
	await create_timer(.5).timeout
	var b=game.battle
	b.active=1; b.sides[1].mana=10; b.sides[1].hand=["earth-pebble-ward"]
	check(b.play(1,0),"Real opponent Secret can be played")
	game.after_action()
	check(game.duel_board.get_node("SecretMarker1_0").tooltip_text=="Opponent Secret","Opponent marker hides identity")
	b.record_event("secret",{"owner":0,"id":"earth-pebble-ward"})
	b.active=0; b.sides[0].weapon={"attack":2,"durability":2}
	check(b.attack(0,-1,-1) and b.sides[1].secrets.is_empty(),"Attack consumes real Secret in engine")
	game.after_action(); game.render()
	check(game.duel_board.get_node_or_null("SecretMarker1_0")!=null,"Queued reveal retains marker through redraw")
	await create_timer(.5).timeout
	check(game.duel_board.get_node("SecretMarker1_0").tooltip_text=="Opponent Secret","Waiting marker still hides identity")
	await create_timer(1.7).timeout
	check(game.duel_board.get_node_or_null("SecretMarker1_0")==null,"Marker disappears when its reveal begins")
	await create_timer(2.2).timeout
	b.active=1; b.sides[1].mana=10; b.sides[1].hand=["earth-pebble-ward"]
	check(b.play(1,0),"Consumed Secret can be played again")
	game.after_action()
	check(game.duel_board.get_node_or_null("SecretMarker1_0")!=null,"Replayed Secret restores marker from scheduled state")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("SECRET MARKER UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
