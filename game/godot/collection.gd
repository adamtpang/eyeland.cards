extends RefCounted
## Catalog browsing never grants ownership. Practice borrows cards in memory only.
const ELEMENTS=["air","water","fire","earth"]
const THEMES={"air":"Draw · Flocks · Board buffs","water":"Healing · Recovery · Resilience","fire":"Damage · Pressure · Board clears","earth":"Armor · Taunt · Mana growth"}

static func query(cards: Dictionary,owned: Dictionary,filters: Dictionary) -> Array:
	var result=[]
	for id in cards:
		var c=cards[id]
		if filters.get("owned",false) and not owned.has(id): continue
		if filters.get("element","")!="" and c.element!=filters.element: continue
		if filters.get("type","")!="" and c.type!=filters.type: continue
		if filters.get("rarity","")!="" and c.rarity!=filters.rarity: continue
		var cost=int(filters.get("cost",-1))
		if cost>=0 and (int(c.cost)!=cost if cost<7 else c.cost<7): continue
		var term=str(filters.get("search","")).strip_edges().to_lower()
		if not term.is_empty() and not (c.name+" "+c.text+" "+c.element+" "+c.rarity).to_lower().contains(term): continue
		result.append(id)
	result.sort_custom(func(a,b): return cards[a].cost<cards[b].cost if cards[a].cost!=cards[b].cost else cards[a].name.naturalnocasecmp_to(cards[b].name)<0)
	return result

static func practice_deck(cards: Dictionary,element: String) -> Array:
	var ids=query(cards,{}, {"element":element})
	var deck=ids.duplicate()
	# One of each element card, then a second copy of five early minions.
	for id in ids:
		if deck.size()==30: break
		if cards[id].type=="minion" and cards[id].rarity!="legendary": deck.append(id)
	return deck

static func dropdown(game,parent,key: String,labels: Array,values: Array):
	var control=OptionButton.new()
	control.name="Filter_"+key
	control.custom_minimum_size=Vector2(105,38)
	for text in labels: control.add_item(text)
	control.select(maxi(0,values.find(game.collection_filters.get(key,values[0]))))
	control.item_selected.connect(func(index): game.collection_filters[key]=values[index]; game.collection_page=0; game.render())
	parent.add_child(control)
	return control

## The card book, laid out like Hearthstone's collection: element tabs across the top, a
## page of eight large cards, mana filters underneath, and the deck as a slim list on the
## right. Clicking a card adds it to the deck, clicking a deck row removes it, and a right
## click opens the card. The same screen edits the 30-card practice deck (every card) and
## the 10-card adventure deck (only earned cards).
static func build(game): book(game,false)

