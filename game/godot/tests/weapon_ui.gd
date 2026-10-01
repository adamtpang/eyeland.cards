extends "res://tests/friendly_targets.gd"
func run():
	create_timer(30).timeout.connect(func(): quit(1))
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://weapon-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","earth"); game.page="deck"
	game.start_practice("earth","",false,0); game.confirm_opening()
	var b=game.battle
	b.sides[0].hand=["earth-earthen-spear"]; b.sides[0].mana=3
	game.render(); game.play_card(0)
	await process_frame; await process_frame
	check(not game.duel_board.friendly_faces[-1].disabled,"Equipped hero becomes interactive")
	var weapon_face=game.duel_board.get_node("PlayerWeapon")
	check(weapon_face.card.id=="earth-earthen-spear" and weapon_face.current_attack==3 and weapon_face.current_health==2,"Equipped weapon displays art and live stats")
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/equipped-weapon.png"))
	await drag(game.duel_board.friendly_faces[-1].get_global_rect().get_center(),game.target_widgets[-1].get_global_rect().get_center())
	check(b.sides[1].hp==27 and b.sides[0].weapon.durability==1,"Physical hero drag deals damage and spends durability")
	check(game.duel_board.friendly_faces[-1].disabled,"Spent hero cannot attack again")
	await wait_for_feedback(game)
	check(game.duel_board.get_node("PlayerWeapon").current_health==1,"Weapon portrait updates remaining durability")
	b.end_turn(0); b.end_turn(1); game.render()
	await process_frame; await process_frame
	game.duel_board.get_node("PlayerWeapon").pressed.emit()
	game.target_widgets[-1].pressed.emit()
	check(b.sides[1].hp==24 and b.sides[0].weapon.is_empty(),"Click hero attack breaks last durability")
	check(game.duel_board.friendly_faces[-1].disabled,"Unarmed hero disabled")
	await wait_for_feedback(game)
	check(game.duel_board.get_node_or_null("PlayerWeapon")==null,"Broken weapon portrait disappears")
	check(b.sides[0].armor==2 and b.log.has("Earthen Spear triggers Deathrattle."),"Native weapon Deathrattle grants armor on break")
	b.sides[0].hand=["earth-earthen-spear","earth-earthen-spear"]; b.sides[0].mana=6
	game.play_card(0); game.play_card(0)
	check(b.sides[0].armor==4 and b.sides[0].weapon.durability==2,"Replacement resolves old native Deathrattle and preserves new weapon")
	await wait_for_feedback(game)
	b.end_turn(0); b.end_turn(1)
	b.summon(1,"home-breeze-finch")
	var defender=b.sides[1].board[0]
	b.sides[0].weapon.durability=1
	game.render(); await process_frame; await process_frame
	game.duel_board.get_node("PlayerWeapon").pressed.emit()
	game.target_widgets[defender.uid].pressed.emit()
	var retaliation=game.get_children().filter(func(n): return n is Label and n.text=="−2")
	check(retaliation.size()==1,"Hero retaliation displays actual incoming damage")
	check(game.get_children().filter(func(n): return n is Label and n.text=="−3").size()==1,"Overkill displays weapon's actual three damage once")
	check(b.sides[0].hp==30 and b.sides[0].armor==4 and b.sides[0].weapon.is_empty(),"Armor absorbs retaliation before broken weapon restores two Armor")
	game.queue_free(); await process_frame
	await create_timer(.1).timeout
	print("WEAPON UI: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)

func wait_for_feedback(game):
	var deadline=Time.get_ticks_msec()+5000
	while game.feedback_busy() and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout
