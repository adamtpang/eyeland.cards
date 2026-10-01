extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://weapon-replace-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","earth"); game.page="deck"
	game.start_practice("earth","",false,0); game.confirm_opening()
	await create_timer(.5).timeout
	var b=game.battle
	for owner in [0,1]:
		b.active=owner; b.sides[owner].mana=6; b.sides[owner].hand=["earth-earthen-spear","earth-earthen-spear"]
		b.play(owner,0); game.after_action(); await create_timer(.4).timeout
		var old_uid=b.sides[owner].weapon.uid
		b.record_event("secret",{"owner":owner,"id":"earth-pebble-ward"})
		b.play(owner,0); game.after_action()
		var new_uid=b.sides[owner].weapon.uid
		check(new_uid!=old_uid and game.weapon_display[owner].uid==old_uid,"Replacement retains previous weapon through queued reveal")
		game.render(); await create_timer(2.0).timeout
		var name="PlayerWeapon" if owner==0 else "EnemyWeapon"
		check(game.duel_board.get_node_or_null(name)==null,"Old weapon disappears before replacement appears")
		await create_timer(.45).timeout
		check(game.weapon_display[owner].uid==new_uid and game.duel_board.get_node(name).current_health==2,"Replacement appears with fresh durability")
		check(game.duel_board.get_node("HeroStats%d" % owner).get_meta("state").armor==2,"Old weapon Deathrattle grants displayed Armor once")
	b.active=0; b.sides[0].mana=3; b.sides[0].hand=["earth-earthen-spear"]
	b.record_event("secret",{"owner":0,"id":"earth-pebble-ward"}); b.play(0,0); game.after_action()
	game.page="deck"; game.render(); await create_timer(2.5).timeout
	check(game.weapon_display.is_empty() and game.battle_effects.is_empty(),"Leaving cancels pending replacement callbacks")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("WEAPON REPLACEMENT UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
