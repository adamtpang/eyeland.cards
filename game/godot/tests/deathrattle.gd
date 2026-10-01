extends SceneTree
const Model=preload("res://model.gd")
const Battle=preload("res://battle.gd")
const Collection=preload("res://collection.gd")
var model=Model.new()
var checks=0
var failed=0
func check(ok,label):
	checks+=1
	if not ok: failed+=1; printerr("FAIL: "+label)
func fixture():
	var deck=Collection.practice_deck(model.cards,"fire")
	return Battle.new(model.cards,deck,deck,30,30,model.world.classes[0],1)
func _initialize():
	var b=fixture()
	b.summon(0,"home-cloudling"); b.summon(0,"fire-coalback-pup"); b.summon(0,"home-mossling")
	var dead=b.sides[0].board[1].uid
	b.hurt(0,dead,2); b.clean()
	check(b.sides[0].board[1].id=="home-breeze-finch","Deathrattle summons at dying minion position")
	check(not b.sides[0].board[1].ready,"Deathrattle summon has sickness")
	check(b.minion(0,dead).is_empty(),"dead creature removed")
	b.clean(); check(b.sides[0].board.size()==3,"Deathrattle fires only once")
	b=fixture()
	for i in range(7): b.summon(0,"fire-coalback-pup")
	for m in b.sides[0].board: m.hp=0
	b.clean()
	check(b.sides[0].board.size()==7 and b.sides[0].board.all(func(m): return m.id=="home-breeze-finch"),"simultaneous deaths free all seven slots")
	b=fixture()
	b.summon(1,"fire-coalback-pup"); b.summon(0,"fire-coalback-pup")
	b.sides[1].board[0].deathrattle=[{"effect":"damageEnemies","amount":5}]
	b.sides[0].board[0].deathrattle=[{"effect":"summon","card":"home-breeze-finch","amount":1}]
	b.sides[0].board[0].hp=0; b.sides[1].board[0].hp=0
	b.clean()
	check(b.sides[0].board.size()==1,"global summon order, not side order, determines trigger order")
	b=fixture()
	b.summon(0,"fire-coalback-pup"); b.summon(1,"fire-coalback-pup")
	b.sides[0].board[0].deathrattle=[{"effect":"damageEnemies","amount":5}]
	b.sides[0].board[0].hp=0; b.clean()
	check(b.sides[1].board.size()==1 and b.sides[1].board[0].id=="home-breeze-finch","chained death batch resolves")
	b=fixture()
	b.summon(0,"fire-coalback-pup"); b.summon(0,"fire-coalback-pup"); b.summon(0,"home-mossling")
	b.sides[0].board[0].hp=0; b.sides[0].board[1].hp=0; b.clean()
	check(b.sides[0].board[2].id=="home-mossling","adjacent deaths preserve replacement placement")
	print("DEATHRATTLE: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
