extends "res://tests/friendly_targets.gd"
func find_option(node: Node,name: String):
	for child in node.get_children():
		if child.get_script()==preload("res://card_face.gd") and child.card.name==name: return child
	return null
func run():
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://choice-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","earth"); game.page="deck"
	game.start_practice("earth","",false,0); game.confirm_opening()
	var b=game.battle
	b.sides[0].hand=["earth-deep-roots"]; b.sides[0].mana=2
	game.render(); await process_frame; await process_frame
	await drag(game.duel_board.hand_faces[0].get_global_rect().get_center(),game.duel_board.global_position+Vector2(game.duel_board.size.x/2,220))
	check(game.selection=="choice" and b.sides[0].mana==2,"Drag opens choice without payment")
	check(find_option(game.duel_board,"Grow")!=null and find_option(game.duel_board,"Shelter")!=null,"Illustrated options are present")
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/choose-one.png"))
	var escape=InputEventKey.new(); escape.keycode=KEY_ESCAPE; escape.pressed=true; root.push_input(escape)
	check(game.selection.is_empty() and b.sides[0].hand.size()==1 and b.sides[0].mana==2,"Escape cancels without cost")
	game.play_card(0)
	find_option(game.duel_board,"Shelter").pressed.emit()
	check(b.sides[0].armor==6 and b.sides[0].mana==0 and b.sides[0].hand.is_empty(),"Selecting option pays and resolves")
	check(b.best_option(0,b.cards["earth-deep-roots"])==0,"AI favors early ramp")
	b.sides[0].max_mana=10
	check(b.best_option(0,b.cards["earth-deep-roots"])==1,"AI avoids ramp at mana cap")
	game.queue_free(); await process_frame
	print("CHOICE UI: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
