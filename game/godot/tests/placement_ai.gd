extends SceneTree
var checks=0
var failed=0
func check(ok: bool,label: String):
	checks+=1
	if not ok: failed+=1; push_error(label)
func _initialize():
	var m=preload("res://model.gd").new()
	var deck=preload("res://collection.gd").practice_deck(m.cards,"air")
	var b=preload("res://battle.gd").new(m.cards,deck,deck,30,30,m.world.classes[0],1)
	b.summon(0,"home-breeze-finch"); b.summon(0,"home-breeze-finch")
	b.sides[0].hand=["air-flock-captain"]; b.sides[0].mana=5; b.sides[0].power_used=true
	var choice=b.ai_choice(0)
	check(choice.kind=="play" and choice.position==1,"AI puts adjacent aura between two creatures")
	check(b.ai_step(0) and b.sides[0].board[1].id=="air-flock-captain" and b.sides[0].board[0].atk==4 and b.sides[0].board[2].atk==4,"Chosen placement actually applies both buffs")
	var before=b.sides[0].board.duplicate(true)
	b.best_placement(0,m.cards["air-wispwing"])
	check(b.sides[0].board==before,"Placement evaluation does not mutate battle")
	b.sides[0].board[0].ready=true; b.sides[0].board[2].ready=true
	var placement=b.best_placement(0,m.cards["air-wispwing"])
	check(placement.position in [0,3],"AI avoids displacing ready aura recipients")
	print("PLACEMENT AI: %d / %d passed" % [checks-failed,checks])
	quit(1 if failed else 0)
