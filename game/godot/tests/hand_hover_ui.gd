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
	game.model.save_path="user://hand-hover-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	game.battle.sides[0].hand=["air-gust-bolt","air-windfall"]; game.battle.sides[0].mana=1; game.render()
	await process_frame; await process_frame
	var face=game.duel_board.hand_faces[1]
	var motion=InputEventMouseMotion.new(); motion.position=face.get_global_rect().get_center(); root.push_input(motion)
	await create_timer(.2).timeout
	check(face.scale.is_equal_approx(Vector2(1.3,1.3)) and face.z_index==30,"Native hover enlarges and raises hand card")
	check(face.disabled and face.unavailable_in_hand,"Unaffordable card remains gray and unplayable while inspected")
	motion=InputEventMouseMotion.new(); motion.position=Vector2(10,10); root.push_input(motion)
	await create_timer(.2).timeout
	check(face.scale==Vector2.ONE and face.z_index==0,"Leaving restores hand geometry")
	game.battle.sides[0].mana=2; game.play_card(1)
	check(game.duel_board.hand_faces.all(func(f): return not f.hand_hover),"Choice modal prevents hand raising over its veil")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("HAND HOVER UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
