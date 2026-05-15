extends Node2D
class_name CityMap

const TILE_SIZE := 16
const MAP_SIZE := Vector2i(132, 76)

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")
const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

var tile_map: TileMap
var building_rects: Array[Dictionary] = []
var current_segment := "morning"
var current_weather := "overcast"


func _ready() -> void:
	z_index = 0
	_create_tile_map()
	_create_buildings()
	_create_boundaries()
	_create_interactables()
	queue_redraw()


func get_player_spawn() -> Vector2:
	return Vector2(150, 228)


func get_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(MAP_SIZE.x * TILE_SIZE, MAP_SIZE.y * TILE_SIZE))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	_draw_shanghai_geography()
	_draw_puddles_and_lights()
	for data in building_rects:
		_draw_building(data)
	_draw_reusable_street_props()
	_draw_metro_glow()


func _create_tile_map() -> void:
	tile_map = TileMap.new()
	tile_map.name = "PixelTileMap"
	tile_map.z_index = -20
	add_child(tile_map)

	var source := TileSetAtlasSource.new()
	source.texture = ArtAssetsScript.TILE_ATLAS_TEXTURE
	source.texture_region_size = Vector2i(TILE_SIZE, TILE_SIZE)
	var tile_names := [
		"old_concrete",
		"wet_asphalt",
		"aged_floor",
		"rain_puddle",
		"alley_patch",
		"office_tile",
		"metro_tile",
		"delivery_wall",
		"media_floor",
	]
	for tile_name in tile_names:
		source.create_tile(ArtAssetsScript.tile_atlas_coords(tile_name))

	var tile_set := TileSet.new()
	tile_set.tile_size = Vector2i(TILE_SIZE, TILE_SIZE)
	tile_set.add_source(source, 0)
	tile_map.tile_set = tile_set

	for y in range(MAP_SIZE.y):
		for x in range(MAP_SIZE.x):
			var atlas := _tile_atlas_for_cell(x, y)
			tile_map.set_cell(0, Vector2i(x, y), 0, atlas)


func _tile_atlas_for_cell(x: int, y: int) -> Vector2i:
	if x >= 57 and x <= 62 and not (y >= 18 and y <= 22) and not (y >= 31 and y <= 35):
		return ArtAssetsScript.tile_atlas_coords("rain_puddle")
	if y >= 15 and y <= 16 and x >= 18 and x <= 58:
		return ArtAssetsScript.tile_atlas_coords("rain_puddle")
	if y >= 17 and y <= 19 and x >= 30 and x <= 58:
		return ArtAssetsScript.tile_atlas_coords("wet_asphalt")
	if x >= 25 and x <= 35:
		return ArtAssetsScript.tile_atlas_coords("wet_asphalt")
	if x >= 60 and x <= 66:
		return ArtAssetsScript.tile_atlas_coords("wet_asphalt")
	if y >= 18 and y <= 23:
		return ArtAssetsScript.tile_atlas_coords("wet_asphalt")
	if y >= 26 and y <= 30 and x >= 56:
		return ArtAssetsScript.tile_atlas_coords("wet_asphalt")
	if y >= 35 and y <= 38 and x >= 8 and x <= 44:
		return ArtAssetsScript.tile_atlas_coords("wet_asphalt")
	if x >= 67 and y <= 36:
		return ArtAssetsScript.tile_atlas_coords("office_tile")
	if x >= 58 and x <= 64 and y >= 2 and y <= 35:
		return ArtAssetsScript.tile_atlas_coords("metro_tile")
	if (x >= 6 and x <= 17 and y >= 13 and y <= 17) or (x >= 36 and x <= 50 and y >= 12 and y <= 17):
		return ArtAssetsScript.tile_atlas_coords("alley_patch")
	if x >= 50 and x <= 57 and y >= 24 and y <= 33:
		return ArtAssetsScript.tile_atlas_coords("delivery_wall")
	if x >= 51 and x <= 60 and y >= 2 and y <= 13:
		return ArtAssetsScript.tile_atlas_coords("media_floor")
	if x >= 16 and x <= 25 and y >= 31 and y <= 41:
		return ArtAssetsScript.tile_atlas_coords("alley_patch")
	if x >= 62:
		return ArtAssetsScript.tile_atlas_coords("old_concrete")
	if (x + y * 2) % 31 == 0:
		return ArtAssetsScript.tile_atlas_coords("rain_puddle")
	if x < 22:
		return ArtAssetsScript.tile_atlas_coords("aged_floor")
	return ArtAssetsScript.tile_atlas_coords("old_concrete")


