extends SceneTree
const Model=preload("res://model.gd")
const Deck=preload("res://constructed.gd")
const Battle=preload("res://battle.gd")
const Main=preload("res://main.tscn")
var checks=0
var failures=0
var game
func check(ok,label):
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func run():
	var m=Model.new()
	var d=Deck.new(m.cards)
	d.path="user://constructed-test-%d.json" % Time.get_ticks_usec()
	d.preset("air")
	check(d.valid(d.deck),"default thirty cards")
	check(not d.valid(d.deck+['home-spark']),"reject 31")
	d.remove("air-tailwind")
	check(not d.valid(d.deck) and d.valid(d.deck,false),"incomplete draft saved but cannot play")
	check(d.add("home-spark"),"mixed element deck edit")
	var reloaded=Deck.new(m.cards); reloaded.path=d.path; reloaded.load_or_create("earth")
	check(reloaded.deck==d.deck,"custom deck survives restart")
	check(not d.valid(["home-cloudling","home-cloudling"],false),"one Legendary copy")
	check(not d.valid(["home-spark","home-spark","home-spark"],false),"two ordinary copies")
	check(not d.valid(["the-coin"],false),"generated cards cannot enter deck")
	var damaged=FileAccess.open(d.path,FileAccess.WRITE); damaged.store_string("damaged"); damaged.close()
	reloaded.load_or_create("air"); reloaded.remove("air-tailwind")
	check(reloaded.blocked and FileAccess.get_file_as_string(d.path)=="damaged","corrupt save preserved")
	DirAccess.remove_absolute(d.path)
	root.size=Vector2i(1280,800)
	game=Main.instantiate(); game.model.save_path="user://constructed-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.model.save()
	game.page="deck"; game.render()
	game.constructed.remove("air-tailwind"); game.render()
	var play=find_button(game.body,"Play")
	check(play!=null and play.disabled,"UI blocks incomplete deck")
	game.constructed.add("home-spark"); game.render()
	find_button(game.body,"Play").pressed.emit()
	check(game.page=="battle" and game.practice_mode,"Play launches custom match")
	check(game.battle.sides[0].hp==30 and game.battle.sides[1].hp==30,"both heroes start at thirty")
	check(game.battle.sides[0].deck.size()+game.battle.sides[0].hand.size()-game.battle.sides[0].hand.count("the-coin")==30,"player has thirty physical cards")
	check(game.battle.sides[1].deck.size()+game.battle.sides[1].hand.size()-game.battle.sides[1].hand.count("the-coin")==30,"opponent thirty plus generated Coin")
	check((game.battle.sides[0].deck+game.battle.sides[0].hand).has("home-spark"),"custom edit reaches actual battle")
	game.confirm_opening()
	while game.thinking: await create_timer(.1).timeout
	game.battle.sides[0].mana=2
	check(game.battle.power() and game.battle.sides[0].mana==0,"hero power costs two")
	game.battle.sides[0].mana=2
	check(not game.battle.power(),"power once per turn")
	game.battle.active=1; game.battle.sides[1].mana=2; game.battle.sides[1].hand=[]
	check(game.battle.ai_step(1) and game.battle.sides[1].armor==2 and game.battle.sides[1].mana==0,"AI uses two-mana power")
	game.battle.sides[0].max_mana=10; game.battle.start_turn(0)
	check(game.battle.sides[0].max_mana==10 and game.battle.sides[0].mana==10,"mana capped at ten")
	game.render()
	var report=game.save_bug_snapshot()
	var data=JSON.parse_string(FileAccess.get_file_as_string(report))
	check(data.deck==game.constructed.deck and data.battle.turn==game.battle.turn and data.catalog.size()==100,"bug snapshot includes match and card definitions")
	check(data.battle.timeline.size()==game.battle.timeline.size() and data.presentation.effect_cursor==game.effect_timeline_cursor and data.presentation.has("pending_hero_stats"),"bug snapshot includes timeline and presentation queue")
	DirAccess.remove_absolute(report)
	var profile=game.model.profile.duplicate(true)
	game.battle.outcome=0; game.after_action()
	find_button(game.body,"Play again").pressed.emit()
	check(game.page=="battle" and game.battle.sides[0].hp==30 and game.model.profile==profile,"rematch resets combat and preserves adventure")
	game.practice_mode=false; game.page="map"; game.render()
	game.world3d.player.position=Vector3(18,1,-3)
	game.model.profile.hp=1
	game.enter_battle()
	check(game.battle.sides[0].hp==30 and game.battle.sides[1].hp==30,"island encounter also starts thirty versus thirty")
	check(game.battle.sides[0].deck.size()+game.battle.sides[0].hand.size()-game.battle.sides[0].hand.count("the-coin")==30,"island uses edited thirty-card deck")
	game.battle.outcome=0; game.after_action()
	check(game.model.profile.won and game.model.profile.owned.has("home-resin-crab"),"island still grants earned reward")
	game.page="deck"; game.render()
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/constructed-deck.png"))
	check(game.body.size.x<=game.size.x-40,"deckbuilder fits width")
	DirAccess.remove_absolute(game.model.save_path)
	DirAccess.remove_absolute(game.constructed.path)
	game.queue_free(); await process_frame
	await create_timer(.1).timeout
	print("CONSTRUCTED: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
func find_button(node,text):
	for child in node.get_children():
		if child is Button and child.text==text: return child
		var found=find_button(child,text)
		if found!=null: return found
	return null
