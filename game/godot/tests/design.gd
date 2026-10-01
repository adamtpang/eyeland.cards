extends SceneTree
const Main=preload("res://main.tscn")
const Battle=preload("res://battle.gd")
var game
var failed=0
var checks=0
var evidence="res://../evidence/godot-clean-ui-2026-09-20"

func check(ok: bool,message: String):
	checks+=1
	if not ok:
		failed+=1
		printerr("FAIL: "+message)

func _initialize(): call_deferred("run")

func capture(name_value: String):
	await process_frame
	await process_frame
	await create_timer(.75).timeout
	check(game.body.size.x<=game.size.x-40,"no horizontal overflow: "+name_value)
	if game.page=="battle" and not game.help_open:
		check(game.body.size.y<=game.size.y-24,"battle fits viewport: "+name_value)
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(evidence+"/"+name_value+".png")

func run():
	create_timer(60).timeout.connect(func(): printerr("Design check timed out"); quit(1))
	evidence=ProjectSettings.globalize_path(evidence).simplify_path()
	DirAccess.make_dir_recursive_absolute(evidence)
	root.size=Vector2i(1280,800)
	game=Main.instantiate()
	game.model.save_path="user://design-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	await capture("setup-desktop")
	game.model.new_profile("wizard","air")
	game.page="map"
	game.render()
	await capture("home-desktop")
	game.world3d.player.position=Vector3(18,1,-3)
	check(game.near_location("encounter"),"3D proximity arrives at encounter")
	game.enter_battle(0)
	game.battle.mulligan([])
	# Deliberate visual fixtures, independent of real-game journey tests.
	game.battle.sides[0].mana=10
	game.battle.sides[0].max_mana=10
	game.battle.sides[0].hand=game.model.profile.deck.duplicate()
	game.battle.sides[0].board=[{"uid":11,"id":"home-cloudling","atk":3,"hp":4,"ready":true,"taunt":false}]
	game.battle.sides[1].board=[{"uid":22,"id":"home-shore-guard","atk":1,"hp":4,"ready":true,"taunt":true}]
	game.selection="attack"
	game.selected=11
	game.render()
	check(not game.target_allowed(-1) and game.target_allowed(22),"attack highlights respect Taunt")
	await capture("attack-targeting")
	var key=InputEventKey.new()
	key.keycode=KEY_ESCAPE
	key.pressed=true
	root.push_input(key)
	check(game.selection.is_empty(),"Escape cancels targeting")
	game.play_card(3)
	check(game.selection=="spell" and game.target_allowed(-1),"spell targeting bypasses Taunt")
	game.target_enemy(-1)
	check(game.battle.sides[1].hp==28,"targeted spell applies")
	game.confirm_retreat()
	for child in game.get_children():
		if child is ConfirmationDialog: child.canceled.emit()
	check(game.page=="battle" and game.battle.outcome==-1,"cancel retreat preserves battle")
	await capture("battle-desktop")
	root.size=Vector2i(1024,720)
	await capture("battle-small-window")
	game.page="start"
	game.render()
	await capture("setup-small-window")
	game.page="deck"
	game.model.profile.won=true
	game.model.profile.resin=2
	game.model.profile.owned["home-resin-crab"]=1
	game.swap_index=4
	game.render()
	await capture("deck-small-window")
	game.page="map"
	game.render()
	await capture("island-small-window")
	game.help_open=true
	game.render()
	await capture("guide-small-window")
	var save_path=game.model.save_path
	game.queue_free()
	await create_timer(.75).timeout
	DirAccess.remove_absolute(save_path)
	print("Design checks: %d / %d passed. Targeting, cancel, 3D proximity and desktop/small-window layouts." % [checks-failed,checks])
	quit(1 if failed else 0)
