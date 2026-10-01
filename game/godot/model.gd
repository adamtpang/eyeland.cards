extends RefCounted
## Small, explicit port of the existing starter rules. No legacy saves touched.
var cards: Dictionary = {}
var world: Dictionary
var profile: Dictionary = {}
var save_path = "user://home-v1.json"
var save_blocked = false
var error = ""

func _init():
	world = JSON.parse_string(FileAccess.get_file_as_string("res://data/world.json"))
	var data = JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
	for card in data.sets[0].cards:
		cards[card.id] = card

func starter(element: String) -> String:
	for item in world.elements:
		if item.id == element:
			return item.starter
	return ""

func valid_class(id: String) -> bool:
	return world.classes.any(func(c): return c.id == id)

func new_profile(job: String, element: String):
	if not valid_class(job) or starter(element).is_empty():
		return
	var deck = [starter(element), "home-shore-guard", "home-breeze-finch", "home-spark", "home-mending-tide"]
	var owned = {}
	for id in deck:
		owned[id] = 1
	profile = {"version":1,"job":job,"element":element,"hp":30,"x":3,"y":4,"won":false,"resin":0,"owned":owned,"deck":deck,"met_home":false,"battle_pending":false,"seed":1}

func land(x: int, y: int) -> bool:
	return y >= 0 and y < world.terrain.size() and x >= 0 and x < world.terrain[y].length() and world.terrain[y][x] == "."

func move(dx: int, dy: int) -> bool:
	if abs(dx) + abs(dy) != 1 or not land(profile.x + dx, profile.y + dy):
		return false
	profile.x += dx
	profile.y += dy
	return true

func nearby(id: String) -> bool:
	return world.landmarks.any(func(p): return p.id == id and abs(p.x-profile.x)+abs(p.y-profile.y)<=1)

func deck_valid(deck: Array, p: Dictionary) -> bool:
	if deck.size() != 5 or not deck.has(starter(p.element)):
		return false
	var counts = {}
	for id in deck:
		if not id is String or not cards.has(id):
			return false
		counts[id] = counts.get(id, 0) + 1
		if counts[id] > p.owned.get(id, 0) or counts[id] > (1 if cards[id].get("rarity", "common") == "legendary" else 2):
			return false
	return true

func valid(p) -> bool:
	if not p is Dictionary:
		return false
	for key in ["version","job","element","hp","x","y","won","resin","owned","deck","met_home","battle_pending","seed"]:
		if not p.has(key): return false
	if p.version != 1 or not p.job is String or not p.element is String or not valid_class(p.job) or starter(p.element).is_empty(): return false
	for key in ["hp","x","y","resin","seed"]:
		if not (p[key] is int or p[key] is float) or not is_finite(p[key]) or p[key] != floor(p[key]): return false
	if not p.won is bool or not p.met_home is bool or not p.battle_pending is bool: return false
	if p.hp < 1 or p.hp > 30 or p.seed < 1 or p.seed > 1000000 or not land(p.x,p.y): return false
	if not p.owned is Dictionary or not p.deck is Array: return false
	if p.has("world_position"):
		if not p.world_position is Array or p.world_position.size()!=3: return false
		for value in p.world_position:
			if not (value is float or value is int) or not is_finite(value) or absf(value)>100: return false
	var expected = [starter(p.element),"home-shore-guard","home-breeze-finch","home-spark","home-mending-tide"]
	if p.won: expected.append(world.encounter.reward)
	if p.owned.size() != expected.size() or p.resin != (world.encounter.resin if p.won else 0): return false
	for id in expected:
		if p.owned.get(id,0) != 1: return false
	return deck_valid(p.deck,p)

func save() -> bool:
	if save_blocked or not valid(profile):
		error = "Save unavailable. Existing data preserved."
		return false
	var file = FileAccess.open(save_path + ".tmp", FileAccess.WRITE)
	if file == null:
		error = "Could not write save; progress is only in memory."
		return false
	file.store_string(JSON.stringify(profile))
	file.flush()
	file.close()
	var result = DirAccess.rename_absolute(save_path + ".tmp", save_path)
	if result != OK:
		error = "Could not replace save; progress is only in memory."
		return false
	error = ""
	return true

func load_profile() -> bool:
	if not FileAccess.file_exists(save_path): return false
	var parser = JSON.new()
	var parsed = parser.parse(FileAccess.get_file_as_string(save_path))
	var p = parser.data if parsed == OK else null
	if not valid(p):
		save_blocked = true
		error = "Unrecognized or damaged save preserved. Play a temporary adventure, or restore your save manually."
		return false
	profile = p
	if profile.battle_pending:
		profile.battle_pending = false
		profile.hp = 1
		profile.x = 6
		profile.y = 5
		profile.world_position=[0,2,6]
		save()
	return true

func finish(won: bool, hp: int) -> bool:
	if not profile.battle_pending: return false
	var reward = won and not profile.won
	profile.battle_pending = false
	profile.hp = clampi(hp,1,30) if won else 1
	if reward:
		profile.won = true
		profile.owned[world.encounter.reward] = 1
		profile.resin += world.encounter.resin
	if not won:
		profile.x = 6
		profile.y = 5
	save()
	return reward