func _create_buildings() -> void:
	_add_building("rental", Rect2(64, 64, 176, 112), Color("#8e6d58"), Color("#6d5046"), Color("#efc36f"))
	_add_building("store", Rect2(560, 76, 192, 116), Color("#6d8d83"), Color("#3d635f"), Color("#f5d37b"))
	_add_building("restaurant", Rect2(282, 340, 168, 92), Color("#a45d45"), Color("#793d36"), Color("#ffe0a3"))
	_add_building("metro", Rect2(652, 398, 132, 84), Color("#4d5d70"), Color("#2f3d4f"), Color("#a9d7ff"))
	_add_building("office", Rect2(1008, 116, 212, 188), Color("#697985"), Color("#3f4d5d"), Color("#c7e7ff"))
	_add_building("office_shop", Rect2(1112, 424, 152, 86), Color("#806b52"), Color("#5b4638"), Color("#f0c77b"))
	_add_building("delivery_station", Rect2(812, 414, 136, 86), Color("#6f7653"), Color("#4d5738"), Color("#f3cf6b"))
	_add_building("media_company", Rect2(824, 58, 148, 152), Color("#7b647f"), Color("#58445f"), Color("#ffc4d6"))
	_add_building("wet_market", Rect2(184, 674, 184, 104), Color("#6f7653"), Color("#4d5738"), Color("#f0c77b"))
	_add_building("community_clinic", Rect2(456, 646, 164, 92), Color("#6d8d83"), Color("#3d635f"), Color("#d8fff0"))
	_add_building("talent_apartment", Rect2(1262, 150, 184, 146), Color("#7d8588"), Color("#56636c"), Color("#ffe2a1"))
	_add_building("rental_agency", Rect2(1218, 538, 164, 86), Color("#806b52"), Color("#5b4638"), Color("#f0c77b"))


func _add_building(id: String, rect: Rect2, body: Color, roof: Color, light: Color) -> void:
	building_rects.append({
		"id": id,
		"rect": rect,
		"body": body,
		"roof": roof,
		"light": light,
	})
	_add_collision_rect("%s_collision" % id, rect.position + Vector2(4, 20), rect.size - Vector2(8, 22))


func _create_boundaries() -> void:
	var world_size := Vector2(MAP_SIZE.x * TILE_SIZE, MAP_SIZE.y * TILE_SIZE)
	_add_collision_rect("north_wall", Vector2(0, -16), Vector2(world_size.x, 16))
	_add_collision_rect("south_wall", Vector2(0, world_size.y), Vector2(world_size.x, 16))
	_add_collision_rect("west_wall", Vector2(-16, 0), Vector2(16, world_size.y))
	_add_collision_rect("east_wall", Vector2(world_size.x, 0), Vector2(16, world_size.y))

	_add_collision_rect("laundry_posts", Vector2(92, 208), Vector2(96, 10))
	_add_collision_rect("food_stall_tables", Vector2(332, 455), Vector2(72, 16))
	_add_collision_rect("skybridge_post_left", Vector2(944, 314), Vector2(12, 32))
	_add_collision_rect("skybridge_post_right", Vector2(1162, 314), Vector2(12, 32))
	_add_collision_rect("delivery_scooters", Vector2(802, 526), Vector2(112, 18))
	_add_collision_rect("huangpu_river_north", Vector2(914, -8), Vector2(96, 292))
	_add_collision_rect("huangpu_river_middle", Vector2(922, 362), Vector2(86, 128))
	_add_collision_rect("huangpu_river_south", Vector2(930, 568), Vector2(92, MAP_SIZE.y * TILE_SIZE - 568))


func _add_collision_rect(name: String, top_left: Vector2, size: Vector2) -> void:
	var body := StaticBody2D.new()
	body.name = name
	body.collision_layer = 1
	body.collision_mask = 0
	body.position = top_left + size * 0.5
	add_child(body)

	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.shape = shape
	body.add_child(collision)


func _create_interactables() -> void:
	_add_interactable({
		"id": "rental_door",
		"name": "Rental Apartment",
		"kind": "enter_apartment",
		"prompt": "Press E to enter the apartment",
		"position": Vector2(152, 190),
		"size": Vector2(44, 26),
		"fill_color": Color(0.86, 0.68, 0.38, 0.26),
	})
	_add_interactable({
		"id": "store",
		"name": "Convenience Store",
		"kind": "shop",
		"prompt": "Press E to shop",
		"position": Vector2(656, 202),
		"size": Vector2(58, 28),
		"fill_color": Color(0.93, 0.78, 0.36, 0.24),
	})
	_add_interactable({
		"id": "metro",
		"name": "Metro Entrance",
		"kind": "enter_metro",
		"prompt": "Press E to enter the metro",
		"position": Vector2(720, 390),
		"size": Vector2(60, 28),
		"lines": {
			"default": ["The metro entrance exhales damp air and fluorescent light."],
			"morning": ["The morning rush is already forming beside the gates."],
			"evening": ["People spill out of the stairs carrying the weight of the day."],
			"late_night": ["The last train warning is softer than it should be."],
		},
		"fill_color": Color(0.42, 0.66, 0.91, 0.22),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "people_square",
		"name": "People Square Direction",
		"kind": "dialogue",
		"prompt": "Press E to look toward People Square",
		"position": Vector2(560, 228),
		"size": Vector2(72, 28),
		"lines": {
			"default": ["This direction compresses metro lines, malls, crowds, and hiring ads into one city knot."],
			"morning": ["The flow of people refreshes like a giant spreadsheet."],
			"evening": ["Mall lights make the square look wider and lonelier."],
		},
		"fill_color": Color(0.56, 0.72, 0.52, 0.18),
		"border_color": Color("#c4d8a8"),
	})
	_add_interactable({
		"id": "bund_prom",
		"name": "Bund Riverside",
		"kind": "dialogue",
		"prompt": "Press E to look toward the Bund",
		"position": Vector2(900, 252),
		"size": Vector2(60, 30),
		"lines": {
			"default": ["Across the river, tourist photos and worker commutes share the same wind."],
			"evening": ["The towers light up like a very expensive payslip."],
			"late_night": ["The river is colder now, but the lights keep working."],
		},
		"fill_color": Color(0.45, 0.70, 0.88, 0.16),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "xujiahui_node",
		"name": "Xujiahui Direction",
		"kind": "dialogue",
		"prompt": "Press E to look toward Xujiahui",
		"position": Vector2(304, 590),
		"size": Vector2(72, 28),
		"lines": {
			"default": ["The southwest direction folds malls, offices, old neighborhoods, and transfer stations together."],
			"afternoon": ["The commercial street shines, but you are still calculating today's earnings."],
		},
		"fill_color": Color(0.86, 0.64, 0.38, 0.18),
		"border_color": Color("#e8c879"),
	})
	_add_interactable({
		"id": "lujiazui_node",
		"name": "Lujiazui Direction",
		"kind": "dialogue",
		"prompt": "Press E to look toward Lujiazui",
		"position": Vector2(1088, 366),
		"size": Vector2(76, 28),
		"lines": {
			"default": ["Past the river, office towers rise like another rulebook for living."],
			"morning": ["Morning crowds pour from the station toward the glass towers."],
			"late_night": ["Some office lights are still on, stretching today into tomorrow."],
		},
		"fill_color": Color(0.55, 0.76, 0.95, 0.16),
		"border_color": Color("#c7e7ff"),
	})
	_add_interactable({
		"id": "wet_market",
		"name": "Wet Market",
		"kind": "shop",
		"prompt": "Press E to shop at the market",
		"position": Vector2(278, 790),
		"size": Vector2(78, 30),
		"lines": {
			"default": ["The market is cheaper than the convenience store, but it asks you to cook your own hope."],
			"morning": ["The morning market is noisy, wet, and alive."],
			"late_night": ["Only water marks and vegetable leaves remain on the ground."],
		},
		"fill_color": Color(0.72, 0.84, 0.42, 0.18),
		"border_color": Color("#d8c886"),
	})
	_add_interactable({
		"id": "community_clinic",
		"name": "Community Clinic",
		"kind": "clinic",
		"prompt": "Press E to rest at the clinic",
		"position": Vector2(538, 750),
		"size": Vector2(78, 30),
		"lines": {
			"default": ["Flu posters and checkup notices crowd the clinic door."],
			"morning": ["More people queue in the morning, many asking for half-day leave."],
			"evening": ["The clinic lights are white enough to make everyone look tired."],
		},
		"fill_color": Color(0.62, 0.90, 0.78, 0.18),
		"border_color": Color("#d8fff0"),
	})
	_add_interactable({
		"id": "talent_apartment",
		"name": "Talent Apartment",
		"kind": "talent_apartment",
		"prompt": "Press E to inspect the talent apartment",
		"position": Vector2(1354, 310),
		"size": Vector2(88, 30),
		"lines": {
			"default": ["Application rules cover the entrance: degree, social insurance, employer, queue number."],
			"evening": ["Each bright window looks like someone who just got off work."],
		},
		"fill_color": Color(0.55, 0.76, 0.95, 0.16),
		"border_color": Color("#c7e7ff"),
	})
	_add_interactable({
		"id": "rental_agency",
		"name": "Rental Agency",
		"kind": "rental_agency",
		"prompt": "Press E to check rental listings",
		"position": Vector2(1300, 636),
		"size": Vector2(78, 30),
		"lines": {
			"default": ["Small paper listings promise rooms, shares, deposits, and distance from the metro."],
			"late_night": ["The shop is closed, but the listings still glow from behind the glass."],
		},
		"fill_color": Color(0.86, 0.64, 0.38, 0.18),
		"border_color": Color("#e8c879"),
	})
	_add_interactable({
		"id": "restaurant",
		"name": "Small Restaurant",
		"kind": "shop",
		"prompt": "Press E to buy food",
		"position": Vector2(366, 438),
		"size": Vector2(52, 26),
		"lines": {
			"default": ["Steam slips out from the door beside a handwritten menu."],
			"evening": ["Nearby workers fill the tables for dinner."],
			"late_night": ["The owner is almost ready to close, but soup still warms the pot."],
		},
		"fill_color": Color(1.0, 0.64, 0.35, 0.20),
		"border_color": Color("#ffd28a"),
	})
	_add_interactable({
		"id": "office_gate",
		"name": "Office Entrance",
		"kind": "office",
		"prompt": "Press E to enter the office",
		"position": Vector2(1112, 318),
		"size": Vector2(72, 30),
		"lines": {
			"default": ["Glass walls cut the sky into tidy pieces."],
			"morning": ["Turnstiles keep beeping while riders and office workers collide at the door."],
			"evening": ["Many office lights are still on."],
			"late_night": ["The security guard scrolls short videos beside the quiet lobby."],
		},
		"fill_color": Color(0.55, 0.76, 0.95, 0.18),
		"border_color": Color("#c7e7ff"),
	})
	_add_interactable({
		"id": "office_coffee",
		"name": "Office Coffee",
		"kind": "shop",
		"prompt": "Press E to buy coffee",
		"position": Vector2(1188, 516),
		"size": Vector2(58, 26),
		"fill_color": Color(0.86, 0.64, 0.38, 0.20),
		"border_color": Color("#f0c77b"),
	})
	_add_interactable({
		"id": "delivery_station",
		"name": "Delivery Station",
		"kind": "delivery_station",
		"prompt": "Press E to accept a delivery order",
		"position": Vector2(878, 508),
		"size": Vector2(72, 28),
		"lines": {
			"default": ["Scooters line up while phones chirp in staggered rhythms."],
			"morning": ["Breakfast orders come in tight clusters."],
			"evening": ["Dinner peak begins; raincoats and helmets hang like tired shadows."],
			"late_night": ["Late orders still jump, but most storefronts are closing."],
		},
		"fill_color": Color(0.95, 0.78, 0.22, 0.22),
		"border_color": Color("#f3cf6b"),
	})
	_add_interactable({
		"id": "delivery_pickup",
		"name": "Delivery Pickup",
		"kind": "delivery_pickup",
		"prompt": "Press E to pick up food",
		"position": Vector2(458, 440),
		"size": Vector2(46, 26),
		"fill_color": Color(1.0, 0.64, 0.35, 0.20),
		"border_color": Color("#ffd28a"),
	})
	_add_interactable({
		"id": "delivery_dropoff",
		"name": "Delivery Dropoff",
		"kind": "delivery_dropoff",
		"prompt": "Press E to deliver food",
		"position": Vector2(228, 206),
		"size": Vector2(46, 26),
		"fill_color": Color(0.86, 0.68, 0.38, 0.22),
		"border_color": Color("#efc36f"),
	})
	_add_interactable({
		"id": "media_company_gate",
		"name": "Media Company",
		"kind": "media_company",
		"prompt": "Press E to enter the media company",
		"position": Vector2(898, 222),
		"size": Vector2(70, 28),
		"lines": {
			"default": ["A short-video agency sign glows pink above the corridor."],
			"morning": ["The front desk is still sorting parcels and sample boxes."],
			"evening": ["Ring lights in the studio turn overtime into another kind of stage."],
			"late_night": ["Someone inside is reviewing numbers under soft pink light."],
		},
		"fill_color": Color(1.0, 0.58, 0.72, 0.18),
		"border_color": Color("#ffc4d6"),
	})

