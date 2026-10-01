extends SceneTree
var games=0
var actions=0
var failed=false
func require(ok: bool,message: String):
	if not ok:
		failed=true
		push_error(message)
func _initialize():
	var m=preload("res://model.gd").new()
	var elements=["air","water","fire","earth"]
	for first in elements:
		for second in elements:
			for seed_value in range(10):
				var a=preload("res://collection.gd").practice_deck(m.cards,first)
				var d=preload("res://collection.gd").practice_deck(m.cards,second)
				var b=preload("res://battle.gd").new(m.cards,a,d,30,30,m.world.classes[seed_value%m.world.classes.size()],seed_value,true,-1)
				b.mulligan([])
				for step in range(2000):
					if b.outcome!=-1: break
					var owner=b.active if b.pending_choice.is_empty() else int(b.pending_choice.owner)
					if not b.ai_step(owner):
						require(b.end_turn(owner),"AI unable to act or pass: %s/%s seed %d step %d" % [first,second,seed_value,step])
					var uids=[]
					for side in b.sides:
						require(side.hand.size()<=10 and side.board.size()<=7,"Hand/board cap")
						require(side.max_mana>=0 and side.max_mana<=10 and side.mana>=0 and side.mana<=10,"Mana bounds")
						require(side.hp<=side.max_hp and side.armor>=0,"Hero health/armor bounds")
						for creature in side.board:
							require(not uids.has(creature.uid),"Unique live minion identity")
							uids.append(creature.uid)
							require(creature.hp<=creature.max_hp,"Creature maximum health")
							if b.pending_choice.is_empty() and b.outcome==-1: require(creature.hp>0,"Resolved board contains no dead creatures")
						actions+=1
						if failed: quit(1); return
				require(b.outcome in [0,1,2],"Match terminates within action budget")
				if failed: quit(1); return
				games+=1
	print("MATCH INVARIANTS: %d complete games, %d checked side states" % [games,actions])
	quit(1 if failed else 0)
