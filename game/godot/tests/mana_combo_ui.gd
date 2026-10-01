extends SceneTree
var checks=0
var failures=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+label)
func label_contains(node: Node,text: String) -> bool:
	if node is Label and text in node.text: return true
	for child in node.get_children():
		if label_contains(child,text): return true
	return false
func _initialize(): call_deferred("run")
func run():
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://mana-combo-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	game.battle.sides[0].mana=3; game.battle.sides[0].max_mana=3
	game.battle.sides[0].hand=["air-gust-bolt","fire-flame-lance"]
	game.render()
	await process_frame; await process_frame
	check(not game.duel_board.hand_faces[1].active_hint,"Combo starts inactive")
	var hero_center=game.target_widgets[-1].get_global_rect().get_center()
	game.play_card(0); game.target_enemy(-1)
	var feedback=game.get_node_or_null("DamageFeedback")
	check(feedback!=null and (feedback.global_position+Vector2(25,20)).distance_to(hero_center)<2,"Immediate selection refresh retains target feedback position")
	check(game.duel_board.hand_faces[0].active_hint and game.duel_board.hand_faces[0].status=="COMBO READY","Successful card activates hand feedback")
	check(label_contains(game.duel_board,"Overload 1"),"Pending Overload visible")
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/combo-ready.png"))
	game.battle.end_turn(0); game.battle.end_turn(1); game.render()
	check(not game.duel_board.hand_faces[0].active_hint,"Next turn clears Combo feedback")
	check(label_contains(game.duel_board,"▣") and not label_contains(game.duel_board,"Overload 1"),"Locked crystal replaces pending debt")
	check(game.battle.sides[0].mana==3 and game.battle.sides[0].max_mana==4,"Displayed turn uses actual locked mana")
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/overload-locked.png"))
	game.queue_free(); await process_frame
	print("MANA COMBO UI: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
