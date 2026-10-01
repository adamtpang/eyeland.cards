extends RefCounted
## Design tokens for every screen. Three looks share one layout:
##   "day"     Sunlit Cel: flat colour, thick ink outlines, hard drop shadows
##   "night"   Inked Relic: indigo, bone line work, one ember accent
##   "classic" the earlier painted coastal look, kept for comparison
## Draw code reads UIStyle.P (the active look); nothing else should hard-code a colour.
const LOOKS = {
	"classic": {
		"ink":Color("102833"),"panel":Color("183541"),"panel2":Color("142e39"),"panel_edge":Color("34505a"),"panel_r":14,
		"accent":Color("e6be77"),"accent_hover":Color("f3d299"),"accent_press":Color("cba467"),"accent_edge":Color("f8d99b"),"accent_ink":Color("102833"),
		"text":Color("f6eddc"),"muted":Color("a9bec1"),"good":Color("77d2bd"),"eyebrow":Color("e6be77"),"bg":Color(0.035,0.075,0.10),
		"button":Color("183541"),"button_hover":Color("294957"),"button_press":Color("3a5760"),"button_disabled":Color("142d37"),
		"edge":Color("355360"),"edge_hover":Color("e6be77"),"edge_disabled":Color("29414a"),"edge_w":1,"radius":12,
		"shadow":Color(0,0,0,0),"shadow_offset":Vector2.ZERO,"shadow_size":0,
		"field":Color("102833"),"field_edge":Color("47616b"),"tip":Color("102833"),"tip_edge":Color("e6be77"),
		"board_art":true,"board":Color("102833"),"board_edge":Color("e6be77"),"board_edge_w":1,"board_r":28,"board_mark":Color(.75,.7,.5,.35),
		"card":Color("273d42"),"card_edge":Color("74674e"),"card_w":2,"card_r":12,"card_shadow":Color(0.01,0.025,0.035,.5),"card_shadow_size":5,"card_shadow_offset":Vector2(0,3),"art_w":0,
		"banner":Color("20363f"),"banner_text":Color("f6eddc"),"rules":Color("e8dcc3"),"rules_edge":Color("d3bc91"),"rules_text":Color("102833"),"tag_text":Color("576569"),
		"token_idle":Color("74674e"),"token_drop":Vector2.ZERO,"token_gap":false,"token_plate":Color("20363f"),"token_plate_text":Color("f6eddc"),"plate_r":6,"plate_w":1,"taunt":Color("b9c8ca"),
		"gem_shape":0,"gem_ring":Color("e6be77"),"gem_w":3,"gem_drop":Vector2(0,2),"gem_shadow":Color("152c36"),"gem_text":Color("fff8eb"),"gem_display":false,
		"mana":Color("317496"),"atk":Color("a87b36"),"hp":Color("a64e4b"),
		"back":Color("284c55"),"back_edge":Color("e6be77"),"pile":Color("293f41"),"pile_edge":Color("ad9566"),"arrow":Color("f0ba72"),
		"stat_text":Color("fff5db"),"stat_outline":Color("3a2924"),"mana_text":Color("8dcde8"),"timer_bg":Color("394d46"),
		"art_style":0,"display":["CormorantGaramond.ttf",0],"body":["Poppins-Regular.ttf",0],
	},
	"day": {
		"ink":Color("1d2a4d"),"panel":Color("ffffff"),"panel2":Color("eaf7fd"),"panel_edge":Color("1d2a4d"),"panel_r":18,
		"accent":Color("ffd23f"),"accent_hover":Color("ffe07a"),"accent_press":Color("f0b90f"),"accent_edge":Color("1d2a4d"),"accent_ink":Color("1d2a4d"),
		"text":Color("1d2a4d"),"muted":Color("4f5f85"),"good":Color("12b886"),"eyebrow":Color("ff6b57"),"bg":Color("7fd3ee"),
		"button":Color("ffffff"),"button_hover":Color("fff3c4"),"button_press":Color("ffe07a"),"button_disabled":Color("d9e6ee"),
		"edge":Color("1d2a4d"),"edge_hover":Color("1d2a4d"),"edge_disabled":Color("8a97b5"),"edge_w":3,"radius":14,
		"shadow":Color("1d2a4d"),"shadow_offset":Vector2(0,4),"shadow_size":1,
		"field":Color("ffffff"),"field_edge":Color("1d2a4d"),"tip":Color("ffffff"),"tip_edge":Color("1d2a4d"),
		"board_art":false,"board":Color("f6dfa0"),"board_edge":Color("1d2a4d"),"board_edge_w":4,"board_r":30,"board_mark":Color(0.114,0.165,0.302,.26),
		"card":Color("ffffff"),"card_edge":Color("1d2a4d"),"card_w":3,"card_r":14,"card_shadow":Color("1d2a4d"),"card_shadow_size":1,"card_shadow_offset":Vector2(3,4),"art_w":2,
		"banner":Color("ff6b57"),"banner_text":Color("ffffff"),"rules":Color("ffffff"),"rules_edge":Color(1,1,1,0),"rules_text":Color("1d2a4d"),"tag_text":Color("8a97b5"),
		"token_idle":Color("1d2a4d"),"token_drop":Vector2(3,4),"token_gap":false,"token_plate":Color("ffffff"),"token_plate_text":Color("1d2a4d"),"plate_r":9,"plate_w":2,"taunt":Color("1d2a4d"),
		"gem_shape":0,"gem_ring":Color("1d2a4d"),"gem_w":3,"gem_drop":Vector2(2,3),"gem_shadow":Color("1d2a4d"),"gem_text":Color("ffffff"),"gem_display":true,
		"mana":Color("2f8fff"),"atk":Color("ffab00"),"hp":Color("ff4d6d"),
		"back":Color("2f8fff"),"back_edge":Color("1d2a4d"),"pile":Color("ff6b57"),"pile_edge":Color("1d2a4d"),"arrow":Color("ff4d6d"),
		"stat_text":Color("ffffff"),"stat_outline":Color("1d2a4d"),"mana_text":Color("1565d8"),"timer_bg":Color(0.114,0.165,0.302,.2),
		"art_style":1,"display":["Baloo2.ttf",800],"body":["Nunito.ttf",700],
	},
	"night": {
		"ink":Color("110f1a"),"panel":Color("1e1b2e"),"panel2":Color("181526"),"panel_edge":Color("4a4466"),"panel_r":4,
		"accent":Color("e2643a"),"accent_hover":Color("f07a4f"),"accent_press":Color("c24f2a"),"accent_edge":Color("e2643a"),"accent_ink":Color("110f1a"),
		"text":Color("d9cfb8"),"muted":Color("8f88a3"),"good":Color("8e7ff5"),"eyebrow":Color("e2643a"),"bg":Color("0d0b14"),
		"button":Color("1e1b2e"),"button_hover":Color("2a2540"),"button_press":Color("342e50"),"button_disabled":Color("15131f"),
		"edge":Color("8f88a3"),"edge_hover":Color("e2643a"),"edge_disabled":Color("2c2840"),"edge_w":1,"radius":3,
		"shadow":Color(0,0,0,0),"shadow_offset":Vector2.ZERO,"shadow_size":0,
		"field":Color("15131f"),"field_edge":Color("4a4466"),"tip":Color("110f1a"),"tip_edge":Color("d9cfb8"),
		"board_art":false,"board":Color("1a1728"),"board_edge":Color("d9cfb8"),"board_edge_w":2,"board_r":6,"board_mark":Color(0.85,0.81,0.72,.3),
		"card":Color("1e1b2e"),"card_edge":Color("8f88a3"),"card_w":1,"card_r":4,"card_shadow":Color(0.886,0.392,0.227,.22),"card_shadow_size":6,"card_shadow_offset":Vector2.ZERO,"art_w":1,
		"banner":Color("110f1a"),"banner_text":Color("e2643a"),"rules":Color("181526"),"rules_edge":Color("4a4466"),"rules_text":Color("d9cfb8"),"tag_text":Color("8f88a3"),
		"token_idle":Color("d9cfb8"),"token_drop":Vector2.ZERO,"token_gap":true,"token_plate":Color("110f1a"),"token_plate_text":Color("d9cfb8"),"plate_r":2,"plate_w":1,"taunt":Color("d9cfb8"),
		"gem_shape":2,"gem_ring":Color("d9cfb8"),"gem_w":2,"gem_drop":Vector2.ZERO,"gem_shadow":Color("110f1a"),"gem_text":Color("110f1a"),"gem_display":true,
		"mana":Color("8e7ff5"),"atk":Color("d9cfb8"),"hp":Color("e2643a"),
		"back":Color("1e1b2e"),"back_edge":Color("d9cfb8"),"pile":Color("1e1b2e"),"pile_edge":Color("8f88a3"),"arrow":Color("e2643a"),
		"stat_text":Color("d9cfb8"),"stat_outline":Color("110f1a"),"mana_text":Color("a99dff"),"timer_bg":Color("2c2840"),
		"art_style":2,"display":["Cinzel.ttf",600],"body":["Spectral-Regular.ttf",0],
	},
}
const ART = Color(.5,.25,.75)  # marker vertex colour: card_style.gdshader restyles draws in this colour as artwork
static var mode = "day"
static var P: Dictionary = {}
static var INK = Color("1d2a4d")
static var PANEL = Color("ffffff")
static var GOLD = Color("ffd23f")
static var TEXT = Color("1d2a4d")
static var MUTED = Color("4f5f85")
static var TEAL = Color("12b886")
static var atlas: Texture2D
static var serif: Font
static var sans: Font
const IDS = ["home-emberling","home-tideling","home-mossling","home-cloudling","home-shore-guard","home-breeze-finch","home-spark","home-mending-tide","home-resin-crab"]

