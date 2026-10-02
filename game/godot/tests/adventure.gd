extends SceneTree
## The Home Island loop: small fights, a card for each first win, a 10-card deck you edit,
## three camps and then the Warden. Saves screenshots as evidence.
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize(): call_deferred("run")

func shot(folder: String,file: String):
	if DisplayServer.get_name()=="headless": return
	RenderingServer.force_draw()
	root.get_texture().get_image().save_png(folder.path_join(file))

func stand_at(game,id: String):
	var at=game.world3d.landmarks[id]
	game.world3d.player.position=Vector3(at.x+1.8,game.world3d.ground_height(at.x+1.8,at.z+1.8)+.2,at.z+1.8)
	await create_timer(.5).timeout

func win(game):
	game.battle.damage_hero(1,99); game.battle.check_outcome(); game.after_action()
	await create_timer(1.6).timeout

func run():
	var folder=ProjectSettings.globalize_path("res://").path_join("../evidence/adventure-2026-10-01")
	DirAccess.make_dir_recursive_absolute(folder)
	var game=preload("res://main.tscn").instantiate()
	game.model.save_path="user://adventure-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	await process_frame
	game.job_index=0; game.element_index=3
	game.begin()
	game.model.profile.quest=4
	game.render()
	await create_timer(1.2).timeout
	var adv=game.adventure()
	check(adv.deck.size()==10 and adv.cleared.is_empty(),"A new adventure starts with a 10-card deck")
	check(game.world3d.goal_id=="encounter","The goal points at the Resin Crab")
	shot(folder,"1-objective.png")
	# the Warden is locked until the camps are cleared
	await stand_at(game,"warden")
	shot(folder,"2-warden.png")
	game.world_interact("warden"); await process_frame
	check(game.page=="map" and game.note.contains("three camps"),"The Warden refuses until the camps are cleared")
	# fight 1: small and quick
	await stand_at(game,"encounter")
	game.world_interact("encounter"); await create_timer(2.2).timeout
	var b=game.battle
	check(game.page=="battle" and b.sides[0].hp==10 and b.sides[1].hp==5,"The first fight is 10 health against 5")
	check(not b.mulligan_pending and b.active==0 and not b.enemy_power,"No opening-hand choice, you go first, no enemy class power")
	check(b.sides[0].hand.size()+b.sides[0].deck.size()==10,"You bring exactly ten cards")
	shot(folder,"3-crab-fight.png")
	await win(game)
	check(game.page=="result" and game.last_reward and int(adv.cards["home-resin-crab"])==2,"Winning awards two Resin Crab cards")
	check(game.model.profile.won and game.quest()==5,"The goal becomes adding the Crab to your deck")
	shot(folder,"4-reward.png")
	# deck editing
	game.page="adeck"; game.render(); await process_frame
	check(game.body.find_child("AdventureDeck",true,false)!=null,"The deck screen opens")
	adv.deck.erase("home-mending-tide"); game.render(); await process_frame
	check(adv.deck.size()==9,"A card can be taken out")
	adv.deck.append("home-resin-crab"); game.settle_quest(); game.model.save(); game.render(); await process_frame
	shot(folder,"5-deck.png")
	check(adv.deck.size()==10 and game.quest()==6,"Adding the Crab completes the goal")
	game.page="map"; game.render(); await create_timer(1.2).timeout
	check(game.world3d.goal_id=="camp2","The next goal is the second camp")
	# rematch gives no second reward
	await stand_at(game,"encounter")
	game.world_interact("encounter"); await create_timer(.6).timeout
	await win(game)
	check(not game.last_reward and int(adv.cards["home-resin-crab"])==2,"A rematch gives no second reward")
	# a loss costs nothing
	game.page="map"; game.render(); await create_timer(1.0).timeout
	await stand_at(game,"camp2")
	game.world_interact("camp2"); await create_timer(1.8).timeout
	check(game.page=="battle" and game.battle.sides[1].hp==8 and game.battle.enemy_name=="Mossback Cub","The second camp is a little tougher")
	shot(folder,"6-cub-fight.png")
	game.battle.outcome=1; game.after_action(); await create_timer(1.6).timeout
	check(game.page=="result" and not adv.cleared.has("camp2") and adv.deck.size()==10,"Losing costs nothing")
	for id in ["camp2","camp3"]:
		game.page="map"; game.render(); await create_timer(1.0).timeout
		await stand_at(game,id)
		game.world_interact(id); await create_timer(.6).timeout
		await win(game)
		check(adv.cleared.has(id) and int(adv.cards[game.ENCOUNTERS[id].reward])==2,"Clearing %s awards its card" % game.ENCOUNTERS[id].name)
	check(game.camps_cleared()==3 and game.quest()==8,"Three camps cleared, the goal is the Warden")
	game.page="map"; game.render(); await create_timer(1.0).timeout
	await stand_at(game,"warden")
	game.world_interact("warden"); await create_timer(1.8).timeout
	check(game.page=="battle" and game.battle.enemy_name=="Hearth Warden","The Warden accepts the challenge")
	shot(folder,"7-warden-fight.png")
	await win(game)
	check(adv.cleared.has("warden") and game.quest()==9,"Beating the Warden completes the island's objective")
	shot(folder,"8-warden-reward.png")
	game.page="map"; game.render(); await create_timer(1.0).timeout
	shot(folder,"9-island-cleared.png")
	# everything survives a reload
	var path=game.model.save_path
	game.queue_free(); await process_frame; await create_timer(.2).timeout
	var again=preload("res://main.tscn").instantiate()
	again.model.save_path=path
	root.add_child(again)
	await process_frame
	var kept=again.adventure()
	check(again.model.error.is_empty() and kept.cleared.size()==4 and kept.deck.has("home-resin-crab") and again.quest()==9,"Cards, deck, camps and goal survive a reload")
	again.queue_free(); await process_frame; await create_timer(.2).timeout
	print("ADVENTURE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
