extends SceneTree
var passed=0
var failed=0
func check(ok: bool,label: String):
	if ok: passed+=1
	else: failed+=1; push_error(label)
func _initialize():
	var model=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(model.cards,"water")
	var b=preload("res://battle.gd").new(model.cards,deck,deck,30,30,model.world.classes[0],1)
	b.sides[0].hp=20
	b.summon(0,"water-reef-otter")
	b.start_turn(0)
	check(b.attack(0,b.sides[0].board[0].uid,-1) and b.sides[0].hp==22,"Attacker heals its own hero")
	b.summon(1,"water-reef-otter")
	b.sides[1].hp=20
	b.start_turn(0)
	check(b.attack(0,b.sides[0].board[0].uid,b.sides[1].board[0].uid) and b.sides[0].hp==24 and b.sides[1].hp==22,"Both sides heal from combat damage")
	b.sides[0].board=[]; b.sides[1].board=[]
	b.summon(0,"water-reef-otter"); b.summon(1,"water-shellback-tortoise")
	b.start_turn(0)
	b.attack(0,b.sides[0].board[0].uid,b.sides[1].board[0].uid)
	check(b.sides[0].hp==24,"Shield blocks Lifesteal healing")
	b.sides[1].board=[]
	b.summon(1,"home-breeze-finch")
	var source={"type":"spell","lifesteal":true,"poisonous":true}
	b.resolve_effects(0,[{"effect":"damage","amount":5}],source,b.sides[1].board[0].uid)
	check(b.sides[0].hp==29 and b.sides[1].board[0].hp==0,"Effect attribution heals full damage and applies poison")
	b.clean(); b.summon(1,"home-mossling")
	b.resolve_effects(0,[{"effect":"damage","amount":1}],source,b.sides[1].board[0].uid)
	check(b.sides[0].hp==30 and b.sides[1].board[0].hp==0,"Poisonous effect destroys large minion and healing caps")
	b.clean(); b.summon(1,"water-shellback-tortoise")
	b.sides[0].hp=20
	b.resolve_effects(0,[{"effect":"damageEnemies","amount":1}],source)
	check(b.sides[0].hp==20 and b.sides[1].board[0].hp==4,"Shield blocks effect poison and Lifesteal")
	b.sides[1].board=[]; b.sides[1].armor=3
	b.resolve_effects(0,[{"effect":"damage","amount":2}],source,-1)
	check(b.sides[0].hp==22 and b.sides[1].armor==1 and b.sides[1].hp==22,"Armor damage heals but poison cannot destroy heroes")
	b.summon(0,"water-reef-otter")
	b.sides[0].board[0].deathrattle=[{"effect":"damage","amount":2}]
	b.sides[0].board[0].hp=0
	b.clean()
	check(b.sides[0].hp==24,"Deathrattle inherits live source Lifesteal")
	print("LIFESTEAL: ",passed," passed; ",failed," failed")
	quit(1 if failed else 0)