func _add_interactable(data: Dictionary) -> void:
	var interactable: WorldInteractable = WorldInteractableScript.new()
	interactable.configure(data)
	add_child(interactable)


func _draw_shanghai_geography() -> void:
	_draw_huangpu_river()
	_draw_suzhou_creek()
	_draw_city_axis_roads()
	_draw_real_map_landmarks()


func _draw_huangpu_river() -> void:
	var river := PackedVector2Array([
		Vector2(914, -20),
		Vector2(1008, -20),
		Vector2(1004, 104),
		Vector2(980, 246),
		Vector2(1008, 404),
		Vector2(1024, 740),
		Vector2(936, 740),
		Vector2(930, 572),
		Vector2(940, 430),
		Vector2(918, 300),
		Vector2(910, 126),
	])
	draw_colored_polygon(river, Color("#405f72"))
	draw_polyline(river, Color(0.72, 0.88, 0.95, 0.28), 2.0, true)
	draw_rect(Rect2(Vector2(858, 292), Vector2(210, 34)), Color("#6e7475"))
	draw_rect(Rect2(Vector2(858, 306), Vector2(210, 5)), Color("#b7a777"))
	draw_rect(Rect2(Vector2(884, 500), Vector2(210, 42)), Color("#6e7475"))
	draw_rect(Rect2(Vector2(884, 518), Vector2(210, 5)), Color("#b7a777"))
	for i in range(7):
		var shimmer_y := 48 + i * 78
		draw_line(Vector2(936, shimmer_y), Vector2(986, shimmer_y + 18), Color(0.82, 0.95, 1.0, 0.15), 1.0)


func _draw_suzhou_creek() -> void:
	var creek := PackedVector2Array([
		Vector2(216, 276),
		Vector2(374, 262),
		Vector2(536, 274),
		Vector2(700, 250),
		Vector2(914, 256),
	])
	draw_polyline(creek, Color("#496879"), 18.0, false)
	draw_polyline(creek, Color(0.82, 0.95, 1.0, 0.20), 2.0, false)
	for bridge_x in [344, 612, 792]:
		draw_rect(Rect2(Vector2(bridge_x, 244), Vector2(62, 30)), Color("#74736c"))
		draw_line(Vector2(bridge_x + 8, 258), Vector2(bridge_x + 54, 258), Color("#c2b27a"), 1.0)


