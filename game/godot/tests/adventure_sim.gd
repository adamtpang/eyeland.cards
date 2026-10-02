extends SceneTree
## How hard is each Home Island fight for an average player? Both sides are played by the
## same AI, 300 games each, with the deck a player would have on arrival.
const Battle=preload("res://battle.gd")
func _initialize():
	var game=preload("res://main.gd")
	var model=preload("res://model.gd").new()
	var job=model.world.classes[0]
	var deck=["home-emberling","home-shore-guard","home-shore-guard","home-breeze-finch","home-breeze-finch","home-breeze-finch","home-spark","home-spark","home-mending-tide","home-mending-tide"]
	var swaps={"encounter":[],"camp2":["home-resin-crab"],"camp3":["earth-mossback-cub","earth-mossback-cub"],"warden":["earth-mossback-cub","earth-mossback-cub","water-reef-otter","water-reef-otter"]}
	var weak=["home-mending-tide","home-mending-tide","home-breeze-finch","home-breeze-finch"]
	for id in ["encounter","camp2","camp3","warden"]:
		var plan=game.ENCOUNTERS[id]
		var mine=deck.duplicate()
		for i in range(swaps[id].size()):
			mine.erase(weak[i])
			mine.append(swaps[id][i])
		var wins=0
		var turns=0
		for n in range(300):
			var b=Battle.new(model.cards,mine,plan.deck,game.START_HP,plan.hp,job,n+1,false,0)
			b.sides[0].max_hp=game.START_HP
			b.enemy_power=false
			var guard=0
			while b.outcome==-1 and guard<2000:
				guard+=1
				if not b.ai_step(b.active): b.end_turn(b.active)
			if b.outcome==0: wins+=1
			turns+=ceili(b.turn/2.0)
		print("SIM %s: player wins %d / 300 (%d%%), average %.1f turns" % [plan.name,wins,roundi(wins/3.0),turns/300.0])
	quit(0)
