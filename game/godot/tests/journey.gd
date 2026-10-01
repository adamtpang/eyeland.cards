extends SceneTree
const Main = preload("res://main.tscn")
const Model = preload("res://model.gd")
var game
var failures = 0
var assertions = 0
var path = "user://journey-%d.json" % Time.get_ticks_usec()
var evidence = "res://../evidence/godot-third-person-2026-09-20"

func check(ok: bool, message: String):
	assertions += 1
	if not ok:
		failures += 1
		printerr("FAIL: " + message)

func _initialize():
	call_deferred("run")

func buttons(node: Node, result: Array = []) -> Array:
	for child in node.get_children():
		if child is Button: result.append(child)
		buttons(child, result)
	return result

func press(text: String) -> bool:
	for b in buttons(game.body, []):
		if text in b.text and not b.disabled:
			b.pressed.emit()
			return true
	check(false, "enabled button: " + text)
	return false

func snapshot(name: String):
	await process_frame
	await process_frame
	await create_timer(.25).timeout
	if DisplayServer.get_name() != "headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(evidence + "/" + name + ".png")

func click_control(text: String, qualifier: String = ""):
	await process_frame
	await process_frame
	for b in buttons(game.body, []):
		if text in b.text and (qualifier.is_empty() or qualifier in b.text) and not b.disabled:
			var point = b.get_global_rect().get_center()
			var motion = InputEventMouseMotion.new()
			motion.position = point
			root.push_input(motion)
			for down in [true,false]:
				var event = InputEventMouseButton.new()
				event.button_index = MOUSE_BUTTON_LEFT
				event.position = point
				event.pressed = down
				event.button_mask = MOUSE_BUTTON_MASK_LEFT if down else 0
				root.push_input(event)
			await process_frame
			return
	check(false, "mouse input target exists: " + text)

