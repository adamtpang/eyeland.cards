extends SceneTree
var failed=0
func check(ok: bool,message: String):
	if not ok: failed+=1; push_error(message)
func _initialize(): call_deferred("run")
func run():
	var args=OS.get_cmdline_user_args()
	check(args.size()>=2,"Supply executable and screenshot path")
	if failed: quit(1); return
	check(ProjectSettings.load_resource_pack(args[0]),"Embedded executable pack loads")
	if failed: quit(1); return
	var skin=load("res://skin.gd")
	var model=load("res://model.gd").new()
	for id in model.cards:
		var texture=skin.art(id)
		check(texture!=null and texture.get_image()!=null,"Exported card artwork: "+id)
	check(skin.card_art.size()==100,"Export contains all 100 dedicated card portraits")
	root.size=Vector2i(1280,800)
	var game=load("res://main.tscn").instantiate()
	game.model.save_path="user://export-art-check.json"
	root.add_child(game)
	game.model.new_profile("warrior","water"); game.page="deck"
	game.start_practice("water","",false,0); game.confirm_opening()
	game.battle.summon(0,"water-river-stag"); game.battle.summon(1,"fire-furnace-beetle")
	game.battle.sides[0].hand=["water-dewdrop-newt","water-mist-heron","water-deep-current","water-pearl-leviathan"]
	game.after_action(); await create_timer(1.5).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(args[1])
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("EXPORTED ART: 100 portraits checked; failures=",failed)
	quit(1 if failed else 0)
