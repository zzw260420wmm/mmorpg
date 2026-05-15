extends Object
class_name ArtAssets

const TILE_SIZE := 16
const PROP_SIZE := 32
const CHARACTER_SIZE := 32
const ICON_SIZE := 16

const TILE_ATLAS_TEXTURE := preload("res://assets/tiles/urban_life_tileset.png")
const PROP_ATLAS_TEXTURE := preload("res://assets/sprites/urban_props_atlas.png")
const CHARACTER_ATLAS_TEXTURE := preload("res://assets/sprites/characters_atlas.png")
const ICON_ATLAS_TEXTURE := preload("res://assets/ui/hud_icons.png")

const TILE_REGIONS := {
	"old_concrete": Rect2(0, 0, 16, 16),
	"wet_asphalt": Rect2(16, 0, 16, 16),
	"aged_floor": Rect2(32, 0, 16, 16),
	"rain_puddle": Rect2(48, 0, 16, 16),
	"alley_patch": Rect2(64, 0, 16, 16),
	"office_tile": Rect2(80, 0, 16, 16),
	"rental_floor": Rect2(96, 0, 16, 16),
	"media_floor": Rect2(112, 0, 16, 16),
	"metro_tile": Rect2(0, 16, 16, 16),
	"warm_wall": Rect2(16, 16, 16, 16),
	"store_wall": Rect2(32, 16, 16, 16),
	"restaurant_wall": Rect2(48, 16, 16, 16),
	"delivery_wall": Rect2(64, 16, 16, 16),
	"media_wall": Rect2(80, 16, 16, 16),
	"night_window": Rect2(96, 16, 16, 16),
	"rain_overlay": Rect2(112, 16, 16, 16),
}

const PROP_REGIONS := {
	"scooter": Rect2(0, 0, 32, 32),
	"rider_bag": Rect2(32, 0, 32, 32),
	"vending_machine": Rect2(64, 0, 32, 32),
	"utility_pole": Rect2(96, 0, 32, 32),
	"ac_unit": Rect2(128, 0, 32, 32),
	"laundry_rack": Rect2(160, 0, 32, 32),
	"food_sign": Rect2(192, 0, 32, 32),
	"metro_sign": Rect2(224, 0, 32, 32),
	"ring_light": Rect2(0, 32, 32, 32),
	"camera": Rect2(32, 32, 32, 32),
	"product_boxes": Rect2(64, 32, 32, 32),
	"office_desk": Rect2(96, 32, 32, 32),
	"bed": Rect2(128, 32, 32, 32),
	"fridge": Rect2(160, 32, 32, 32),
	"rent_notice": Rect2(192, 32, 32, 32),
}

const CHARACTER_REGIONS := {
	"player_grad": Rect2(0, 0, 32, 32),
	"landlord": Rect2(32, 0, 32, 32),
	"shopkeeper": Rect2(64, 0, 32, 32),
	"drifter_girl": Rect2(96, 0, 32, 32),
	"delivery_rider": Rect2(128, 0, 32, 32),
	"office_worker": Rect2(160, 0, 32, 32),
	"streamer": Rect2(192, 0, 32, 32),
	"metro_commuter": Rect2(224, 0, 32, 32),
}

const ICON_REGIONS := {
	"money": Rect2(0, 0, 16, 16),
	"energy": Rect2(16, 0, 16, 16),
	"stress": Rect2(32, 0, 16, 16),
	"rent": Rect2(48, 0, 16, 16),
	"weather": Rect2(64, 0, 16, 16),
	"work": Rect2(80, 0, 16, 16),
	"delivery": Rect2(96, 0, 16, 16),
	"stream": Rect2(112, 0, 16, 16),
	"character": Rect2(0, 16, 16, 16),
	"contacts": Rect2(0, 16, 16, 16),
	"bag": Rect2(16, 16, 16, 16),
	"city": Rect2(32, 16, 16, 16),
	"tasks": Rect2(48, 16, 16, 16),
}


static func tile_atlas_coords(name: String) -> Vector2i:
	var region: Rect2 = TILE_REGIONS.get(name, TILE_REGIONS["old_concrete"])
	return Vector2i(int(region.position.x / TILE_SIZE), int(region.position.y / TILE_SIZE))


