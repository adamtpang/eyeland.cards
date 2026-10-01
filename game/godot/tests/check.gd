extends SceneTree
const Model=preload("res://model.gd")
const Battle=preload("res://battle.gd")
var checks=0
var failed=0

func check(condition: bool, message: String):
	checks+=1
	if not condition:
		failed+=1
		printerr("FAIL: "+message)

func _initialize():
	var m=Model.new()
	m.save_path="user://test-%d.json" % Time.get_ticks_usec()
	m.new_profile("warrior","fire")
	check(m.valid(m.profile),"fresh profile valid")
	check(m.profile.deck.size()==5,"five physical cards")
	check(not m.move(9,0),"reject teleport")
	m.profile.x=3
	m.profile.y=1
	check(not m.move(0,-1),"sea collision")
	var wrong=m.profile.deck.duplicate()
	wrong[1]="home-resin-crab"
	check(not m.deck_valid(wrong,m.profile),"unowned card rejected")
	wrong=m.profile.deck.duplicate()
	wrong[0]="home-breeze-finch"
	check(not m.deck_valid(wrong,m.profile),"starter protected")
	check(not m.finish(true,20),"no reward without encounter")
	m.profile.battle_pending=true
	check(m.finish(true,20),"first victory reward")
	check(m.profile.resin==2 and m.profile.owned["home-resin-crab"]==1,"reward quantities")
	m.profile.battle_pending=true
	check(not m.finish(true,20) and m.profile.resin==2,"rematch idempotency")
	wrong=m.profile.deck.duplicate()
	wrong[4]="home-resin-crab"
	check(m.deck_valid(wrong,m.profile),"earned card equip")
	m.profile.deck=wrong
	check(m.save(),"save writes")
	var loaded=Model.new()
	loaded.save_path=m.save_path
	check(loaded.load_profile() and loaded.profile.deck==wrong,"reload equipped reward")
	m.profile.battle_pending=true
	m.save()
	check(loaded.load_profile() and loaded.profile.hp==1 and not loaded.profile.battle_pending,"interrupted battle recovery")
	var bad=m.profile.duplicate(true)
	bad.hp="bad"
	check(not m.valid(bad),"invalid health type")
	bad=m.profile.duplicate(true)
	bad.version=999
	check(not m.valid(bad),"unknown version rejected")
	var f=FileAccess.open(m.save_path,FileAccess.WRITE)
	f.store_string("broken-save")
	f.close()
	check(not loaded.load_profile() and loaded.save_blocked,"malformed save preserved")
	check(not loaded.save() and FileAccess.get_file_as_string(m.save_path)=="broken-save","blocked save cannot overwrite")
	DirAccess.remove_absolute(m.save_path)
	var b=Battle.new(m.cards,m.profile.deck,m.world.encounter.deck,30,12,m.world.classes[0],5)
	check(not b.play(1,0),"out of turn play rejected")
	b.sides[0].hand=["home-emberling","home-spark"]
	check(not b.play(0,0),"insufficient mana rejected")
	b.sides[0].mana=10
	check(not b.play(0,1,999) and b.sides[0].mana==10,"invalid spell target does not spend")
	check(b.play(0,0) and b.sides[0].armor==2,"legendary battlecry")
	var uid=b.sides[0].board[0].uid
	check(not b.attack(0,uid,-1),"summoning sickness")
	b.sides[0].board[0].ready=true
	b.sides[0].board[0].summoning_sick=false
	b.summon(1,"home-shore-guard")
	b.sides[1].board[0].uid=999
	b.sides[1].board[0].atk=1
	b.sides[1].board[0].hp=4
	b.sides[1].board[0].max_hp=4
	check(not b.attack(0,uid,-1),"taunt blocks face attack")
	check(b.attack(0,uid,999) and b.sides[0].board[0].hp==3,"simultaneous creature damage")
	check(not b.attack(0,uid,999),"only one attack")
	check(b.play(0,0,-1) and b.sides[1].hp==10,"spell bypasses taunt")
	check(b.power() and not b.power(),"hero power once per turn")
	var wins=0
	for job in m.world.classes:
		for e in m.world.elements:
			for seed_value in range(25):
				m.new_profile(job.id,e.id)
				var sim=Battle.new(m.cards,m.profile.deck,m.world.encounter.deck,30,12,job,seed_value)
				var actions=0
				while sim.outcome==-1 and actions<500:
					if not sim.ai_step(sim.active): sim.end_turn(sim.active)
					actions+=1
				check(sim.outcome!=-1,"simulation terminates")
				if sim.outcome==0: wins+=1
	print("Godot checks: %d passed / %d; tutorial AI wins %d / 300" % [checks-failed,checks,wins])
	quit(1 if failed else 0)
