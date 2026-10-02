extends SceneTree
const Main=preload("res://main.tscn")
const Battle=preload("res://battle.gd")
const Model=preload("res://model.gd")
var game
var count=0
var failures=0
func check(ok: bool,label: String):
	count+=1
	if not ok: failures+=1; printerr("FAIL: "+label)
func _initialize(): call_deferred("run")
func pointer(at: Vector2,down: bool):
	var event=InputEventMouseButton.new()
	event.position=at
	event.button_index=MOUSE_BUTTON_LEFT
	event.button_mask=MOUSE_BUTTON_MASK_LEFT if down else 0
	event.pressed=down
	root.push_input(event)
func drag(from: Vector2,to: Vector2,cancel=false):
	await create_timer(.15).timeout
	var first=InputEventMouseMotion.new()
	first.position=from
	root.push_input(first)
	await process_frame
	pointer(from,true)
	for i in range(1,11):
		var motion=InputEventMouseMotion.new()
		motion.position=from.lerp(to,i/10.0)
		motion.relative=(to-from)/10
		motion.button_mask=MOUSE_BUTTON_MASK_LEFT
		root.push_input(motion)
		await create_timer(.025).timeout
	if game.duel_board.drag_slot>=0:
		RenderingServer.force_draw()
		root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/drag-placement.png"))
	if cancel:
		var escape=InputEventKey.new()
		escape.keycode=KEY_ESCAPE
		escape.pressed=true
		root.push_input(escape)
	pointer(to,false)
	await process_frame
	await process_frame
func run():
	create_timer(30).timeout.connect(func(): printerr("UI parity timeout"); quit(1))
	root.size=Vector2i(1280,800)
	var model=Model.new()
	model.new_profile("warrior","fire")
	var b=Battle.new(model.cards,model.profile.deck,model.world.encounter.deck,30,12,model.world.classes[0],42,true)
	check(b.sides[0].hand.size()==3 and b.sides[1].hand.size()==5 and b.sides[1].hand.has("the-coin"),"3 versus 4+Coin opening")
	check(b.turn==0 and not b.end_turn(0) and not b.can_play(0,0),"mulligan blocks live actions")
	var hand=b.sides[0].hand.duplicate()
	check(not b.mulligan([0,0]) and b.sides[0].hand==hand,"invalid mulligan atomic")
	check(b.mulligan([0]) and b.sides[0].hand[0]!=hand[0] and b.turn==1 and b.sides[0].hand.size()==4,"replacement before returned-card shuffle and first draw")
	b.end_turn(0)
	var coin=b.sides[1].hand.find("the-coin")
	var mana=b.sides[1].mana
	check(b.play(1,coin) and b.sides[1].mana==mana+1 and b.sides[1].max_mana==1,"Coin temporary mana")
	b.sides[0].hand=[]
	for i in range(10): b.sides[0].hand.append("home-spark")
	b.sides[0].deck=["home-breeze-finch"]
	b.draw(0)
	check(b.sides[0].hand.size()==10 and b.sides[0].deck.is_empty(),"11th card burns")
	game=Main.instantiate()
	game.model.save_path="user://duel-ui-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.begin()
	game.world3d.player.position=Vector3(18,1,-3)
	game.enter_battle(0)
	check(not game.battle.mulligan_pending and game.battle.active==0,"adventure fights skip the opening-hand choice")
	game.battle.sides[1].hp=30  # roomy fixtures; the real first fight is small
	game.battle.sides[0].max_hp=30
	game.battle.sides[0].hand=["home-breeze-finch","home-spark"]
	game.battle.sides[0].mana=2
	game.battle.sides[0].max_mana=2
	game.render()
	await process_frame
	await process_frame
	await create_timer(.25).timeout
	var board=game.duel_board
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/godot-third-person-2026-09-20/drag-fixture.png"))
	var from=board.hand_faces[0].get_global_rect().get_center()
	await drag(from,board.global_position+Vector2(board.size.x*.4,300))
	check(game.battle.sides[0].board.size()==1,"native drag hand to battlefield")
	board=game.duel_board
	from=board.hand_faces[0].get_global_rect().get_center()
	var enemy_hp=game.battle.sides[1].hp
	await drag(from,game.target_widgets[-1].get_global_rect().get_center())
	check(game.battle.sides[1].hp==enemy_hp-2,"native targeted spell drag to enemy hero")
	if game.battle.sides[0].board.is_empty():
		printerr("No creature from drag; aborting dependent checks")
		quit(1)
		return
	game.battle.sides[0].board[0].ready=true
	game.battle.sides[0].board[0].summoning_sick=false
	game.render()
	await process_frame
	await process_frame
	board=game.duel_board
	var uid=game.battle.sides[0].board[0].uid
	from=board.friendly_faces[uid].get_global_rect().get_center()
	enemy_hp=game.battle.sides[1].hp
	await drag(from,game.target_widgets[-1].get_global_rect().get_center())
	check(game.battle.sides[1].hp==enemy_hp-2,"native creature drag attacks hero")
	game.battle.sides[0].hand=["home-shore-guard"]
	game.battle.sides[0].mana=5
	game.battle.sides[0].max_mana=5
	game.render()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	board=game.duel_board
	from=board.hand_faces[0].get_global_rect().get_center()
	await drag(from,board.friendly_faces[uid].get_global_rect().get_center())
	check(game.battle.sides[0].board.size()==2,"drop onto an existing friendly creature is accepted")
	game.battle.sides[0].hand=["home-resin-crab"]
	game.render()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	board=game.duel_board
	from=board.hand_faces[0].get_global_rect().get_center()
	await drag(from,board.global_position+Vector2(board.size.x*.3,300))
	check(game.battle.sides[0].board[0].id=="home-resin-crab","drop position places new creature to the left")
	game.battle.sides[0].hand=["home-breeze-finch"]
	game.render()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	board=game.duel_board
	from=board.hand_faces[0].get_global_rect().get_center()
	var old_mana=game.battle.sides[0].mana
	await drag(from,board.global_position+Vector2(35,500))
	check(game.battle.sides[0].hand.size()==1 and game.battle.sides[0].mana==old_mana,"invalid drop returns card without spending mana")
	board=game.duel_board
	from=board.hand_faces[0].get_global_rect().get_center()
	await drag(from,board.global_position+Vector2(board.size.x*.4,300),true)
	check(game.battle.sides[0].hand.size()==1 and game.battle.sides[0].mana==old_mana and game.drag_payload.is_empty(),"Escape cancels a dragged card without playing it")
	game.battle.sides[0].hand=["home-mending-tide"]
	game.battle.sides[0].hp=20
	game.render()
	await process_frame
	await process_frame
	RenderingServer.force_draw()
	board=game.duel_board
	from=board.hand_faces[0].get_global_rect().get_center()
	await drag(from,board.global_position+Vector2(board.size.x*.4,180))
	check(game.battle.sides[0].hp==24,"untargeted spell accepts broad battlefield drop")
	var save_path=game.model.save_path
	game.queue_free()
	await create_timer(.3).timeout
	DirAccess.remove_absolute(save_path)
	print("Battle structure checks: %d / %d passed" % [count-failures,count])
	quit(1 if failures else 0)