static func draw_prop(canvas: CanvasItem, name: String, top_left: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = PROP_REGIONS.get(name, PROP_REGIONS["rider_bag"])
	canvas.draw_texture_rect_region(PROP_ATLAS_TEXTURE, Rect2(top_left, region.size * scale), region, modulate)


static func draw_prop_centered(canvas: CanvasItem, name: String, center: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = PROP_REGIONS.get(name, PROP_REGIONS["rider_bag"])
	draw_prop(canvas, name, center - region.size * scale * 0.5, scale, modulate)


static func draw_character(canvas: CanvasItem, name: String, top_left: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = CHARACTER_REGIONS.get(name, CHARACTER_REGIONS["player_grad"])
	canvas.draw_texture_rect_region(CHARACTER_ATLAS_TEXTURE, Rect2(top_left, region.size * scale), region, modulate)


static func _character_row_for_direction(direction: Vector2, walking: bool) -> int:
	var base_row := 0
	if absf(direction.x) > absf(direction.y):
		base_row = 6 if direction.x > 0.0 else 4
	elif direction.y < 0.0:
		base_row = 2
	return base_row + (1 if walking else 0)


static func draw_character_frame(canvas: CanvasItem, name: String, top_left: Vector2, walking: bool = false, scale: float = 1.0, modulate: Color = Color.WHITE, direction: Vector2 = Vector2.DOWN) -> void:
	var region: Rect2 = CHARACTER_REGIONS.get(name, CHARACTER_REGIONS["player_grad"])
	region.position.y = _character_row_for_direction(direction, walking) * CHARACTER_SIZE
	canvas.draw_texture_rect_region(CHARACTER_ATLAS_TEXTURE, Rect2(top_left, region.size * scale), region, modulate)


static func draw_character_centered(canvas: CanvasItem, name: String, center: Vector2, walking: bool = false, scale: float = 1.0, modulate: Color = Color.WHITE, direction: Vector2 = Vector2.DOWN) -> void:
	var region: Rect2 = CHARACTER_REGIONS.get(name, CHARACTER_REGIONS["player_grad"])
	draw_character_frame(canvas, name, center - region.size * scale * 0.5, walking, scale, modulate, direction)


static func draw_icon(canvas: CanvasItem, name: String, top_left: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = ICON_REGIONS.get(name, ICON_REGIONS["work"])
	canvas.draw_texture_rect_region(ICON_ATLAS_TEXTURE, Rect2(top_left, region.size * scale), region, modulate)


static func make_icon_texture(name: String) -> AtlasTexture:
	var texture := AtlasTexture.new()
	texture.atlas = ICON_ATLAS_TEXTURE
	texture.region = ICON_REGIONS.get(name, ICON_REGIONS["work"])
	return texture


static func draw_pixel_grid(canvas: CanvasItem, rect: Rect2, step: int = TILE_SIZE, color: Color = Color(0.0, 0.0, 0.0, 0.18)) -> void:
	for x in range(1, int(floor(rect.size.x / float(step)))):
		var px := rect.position.x + x * step
		canvas.draw_line(Vector2(px, rect.position.y), Vector2(px, rect.end.y), color, 1.0)
	for y in range(1, int(floor(rect.size.y / float(step)))):
		var py := rect.position.y + y * step
		canvas.draw_line(Vector2(rect.position.x, py), Vector2(rect.end.x, py), color, 1.0)


static func draw_tiled_rect(canvas: CanvasItem, tile_name: String, rect: Rect2, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = TILE_REGIONS.get(tile_name, TILE_REGIONS["old_concrete"])
	var columns := int(ceil(rect.size.x / TILE_SIZE))
	var rows := int(ceil(rect.size.y / TILE_SIZE))
	for row in range(rows):
		for column in range(columns):
			var tile_pos := rect.position + Vector2(column * TILE_SIZE, row * TILE_SIZE)
			var draw_size := Vector2(
				min(TILE_SIZE, rect.end.x - tile_pos.x),
				min(TILE_SIZE, rect.end.y - tile_pos.y)
			)
			if draw_size.x > 0 and draw_size.y > 0:
				canvas.draw_texture_rect_region(TILE_ATLAS_TEXTURE, Rect2(tile_pos, draw_size), Rect2(region.position, draw_size), modulate)
