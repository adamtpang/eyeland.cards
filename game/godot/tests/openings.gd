extends SceneTree
const Model=preload("res://model.gd")
const Battle=preload("res://battle.gd")
const Collection=preload("res://collection.gd")
const Main=preload("res://main.tscn")
var checks=0
var failed=0
func check(ok,label):
	checks+=1
	if not ok: failed+=1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
	create_timer(180).timeout.connect(func(): printerr("Opening journey timed out"); quit(1))
	var m=Model.new()
	var deck=Collection.practice_deck(m.cards,"earth")
	var seen={0:0,1:0}
	for seed_value in range(40):
		var b=Battle.new(m.cards,deck,deck,30,30,m.world.classes[0],seed_value,true,-1)
		seen[b.first_player]+=1
		var repeat=Battle.new(m.cards,deck,deck,30,30,m.world.classes[0],seed_value,true,-1)
		check(repeat.first_player==b.first_player and repeat.sides==b.sides,"deterministic opening "+str(seed_value))
		check(b.sides[b.first_player].hand.size()==3 and b.sides[1-b.first_player].hand.size()==5,"3 versus 4 and Coin")
		var before=b.sides.duplicate(true)
		check(not b.mulligan([0,0]) and b.sides==before,"invalid mulligan atomic")
		if b.first_player==1: check(not b.mulligan([4]) and b.sides==before,"Coin cannot be replaced")
		check(b.mulligan([0,1]),"valid replacements")
		check(b.active==b.first_player and b.turn==1 and b.sides[b.active].mana==1,"correct first turn")
		check(b.sides[1-b.first_player].hand.count("the-coin")==1,"Coin remains unique")
		for side in [0,1]:
			var actual=b.sides[side].hand+b.sides[side].deck
			actual.erase("the-coin")
			var expected=deck.duplicate(); actual.sort(); expected.sort()
			check(actual==expected,"mulligans preserve multiset")
	check(seen[0]>5 and seen[1]>5,"randomized order exercises both sides")
	var b=Battle.new(m.cards,deck,deck,30,30,m.world.classes[0],55,true,0)
	b.sides[1].hand=["earth-orun-living-mountain","home-resin-crab","earth-ancient-grove","earth-deep-roots","the-coin"]
	check(b.mulligan([]) and b.opponent_mulligan_count==2 and b.sides[1].hand[1]=="home-resin-crab" and b.sides[1].hand[3]=="earth-deep-roots","opponent keeps early curve and replaces expensive cards")
	var game=Main.instantiate()
	game.model.save_path="user://opening-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air")
	game.page="deck"
	game.start_practice("air","",false,1)
	await process_frame; await process_frame
	check(game.battle.mulligan_pending and game.battle.sides[0].hand.has("the-coin"),"second-player opening UI")
	var coin=find_coin(game.body)
	check(coin!=null and coin.disabled,"Coin visually locked in mulligan")
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/second-player-mulligan.png"))
	game.confirm_opening()
	check(game.thinking and game.battle.active==1,"opponent goes first automatically")
	var timer=game.clock_left
	game.end_turn()
	check(game.battle.active==1,"human cannot end opponent turn")
	while game.thinking: await create_timer(.1).timeout
	check(game.battle.active==0 and game.battle.turn==2 and game.battle.sides[0].mana==1,"opening AI yields player's first turn")
	check(game.battle.sides[0].hand.size()==6,"second player draws after four plus Coin")
	check(game.clock_left>74,"player clock begins after opponent")
	var coin_index=game.battle.sides[0].hand.find("the-coin")
	check(game.battle.play(0,coin_index) and game.battle.sides[0].mana==2 and game.battle.sides[0].max_mana==1,"second player Coin is temporary mana")
	var steps=0
	while game.page=="battle" and steps<500:
		if game.thinking:
			await create_timer(.1).timeout
			continue
		var action=game.battle.ai_choice(0)
		match action.kind:
			"play":
				game.play_card(action.index)
				if game.selection=="spell": game.target_enemy(action.target)
				elif game.selection=="choice":
					var card=game.battle.cards[game.battle.sides[0].hand[action.index]]
					for node in game.duel_board.get_children():
						if node.get_script()==preload("res://card_face.gd") and node.card.name==card.choices[action.choice].name:
							node.pressed.emit(); break
			"discover":
				game.duel_board.get_node("DiscoverOption%d" % action.index).pressed.emit()
			"attack":
				game.selection="attack"; game.selected=action.uid; game.render()
				game.target_enemy(action.target)
			"power":
				game.use_power()
				if game.selection=="power": game.target_enemy(action.target)
			_: game.end_turn()
		steps+=1
		await process_frame
	if game.page!="result": print("OPENING STOP: ", {"active":game.battle.active,"choice":game.battle.pending_choice,"selection":game.selection,"decision":game.battle.ai_choice(0),"steps":steps,"turn":game.battle.turn})
	check(game.page=="result" and game.battle.outcome!=-1,"full second-player rendered match reaches result")
	check(not game.model.profile.battle_pending and game.model.profile.hp==30,"second-player practice preserves adventure")
	game.queue_free(); await process_frame
	await create_timer(.1).timeout
	print("OPENINGS: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
func find_coin(node):
	for child in node.get_children():
		if child.get_script()==preload("res://card_face.gd") and child.card.id=="the-coin" and child.disabled: return child
		var found=find_coin(child)
		if found!=null: return found
	return null
