extends SceneTree
var checks=0
var failures=0
var game
func check(ok: bool,label: String):
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+label)
func find_text(node: Node,text: String) -> bool:
	if node is Label and node.text==text: return true
	for child in node.get_children():
		if find_text(child,text): return true
	return false
func _initialize(): call_deferred("run")
func draw_match():
	game.confirm_opening()
	game.battle.sides[0].hp=7; game.battle.sides[1].hp=7
	game.battle.sides[0].mana=8
	# Late-game fixture; resolve the actual catalog spell through the UI handler.
	game.battle.sides[0].hand=["fire-worldfire"]
	game.render()
	game.play_card(0)
func wait_for_result():
	var deadline=Time.get_ticks_msec()+5000
	while game.page=="battle" and Time.get_ticks_msec()<deadline:
		await create_timer(.05).timeout

func run():
	create_timer(30).timeout.connect(func(): printerr("Draw journey timed out"); quit(1))
	root.size=Vector2i(1280,800)
	game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://draw-journey-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","fire"); game.model.save()
	var original=game.model.profile.duplicate(true)
	game.page="deck"; game.render()
	game.start_practice("fire","",false,0)
	draw_match()
	check(game.page=="battle" and game.thinking,"Final spell remains visible with input locked before results")
	game.after_action()
	await wait_for_result()
	check(game.page=="result" and game.battle.outcome==2,"Practice spell reaches draw result")
	check(find_text(game.body,"Practice draw"),"Practice label says draw")
	check(game.model.profile==original,"Practice draw preserves adventure")
	game.practice_mode=false; game.page="map"; game.render()
	game.world3d.player.position=Vector3(18,1,-3)
	game.enter_battle(0)
	draw_match()
	var saved=game.model.profile.duplicate(true)
	game.after_action()
	check(game.model.profile==saved,"Repeated finalization does not award or save outcome twice")
	await wait_for_result()
	check(game.page=="result" and find_text(game.body,"Draw"),"Island result labels draw")
	check(not game.last_reward and not game.model.profile.won and game.model.profile.resin==0 and not game.model.profile.owned.has("home-resin-crab"),"Draw grants no victory loot")
	check(game.model.profile.hp==1 and not game.model.profile.battle_pending,"Draw clears pending battle and returns at one health")
	var reloaded=preload("res://model.gd").new()
	reloaded.save_path=game.model.save_path
	var loaded=reloaded.load_profile()
	var same_owned=loaded and reloaded.profile.owned.size()==original.owned.size()
	if loaded:
		for id in original.owned:
			same_owned=same_owned and reloaded.profile.owned.get(id,0)==original.owned[id]
	check(loaded and reloaded.profile.hp==1 and not reloaded.profile.won and reloaded.profile.resin==0 and not reloaded.profile.battle_pending and same_owned,"Draw recovery persists across reload")
	await process_frame; await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/draw-result.png"))
	DirAccess.remove_absolute(game.model.save_path)
	DirAccess.remove_absolute(game.constructed.path)
	game.queue_free(); await process_frame
	print("DRAW JOURNEY: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
