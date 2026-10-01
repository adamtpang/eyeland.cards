extends RefCounted
const INK = Color("102833")
const PANEL = Color("183541")
const GOLD = Color("e6be77")
const TEXT = Color("f6eddc")
const MUTED = Color("a9bec1")
const TEAL = Color("77d2bd")
static var atlas: Texture2D
static var serif: Font
static var sans: Font
const IDS = ["home-emberling","home-tideling","home-mossling","home-cloudling","home-shore-guard","home-breeze-finch","home-spark","home-mending-tide","home-resin-crab"]

static func fonts():
	if serif == null:
		serif = load("res://assets/fonts/CormorantGaramond.ttf")
		sans = load("res://assets/fonts/Poppins-Regular.ttf")

static var art_aliases: Dictionary={}
static var card_art: Dictionary={}
static var card_atlases: Dictionary={}
static var art_manifest_loaded=false
static func art(id: String) -> Texture2D:
	if id=="the-coin": return load("res://assets/coin.svg")
	if not art_manifest_loaded:
		art_manifest_loaded=true
		var manifest_path="res://assets/cards/manifest.json"
		if FileAccess.file_exists(manifest_path):
			var manifest=JSON.parse_string(FileAccess.get_file_as_string(manifest_path))
			for element in manifest:
				var entry=manifest[element]
				var path="res://assets/cards/"+entry.file
				if not ResourceLoader.exists(path): continue
				var sheet=load(path)
				card_atlases[element]=sheet
				var cell=sheet.get_size()/Vector2(entry.columns,entry.rows)
				for i in range(entry.cards.size()):
					var portrait=AtlasTexture.new()
					portrait.atlas=sheet
					portrait.region=Rect2(Vector2(i%int(entry.columns),i/int(entry.columns))*cell,cell)
					card_art[entry.cards[i]]=portrait
	if card_art.has(id): return card_art[id]
	if art_aliases.is_empty():
		var data=JSON.parse_string(FileAccess.get_file_as_string("res://data/cards.json"))
		for card in data.sets[0].cards: art_aliases[card.id]=card.get("art",card.id)
	id=art_aliases.get(id,id)
	if atlas == null and ResourceLoader.exists("res://assets/creatures.png"):
		atlas = load("res://assets/creatures.png")
	if atlas == null: return null
	var index = IDS.find(id)
	if index < 0: return null
	var result = AtlasTexture.new()
	result.atlas = atlas
	var cell = atlas.get_size()/3.0
	result.region = Rect2(Vector2(index%3,index/3)*cell,cell)
	return result

static func box(color: Color, border: Color = Color("355360"), radius: int = 12, margin: int = 12) -> StyleBoxFlat:
	var result = StyleBoxFlat.new()
	result.bg_color=color
	result.border_color=border
	result.set_border_width_all(1)
	result.set_corner_radius_all(radius)
	result.content_margin_left=margin
	result.content_margin_right=margin
	result.content_margin_top=margin
	result.content_margin_bottom=margin
	return result

static func theme() -> Theme:
	fonts()
	var t = Theme.new()
	t.default_font=sans
	t.default_font_size=14
	t.set_color("font_color","Label",TEXT)
	t.set_color("font_color","Button",TEXT)
	t.set_color("font_disabled_color","Button",MUTED)
	t.set_stylebox("normal","Button",box(PANEL))
	t.set_stylebox("hover","Button",box(Color("294957"),GOLD))
	t.set_stylebox("pressed","Button",box(Color("3a5760"),GOLD))
	t.set_stylebox("disabled","Button",box(Color("142d37"),Color("29414a")))
	var focus = box(Color(0,0,0,0),GOLD)
	focus.set_border_width_all(2)
	t.set_stylebox("focus","Button",focus)
	for control in ["OptionButton","LineEdit"]:
		t.set_color("font_color",control,TEXT)
		t.set_color("font_hover_color",control,TEXT)
		t.set_color("font_focus_color",control,TEXT)
		t.set_stylebox("normal",control,box(INK,Color("47616b"),8,10))
		t.set_stylebox("hover",control,box(PANEL,GOLD,8,10))
		t.set_stylebox("focus",control,focus)
	t.set_color("font_placeholder_color","LineEdit",MUTED)
	t.set_color("caret_color","LineEdit",GOLD)
	t.set_color("selection_color","LineEdit",Color("376b70"))
	t.set_stylebox("panel","PopupMenu",box(INK,Color("47616b"),8,8))
	t.set_stylebox("hover","PopupMenu",box(PANEL,GOLD,5,6))
	t.set_color("font_color","PopupMenu",TEXT)
	t.set_color("font_hover_color","PopupMenu",TEXT)
	t.set_constant("outline_size","TooltipLabel",0)
	t.set_stylebox("panel","TooltipPanel",box(INK,GOLD,8,14))
	t.set_color("font_color","TooltipLabel",TEXT)
	return t

static func primary(b: Button):
	b.add_theme_stylebox_override("normal",box(GOLD,Color("f8d99b"),9))
	b.add_theme_stylebox_override("hover",box(Color("f3d299"),Color("ffe5b5"),9))
	b.add_theme_stylebox_override("pressed",box(Color("cba467"),GOLD,9))
	b.add_theme_color_override("font_color",INK)
	b.add_theme_color_override("font_hover_color",INK)
	b.add_theme_color_override("font_pressed_color",INK)

static var hero_textures: Dictionary={}
static func hero_art(job_id: String,power=false) -> Texture2D:
	var id={"warrior":"brace","ranger":"true-shot","wizard":"spark"}.get(job_id,"") if power else job_id
	if not hero_textures.has(id):
		var path="res://assets/heroes/"+id+".png"
		if not ResourceLoader.exists(path): return null
		hero_textures[id]=load(path)
	return hero_textures[id]
