class_name UI
extends RefCounted

const INK = Color("172f29")
const CREAM = Color("f3e7d0")
const GOLD = Color("d9b575")
const MUTED = Color("a9b5a1")
static var body: Font = preload("res://assets/fonts/NotoSans-Regular.ttf")
static var bold: Font = preload("res://assets/fonts/NotoSans-Bold.ttf")
static var serif: Font = preload("res://assets/fonts/NotoSerif-Regular.ttf")
static var symbols: Font = preload("res://assets/fonts/Symbols.ttf")
static var icons: Dictionary = {}
static var dragon_frames: Dictionary = {}
static var farm_frames: Dictionary = {}

static func farm_art(name: String) -> Texture2D:
	if not farm_frames.has(name):
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/farm/objects.png")
		atlas.region = {"house": Rect2(0,0,690,692), "pond": Rect2(694,0,553,693), "moss_garden": Rect2(0,700,625,550), "garden_bed": Rect2(626,700,621,561)}[name]
		farm_frames[name] = atlas
	return farm_frames[name]

static func dragon(frame: int = 0) -> Texture2D:
	if not dragon_frames.has(frame):
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/characters/mos-atlas.png")
		atlas.region = Rect2((frame%3)*512,int(frame/3)*512,512,512)
		dragon_frames[frame] = atlas
	return dragon_frames[frame]

static func init_fonts():
	body.fallbacks = [symbols]
	bold.fallbacks = [symbols]
	serif.fallbacks = [symbols]

static func icon(name: String) -> Texture2D:
	if name == "mos": return dragon()
	if name in ["house", "pond", "moss_garden", "garden_bed"]: return farm_art(name)
	var file = "res://assets/ui/" + name + ".svg"
	if not ResourceLoader.exists(file): file = "res://assets/ui/leaf.svg"
	if not icons.has(file): icons[file] = load(file)
	return icons[file]

static func box(color: Color, radius: int = 18, border: Color = Color.TRANSPARENT, width: int = 1) -> StyleBoxFlat:
	var style = StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(radius)
	style.border_color = border
	style.set_border_width_all(width)
	style.content_margin_left = 18
	style.content_margin_right = 18
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

static func label(parent: Node, text: String, rect: Rect2, font_size: int = 18, color: Color = CREAM, font: Font = null) -> Label:
	var node = Label.new()
	node.text = text
	node.position = rect.position
	node.size = rect.size
	if parent is ScrollContainer:
		node.custom_minimum_size = rect.size
		node.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	node.add_theme_font_override("font", body if font == null else font)
	node.add_theme_font_size_override("font_size", font_size)
	node.add_theme_color_override("font_color", color)
	node.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node

static func button(parent: Node, text: String, rect: Rect2, callback: Callable, primary: bool = false, small: bool = false) -> Button:
	var node = Button.new()
	node.name = "Button_" + text.validate_node_name()
	node.text = text
	node.position = rect.position
	node.size = Vector2(maxf(48,rect.size.x),maxf(48,rect.size.y))
	node.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	node.add_theme_font_override("font", bold)
	node.add_theme_font_size_override("font_size", 14 if small else 16)
	var bg = GOLD if primary else Color("173a30")
	node.add_theme_stylebox_override("normal", box(bg, 12, Color("8e8059") if primary else Color("49634e")))
	node.add_theme_stylebox_override("hover", box(bg.lightened(0.12), 12, CREAM))
	node.add_theme_stylebox_override("pressed", box(bg.darkened(0.1), 12, GOLD))
	node.add_theme_stylebox_override("focus", box(Color.TRANSPARENT, 12, Color("fff1be"), 3))
	node.add_theme_color_override("font_color", INK if primary else CREAM)
	node.add_theme_color_override("font_hover_color", INK if primary else CREAM)
	node.add_theme_color_override("font_pressed_color", INK if primary else CREAM)
	node.pressed.connect(callback)
	parent.add_child(node)
	return node

static func panel(parent: Node, rect: Rect2, color: Color = Color("122c26"), radius: int = 20) -> Panel:
	var panel_node = Panel.new()
	panel_node.position = rect.position
	panel_node.size = rect.size
	panel_node.add_theme_stylebox_override("panel", box(color, radius, Color("7b7755")))
	panel_node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(panel_node)
	return panel_node

static func image(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var node = TextureRect.new()
	node.texture = texture
	node.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	node.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	node.position = rect.position
	node.size = rect.size
	node.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(node)
	return node
