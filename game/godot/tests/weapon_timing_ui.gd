extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://weapon-timing-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","earth"); game.page="deck"
	game.start_practice("earth","",false,0); game.confirm_opening()
	await create_timer(.5).timeout
	var b=game.battle
	for owner in [0,1]:
		b.active=owner; b.sides[owner].mana=3; b.sides[owner].hand=["earth-earthen-spear"]
		b.play(owner,0); game.after_action(); await create_timer(.4).timeout
		var name="PlayerWeapon" if owner==0 else "EnemyWeapon"
		check(game.duel_board.get_node(name).current_health==2,"Equipped weapon visible with two durability")
		b.attack(owner,-1,-1); game.after_action()
		check(game.duel_board.get_node(name).current_health==2,"Durability remains until impact")
		game.render(); await create_timer(.45).timeout
		check(game.duel_board.get_node(name).current_health==1,"Impact spends displayed durability across redraw")
		b.sides[owner].hero_attacks=0
		b.attack(owner,-1,-1); game.after_action()
		check(game.duel_board.get_node_or_null(name)!=null,"Final swing retains weapon before break")
		await create_timer(.5).timeout
		check(game.duel_board.get_node_or_null(name)==null and b.sides[owner].armor==2,"Broken weapon disappears and native Deathrattle resolves")
	await create_timer(.5).timeout
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("WEAPON TIMING UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