static func typeface(spec: Array) -> Font:
	var base = load("res://assets/fonts/"+spec[0])
	if spec[1] == 0: return base
	var weighted = FontVariation.new()
	weighted.base_font = base
	weighted.variation_opentype = {TextServerManager.get_primary_interface().name_to_tag("wght"): spec[1]}
	return weighted

## Switch the whole game to one look. Callers rebuild their widgets afterwards.
static func set_mode(next: String):
	mode = next if LOOKS.has(next) else "day"
	P = LOOKS[mode]
	INK = P.ink; PANEL = P.panel; GOLD = P.accent; TEXT = P.text; MUTED = P.muted; TEAL = P.good
	serif = typeface(P.display)
	sans = typeface(P.body)
	RenderingServer.set_default_clear_color(P.bg)

static func fonts():
	if P.is_empty(): set_mode(mode)

## Material for anything that shows card or hero artwork.
static func art_material(all_art: bool = false) -> ShaderMaterial:
	fonts()
	var material = ShaderMaterial.new()
	material.shader = preload("res://card_style.gdshader")
	material.set_shader_parameter("style", float(P.art_style))
	material.set_shader_parameter("all_art", 1.0 if all_art else 0.0)
	return material

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

## A themed surface: panel, button or plate, with the look's outline and shadow.
static func plate(color: Color, border: Color, radius: int = -1, margin: int = 12) -> StyleBoxFlat:
	var result = box(color, border, P.radius if radius < 0 else radius, margin)
	result.set_border_width_all(P.edge_w)
	result.shadow_color = P.shadow
	result.shadow_size = P.shadow_size
	result.shadow_offset = P.shadow_offset
	return result

