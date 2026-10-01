extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")
func move(point: Vector2):
	var motion=InputEventMouseMotion.new(); motion.position=point; root.push_input(motion,true)
	await create_timer(.16).timeout
func run():
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://full-hand-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("warrior","air"); game.page="deck"
	game.start_practice("air","",false,0); game.confirm_opening()
	game.battle.sides[0].hand=["air-gust-bolt","air-windfall","air-feather-ward","fire-cinder-moth","water-reef-otter","earth-earthen-spear","air-flock-captain","water-shellback-tortoise","fire-coalback-pup","air-skyfin-ray"]
	game.battle.sides[0].mana=10
	game.battle.sides[0].max_mana=10
	for dimensions in [Vector2i(1280,800),Vector2i(1600,900)]:
		root.size=dimensions; game.render()
		await process_frame; await process_frame
		for i in range(10):
			await move(Vector2(10,10))
			var face=game.duel_board.hand_faces[i]
			var rect=face.get_global_rect()
			await move(Vector2(rect.position.x+20,rect.position.y+50))
			check(face.scale.x>1.29,"Card %d can be reached in full hand at %s" % [i,dimensions])
			var raised=face.get_global_rect()
			check(raised.position.x>=0 and raised.end.x<=game.size.x and raised.position.y>=0 and raised.end.y<=game.size.y,"Raised card remains within viewport")
		if DisplayServer.get_name()!="headless":
			RenderingServer.force_draw()
			root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/full-hand-%d.png" % dimensions.x))
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("FULL HAND UI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
