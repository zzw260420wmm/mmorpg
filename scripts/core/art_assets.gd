extends Object
class_name ArtAssets

const TILE_SIZE := 16
const PROP_SIZE := 32
const CHARACTER_SIZE := 64
const BUILDING_SPRITE_SIZE := Vector2i(192, 128)
const ICON_SIZE := 16
const TASK_GUIDE_FRAME_SIZE := Vector2i(96, 128)

const TILE_ATLAS_TEXTURE := preload("res://assets/tiles/urban_life_tileset.png")
const HANDDRAWN_GROUND_ATLAS_TEXTURE := preload("res://assets/tiles/handdrawn_ground_tiles_64.png")
const PROP_ATLAS_TEXTURE := preload("res://assets/sprites/urban_props_atlas.png")
const METRO_PROP_ATLAS_TEXTURE := preload("res://assets/sprites/metro_station_props.png")
const INTERNET_CAFE_PROP_ATLAS_TEXTURE := preload("res://assets/sprites/internet_cafe_props.png")
const CHARACTER_ATLAS_TEXTURE := preload("res://assets/sprites/characters_atlas.png")
const TASK_GUIDE_ATLAS_TEXTURE := preload("res://assets/sprites/task_guide/task_guide_character_atlas.png")
const BUILDING_ATLAS_TEXTURE := preload("res://assets/sprites/cartoon_buildings_atlas.png")
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