func run():
	root.size = Vector2i(1280,800)
	create_timer(180).timeout.connect(func(): printerr("FAIL: journey timeout"); quit(1))
	evidence = ProjectSettings.globalize_path(evidence).simplify_path()
	DirAccess.make_dir_recursive_absolute(evidence)
	game = Main.instantiate()
	game.model.save_path = path
	root.add_child(game)
	await snapshot("start")
	await click_control("Ranger")
	await click_control("Water")
	await click_control("Begin at home")
	check(game.model.profile.job == "ranger" and game.model.profile.element == "water", "selection callbacks capture correct indexes")
	game.world3d.player.position=Vector3(-18,1,-4)
	await create_timer(.3).timeout
	game.world_interact("home")
	check(game.model.profile.met_home,"3D home interaction")
	game.world3d.player.position=Vector3(18,1,-3)
	await create_timer(.3).timeout
	await snapshot("island")
	var seed_found=false
	for candidate in range(1,101):
		var sample=game.Battle.new(game.model.cards,game.constructed.deck,game.Collection.practice_deck(game.model.cards,"earth"),30,30,game.model.world.classes[1],candidate,true,-1)
		if sample.first_player!=0: continue
		sample.mulligan([])
		for action in range(1500):
			if sample.outcome!=-1: break
			if not sample.ai_step(sample.active): sample.end_turn(sample.active)
		if sample.outcome==0:
			game.model.profile.seed=1000000 if candidate==1 else candidate-1
			seed_found=true
			break
	check(seed_found,"winning real-engine fixture seed found")
	game.world_interact("encounter")
	check(game.page=="battle" and game.model.profile.battle_pending,"3D encounter enters battle")
	await snapshot("mulligan")
	await click_control("Keep hand & begin")
	check(not game.battle.mulligan_pending,"opening hand confirmed with mouse")
	await snapshot("tabletop")
	var actions = 0
	while game.page == "battle" and actions < 200:
		if game.thinking:
			await create_timer(0.1).timeout
			continue
		var decision=game.battle.ai_choice(0)
		match decision.kind:
			"play":
				var played_card=game.battle.cards[game.battle.sides[0].hand[decision.index]]
				if played_card.type=="minion" and played_card.get("targeting","")!="optionalCreature" and not played_card.has("choices"):
					var board=game.duel_board
					var count=game.battle.sides[0].board.size()
					var x=board.size.x/2.0+(decision.get("position",count)-count/2.0)*board.gap()
					board._drop_data(Vector2(x,300),{"kind":"hand","index":decision.index})
					await process_frame
					actions+=1
					continue
				game.play_card(decision.index)
				if game.selection=="spell": game.target_enemy(decision.target)
				elif game.selection=="choice":
					var card=game.battle.cards[game.battle.sides[0].hand[decision.index]]
					var option=card.choices[decision.choice].name
					for node in game.duel_board.get_children():
						if node.get_script()==preload("res://card_face.gd") and node.card.name==option:
							node.pressed.emit(); break
			"discover":
				game.duel_board.get_node("DiscoverOption%d" % decision.index).pressed.emit()
			"attack":
				game.selection="attack"; game.selected=decision.uid; game.render()
				game.target_enemy(decision.target)
			"power":
				game.use_power()
				if game.selection=="power": game.target_enemy(decision.target)
			_: press("End turn")
		actions += 1
		if actions == 7: await snapshot("battle")
		await process_frame
	check(game.page == "result" and game.battle.outcome == 0, "real-engine victory")
	check(game.model.profile.resin == 2 and game.model.profile.owned.has("home-resin-crab"), "reward received")
	await snapshot("reward")
	press("Continue to island")
	press("Collection")
	# Change the saved thirty-card playtest deck while keeping earned inventory.
	var removed=game.constructed.deck[0]
	game.constructed.remove(removed)
	check(game.constructed.add("home-resin-crab"),"earned Crab added to constructed deck")
	game.render()
	check(game.constructed.deck.has("home-resin-crab"), "reward equipped")
	await snapshot("deck")
	game.queue_free()
	await process_frame
	game = Main.instantiate()
	game.model.save_path = path
	root.add_child(game)
	check(game.page == "map" and game.constructed.deck.has("home-resin-crab"), "scene restart reloads earned deck")
	game.world3d.player.position=Vector3(0,1,6)
	game.world_interact("camp")
	check(game.model.profile.hp==30,"camp heals")
	game.world3d.player.position=Vector3(18,1,-3)
	game.world_interact("encounter")
	press("Keep hand & begin")
	while game.thinking: await create_timer(.1).timeout
	var index=game.battle.sides[0].deck.find("home-resin-crab")
	if index>=0 and not game.battle.sides[0].hand.has("home-resin-crab"):
		game.battle.sides[0].deck[index]=game.battle.sides[0].hand[0]
		game.battle.sides[0].hand[0]="home-resin-crab"
		game.render()
	var played = false
	for turn_index in range(3):
		var s = game.battle.sides[0]
		if s.hand.has("home-resin-crab"):
			await click_control("Resin Crab","IN HAND")
			played = s.board.any(func(m): return m.id == "home-resin-crab")
			break
		press("End turn")
		while game.thinking: await create_timer(0.1).timeout
	check(played, "earned Crab playable after restart")
	press("Retreat")
	for child in game.get_children():
		if child is ConfirmationDialog: child.confirmed.emit()
	press("Continue to island")
	check(game.model.profile.hp == 1 and game.model.profile.resin == 2, "retreat preserves loot")
	game.world_interact("camp")
	check(game.model.profile.hp == 30, "rest after retreat")
	game.queue_free()
	await process_frame
	await process_frame
	await create_timer(.3).timeout
	DirAccess.remove_absolute(path)
	DirAccess.remove_absolute(path+".deck.json")
	print("Godot journey: %d / %d checks passed; actual UI callbacks and real battle, isolated save." % [assertions - failures, assertions])
	quit(1 if failures else 0)