func _draw_city_axis_roads() -> void:
	draw_line(Vector2(190, 574), Vector2(930, 318), Color(0.46, 0.46, 0.43, 0.55), 7.0)
	draw_line(Vector2(444, 218), Vector2(914, 240), Color(0.46, 0.46, 0.43, 0.52), 8.0)
	draw_line(Vector2(1066, 316), Vector2(1312, 330), Color(0.46, 0.46, 0.43, 0.50), 7.0)
	draw_line(Vector2(558, 130), Vector2(558, 626), Color(0.42, 0.42, 0.40, 0.45), 6.0)
	draw_line(Vector2(190, 574), Vector2(930, 318), Color("#d0c38a"), 1.0)
	draw_line(Vector2(444, 218), Vector2(914, 240), Color("#d0c38a"), 1.0)
	draw_line(Vector2(1066, 316), Vector2(1312, 330), Color("#d0c38a"), 1.0)


func _draw_real_map_landmarks() -> void:
	draw_rect(Rect2(Vector2(486, 126), Vector2(150, 88)), Color("#5f7a59"))
	draw_rect(Rect2(Vector2(506, 146), Vector2(110, 48)), Color(0.86, 0.76, 0.46, 0.36))
	for i in range(4):
		draw_circle(Vector2(516 + i * 32, 204), 4, Color("#d8c886"))
	draw_rect(Rect2(Vector2(872, 126), Vector2(34, 280)), Color("#6b6259"))
	for i in range(8):
		draw_rect(Rect2(Vector2(878, 146 + i * 30), Vector2(22, 12)), Color("#d6c69a"))
	draw_circle(Vector2(1086, 238), 42, Color(0.55, 0.76, 0.95, 0.14))
	draw_rect(Rect2(Vector2(1060, 168), Vector2(22, 88)), Color("#7f9caf"))
	draw_rect(Rect2(Vector2(1092, 136), Vector2(28, 128)), Color("#8fb1c2"))
	draw_rect(Rect2(Vector2(1130, 188), Vector2(20, 70)), Color("#6f8795"))
	draw_rect(Rect2(Vector2(248, 548), Vector2(142, 88)), Color("#806b52"))
	draw_rect(Rect2(Vector2(270, 566), Vector2(100, 32)), Color("#f0c77b"))
	draw_rect(Rect2(Vector2(286, 608), Vector2(68, 18)), Color("#5b4638"))


func _draw_reusable_street_props() -> void:
	ArtAssetsScript.draw_prop(self, "laundry_rack", Vector2(104, 188), 1.0)
	ArtAssetsScript.draw_prop(self, "ac_unit", Vector2(80, 92), 0.9)
	ArtAssetsScript.draw_prop(self, "ac_unit", Vector2(186, 92), 0.9)
	ArtAssetsScript.draw_prop(self, "vending_machine", Vector2(760, 208), 1.0)
	ArtAssetsScript.draw_prop(self, "utility_pole", Vector2(504, 190), 1.0)
	ArtAssetsScript.draw_prop(self, "food_sign", Vector2(402, 408), 1.0)
	ArtAssetsScript.draw_prop(self, "metro_sign", Vector2(694, 394), 1.0)
	ArtAssetsScript.draw_prop(self, "rider_bag", Vector2(822, 506), 1.0)
	for i in range(4):
		ArtAssetsScript.draw_prop(self, "scooter", Vector2(796 + i * 34, 520), 1.0)
	ArtAssetsScript.draw_prop(self, "product_boxes", Vector2(860, 192), 1.0)
	ArtAssetsScript.draw_prop(self, "ring_light", Vector2(936, 188), 0.9, Color(1.0, 1.0, 1.0, 0.88))


func _draw_building(data: Dictionary) -> void:
	var rect: Rect2 = data["rect"]
	var body: Color = data["body"]
	var roof: Color = data["roof"]
	var light: Color = data["light"]
	var id: String = data["id"]

	draw_rect(Rect2(rect.position + Vector2(5, 8), rect.size), Color(0.04, 0.04, 0.05, 0.28))
	draw_rect(rect, body)
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 24)), roof)
	draw_rect(rect, Color(0.06, 0.05, 0.05, 0.24), false, 2.0)

	if id == "rental":
		_draw_rental_details(rect, light)
	elif id == "store":
		_draw_store_details(rect, light)
	elif id == "restaurant":
		_draw_restaurant_details(rect, light)
	elif id == "metro":
		_draw_metro_details(rect, light)
	elif id == "office":
		_draw_office_details(rect, light)
	elif id == "office_shop":
		_draw_office_shop_details(rect, light)
	elif id == "delivery_station":
		_draw_delivery_station_details(rect, light)
	elif id == "media_company":
		_draw_media_company_details(rect, light)
	elif id == "wet_market":
		_draw_wet_market_details(rect, light)
	elif id == "community_clinic":
		_draw_clinic_details(rect, light)
	elif id == "talent_apartment":
		_draw_talent_apartment_details(rect, light)
	elif id == "rental_agency":
		_draw_rental_agency_details(rect, light)