const HANDDRAWN_GROUND_SIZE := 64
const HANDDRAWN_GROUND_REGIONS := {
	"happy_grass": Rect2(0, 0, 64, 64),
	"grass_flowers": Rect2(64, 0, 64, 64),
	"grass_edge_n": Rect2(128, 0, 64, 64),
	"grass_edge_e": Rect2(192, 0, 64, 64),
	"grass_edge_s": Rect2(256, 0, 64, 64),
	"grass_edge_w": Rect2(320, 0, 64, 64),
	"grass_corner_ne": Rect2(384, 0, 64, 64),
	"grass_corner_sw": Rect2(448, 0, 64, 64),
	"warm_sidewalk": Rect2(0, 64, 64, 64),
	"sidewalk_cracked": Rect2(64, 64, 64, 64),
	"sidewalk_curb_n": Rect2(128, 64, 64, 64),
	"sidewalk_curb_e": Rect2(192, 64, 64, 64),
	"sidewalk_curb_s": Rect2(256, 64, 64, 64),
	"sidewalk_curb_w": Rect2(320, 64, 64, 64),
	"sidewalk_tree_well": Rect2(384, 64, 64, 64),
	"sidewalk_manhole": Rect2(448, 64, 64, 64),
	"soft_asphalt": Rect2(0, 128, 64, 64),
	"wet_asphalt": Rect2(64, 128, 64, 64),
	"road_h": Rect2(128, 128, 64, 64),
	"road_v": Rect2(192, 128, 64, 64),
	"road_cross": Rect2(256, 128, 64, 64),
	"road_corner_ne": Rect2(320, 128, 64, 64),
	"road_corner_sw": Rect2(384, 128, 64, 64),
	"crosswalk": Rect2(448, 128, 64, 64),
	"plane_tree": Rect2(0, 192, 64, 64),
	"small_tree": Rect2(64, 192, 64, 64),
	"shrub": Rect2(128, 192, 64, 64),
	"flower_box": Rect2(192, 192, 64, 64),
	"rain_puddle": Rect2(256, 192, 64, 64),
	"fallen_leaves": Rect2(320, 192, 64, 64),
	"bike_lane": Rect2(384, 192, 64, 64),
	"curb_ramp": Rect2(448, 192, 64, 64),
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

const METRO_PROP_SIZE := 64
const METRO_PROP_REGIONS := {
	"ticket_machine": Rect2(0, 0, 64, 64),
	"ticket_gate_open": Rect2(64, 0, 64, 64),
	"ticket_gate_closed": Rect2(128, 0, 64, 64),
	"info_kiosk": Rect2(192, 0, 64, 64),
	"exit_sign": Rect2(256, 0, 64, 64),
	"line_sign": Rect2(320, 0, 64, 64),
	"ad_lightbox": Rect2(384, 0, 64, 64),
	"warning_sign": Rect2(448, 0, 64, 64),
	"pillar": Rect2(0, 64, 64, 64),
	"trash_bin": Rect2(64, 64, 64, 64),
	"tactile_straight": Rect2(128, 64, 64, 64),
	"tactile_turn": Rect2(192, 64, 64, 64),
	"platform_door": Rect2(256, 64, 64, 64),
	"ceiling_light": Rect2(320, 64, 64, 64),
	"rail_barrier": Rect2(384, 64, 64, 64),
	"floor_arrow": Rect2(448, 64, 64, 64),
}

const INTERNET_CAFE_PROP_SIZE := 64
const INTERNET_CAFE_PROP_REGIONS := {
	"gaming_pc": Rect2(0, 0, 64, 64),
	"messy_desk": Rect2(64, 0, 64, 64),
	"gaming_chair": Rect2(128, 0, 64, 64),
	"noodle_cup": Rect2(192, 0, 64, 64),
	"soda_can": Rect2(256, 0, 64, 64),
	"rgb_sign": Rect2(320, 0, 64, 64),
	"front_counter": Rect2(384, 0, 64, 64),
	"snack_shelf": Rect2(448, 0, 64, 64),
	"router_stack": Rect2(0, 64, 64, 64),
	"ashtray": Rect2(64, 64, 64, 64),
	"blue_wall_poster": Rect2(128, 64, 64, 64),
	"headset": Rect2(192, 64, 64, 64),
	"keyboard_mouse": Rect2(256, 64, 64, 64),
	"sleeping_user": Rect2(320, 64, 64, 64),
	"floor_cable": Rect2(384, 64, 64, 64),
	"exit_door": Rect2(448, 64, 64, 64),
}

const CHARACTER_REGIONS := {
	"player_grad": Rect2(0, 0, 64, 64),
	"landlord": Rect2(64, 0, 64, 64),
	"shopkeeper": Rect2(128, 0, 64, 64),
	"drifter_girl": Rect2(192, 0, 64, 64),
	"delivery_rider": Rect2(256, 0, 64, 64),
	"office_worker": Rect2(320, 0, 64, 64),
	"streamer": Rect2(384, 0, 64, 64),
	"metro_commuter": Rect2(448, 0, 64, 64),
}

const BUILDING_REGIONS := {
	"shanghai_lane_house": Rect2(0, 0, 192, 128),
	"shanghai_convenience_store": Rect2(192, 0, 192, 128),
	"shanghai_office_tower": Rect2(384, 0, 192, 128),
	"beijing_hutong_courtyard": Rect2(576, 0, 192, 128),
	"guangzhou_qilou_shop": Rect2(0, 128, 192, 128),
	"shenzhen_tech_park": Rect2(192, 128, 192, 128),
	"chengdu_noodle_shop": Rect2(384, 128, 192, 128),
	"hangzhou_waterside_house": Rect2(576, 128, 192, 128),
	"chongqing_slope_apartment": Rect2(0, 256, 192, 128),
	"wuhan_riverside_market": Rect2(192, 256, 192, 128),
	"nanjing_plane_tree_block": Rect2(384, 256, 192, 128),
	"shanghai_media_company": Rect2(576, 256, 192, 128),
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


static func draw_handdrawn_ground(canvas: CanvasItem, name: String, top_left: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = HANDDRAWN_GROUND_REGIONS.get(name, HANDDRAWN_GROUND_REGIONS["warm_sidewalk"])
	canvas.draw_texture_rect_region(HANDDRAWN_GROUND_ATLAS_TEXTURE, Rect2(top_left, region.size * scale), region, modulate)


static func draw_prop_centered(canvas: CanvasItem, name: String, center: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = PROP_REGIONS.get(name, PROP_REGIONS["rider_bag"])
	draw_prop(canvas, name, center - region.size * scale * 0.5, scale, modulate)


static func draw_metro_prop(canvas: CanvasItem, name: String, top_left: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = METRO_PROP_REGIONS.get(name, METRO_PROP_REGIONS["ticket_machine"])
	canvas.draw_texture_rect_region(METRO_PROP_ATLAS_TEXTURE, Rect2(top_left, region.size * scale), region, modulate)


static func draw_internet_cafe_prop(canvas: CanvasItem, name: String, top_left: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = INTERNET_CAFE_PROP_REGIONS.get(name, INTERNET_CAFE_PROP_REGIONS["gaming_pc"])
	canvas.draw_texture_rect_region(INTERNET_CAFE_PROP_ATLAS_TEXTURE, Rect2(top_left, region.size * scale), region, modulate)


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


static func _task_guide_row_for_direction(direction: Vector2) -> int:
	if absf(direction.x) > absf(direction.y):
		return 1 if direction.x > 0.0 else 3
	if direction.y < 0.0:
		return 2
	return 0


static func draw_task_guide_frame(canvas: CanvasItem, center: Vector2, frame_index: int, direction: Vector2 = Vector2.DOWN, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var row: int = _task_guide_row_for_direction(direction)
	var column: int = clampi(frame_index, 0, 3)
	var region: Rect2 = Rect2(
		column * TASK_GUIDE_FRAME_SIZE.x,
		row * TASK_GUIDE_FRAME_SIZE.y,
		TASK_GUIDE_FRAME_SIZE.x,
		TASK_GUIDE_FRAME_SIZE.y
	)
	var draw_size: Vector2 = region.size * scale
	canvas.draw_texture_rect_region(TASK_GUIDE_ATLAS_TEXTURE, Rect2(center - draw_size * 0.5, draw_size), region, modulate)


static func draw_building_sprite(canvas: CanvasItem, name: String, top_left: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = BUILDING_REGIONS.get(name, BUILDING_REGIONS["shanghai_lane_house"])
	canvas.draw_texture_rect_region(BUILDING_ATLAS_TEXTURE, Rect2(top_left, region.size * scale), region, modulate)


static func draw_building_sprite_centered(canvas: CanvasItem, name: String, center: Vector2, scale: float = 1.0, modulate: Color = Color.WHITE) -> void:
	var region: Rect2 = BUILDING_REGIONS.get(name, BUILDING_REGIONS["shanghai_lane_house"])
	draw_building_sprite(canvas, name, center - region.size * scale * 0.5, scale, modulate)


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