static func theme() -> Theme:
	fonts()
	var t = Theme.new()
	t.default_font=sans
	t.default_font_size=14
	t.set_color("font_color","Label",TEXT)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: t.set_color(state,"Button",TEXT)
	t.set_color("font_disabled_color","Button",MUTED)
	t.set_stylebox("normal","Button",plate(P.button,P.edge))
	t.set_stylebox("hover","Button",plate(P.button_hover,P.edge_hover))
	var pressed = plate(P.button_press,P.edge_hover)
	pressed.shadow_size = 0
	t.set_stylebox("pressed","Button",pressed)
	var disabled = plate(P.button_disabled,P.edge_disabled)
	disabled.shadow_size = 0
	t.set_stylebox("disabled","Button",disabled)
	var focus = box(Color(0,0,0,0),GOLD,P.radius)
	focus.set_border_width_all(2)
	t.set_stylebox("focus","Button",focus)
	for control in ["OptionButton","LineEdit"]:
		t.set_color("font_color",control,TEXT)
		t.set_color("font_hover_color",control,TEXT)
		t.set_color("font_focus_color",control,TEXT)
		t.set_stylebox("normal",control,box(P.field,P.field_edge,8,10))
		t.set_stylebox("hover",control,box(P.field,GOLD,8,10))
		t.set_stylebox("focus",control,focus)
	t.set_color("font_placeholder_color","LineEdit",MUTED)
	t.set_color("caret_color","LineEdit",P.edge_hover)
	t.set_color("selection_color","LineEdit",Color(P.good,.45))
	t.set_stylebox("panel","PopupMenu",box(P.field,P.field_edge,8,8))
	t.set_stylebox("hover","PopupMenu",box(P.button_hover,P.edge_hover,5,6))
	t.set_color("font_color","PopupMenu",TEXT)
	t.set_color("font_hover_color","PopupMenu",TEXT)
	t.set_constant("outline_size","TooltipLabel",0)
	t.set_stylebox("panel","TooltipPanel",box(P.tip,P.tip_edge,8,14))
	t.set_color("font_color","TooltipLabel",TEXT)
	return t

static func primary(b: Button):
	var normal = plate(P.accent,P.accent_edge)
	b.add_theme_stylebox_override("normal",normal)
	b.add_theme_stylebox_override("hover",plate(P.accent_hover,P.accent_edge))
	var pressed = plate(P.accent_press,P.accent_edge)
	pressed.shadow_size = 0
	b.add_theme_stylebox_override("pressed",pressed)
	for state in ["font_color","font_hover_color","font_pressed_color","font_focus_color"]: b.add_theme_color_override(state,P.accent_ink)

static var hero_textures: Dictionary={}
static func hero_art(job_id: String,power=false) -> Texture2D:
	var id={"warrior":"brace","ranger":"true-shot","wizard":"spark"}.get(job_id,"") if power else job_id
	if not hero_textures.has(id):
		var path="res://assets/heroes/"+id+".png"
		if not ResourceLoader.exists(path): return null
		hero_textures[id]=load(path)
	return hero_textures[id]