func _draw_rental_details(rect: Rect2, light: Color) -> void:
	for i in range(4):
		var window_pos := rect.position + Vector2(18 + i * 38, 42)
		draw_rect(Rect2(window_pos, Vector2(18, 18)), Color("#d9c194") if i != 2 else Color("#3b3b43"))
		draw_rect(Rect2(window_pos + Vector2(7, 0), Vector2(2, 18)), Color("#68564c"))
	draw_rect(Rect2(rect.position + Vector2(75, 84), Vector2(28, 28)), Color("#493c37"))
	draw_line(rect.position + Vector2(26, 120), rect.position + Vector2(134, 120), Color("#d8c8a0"), 1.0)
	draw_rect(Rect2(rect.position + Vector2(42, 116), Vector2(14, 8)), Color("#bdd3e0"))
	draw_rect(Rect2(rect.position + Vector2(86, 116), Vector2(18, 8)), Color("#e08772"))
	draw_rect(Rect2(rect.position + Vector2(112, 116), Vector2(16, 8)), Color("#f2d77b"))
	draw_rect(Rect2(rect.position + Vector2(77, 78), Vector2(24, 4)), light)


func _draw_store_details(rect: Rect2, light: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(16, 36), Vector2(160, 32)), Color("#efe2bb"))
	draw_rect(Rect2(rect.position + Vector2(22, 42), Vector2(38, 20)), Color("#83b4ba"))
	draw_rect(Rect2(rect.position + Vector2(68, 42), Vector2(38, 20)), Color("#e5a45b"))
	draw_rect(Rect2(rect.position + Vector2(114, 42), Vector2(54, 20)), Color("#c24a54"))
	draw_rect(Rect2(rect.position + Vector2(74, 84), Vector2(44, 32)), Color("#31505a"))
	draw_rect(Rect2(rect.position + Vector2(18, 12), Vector2(156, 12)), Color("#ffcf72"))
	draw_rect(Rect2(rect.position + Vector2(26, 14), Vector2(60, 6)), Color("#f25f5c"))
	draw_rect(Rect2(rect.position + Vector2(98, 14), Vector2(56, 6)), Color("#5fd4c5"))
	draw_rect(Rect2(rect.position + Vector2(62, 76), Vector2(68, 8)), light)


func _draw_restaurant_details(rect: Rect2, light: Color) -> void:
	for i in range(5):
		var stripe_color := Color("#f2d78d") if i % 2 == 0 else Color("#a93f3a")
		draw_rect(Rect2(rect.position + Vector2(10 + i * 30, 25), Vector2(30, 12)), stripe_color)
	draw_rect(Rect2(rect.position + Vector2(22, 50), Vector2(40, 26)), light)
	draw_rect(Rect2(rect.position + Vector2(104, 50), Vector2(34, 42)), Color("#50342d"))
	draw_rect(Rect2(rect.position + Vector2(20, 6), Vector2(72, 12)), Color("#ffe2a1"))
	draw_rect(Rect2(rect.position + Vector2(40, 108), Vector2(26, 14)), Color("#4a382e"))
	draw_rect(Rect2(rect.position + Vector2(72, 110), Vector2(24, 12)), Color("#4a382e"))


func _draw_metro_details(rect: Rect2, light: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(16, 18), Vector2(100, 12)), Color("#77b9e8"))
	draw_rect(Rect2(rect.position + Vector2(34, 36), Vector2(64, 36)), Color("#263647"))
	for i in range(4):
		draw_line(rect.position + Vector2(40, 44 + i * 7), rect.position + Vector2(94, 44 + i * 7), Color("#617287"), 1.0)
	draw_circle(rect.position + Vector2(22, 24), 8, light)
	draw_rect(Rect2(rect.position + Vector2(19, 20), Vector2(6, 8)), Color("#2d4258"))


func _draw_office_details(rect: Rect2, light: Color) -> void:
	for row in range(5):
		for col in range(5):
			var window_pos := rect.position + Vector2(18 + col * 36, 38 + row * 28)
			var lit := (row + col) % 3 != 0 or current_segment in ["evening", "late_night"]
			draw_rect(Rect2(window_pos, Vector2(22, 16)), light if lit else Color("#344454"))
	draw_rect(Rect2(rect.position + Vector2(72, 150), Vector2(68, 38)), Color("#26313d"))
	draw_rect(Rect2(rect.position + Vector2(84, 158), Vector2(44, 20)), Color("#8fc4d4"))
	draw_rect(Rect2(rect.position + Vector2(20, 10), Vector2(172, 12)), Color("#c7e7ff"))
	draw_line(rect.position + Vector2(-70, 202), rect.position + Vector2(138, 202), Color("#8a8f91"), 3.0)


