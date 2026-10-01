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

static func build(game):
	var title=game.row_at(game.body)
	game.label_at(title,"Collection",38)
	game.muted(title,"%d cards · Playtest library" % game.model.cards.size() if not game.adventure_deck_view else "%d / %d owned" % [game.model.profile.owned.size(),game.model.cards.size()],14)
	var layout=game.row_at(game.body)
	var sidebar=game.panel(layout)
	sidebar.get_parent().custom_minimum_size.x=224
	sidebar.get_parent().size_flags_horizontal=Control.SIZE_FILL
	game.label_at(sidebar,"Your deck",27)
	game.muted(sidebar,"%d / 30 cards" % game.constructed.deck.size(),14)
	var play=game.button_at(sidebar,"Play",func(): game.start_practice(game.constructed.element,"",true),not game.constructed.valid(game.constructed.deck))
	game.UIStyle.primary(play)
	play.tooltip_text="30 health each. 2-mana hero power. 10 maximum mana. All cards available for playtesting."
	var presets=OptionButton.new()
	presets.add_item("Load a starter deck…")
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
	var deck_scroll=ScrollContainer.new()
	deck_scroll.custom_minimum_size=Vector2(210,390)
	deck_scroll.horizontal_scroll_mode=ScrollContainer.SCROLL_MODE_DISABLED
	sidebar.add_child(deck_scroll)
	var entries=VBoxContainer.new()
	entries.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	deck_scroll.add_child(entries)
	var unique={}
	for id in game.constructed.deck: unique[id]=unique.get(id,0)+1
	for id in query(game.model.cards,unique,{"owned":true}):
		var c=game.model.cards[id]
		var remove=game.button_at(entries,"%d  %s  ×%d" % [c.cost,c.name,unique[id]],func(): game.constructed.remove(id); game.render())
		remove.text_overrun_behavior=TextServer.OVERRUN_TRIM_ELLIPSIS
		remove.alignment=HORIZONTAL_ALIGNMENT_LEFT
		remove.custom_minimum_size.y=32
		remove.icon=game.UIStyle.art(id)
		remove.expand_icon=true
		remove.add_theme_constant_override("icon_max_width",28)
		remove.tooltip_text=c.name+"\n"+c.text+"\nClick to remove one copy."
	game.button_at(sidebar,"Earned collection",func(): game.collection_filters={"owned":true}; game.collection_page=0; game.render()).tooltip_text="Your original adventure inventory is preserved separately."
	var element=game.collection_filters.get("element","")
	var right=VBoxContainer.new()
	right.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation",10)
	layout.add_child(right)
	var filters=game.row_at(right)
	var search=LineEdit.new()
	search.name="CollectionSearch"
	search.placeholder_text="Search cards…"
	search.text=game.collection_filters.get("search","")
	search.size_flags_horizontal=Control.SIZE_EXPAND_FILL
	search.custom_minimum_size=Vector2(125,38)
	search.tooltip_text="Search names, rules, elements or rarities. Press Enter to search."
	search.text_submitted.connect(func(value): game.collection_filters.search=value; game.collection_page=0; game.render())
	filters.add_child(search)
	dropdown(game,filters,"type",["All types","Minions","Spells","Weapons"],["","minion","spell","weapon"])
	dropdown(game,filters,"rarity",["All rarities","Common","Rare","Epic","Legendary"],["","common","rare","epic","legendary"])
	dropdown(game,filters,"cost",["All mana","0","1","2","3","4","5","6","7+"],[-1,0,1,2,3,4,5,6,7])
	var tabs=game.row_at(right)
	for e in [""]+ELEMENTS:
		var tab=game.button_at(tabs,"All" if e=="" else e.capitalize(),func(): game.collection_filters.element=e; game.collection_page=0; game.render())
		if e==element: game.UIStyle.primary(tab)
	dropdown(game,tabs,"owned",["All cards","Owned"],[false,true])
	if not game.collection_filters.is_empty():
		var reset=game.button_at(tabs,"Reset",func(): game.collection_filters={}; game.collection_page=0; game.render())
		reset.tooltip_text="Clear search and all filters."
	var ids=query(game.model.cards,game.model.profile.owned,game.collection_filters)
	var columns=clampi(int((game.size.x-310)/158),3,5)
	var per_page=columns*2
	var page_count=maxi(1,ceili(float(ids.size())/per_page))
	game.collection_page=clampi(game.collection_page,0,page_count-1)
	var grid=GridContainer.new()
	grid.name="CollectionGrid"
	grid.columns=columns
	grid.size_flags_horizontal=Control.SIZE_SHRINK_CENTER
	grid.add_theme_constant_override("h_separation",8)
	grid.add_theme_constant_override("v_separation",8)
	right.add_child(grid)
	for id in ids.slice(game.collection_page*per_page,(game.collection_page+1)*per_page):
		var cell=VBoxContainer.new()
		grid.add_child(cell)
		var count=game.model.profile.owned.get(id,0)
		var c=game.card_button(cell,id,func():
			var candidate=game.model.profile.deck.duplicate()
			if game.swap_index>=0: candidate[game.swap_index]=id
			if game.swap_index>=0 and game.model.deck_valid(candidate,game.model.profile): game.replace_card(id)
			else: inspect(game,id)
		,false,"Owned: %d" % count if count>0 else "Not owned · Available in practice")
		c.name="Catalog_"+id
		c.custom_minimum_size=Vector2(148,204)
		c.active_hint=false
		var quantity=game.muted(cell,"×%d" % count if count>0 else "Not owned",11) if game.adventure_deck_view else game.button_at(cell,"Add · %d/%d" % [game.constructed.deck.count(id),1 if game.model.cards[id].rarity=="legendary" else 2],func(): game.constructed.add(id); game.render(),game.constructed.deck.size()>=30 or game.constructed.deck.count(id)>=(1 if game.model.cards[id].rarity=="legendary" else 2))
		if quantity is Button:
			quantity.custom_minimum_size.y=30
			quantity.tooltip_text="Remove a card from your deck first." if game.constructed.deck.size()>=30 else ("Maximum copies already in your deck." if quantity.disabled else "Add one copy to your deck.")
		if quantity is Label: quantity.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	if ids.is_empty():
		game.label_at(right,"No matching cards",25)
		game.button_at(right,"Clear filters",func(): game.collection_filters={}; game.collection_page=0; game.render())
	var paging=game.row_at(right)
	game.button_at(paging,"←",func(): game.collection_page-=1; game.render(),game.collection_page==0).tooltip_text="Previous page"
	var count_label=game.muted(paging,"%d cards · %d / %d" % [ids.size(),game.collection_page+1,page_count],12)
	count_label.horizontal_alignment=HORIZONTAL_ALIGNMENT_CENTER
	game.button_at(paging,"→",func(): game.collection_page+=1; game.render(),game.collection_page==page_count-1).tooltip_text="Next page"

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