static func book(game,adventure: bool):
	var adv=game.adventure() if adventure else {}
	var deck: Array=adv.deck if adventure else game.constructed.deck
	var capacity: int=game.DECK_SIZE if adventure else 30
	var limit=func(id: String) -> int:
		if adventure: return int(adv.cards.get(id,0))
		return 1 if game.model.cards[id].rarity=="legendary" else 2
	var add=func(id: String):
		if deck.size()>=capacity or deck.count(id)>=limit.call(id): return
		if adventure:
			deck.append(id); game.settle_quest(); game.model.save()
		else: game.constructed.add(id)
		game.render()
	var remove=func(id: String):
		if adventure:
			deck.erase(id); game.model.save()
		else: game.constructed.remove(id)
		game.render()
	var filters: Dictionary=game.collection_filters
	var layout=game.row_at(game.body)
	layout.add_theme_constant_override("separation",16)
	var pages=VBoxContainer.new()
	pages.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	pages.add_theme_constant_override("separation",10)
	layout.add_child(pages)
	# element tabs and search
	var tabs=game.row_at(pages)
	var element=filters.get("element","")
	for e in [""]+ELEMENTS:
		var tab=game.button_at(tabs,"All" if e=="" else e.capitalize(),func(): game.collection_filters.element=e; game.collection_page=0; game.render())
		tab.custom_minimum_size=Vector2(84,38)
		if e==element: game.UIStyle.primary(tab)
	var gap=Control.new()
	gap.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	tabs.add_child(gap)
	var search=LineEdit.new()
	search.name="CollectionSearch"
	search.placeholder_text="Search"
	search.text=filters.get("search","")
	search.custom_minimum_size=Vector2(190,38)
	search.tooltip_text="Search names and rules. Press Enter."
	search.text_submitted.connect(func(value): game.collection_filters.search=value; game.collection_page=0; game.render())
	tabs.add_child(search)
	# one page of cards
	var ids=query(game.model.cards,adv.cards if adventure else game.model.profile.owned,filters.merged({"owned":true},true) if adventure else filters)
	var columns=4 if game.size.x>=1180 else 3
	var per_page=columns*2
	var page_count=maxi(1,ceili(float(ids.size())/per_page))
	game.collection_page=clampi(game.collection_page,0,page_count-1)
	var grid=GridContainer.new()
	grid.name="CollectionGrid"
	grid.columns=columns
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.custom_minimum_size.y=2*224+12
	grid.add_theme_constant_override("h_separation",14)
	grid.add_theme_constant_override("v_separation",12)
	pages.add_child(grid)
	for id in ids.slice(game.collection_page*per_page,(game.collection_page+1)*per_page):
		var held=deck.count(id)
		var most: int=limit.call(id)
		var full=held>=most
		var c=game.card_button(grid,id,add.bind(id),false,"")
		c.name="Catalog_"+id
		c.custom_minimum_size=Vector2(163,224)
		c.active_hint=false
		c.tooltip_text+="\nClick to add. Right-click to look closer."
		if full: c.modulate=Color(1,1,1,.55)
		c.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index==MOUSE_BUTTON_RIGHT: inspect(game,id))
		if held>0 or adventure:
			var badge=Label.new()
			badge.text="%d / %d" % [held,most]
			badge.add_theme_font_size_override("font_size",12)
			badge.add_theme_color_override("font_color",game.UIStyle.P.text)
			badge.add_theme_stylebox_override("normal",game.UIStyle.plate(game.UIStyle.P.accent if held>0 else game.UIStyle.P.panel,game.UIStyle.P.panel_edge,8,5))
			badge.mouse_filter=Control.MOUSE_FILTER_IGNORE
			c.add_child(badge)
			badge.position=Vector2(163-50,-8)
	if ids.is_empty():
		game.muted(pages,"No cards match." if not adventure or not filters.is_empty() else "No cards yet.",16).horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	# page arrows with the mana filter between them
	var foot=game.row_at(pages)
	foot.alignment=BoxContainer.ALIGNMENT_CENTER
	var back=game.button_at(foot,"<",func(): game.collection_page-=1; game.render(),game.collection_page==0)
	back.custom_minimum_size=Vector2(44,38)
	back.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	back.tooltip_text="Previous page"
	var cost=int(filters.get("cost",-1))
	for value in range(8):
		var gem=game.button_at(foot,"7+" if value==7 else str(value),func():
			if cost==value: game.collection_filters.erase("cost")
			else: game.collection_filters.cost=value
			game.collection_page=0; game.render())
		gem.name="Mana%d" % value
		gem.custom_minimum_size=Vector2(38,38)
		gem.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
		gem.tooltip_text="Show only cards that cost %s mana." % gem.text
		if cost==value: game.UIStyle.primary(gem)
	var forward=game.button_at(foot,">",func(): game.collection_page+=1; game.render(),game.collection_page==page_count-1)
	forward.custom_minimum_size=Vector2(44,38)
	forward.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	forward.tooltip_text="Next page"
	game.muted(foot,"Page %d of %d" % [game.collection_page+1,page_count],12)
	# the deck list
	var sidebar=game.panel(layout)
	sidebar.get_parent().name="AdventureDeck" if adventure else "PracticeDeck"
	sidebar.get_parent().custom_minimum_size.x=236
	sidebar.get_parent().size_flags_horizontal=Control.SIZE_FILL
	sidebar.add_theme_constant_override("separation",8)
	var heading=game.row_at(sidebar)
	game.label_at(heading,"Your deck",20).size_flags_horizontal=Control.SIZE_EXPAND_FILL
	game.label_at(heading,"%d / %d" % [deck.size(),capacity],16)
	var deck_scroll=ScrollContainer.new()
	deck_scroll.custom_minimum_size=Vector2(212,382)
	deck_scroll.size_flags_vertical=Control.SIZE_EXPAND_FILL
	deck_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(deck_scroll)
	var entries=VBoxContainer.new()
	entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	entries.add_theme_constant_override("separation",3)
	deck_scroll.add_child(entries)
	var unique={}
	for id in deck: unique[id]=unique.get(id,0)+1
	for id in query(game.model.cards,unique,{"owned":true}):
		var c=game.model.cards[id]
		var row=game.button_at(entries,"%d   %s%s" % [c.cost,c.name,"   x%d" % unique[id] if unique[id]>1 else ""],remove.bind(id))
		row.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		row.alignment=HORIZONTAL_ALIGNMENT_LEFT
		row.custom_minimum_size.y=30
		row.add_theme_font_size_override("font_size",13)
		row.tooltip_text=c.name+"\n"+c.text+"\nClick to take one out."
	if adventure:
		var done=game.button_at(sidebar,"Done" if deck.size()==capacity else "Add %d more" % (capacity-deck.size()),func(): game.page="map"; game.render())
		if deck.size()==capacity: game.UIStyle.primary(done)
	else:
		var play=game.button_at(sidebar,"Play",func(): game.start_practice(game.constructed.element,"",true),not game.constructed.valid(game.constructed.deck))
		game.UIStyle.primary(play)
		play.tooltip_text="A full 30-card battle with every card available. Your adventure is not affected."
		var presets=OptionButton.new()
		presets.add_item("Starter decks")
		for e in ELEMENTS: presets.add_item(e.capitalize())
		presets.item_selected.connect(func(index):
			if index>0:
				var confirm=ConfirmationDialog.new()
				confirm.dialog_text="Replace this deck with the "+ELEMENTS[index-1].capitalize()+" starter deck?"
				confirm.confirmed.connect(func(): game.constructed.preset(ELEMENTS[index-1]); confirm.queue_free(); game.render())
				confirm.canceled.connect(confirm.queue_free)
				game.add_child(confirm); confirm.popup_centered()
		)
		sidebar.add_child(presets)

static func inspect(game,id: String):
	game.close_inspection()
	var veil=ColorRect.new()
	veil.name="CardInspection"
	veil.color=Color(.01,.025,.035,.88)
	game.add_child(veil)
	veil.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	game.inspection=veil
	var center=CenterContainer.new()
	veil.add_child(center)
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var content=game.panel(center)
	content.get_parent().custom_minimum_size.x=325
	var face=game.card_button(content,id,func(): pass,false)
	face.custom_minimum_size=Vector2(249,342)
	face.mouse_filter=Control.MOUSE_FILTER_IGNORE
	face.active_hint=false
	var c=game.model.cards[id]
	game.muted(content,c.element.capitalize()+" · "+c.rarity.capitalize()+" · "+c.type.capitalize(),13)
	game.muted(content,"Owned: %d" % game.model.profile.owned.get(id,0),13)
	var try_button=game.button_at(content,"Try in "+c.element.capitalize()+" deck",func(): game.close_inspection(); game.start_practice(c.element,id))
	try_button.tooltip_text="Borrow a full deck. This card starts in your opening hand; choose Keep to retain it. No adventure rewards."
	var close=game.button_at(content,"Close",game.close_inspection)
	close.grab_focus()
