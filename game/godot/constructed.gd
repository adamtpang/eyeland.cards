extends RefCounted
## Local prototype deck. Catalog access is separate from earned adventure ownership.
const Collection=preload("res://collection.gd")
var cards: Dictionary
var deck: Array=[]
var element="air"
var path="user://constructed-v1.json"
var error=""
var blocked=false

func _init(catalog: Dictionary): cards=catalog

func valid(candidate: Variant,complete=true) -> bool:
	if not candidate is Array or candidate.size()>30 or (complete and candidate.size()!=30): return false
	var counts={}
	for id in candidate:
		if not id is String or not cards.has(id): return false
		counts[id]=counts.get(id,0)+1
		if counts[id]>(1 if cards[id].rarity=="legendary" else 2): return false
	return true

func preset(value: String):
	if value not in Collection.ELEMENTS: return
	element=value
	deck=Collection.practice_deck(cards,value)
	save()

func add(id: String) -> bool:
	var next=deck.duplicate(); next.append(id)
	if not valid(next,false): return false
	deck=next; save(); return true

func remove(id: String):
	deck.erase(id); save()

func save() -> bool:
	if blocked: return false
	if not valid(deck,false) or element not in Collection.ELEMENTS: error="Invalid deck was not saved."; return false
	var file=FileAccess.open(path+".tmp",FileAccess.WRITE)
	if file==null: error="Could not save your deck."; return false
	file.store_string(JSON.stringify({"version":1,"element":element,"deck":deck}))
	file.flush(); file.close()
	if DirAccess.rename_absolute(path+".tmp",path)!=OK: error="Could not replace deck save."; return false
	error=""; return true

func load_or_create(fallback: String):
	element=fallback
	deck=Collection.practice_deck(cards,fallback)
	if not FileAccess.file_exists(path): return
	var parser=JSON.new()
	var parsed=parser.parse(FileAccess.get_file_as_string(path))
	var data=parser.data if parsed==OK else null
	if not data is Dictionary or data.get("version")!=1 or not data.get("element") in Collection.ELEMENTS or not valid(data.get("deck"),false):
		blocked=true
		error="Unreadable deck save preserved. Edits are temporary this session."
		return
	element=data.element; deck=data.deck
