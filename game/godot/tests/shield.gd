extends SceneTree
const Model=preload("res://model.gd")
const Battle=preload("res://battle.gd")
const Collection=preload("res://collection.gd")
var checks=0
var failed=0
func check(ok,label):
	checks+=1
	if not ok: failed+=1; printerr("FAIL: "+label)
func _initialize():
	var m=Model.new()
	var deck=Collection.practice_deck(m.cards,"water")
	var b=Battle.new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.summon(0,"water-shellback-tortoise")
	var turtle=b.sides[0].board[0]
	check(turtle.divine_shield,"summon gains shield")
	b.hurt(0,turtle.uid,0)
	check(turtle.divine_shield,"zero damage preserves shield")
	b.hurt(0,turtle.uid,50)
	check(turtle.hp==4 and not turtle.divine_shield,"shield absorbs entire damage instance")
	b.hurt(0,turtle.uid,1)
	check(turtle.hp==3,"subsequent damage applies")
	turtle.divine_shield=true; turtle.ready=true; turtle.summoning_sick=false
	b.summon(1,"home-cloudling")
	check(b.attack(0,turtle.uid,b.sides[1].board[0].uid),"shielded creature attacks")
	check(turtle.hp==3 and not turtle.divine_shield and b.sides[1].board[0].hp==2,"retaliation consumes shield, attack still deals damage")
	b.summon(1,"water-shellback-tortoise")
	b.sides[0].hand=["fire-brushfire"]; b.sides[0].mana=10
	b.play(0,0)
	check(b.sides[1].board.size()==1 and b.sides[1].board[0].hp==4 and not b.sides[1].board[0].divine_shield,"area damage consumes shield without health loss")
	print("DIVINE SHIELD: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