func _draw_office_shop_details(rect: Rect2, light: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(12, 20), Vector2(128, 24)), Color("#f1d6a1"))
	draw_rect(Rect2(rect.position + Vector2(22, 26), Vector2(32, 12)), Color("#6f4a34"))
	draw_rect(Rect2(rect.position + Vector2(62, 26), Vector2(28, 12)), Color("#314350"))
	draw_rect(Rect2(rect.position + Vector2(100, 26), Vector2(24, 12)), Color("#b75c47"))
	draw_rect(Rect2(rect.position + Vector2(58, 54), Vector2(36, 32)), Color("#49372c"))
	draw_rect(Rect2(rect.position + Vector2(16, 52), Vector2(32, 20)), light)


func _draw_delivery_station_details(rect: Rect2, light: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(12, 18), Vector2(112, 18)), Color("#f4d56f"))
	draw_rect(Rect2(rect.position + Vector2(20, 24), Vector2(24, 5)), Color("#4d5738"))
	draw_rect(Rect2(rect.position + Vector2(54, 24), Vector2(24, 5)), Color("#4d5738"))
	draw_rect(Rect2(rect.position + Vector2(88, 24), Vector2(18, 5)), Color("#4d5738"))
	draw_rect(Rect2(rect.position + Vector2(50, 52), Vector2(36, 34)), Color("#35412e"))
	draw_rect(Rect2(rect.position + Vector2(14, 50), Vector2(22, 24)), Color(light))
	for i in range(4):
		var scooter_pos := rect.position + Vector2(-8 + i * 32, 112)
		draw_rect(Rect2(scooter_pos, Vector2(22, 7)), Color("#f1c232"))
		draw_circle(scooter_pos + Vector2(5, 8), 4, Color("#26313d"))
		draw_circle(scooter_pos + Vector2(18, 8), 4, Color("#26313d"))


func _draw_media_company_details(rect: Rect2, light: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(14, 20), Vector2(120, 18)), Color("#ffc4d6"))
	draw_rect(Rect2(rect.position + Vector2(26, 26), Vector2(24, 5)), Color("#58445f"))
	draw_rect(Rect2(rect.position + Vector2(58, 26), Vector2(24, 5)), Color("#58445f"))
	draw_rect(Rect2(rect.position + Vector2(90, 26), Vector2(18, 5)), Color("#58445f"))
	for row in range(3):
		for col in range(3):
			var window_pos := rect.position + Vector2(22 + col * 38, 52 + row * 30)
			var lit := current_segment in ["evening", "late_night"] or (row + col) % 2 == 0
			draw_rect(Rect2(window_pos, Vector2(22, 16)), light if lit else Color("#3e3544"))
	draw_rect(Rect2(rect.position + Vector2(58, 116), Vector2(34, 36)), Color("#342b38"))
	draw_circle(rect.position + Vector2(116, 128), 12, Color("#ffe2ed"))


func _draw_wet_market_details(rect: Rect2, light: Color) -> void:
	for i in range(5):
		var awning_color := Color("#f0c77b") if i % 2 == 0 else Color("#6f7653")
		draw_rect(Rect2(rect.position + Vector2(10 + i * 34, 26), Vector2(34, 14)), awning_color)
	draw_rect(Rect2(rect.position + Vector2(20, 54), Vector2(42, 28)), Color("#4d5738"))
	draw_rect(Rect2(rect.position + Vector2(70, 54), Vector2(42, 28)), Color("#8a4b42"))
	draw_rect(Rect2(rect.position + Vector2(120, 54), Vector2(42, 28)), Color("#6d8d83"))
	for i in range(4):
		draw_circle(rect.position + Vector2(28 + i * 10, 66), 3, Color("#e08772"))
		draw_circle(rect.position + Vector2(78 + i * 10, 66), 3, Color("#e5bd3f"))
		draw_circle(rect.position + Vector2(128 + i * 10, 66), 3, Color("#bdd3a0"))
	draw_rect(Rect2(rect.position + Vector2(18, 8), Vector2(96, 12)), light)
	draw_rect(Rect2(rect.position + Vector2(58, 86), Vector2(52, 18)), Color("#3d3a32"))


func _draw_clinic_details(rect: Rect2, light: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(16, 28), Vector2(132, 24)), Color("#d8fff0"))
	draw_rect(Rect2(rect.position + Vector2(76, 32), Vector2(10, 16)), Color("#c76b6d"))
	draw_rect(Rect2(rect.position + Vector2(70, 38), Vector2(22, 6)), Color("#c76b6d"))
	for i in range(3):
		draw_rect(Rect2(rect.position + Vector2(24 + i * 42, 58), Vector2(26, 18)), light)
	draw_rect(Rect2(rect.position + Vector2(66, 76), Vector2(34, 16)), Color("#2f4c4a"))
	draw_rect(Rect2(rect.position + Vector2(20, 8), Vector2(88, 10)), Color("#e9fff7"))
	draw_rect(Rect2(rect.position + Vector2(24, 11), Vector2(38, 4)), Color("#3d635f"))


