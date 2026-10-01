extends SceneTree
const Model=preload("res://model.gd")
const Battle=preload("res://battle.gd")
var model=Model.new()
var checks=0
var failures=0
func check(ok,label):
	checks+=1
	if not ok: failures+=1; printerr("FAIL: "+label)
func fixture():
	var b=Battle.new(model.cards,["home-spark","home-breeze-finch","home-shore-guard","home-cloudling","home-mending-tide"],["home-spark","home-breeze-finch","home-shore-guard","home-cloudling","home-mending-tide"],30,30,model.world.classes[0],2)
	b.sides[0].mana=1; b.sides[0].hand=[]
	return b
func _initialize():
	var life=fixture()
	life.sides[0].hp=2; life.sides[0].weapon={"attack":3,"durability":2,"lifesteal":true}
	life.summon(1,"home-shore-guard")
	life.sides[1].board[0].atk=3; life.sides[1].board[0].hp=2
	check(life.ai_choice(0).kind=="attack" and life.ai_step(0) and life.sides[0].hp==2 and life.outcome==-1,"AI recognizes Lifesteal surviving otherwise lethal retaliation")
	life=fixture(); life.sides[0].hp=2; life.sides[0].weapon={"attack":3,"durability":2,"lifesteal":true}
	life.summon(1,"home-shore-guard"); life.sides[1].board[0].atk=3; life.sides[1].board[0].divine_shield=true
	check(life.ai_choice(0).kind!="attack","AI does not count blocked Lifesteal as survival")
	life.sides[1].board[0].divine_shield=false; life.sides[0].weapon.lifesteal=false
	check(life.ai_choice(0).kind!="attack","AI rejects same lethal trade without Lifesteal")
	var b=fixture(); b.sides[0].hand=["home-spark"]; b.summon(1,"home-breeze-finch")
	check(b.ai_step(0) and b.sides[1].board.is_empty() and b.sides[1].hp==30,"damage spell removes valuable minion")
	b=fixture(); b.sides[0].hand=["home-spark"]; b.sides[1].hp=2; b.summon(1,"home-breeze-finch")
	check(b.ai_step(0) and b.outcome==0,"lethal beats removal")
	b=fixture(); b.summon(0,"water-reef-otter"); b.summon(1,"home-breeze-finch"); b.sides[0].board[0].ready=true; b.sides[0].board[0].summoning_sick=false
	check(b.ai_step(0) and b.sides[1].board.is_empty() and b.sides[0].board[0].hp==1,"takes surviving trade")
	b=fixture(); b.summon(0,"home-resin-crab"); b.summon(1,"home-cloudling"); b.sides[0].board[0].ready=true; b.sides[0].board[0].summoning_sick=false
	check(b.ai_step(0) and b.sides[1].hp==29 and b.sides[0].board.size()==1,"avoids pointless suicide")
	b=fixture(); b.sides[0].hand=["home-mending-tide"]
	check(not b.ai_step(0) and b.sides[0].hand.size()==1,"does not heal full health")
	b=fixture(); b.sides[0].hand=["air-tailwind"]
	check(not b.ai_step(0),"holds buff on empty board")
	b=fixture(); b.sides[0].hand=["the-coin"]
	check(not b.ai_step(0),"holds Coin without enabled play")
	b=fixture(); b.sides[0].hand=["the-coin","home-shore-guard"]
	check(b.ai_step(0) and b.sides[0].mana==2 and not b.sides[0].hand.has("the-coin"),"Coin enables two-drop")
	b=fixture(); b.summon(0,"home-cloudling"); b.summon(1,"home-shore-guard"); b.sides[0].board[0].ready=true; b.sides[0].board[0].summoning_sick=false
	check(b.ai_choice(0).target==b.sides[1].board[0].uid,"AI respects Taunt")
	b=fixture(); b.job=model.world.classes[2]; b.sides[0].mana=2; b.summon(1,"home-breeze-finch"); b.sides[1].board[0].hp=1
	check(b.ai_step(0) and b.sides[1].board.is_empty() and b.sides[0].power_used,"targeted power finishes minion")
	b=fixture(); b.summon(0,"water-dewdrop-newt"); b.summon(1,"home-cloudling")
	b.sides[0].board[0].ready=true; b.sides[0].board[0].summoning_sick=false
	check(b.ai_step(0) and b.sides[1].board.is_empty(),"Poisonous trades into a larger creature")
	b=fixture(); b.summon(0,"home-cloudling"); b.summon(1,"water-dewdrop-newt")
	b.sides[0].board[0].ready=true; b.sides[0].board[0].summoning_sick=false
	check(b.ai_choice(0).target==-1,"Avoids losing large creature to poison retaliation")
	b=fixture(); b.sides[0].hp=20
	var source={"lifesteal":true,"poisonous":true}
	b.summon(1,"water-shellback-tortoise")
	check(b.damage_choice(0,1,source).target==-1,"Shield prevents poison kill and Lifesteal value")
	b.sides[1].board[0].divine_shield=false
	check(b.damage_choice(0,1,source).target==b.sides[1].board[0].uid,"Attributed poison spell recognizes lethal minion damage")
	check(b.healing_value(0,20,source)==7.0 and b.healing_value(1,20,source)==0.0,"Lifesteal utility counts only missing health")
	b=fixture(); b.sides[0].mana=10; b.summon(0,"air-wind-archivist")
	b.summon(1,"home-cloudling"); b.sides[1].board[0].hp=3
	b.cards["test-wave"]={"id":"test-wave","name":"Wave","cost":1,"type":"spell","onPlay":[{"effect":"damageEnemies","amount":2}]}
	b.sides[0].hand=["test-wave"]
	var choice=b.ai_choice(0)
	check(choice.kind=="play" and choice.score>=b.creature_value(b.sides[1].board[0]) and b.ai_step(0) and b.sides[1].board.is_empty(),"Area removal valuation includes Spell Damage")
	print("AI DECISIONS: %d / %d passed" % [checks-failures,checks])
	quit(1 if failures else 0)
