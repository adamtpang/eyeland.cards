extends SceneTree
var failures=0
var checks=0
func check(ok: bool,message: String):
	checks+=1
	if not ok: failures+=1; push_error(message)
func _initialize(): call_deferred("run")
func snapshot(name: String):
	await process_frame; await process_frame; await create_timer(.15).timeout
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path("res://../evidence/art-"+name+".png"))
func run():
	var model=preload("res://model.gd").new()
	var skin=preload("res://skin.gd")
	var regions={}
	for id in model.cards:
		var texture=skin.art(id)
		check(texture is AtlasTexture,"Art exists: "+id)
		if texture is AtlasTexture:
			var key=texture.atlas.resource_path+str(texture.region)
			check(not regions.has(key),"Distinct illustration: "+id)
			regions[key]=true
			check(texture.region.size.x>=240 and texture.region.end.x<=texture.atlas.get_width()+1 and texture.region.end.y<=texture.atlas.get_height()+1,"Valid art crop: "+id)
	check(skin.art("the-coin")!=null,"Generated Coin retains illustration")
	root.size=Vector2i(1280,800)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://art-review-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	await snapshot("start")
	game.model.new_profile("warrior","water"); game.page="deck"
	for dimensions in [Vector2i(1280,800),Vector2i(1024,720)]:
		root.size=dimensions
		for element in ["air","water","fire","earth"]:
			game.collection_filters={"element":element}; game.render()
			await snapshot("collection-%s-%d" % [element,dimensions.x])
			var grid=game.find_child("CollectionGrid",true,false)
			check(grid.get_global_rect().end.x<=game.get_viewport_rect().size.x,"Collection fits logical viewport width: "+element+str(dimensions))
	root.size=Vector2i(1280,800)
	game.start_practice("water","",false,0); game.confirm_opening()
	game.battle.summon(0,"water-river-stag"); game.battle.summon(1,"fire-furnace-beetle")
	game.battle.sides[0].hand=["water-dewdrop-newt","water-mist-heron","water-deep-current","water-pearl-leviathan"]
	game.after_action(); await create_timer(1.5).timeout
	await snapshot("battle")
	game.page="result"; game.battle.outcome=0; game.render(); await snapshot("result")
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	print("ART UI: %d / %d passed" % [checks-failures,checks]); quit(1 if failures else 0)
