extends SceneTree
const Model=preload("res://model.gd")
const Battle=preload("res://battle.gd")
const Collection=preload("res://collection.gd")
const Main=preload("res://main.tscn")
var checks=0
var failed=0
var model=Model.new()
var game

func check(ok: bool,message: String):
	checks+=1
	if not ok: failed+=1; printerr("FAIL: "+message)

func fight() -> RefCounted:
	var deck=Collection.practice_deck(model.cards,"earth")
	return Battle.new(model.cards,deck,deck,30,30,model.world.classes[0],14)

func cast(b,id: String):
	b.sides[0].hand=[id]
	b.sides[0].mana=10
	if b.cards[id].get("targetSide","")=="friendly":
		b.summon(0,"home-breeze-finch")
		return b.play(0,0,b.sides[0].board[0].uid)
	return b.play(0,0,-1,-1,0 if b.cards[id].has("choices") else -1)

func _initialize(): call_deferred("run")

func run():
	create_timer(90).timeout.connect(func(): printerr("Collection test timed out"); quit(1))
	check(model.cards.size()==100,"exactly 100 collectible definitions; Coin excluded")
	check(Collection.query(model.cards,{}, {"type":"minion"}).size()==60,"60 minions")
	check(Collection.query(model.cards,{}, {"type":"spell"}).size()==39,"39 spells")
	var supported=["discover","freezeTarget","equipWeapon","buffTarget","silenceEnemies","freezeEnemies","gainArmor","healCaster","damage","draw","ramp","damageEnemies","damageBoard","damageAll","buffAll","buffElement","healBoard","summon"]
	for id in model.cards:
		var c=model.cards[id]
		check(preload("res://skin.gd").art(id)!=null,"prototype art resolves "+id)
		check(c.cost>=0 and c.cost<=10 and c.element in Collection.ELEMENTS and c.rarity in ["common","rare","epic","legendary"],"valid definition "+id)
		for e in c.get("onPlay",[]):
			check(e.effect in supported,"supported effect "+id)
			if e.effect=="summon": check(model.cards.has(e.card) and model.cards[e.card].type=="minion","valid summon "+id)
		var b=fight()
		check(cast(b,id),"plays without unsupported mechanics "+id)
	for element in Collection.ELEMENTS:
		check(Collection.query(model.cards,{}, {"element":element}).size()==25,"25 "+element+" cards")
		var deck=Collection.practice_deck(model.cards,element)
		check(deck.size()==30,"30-card practice "+element)
		var valid=true
		for id in deck: valid=valid and deck.count(id)<=(1 if model.cards[id].rarity=="legendary" else 2)
		check(valid,"practice copy limits "+element)
	check(Collection.query(model.cards,{}, {"search":"taunt","element":"earth"}).size()>0,"search rules and element together")
	check(Collection.query(model.cards,{}, {"type":"spell","cost":0}).size()==2,"zero-cost filters")
	check(Collection.query(model.cards,{}, {"search":"no-such-card"}).is_empty(),"empty search")
	var b=fight()
	var before=b.sides[0].hand.size()
	cast(b,"fire-fuel-the-fire")
	check(b.sides[0].hand.size()==2,"draw two resolves")
	b=fight(); b.sides[0].max_mana=3
	cast(b,"earth-deep-roots")
	check(b.sides[0].max_mana==4 and b.sides[0].mana==8,"ramp gives empty crystal, not spendable mana")
	b.sides[0].max_mana=10
	cast(b,"earth-deep-roots")
	check(b.sides[0].max_mana==10,"ramp capped at ten")
	b=fight()
	b.summon(0,"home-cloudling"); b.summon(0,"home-mossling")
	cast(b,"air-rising-winds")
	check(b.sides[0].board[0].atk==4 and b.sides[0].board[1].atk==3,"element buffs only own matching minions")
	cast(b,"air-skyward-chorus")
	check(b.sides[0].board[0].atk==6 and b.sides[0].board[1].atk==5,"board buffs compound")
	b.sides[0].board[0].hp=1
	cast(b,"water-restoring-rain")
	check(b.sides[0].board[0].hp==5,"healing restores damaged minion")
	cast(b,"water-restoring-rain")
	check(b.sides[0].board[0].hp==7,"healing capped at buffed maximum")
	b=fight(); b.summon(0,"home-breeze-finch"); b.summon(1,"home-breeze-finch")
	cast(b,"fire-brushfire")
	check(b.sides[1].board.is_empty() and b.sides[0].board.size()==1,"enemy-only board damage")
	b.summon(1,"home-mossling")
	cast(b,"earth-earthquake")
	check(b.sides[0].board.is_empty() and b.sides[1].board.is_empty(),"symmetric damage and deaths")
	b=fight()
	for i in range(6): b.summon(0,"home-resin-crab")
	cast(b,"earth-crab-colony")
	check(b.sides[0].board.size()==7 and not b.sides[0].board[6].ready,"summon respects board cap and sickness")
	b=fight(); b.sides[0].deck=[]; b.sides[0].hp=2
	cast(b,"fire-fuel-the-fire")
	check(b.outcome==1,"draw fatigue can end game")
	b=fight(); b.sides[0].deck=[]; b.sides[0].hp=1
	cast(b,"water-clearwater")
	check(b.outcome==1 and b.sides[0].hp==0,"lethal draw stops later healing")
	# Representative element-v-element games must terminate across many shuffles.
	for seed_value in range(40):
		var left=Collection.ELEMENTS[seed_value%4]
		var right=Collection.ELEMENTS[(seed_value/4)%4]
		b=Battle.new(model.cards,Collection.practice_deck(model.cards,left),Collection.practice_deck(model.cards,right),30,30,model.world.classes[0],seed_value)
		var actions=0
		while b.outcome==-1 and actions<1500:
			if not b.ai_step(b.active): b.end_turn(b.active)
			actions+=1
		check(b.outcome!=-1,"element simulation terminates "+str(seed_value))
	root.size=Vector2i(1280,800)
	game=Main.instantiate()
	game.model.save_path="user://collection-test-%d.json" % Time.get_ticks_usec()
	root.add_child(game)
	game.model.new_profile("wizard","air")
	game.page="deck"; game.render()
	await capture("collection-all")
	check(game.body.find_child("CollectionGrid",true,false).get_child_count()==10,"paginated grid")
	Collection.inspect(game,"air-aella-open-sky")
	await capture("collection-inspect")
	check(game.inspection.get_child(0).get_child(0).size.y<game.size.y,"inspection fits viewport")
	game.close_inspection()
	game.collection_filters={"element":"water","type":"spell","rarity":"rare"}; game.render()
	await capture("collection-filtered")
	check(Collection.query(game.model.cards,{},game.collection_filters).size()==3,"combined collection filters")
	game.collection_filters={"owned":true}; game.render()
	check(game.body.find_child("CollectionGrid",true,false).get_child_count()==5,"only five cards owned; no free rewards")
	var original=game.model.profile.duplicate(true)
	game.start_practice("earth","earth-orun-living-mountain")
	check(game.practice_mode and game.battle.sides[0].hand.has("earth-orun-living-mountain"),"featured card in practice opening hand")
	game.battle.mulligan([])
	game.render()
	await capture("collection-practice")
	game.battle.outcome=0; game.after_action()
	check(game.model.profile==original and not game.model.profile.battle_pending,"practice victory cannot mutate adventure")
	game.page="deck"; game.start_practice("fire")
	game.retreat()
	check(game.model.profile==original,"practice retreat cannot damage adventure hero")
	game.practice_mode=false; game.page="deck"; game.collection_filters={}; game.render()
	root.size=Vector2i(1024,720)
	await process_frame
	game.render()
	await capture("collection-small")
	check(game.body.size.x<=game.size.x-40,"collection has no horizontal overflow at 1024")
	var file=game.model.save_path
	game.queue_free()
	await process_frame
	await create_timer(.1).timeout # Allow audio-thread playback releases before process exit.
	if FileAccess.file_exists(file): DirAccess.remove_absolute(file)
	print("FOUNDATIONS COLLECTION: %d/%d passed" % [checks-failed,checks])
	quit(1 if failed else 0)

func capture(label: String):
	await process_frame
	await process_frame
	if DisplayServer.get_name()!="headless":
		RenderingServer.force_draw()
		var path=ProjectSettings.globalize_path("res://../evidence/godot-collection-2026-09-20")
		DirAccess.make_dir_recursive_absolute(path)
		root.get_texture().get_image().save_png(path+"/"+label+".png")
