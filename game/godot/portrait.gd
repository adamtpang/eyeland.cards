extends Control
## Replaceable, original procedural placeholder portraits. No external art.
var card_id = ""
var element = "earth"

func _draw():
	var colors = {"fire":Color("ef986c"),"water":Color("76cddd"),"earth":Color("abc879"),"air":Color("cbbcef")}
	var tint = colors.get(element, Color.WHITE)
	var center = size / 2
	var r = minf(size.y * 0.40, 28)
	draw_circle(center, r * 1.22, Color("142c39"))
	if "spark" in card_id:
		draw_colored_polygon(PackedVector2Array([center+Vector2(3,-r),center+Vector2(-13,4),center+Vector2(0,4),center+Vector2(-3,r),center+Vector2(14,-5),center+Vector2(1,-5)]),tint)
	elif "mending" in card_id:
		draw_arc(center, r*.7, 0, TAU, 40, tint, 5, true)
		draw_line(center+Vector2(-9,0),center+Vector2(9,0),Color.WHITE,4,true)
		draw_line(center+Vector2(0,-9),center+Vector2(0,9),Color.WHITE,4,true)
	else:
		if "crab" in card_id:
			for side in [-1,1]:
				for y in [-3,5,12]: draw_line(center+Vector2(side*10,y),center+Vector2(side*26,y+6),tint,3,true)
				draw_circle(center+Vector2(side*24,-12),7,tint)
		elif "finch" in card_id:
			draw_colored_polygon(PackedVector2Array([center,center+Vector2(-30,-12),center+Vector2(-15,13)]),tint.darkened(.2))
			draw_colored_polygon(PackedVector2Array([center,center+Vector2(30,-12),center+Vector2(15,13)]),tint.darkened(.2))
		else:
			draw_colored_polygon(PackedVector2Array([center+Vector2(-15,-5),center+Vector2(-16,-26),center+Vector2(-2,-13)]),tint)
			draw_colored_polygon(PackedVector2Array([center+Vector2(15,-5),center+Vector2(16,-26),center+Vector2(2,-13)]),tint)
			draw_circle(center+Vector2(-12,14),7,tint.darkened(.2))
			draw_circle(center+Vector2(12,14),7,tint.darkened(.2))
		draw_circle(center, r*.72,tint)
		if "guard" in card_id:
			draw_colored_polygon(PackedVector2Array([center+Vector2(-18,4),center+Vector2(0,0),center+Vector2(18,4),center+Vector2(0,25)]),Color("698a7b"))
		for x in [-6,6]:
			draw_circle(center+Vector2(x,-4),3,Color("112430"))
			draw_circle(center+Vector2(x-1,-5),1,Color.WHITE)
		draw_arc(center+Vector2(0,3),4,0,PI,12,Color("112430"),1.5,true)