func _draw_talent_apartment_details(rect: Rect2, light: Color) -> void:
	for row in range(4):
		for col in range(4):
			var window_pos := rect.position + Vector2(22 + col * 36, 42 + row * 24)
			var lit := current_segment in ["evening", "late_night"] and (row + col) % 2 == 0
			draw_rect(Rect2(window_pos, Vector2(20, 14)), light if lit else Color("#3f4d5d"))
	draw_rect(Rect2(rect.position + Vector2(58, 112), Vector2(56, 34)), Color("#2f3d4f"))
	draw_rect(Rect2(rect.position + Vector2(70, 122), Vector2(32, 16)), Color("#8fc4d4"))
	draw_rect(Rect2(rect.position + Vector2(16, 10), Vector2(132, 12)), Color("#c7e7ff"))
	draw_rect(Rect2(rect.position + Vector2(30, 14), Vector2(32, 4)), Color("#56636c"))
	draw_rect(Rect2(rect.position + Vector2(74, 14), Vector2(44, 4)), Color("#56636c"))


func _draw_rental_agency_details(rect: Rect2, light: Color) -> void:
	draw_rect(Rect2(rect.position + Vector2(14, 24), Vector2(136, 22)), Color("#f1d6a1"))
	draw_rect(Rect2(rect.position + Vector2(24, 30), Vector2(28, 6)), Color("#5b4638"))
	draw_rect(Rect2(rect.position + Vector2(64, 30), Vector2(28, 6)), Color("#5b4638"))
	draw_rect(Rect2(rect.position + Vector2(104, 30), Vector2(32, 6)), Color("#8a4b42"))
	draw_rect(Rect2(rect.position + Vector2(18, 54), Vector2(42, 26)), light)
	draw_rect(Rect2(rect.position + Vector2(96, 50), Vector2(38, 36)), Color("#49372c"))
	draw_rect(Rect2(rect.position + Vector2(100, 56), Vector2(30, 8)), Color("#d8c8a0"))
	draw_rect(Rect2(rect.position + Vector2(100, 68), Vector2(22, 6)), Color("#c76b6d"))


func _draw_puddles_and_lights() -> void:
	var puddle_color := Color(0.34, 0.49, 0.56, 0.44)
	if current_weather == "rain":
		puddle_color = Color(0.38, 0.56, 0.66, 0.62)
	_draw_ellipse(Rect2(292, 222, 58, 18), puddle_color)
	_draw_ellipse(Rect2(506, 260, 42, 13), puddle_color)
	_draw_ellipse(Rect2(194, 412, 52, 15), puddle_color)
	_draw_ellipse(Rect2(604, 330, 48, 14), puddle_color)
	_draw_ellipse(Rect2(984, 374, 62, 17), puddle_color)
	_draw_ellipse(Rect2(1160, 350, 46, 14), puddle_color)
	_draw_ellipse(Rect2(812, 548, 58, 15), puddle_color)
	_draw_ellipse(Rect2(520, 226, 66, 16), puddle_color)
	_draw_ellipse(Rect2(884, 296, 54, 14), puddle_color)
	_draw_ellipse(Rect2(1086, 338, 64, 16), puddle_color)
	_draw_ellipse(Rect2(284, 626, 58, 14), puddle_color)

	if current_weather == "rain":
		for i in range(32):
			var x := float((i * 37) % (MAP_SIZE.x * TILE_SIZE))
			var y := float((i * 53) % (MAP_SIZE.y * TILE_SIZE))
			draw_line(Vector2(x, y), Vector2(x - 5, y + 10), Color(0.75, 0.88, 0.95, 0.28), 1.0)

	if current_segment in ["evening", "late_night"]:
		draw_circle(Vector2(653, 202), 72, Color(1.0, 0.78, 0.36, 0.08))
		draw_circle(Vector2(368, 438), 58, Color(1.0, 0.55, 0.28, 0.07))
		draw_circle(Vector2(720, 390), 68, Color(0.45, 0.7, 1.0, 0.08))
		draw_circle(Vector2(878, 508), 54, Color(1.0, 0.82, 0.22, 0.08))
		draw_circle(Vector2(898, 222), 62, Color(1.0, 0.50, 0.68, 0.07))
		draw_circle(Vector2(560, 228), 90, Color(1.0, 0.82, 0.38, 0.06))
		draw_circle(Vector2(900, 252), 96, Color(0.50, 0.78, 1.0, 0.07))
		draw_circle(Vector2(1088, 366), 112, Color(0.55, 0.76, 1.0, 0.08))
		draw_circle(Vector2(304, 590), 72, Color(1.0, 0.70, 0.38, 0.06))


func _draw_metro_glow() -> void:
	if current_segment == "morning":
		return
	draw_line(Vector2(650, 394), Vector2(785, 394), Color(0.45, 0.72, 1.0, 0.35), 2.0)


func _draw_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.position + rect.size * 0.5
	var radius := rect.size * 0.5
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
