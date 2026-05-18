extends Node2D
class_name CityMap

const TILE_SIZE := 16
const BUILDING_GRID := TILE_SIZE * 4
const MAP_SCALE := 3
const MAP_SIZE := Vector2i(132 * MAP_SCALE, 76 * MAP_SCALE)

const STREET_HOME := Vector2(348, 382)
const STREET_STORE := Vector2(1238, 382)
const STREET_RESTAURANT := Vector2(858, 1018)
const STREET_METRO := Vector2(2138, 1218)
const STREET_OFFICE := Vector2(3540, 642)
const STREET_OFFICE_COFFEE := Vector2(3936, 1408)
const STREET_DELIVERY_STATION := Vector2(2976, 1408)
const STREET_DELIVERY_PICKUP := Vector2(858, 1018)
const STREET_DELIVERY_DROPOFF := Vector2(4700, 642)
const STREET_MEDIA := Vector2(2784, 386)
const STREET_INTERNET_CAFE := Vector2(1680, 1024)
const STREET_MARKET := Vector2(670, 2494)
const STREET_CLINIC := Vector2(1438, 2366)
const STREET_TALENT_APARTMENT := Vector2(4700, 642)
const STREET_RENTAL_AGENCY := Vector2(4512, 1664)
const STREET_PEOPLE_SQUARE := Vector2(2304, 960)
const STREET_BUND := Vector2(5150, 980)
const STREET_LUJIAZUI := Vector2(5570, 880)
const STREET_HIGH_SPEED_RAIL := Vector2(5880, 1740)
const STREET_REPUBLIC_SHANGHAI := Vector2(5340, 1300)

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
	return STREET_HOME + Vector2(0, 28)


func get_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(MAP_SIZE.x * TILE_SIZE, MAP_SIZE.y * TILE_SIZE))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	if _has_reference_road_tile_map():
		_draw_handdrawn_ground_overlays()
		_draw_showcase_buildings()
		_draw_reusable_street_props()
		_draw_metro_glow()
		return
	_draw_shanghai_geography()
	_draw_handdrawn_ground_overlays()
	_draw_puddles_and_lights()
	for data in building_rects:
		_draw_building(data)
	_draw_shanghai_life_markers()
	_draw_showcase_buildings()
	_draw_reusable_street_props()
	_draw_metro_glow()


func _has_reference_road_tile_map() -> bool:
	var road_tile_map: TileMap = get_node_or_null("RoadElementTileMap") as TileMap
	if road_tile_map == null:
		road_tile_map = get_node_or_null("RoadScreenshotTileMap") as TileMap
	return road_tile_map != null and road_tile_map.visible


func _create_tile_map() -> void:
	tile_map = get_node_or_null("PixelTileMap") as TileMap
	if tile_map == null:
		tile_map = TileMap.new()
		tile_map.name = "PixelTileMap"
		tile_map.z_index = -20
		add_child(tile_map)

	if _has_reference_road_tile_map():
		return

	if tile_map.tile_set == null:
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

	if tile_map.get_used_cells(0).is_empty():
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
	_add_building("rental", _grid_rect(4, 4, 2, 2), Color("#8e6d58"), Color("#6d5046"), Color("#efc36f"))
	_add_building("store", _grid_rect(18, 4, 2, 2), Color("#6d8d83"), Color("#3d635f"), Color("#f5d37b"))
	_add_building("restaurant", _grid_rect(12, 15, 2, 1), Color("#a45d45"), Color("#793d36"), Color("#ffe0a3"))
	_add_building("metro", _grid_rect(32, 18, 2, 1), Color("#4d5d70"), Color("#2f3d4f"), Color("#a9d7ff"))
	_add_building("office", _grid_rect(54, 8, 2, 2), Color("#697985"), Color("#3f4d5d"), Color("#c7e7ff"))
	_add_building("office_shop", _grid_rect(60, 21, 2, 1), Color("#806b52"), Color("#5b4638"), Color("#f0c77b"))
	_add_building("delivery_station", _grid_rect(45, 21, 2, 1), Color("#6f7653"), Color("#4d5738"), Color("#f3cf6b"))
	_add_building("media_company", _grid_rect(42, 4, 2, 2), Color("#7b647f"), Color("#58445f"), Color("#ffc4d6"))
	_add_building("internet_cafe", _grid_rect(26, 15, 2, 1), Color("#38485a"), Color("#202838"), Color("#6fd2ff"))
	_add_building("wet_market", _grid_rect(9, 38, 2, 1), Color("#6f7653"), Color("#4d5738"), Color("#f0c77b"))
	_add_building("community_clinic", _grid_rect(21, 36, 2, 1), Color("#6d8d83"), Color("#3d635f"), Color("#d8fff0"))
	_add_building("talent_apartment", _grid_rect(72, 8, 2, 2), Color("#7d8588"), Color("#56636c"), Color("#ffe2a1"))
	_add_building("rental_agency", _grid_rect(69, 25, 2, 1), Color("#806b52"), Color("#5b4638"), Color("#f0c77b"))


func _grid_rect(tile_x: int, tile_y: int, tile_width: int, tile_height: int) -> Rect2:
	return Rect2(
		Vector2(tile_x * BUILDING_GRID, tile_y * BUILDING_GRID),
		Vector2(tile_width * BUILDING_GRID, tile_height * BUILDING_GRID)
	)


func _add_building(id: String, rect: Rect2, body: Color, roof: Color, light: Color) -> void:
	rect = _snap_building_rect(rect)
	building_rects.append({
		"id": id,
		"rect": rect,
		"body": body,
		"roof": roof,
		"light": light,
	})
	_add_collision_rect("%s_collision" % id, rect.position + Vector2(4, 20), rect.size - Vector2(8, 22))


func _snap_building_rect(rect: Rect2) -> Rect2:
	var grid := float(BUILDING_GRID)
	var snapped_position := Vector2(round(rect.position.x / grid) * grid, round(rect.position.y / grid) * grid)
	var snapped_size := Vector2(
		clampf(round(rect.size.x / grid) * grid, grid, grid * 2.0),
		clampf(round(rect.size.y / grid) * grid, grid, grid * 2.0)
	)
	return Rect2(snapped_position, snapped_size)


func _create_boundaries() -> void:
	var world_size := Vector2(MAP_SIZE.x * TILE_SIZE, MAP_SIZE.y * TILE_SIZE)
	_add_collision_rect("north_wall", Vector2(0, -16), Vector2(world_size.x, 16))
	_add_collision_rect("south_wall", Vector2(0, world_size.y), Vector2(world_size.x, 16))
	_add_collision_rect("west_wall", Vector2(-16, 0), Vector2(16, world_size.y))
	_add_collision_rect("east_wall", Vector2(world_size.x, 0), Vector2(16, world_size.y))

	_add_collision_rect("laundry_posts", Vector2(300, 408), Vector2(96, 10))
	_add_collision_rect("food_stall_tables", Vector2(802, 1050), Vector2(72, 16))
	_add_collision_rect("skybridge_post_left", Vector2(3380, 834), Vector2(12, 32))
	_add_collision_rect("skybridge_post_right", Vector2(3602, 834), Vector2(12, 32))
	_add_collision_rect("delivery_scooters", Vector2(2884, 1436), Vector2(112, 18))
	_add_collision_rect("huangpu_river_north", Vector2(5248, -8), Vector2(256, 904))
	_add_collision_rect("huangpu_river_middle_a", Vector2(5248, 1024), Vector2(256, 640))
	_add_collision_rect("huangpu_river_middle_b", Vector2(5248, 1792), Vector2(256, 1024))
	_add_collision_rect("huangpu_river_south", Vector2(5248, 2944), Vector2(256, MAP_SIZE.y * TILE_SIZE - 2944))


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
		"name": "出租屋",
		"kind": "enter_apartment",
		"prompt": "按 E 回家",
		"position": STREET_HOME,
		"size": Vector2(44, 26),
		"fill_color": Color(0.86, 0.68, 0.38, 0.26),
	})
	_add_interactable({
		"id": "store",
		"name": "便利店",
		"kind": "shop",
		"prompt": "按 E 购物",
		"position": STREET_STORE,
		"size": Vector2(58, 28),
		"fill_color": Color(0.93, 0.78, 0.36, 0.24),
	})
	_add_interactable({
		"id": "metro",
		"name": "地铁口",
		"kind": "enter_metro",
		"prompt": "按 E 进地铁站",
		"position": STREET_METRO,
		"size": Vector2(60, 28),
		"lines": {
			"default": ["地铁口吐出潮湿的风和白色灯光。"],
			"morning": ["早高峰已经在闸机旁边成形。"],
			"evening": ["人群从楼梯口涌出来，带着一整天的重量。"],
			"late_night": ["末班车提示音比想象中更轻。"],
		},
		"fill_color": Color(0.42, 0.66, 0.91, 0.22),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "people_square",
		"name": "人民广场方向",
		"kind": "dialogue",
		"prompt": "按 E 看人民广场方向",
		"position": STREET_PEOPLE_SQUARE,
		"size": Vector2(72, 28),
		"lines": {
			"default": ["这个方向把地铁线、商场、人流和招聘广告压成一个城市结。"],
			"morning": ["人流像一张巨大的表格不断刷新。"],
			"evening": ["商场灯光让广场显得更宽，也更孤独。"],
		},
		"fill_color": Color(0.56, 0.72, 0.52, 0.18),
		"border_color": Color("#c4d8a8"),
	})
	_add_interactable({
		"id": "shanghai_city_task",
		"name": "上海城市委托栏",
		"kind": "city_task",
		"prompt": "按 E 接城市委托",
		"position": STREET_PEOPLE_SQUARE + Vector2(118, 42),
		"size": Vector2(112, 34),
		"fill_color": Color(0.56, 0.72, 0.52, 0.20),
		"border_color": Color("#c4d8a8"),
	})
	_add_interactable({
		"id": "bund_prom",
		"name": "外滩江边",
		"kind": "dialogue",
		"prompt": "按 E 看外滩方向",
		"position": STREET_BUND,
		"size": Vector2(60, 30),
		"lines": {
			"default": ["江对岸，游客照片和打工人的通勤吹着同一阵风。"],
			"evening": ["高楼亮起来，像一张很贵的工资条。"],
			"late_night": ["江风更冷了，但灯还在工作。"],
		},
		"fill_color": Color(0.45, 0.70, 0.88, 0.16),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "xujiahui_node",
		"name": "徐家汇方向",
		"kind": "dialogue",
		"prompt": "按 E 看徐家汇方向",
		"position": Vector2(960, 2880),
		"size": Vector2(72, 28),
		"lines": {
			"default": ["西南方向把商场、办公室、老小区和换乘站折在一起。"],
			"afternoon": ["商业街很亮，但你还在算今天赚了多少。"],
		},
		"fill_color": Color(0.86, 0.64, 0.38, 0.18),
		"border_color": Color("#e8c879"),
	})
	_add_interactable({
		"id": "lujiazui_node",
		"name": "东方明珠",
		"kind": "dialogue",
		"prompt": "按 E 看东方明珠",
		"position": STREET_LUJIAZUI,
		"size": Vector2(86, 30),
		"lines": {
			"default": ["东方明珠立在江对岸，像城市给每个漂着的人留下的坐标。"],
			"morning": ["早高峰的人流从塔下掠过，没人真的停下来抬头。"],
			"evening": ["塔身灯光亮起来，江风把今天的疲惫吹得更清楚。"],
			"late_night": ["东方明珠还亮着，有些办公室也还亮着。"],
		},
		"fill_color": Color(0.55, 0.76, 0.95, 0.16),
		"border_color": Color("#c7e7ff"),
	})
	_add_interactable({
		"id": "shanghai_hsr",
		"name": "上海高铁站",
		"kind": "high_speed_rail",
		"prompt": "按 E 乘高铁",
		"position": STREET_HIGH_SPEED_RAIL,
		"size": Vector2(112, 36),
		"lines": {
			"default": ["站厅里滚动着去往各地的车次。"],
		},
		"fill_color": Color(0.48, 0.68, 0.88, 0.22),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "republic_shanghai_portal",
		"name": "民国上海旧影",
		"kind": "enter_republic_shanghai",
		"prompt": "按 E 前往民国上海",
		"position": STREET_REPUBLIC_SHANGHAI,
		"size": Vector2(118, 38),
		"lines": {
			"default": ["旧报纸和黄浦江风把这条路折回了另一个年代。"],
		},
		"fill_color": Color(0.48, 0.68, 0.88, 0.20),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "shanghai_mansion_gate",
		"name": "海上公馆",
		"kind": "enter_shanghai_mansion",
		"prompt": "按 E 进公馆",
		"position": STREET_REPUBLIC_SHANGHAI + Vector2(-180, 92),
		"size": Vector2(92, 34),
		"lines": {
			"default": ["一栋老公馆藏在梧桐影子里，门牌擦得很亮。"],
		},
		"fill_color": Color(0.72, 0.58, 0.38, 0.20),
		"border_color": Color("#e8c879"),
	})
	_add_interactable({
		"id": "wet_market",
		"name": "菜场",
		"kind": "enter_wet_market",
		"prompt": "按 E 进菜场",
		"position": STREET_MARKET,
		"size": Vector2(78, 30),
		"lines": {
			"default": ["菜场比便利店便宜，但它要求你自己把希望煮熟。"],
			"morning": ["早市吵、湿，也很有活气。"],
			"late_night": ["地上只剩水痕和几片菜叶。"],
		},
		"fill_color": Color(0.72, 0.84, 0.42, 0.18),
		"border_color": Color("#d8c886"),
	})
	_add_interactable({
		"id": "community_clinic",
		"name": "社区诊所",
		"kind": "enter_clinic",
		"prompt": "按 E 进诊所",
		"position": STREET_CLINIC,
		"size": Vector2(78, 30),
		"lines": {
			"default": ["流感海报和体检通知挤在诊所门口。"],
			"morning": ["早上排队的人更多，很多人在问半天病假怎么开。"],
			"evening": ["诊所的白光把每个人都照得很累。"],
		},
		"fill_color": Color(0.62, 0.90, 0.78, 0.18),
		"border_color": Color("#d8fff0"),
	})
	_add_interactable({
		"id": "talent_apartment",
		"name": "人才公寓",
		"kind": "talent_apartment",
		"prompt": "按 E 查看人才公寓",
		"position": STREET_TALENT_APARTMENT,
		"size": Vector2(88, 30),
		"lines": {
			"default": ["门口贴满申请条件：学历、社保、单位、排队号。"],
			"evening": ["每一扇亮着的窗都像刚下班的人。"],
		},
		"fill_color": Color(0.55, 0.76, 0.95, 0.16),
		"border_color": Color("#c7e7ff"),
	})
	_add_interactable({
		"id": "rental_agency",
		"name": "房产中介",
		"kind": "rental_agency",
		"prompt": "按 E 看租房信息",
		"position": STREET_RENTAL_AGENCY,
		"size": Vector2(78, 30),
		"lines": {
			"default": ["小纸条承诺房间、合租、押金和离地铁的距离。"],
			"late_night": ["店关了，但房源信息还在玻璃后面发亮。"],
		},
		"fill_color": Color(0.86, 0.64, 0.38, 0.18),
		"border_color": Color("#e8c879"),
	})
	_add_interactable({
		"id": "restaurant",
		"name": "小饭馆",
		"kind": "shop",
		"prompt": "按 E 买饭",
		"position": STREET_RESTAURANT,
		"size": Vector2(52, 26),
		"lines": {
			"default": ["热气从手写菜单旁边的门缝里溜出来。"],
			"evening": ["附近打工人把桌子坐满了。"],
			"late_night": ["老板快收摊了，但锅里的汤还热着。"],
		},
		"fill_color": Color(1.0, 0.64, 0.35, 0.20),
		"border_color": Color("#ffd28a"),
	})
	_add_interactable({
		"id": "office_gate",
		"name": "写字楼入口",
		"kind": "office",
		"prompt": "按 E 进公司",
		"position": STREET_OFFICE,
		"size": Vector2(72, 30),
		"lines": {
			"default": ["玻璃墙把天空切成整齐的几块。"],
			"morning": ["闸机一直响，骑手和白领在门口交错。"],
			"evening": ["很多办公室的灯还亮着。"],
			"late_night": ["保安在安静的大堂旁刷短视频。"],
		},
		"fill_color": Color(0.55, 0.76, 0.95, 0.18),
		"border_color": Color("#c7e7ff"),
	})
	_add_interactable({
		"id": "office_coffee",
		"name": "写字楼咖啡",
		"kind": "shop",
		"prompt": "按 E 买咖啡",
		"position": STREET_OFFICE_COFFEE,
		"size": Vector2(58, 26),
		"fill_color": Color(0.86, 0.64, 0.38, 0.20),
		"border_color": Color("#f0c77b"),
	})
	_add_interactable({
		"id": "delivery_station",
		"name": "配送站",
		"kind": "delivery_station",
		"prompt": "按 E 接外卖单",
		"position": STREET_DELIVERY_STATION,
		"size": Vector2(72, 28),
		"lines": {
			"default": ["电动车排成一排，手机提示音此起彼伏。"],
			"morning": ["早餐单一波一波地涌进来。"],
			"evening": ["晚高峰开始了，雨衣和头盔像疲惫的影子。"],
			"late_night": ["夜宵单还在跳，但多数店面已经准备关门。"],
		},
		"fill_color": Color(0.95, 0.78, 0.22, 0.22),
		"border_color": Color("#f3cf6b"),
	})
	_add_interactable({
		"id": "delivery_pickup",
		"name": "取餐点",
		"kind": "delivery_pickup",
		"prompt": "按 E 取餐",
		"position": STREET_DELIVERY_PICKUP,
		"size": Vector2(46, 26),
		"fill_color": Color(1.0, 0.64, 0.35, 0.20),
		"border_color": Color("#ffd28a"),
	})
	_add_interactable({
		"id": "delivery_dropoff",
		"name": "送达点",
		"kind": "delivery_dropoff",
		"prompt": "按 E 送达",
		"position": STREET_DELIVERY_DROPOFF,
		"size": Vector2(46, 26),
		"fill_color": Color(0.86, 0.68, 0.38, 0.22),
		"border_color": Color("#efc36f"),
	})
	_add_interactable({
		"id": "media_company_gate",
		"name": "传媒公司",
		"kind": "media_company",
		"prompt": "按 E 进传媒公司",
		"position": STREET_MEDIA,
		"size": Vector2(70, 28),
		"lines": {
			"default": ["短视频机构的粉色招牌在走廊上方发光。"],
			"morning": ["前台还在整理快递和样品盒。"],
			"evening": ["直播间的环形灯把加班变成另一种舞台。"],
			"late_night": ["有人在柔粉色灯光下复盘数据。"],
		},
		"fill_color": Color(1.0, 0.58, 0.72, 0.18),
		"border_color": Color("#ffc4d6"),
	})
	_add_interactable({
		"id": "internet_cafe_gate",
		"name": "旧网吧",
		"kind": "internet_cafe",
		"prompt": "按 E 进网吧",
		"position": STREET_INTERNET_CAFE,
		"size": Vector2(72, 28),
		"lines": {
			"default": ["楼梯口贴着褪色的网吧招牌，里面透出蓝色的屏幕光。"],
			"evening": ["晚饭后，附近年轻人和下班的人把角落坐满。"],
			"late_night": ["包夜价目表还亮着，像城市给失眠的人开的临时房间。"],
		},
		"fill_color": Color(0.20, 0.42, 0.95, 0.18),
		"border_color": Color("#6fd2ff"),
	})

func _add_interactable(data: Dictionary) -> void:
	var interactable: WorldInteractable = WorldInteractableScript.new()
	interactable.configure(data)
	add_child(interactable)


func _draw_shanghai_geography() -> void:
	_draw_city_block_grid()
	_draw_huangpu_river()
	_draw_suzhou_creek()
	_draw_city_axis_roads()
	_draw_real_map_landmarks()


func _draw_city_block_grid() -> void:
	var world_rect := Rect2(Vector2.ZERO, Vector2(MAP_SIZE.x * TILE_SIZE, MAP_SIZE.y * TILE_SIZE))
	ArtAssetsScript.draw_pixel_grid(self, world_rect, BUILDING_GRID, Color(0.22, 0.20, 0.17, 0.11))


func _draw_huangpu_river() -> void:
	_draw_grid_water(Rect2(Vector2(896, 0), Vector2(128, 256)))
	_draw_grid_water(Rect2(Vector2(960, 256), Vector2(96, 192)))
	_draw_grid_water(Rect2(Vector2(928, 448), Vector2(128, 320)))
	_draw_grid_bridge(Rect2(Vector2(832, 288), Vector2(256, 32)))
	_draw_grid_bridge(Rect2(Vector2(864, 512), Vector2(256, 32)))
	for i in range(7):
		var shimmer_y := 48 + i * 80
		draw_line(Vector2(928, shimmer_y), Vector2(992, shimmer_y), Color(0.82, 0.95, 1.0, 0.15), 1.0)


func _draw_suzhou_creek() -> void:
	_draw_grid_water(Rect2(Vector2(192, 256), Vector2(256, 32)))
	_draw_grid_water(Rect2(Vector2(448, 240), Vector2(256, 32)))
	_draw_grid_water(Rect2(Vector2(704, 256), Vector2(192, 32)))
	for bridge_x in [320, 576, 768]:
		_draw_grid_bridge(Rect2(Vector2(bridge_x, 240), Vector2(64, 48)))


func _draw_city_axis_roads() -> void:
	_draw_grid_road(Rect2(Vector2(192, 576), Vector2(384, 32)))
	_draw_grid_road(Rect2(Vector2(576, 320), Vector2(32, 288)))
	_draw_grid_road(Rect2(Vector2(608, 320), Vector2(320, 32)))
	_draw_grid_road(Rect2(Vector2(448, 192), Vector2(448, 32)))
	_draw_grid_road(Rect2(Vector2(544, 128), Vector2(32, 512)))
	_draw_grid_road(Rect2(Vector2(1056, 320), Vector2(256, 32)))


func _draw_grid_water(rect: Rect2) -> void:
	draw_rect(rect, Color("#405f72"))
	draw_rect(rect, Color(0.72, 0.88, 0.95, 0.20), false, 1.0)
	ArtAssetsScript.draw_pixel_grid(self, rect, TILE_SIZE, Color(0.82, 0.95, 1.0, 0.07))


func _draw_grid_bridge(rect: Rect2) -> void:
	draw_rect(rect, Color("#6e7475"))
	draw_rect(Rect2(rect.position + Vector2(0, rect.size.y * 0.5 - 2), Vector2(rect.size.x, 4)), Color("#b7a777"))
	draw_rect(rect, Color(0.05, 0.05, 0.04, 0.24), false, 1.0)


func _draw_grid_road(rect: Rect2) -> void:
	draw_rect(rect, Color(0.46, 0.46, 0.43, 0.48))
	var center_y := rect.position.y + rect.size.y * 0.5
	var center_x := rect.position.x + rect.size.x * 0.5
	if rect.size.x >= rect.size.y:
		draw_line(Vector2(rect.position.x + 8, center_y), Vector2(rect.end.x - 8, center_y), Color("#d0c38a"), 1.0)
	else:
		draw_line(Vector2(center_x, rect.position.y + 8), Vector2(center_x, rect.end.y - 8), Color("#d0c38a"), 1.0)
	draw_rect(rect, Color(0.05, 0.05, 0.04, 0.16), false, 1.0)


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


func _draw_handdrawn_ground_overlays() -> void:
	_draw_ground_patch(Rect2(Vector2(192, 256), Vector2(384, 256)), "warm_sidewalk")
	_draw_ground_patch(Rect2(Vector2(192, 320), Vector2(384, 64)), "sidewalk_cracked")
	_draw_ground_patch(Rect2(Vector2(320, 384), Vector2(128, 64)), "happy_grass")
	_draw_ground_patch(Rect2(Vector2(384, 384), Vector2(128, 64)), "grass_flowers")
	_draw_ground_patch(Rect2(Vector2(256, 448), Vector2(64, 64)), "plane_tree")
	_draw_ground_patch(Rect2(Vector2(512, 384), Vector2(64, 64)), "small_tree")
	_draw_ground_patch(Rect2(Vector2(768, 960), Vector2(256, 128)), "warm_sidewalk")
	_draw_ground_patch(Rect2(Vector2(768, 1024), Vector2(256, 64)), "crosswalk")
	_draw_ground_patch(Rect2(Vector2(1152, 320), Vector2(256, 128)), "warm_sidewalk")
	_draw_ground_patch(Rect2(Vector2(1216, 384), Vector2(64, 64)), "sidewalk_tree_well")
	_draw_ground_patch(Rect2(Vector2(1280, 384), Vector2(64, 64)), "flower_box")
	_draw_ground_patch(Rect2(Vector2(2048, 1152), Vector2(256, 128)), "soft_asphalt")
	_draw_ground_patch(Rect2(Vector2(2112, 1152), Vector2(128, 64)), "crosswalk")
	_draw_ground_patch(Rect2(Vector2(2816, 1344), Vector2(384, 192)), "wet_asphalt")
	_draw_ground_patch(Rect2(Vector2(2880, 1408), Vector2(256, 64)), "bike_lane")
	_draw_ground_patch(Rect2(Vector2(2688, 320), Vector2(256, 128)), "warm_sidewalk")
	_draw_ground_patch(Rect2(Vector2(2752, 384), Vector2(64, 64)), "rain_puddle")
	_draw_ground_patch(Rect2(Vector2(3456, 576), Vector2(256, 128)), "warm_sidewalk")
	_draw_ground_patch(Rect2(Vector2(3904, 1344), Vector2(192, 128)), "sidewalk_cracked")
	_draw_ground_patch(Rect2(Vector2(5120, 896), Vector2(192, 128)), "fallen_leaves")
	_draw_ground_patch(Rect2(Vector2(5504, 832), Vector2(192, 128)), "warm_sidewalk")
	_draw_ground_patch(Rect2(Vector2(5760, 1664), Vector2(320, 160)), "soft_asphalt")
	_draw_ground_patch(Rect2(Vector2(5824, 1728), Vector2(192, 64)), "crosswalk")


func _draw_ground_patch(rect: Rect2, tile_name: String) -> void:
	var size := float(ArtAssetsScript.HANDDRAWN_GROUND_SIZE)
	var columns := int(ceil(rect.size.x / size))
	var rows := int(ceil(rect.size.y / size))
	for row in range(rows):
		for column in range(columns):
			var tile_pos := rect.position + Vector2(column * size, row * size)
			ArtAssetsScript.draw_handdrawn_ground(self, tile_name, tile_pos)


func _draw_shanghai_life_markers() -> void:
	_draw_life_marker(STREET_HOME, "住", Color("#e8c879"), Color("#4b3724"))
	_draw_life_marker(STREET_OFFICE, "工", Color("#a9d7ff"), Color("#243849"))
	_draw_life_marker(STREET_PEOPLE_SQUARE + Vector2(118, 42), "委", Color("#c4d8a8"), Color("#33452d"))


func _draw_life_marker(center: Vector2, glyph: String, accent: Color, body: Color) -> void:
	var base := Rect2(center - Vector2(26, 23), Vector2(52, 46))
	draw_rect(base.grow(4), Color(0.06, 0.05, 0.04, 0.22))
	draw_rect(base, body)
	draw_rect(base, accent, false, 3.0)
	_draw_marker_glyph(center + Vector2(-8, -11), glyph, accent)


func _draw_marker_glyph(pos: Vector2, glyph: String, color: Color) -> void:
	if glyph == "住":
		draw_rect(Rect2(pos + Vector2(0, 10), Vector2(16, 13)), color)
		draw_polygon(PackedVector2Array([pos + Vector2(-2, 10), pos + Vector2(8, 0), pos + Vector2(18, 10)]), PackedColorArray([color]))
	elif glyph == "工":
		draw_rect(Rect2(pos + Vector2(0, 1), Vector2(16, 4)), color)
		draw_rect(Rect2(pos + Vector2(6, 5), Vector2(4, 16)), color)
		draw_rect(Rect2(pos + Vector2(0, 21), Vector2(16, 4)), color)
	else:
		draw_rect(Rect2(pos + Vector2(1, 0), Vector2(15, 21)), color)
		draw_rect(Rect2(pos + Vector2(5, 5), Vector2(7, 2)), Color("#33452d"))
		draw_rect(Rect2(pos + Vector2(5, 11), Vector2(7, 2)), Color("#33452d"))


func _draw_reusable_street_props() -> void:
	ArtAssetsScript.draw_prop(self, "laundry_rack", Vector2(312, 388), 1.0)
	ArtAssetsScript.draw_prop(self, "ac_unit", Vector2(270, 284), 0.9)
	ArtAssetsScript.draw_prop(self, "ac_unit", Vector2(376, 284), 0.9)
	ArtAssetsScript.draw_prop(self, "vending_machine", Vector2(1264, 404), 1.0)
	ArtAssetsScript.draw_prop(self, "utility_pole", Vector2(1840, 930), 1.0)
	ArtAssetsScript.draw_prop(self, "food_sign", Vector2(842, 1036), 1.0)
	ArtAssetsScript.draw_prop(self, "metro_sign", Vector2(2112, 1180), 1.0)
	ArtAssetsScript.draw_prop(self, "rider_bag", Vector2(2904, 1420), 1.0)
	for i in range(4):
		ArtAssetsScript.draw_prop(self, "scooter", Vector2(2888 + i * 34, 1430), 1.0)
	ArtAssetsScript.draw_prop(self, "product_boxes", Vector2(2720, 376), 1.0)
	ArtAssetsScript.draw_prop(self, "ring_light", Vector2(2796, 374), 0.9, Color(1.0, 1.0, 1.0, 0.88))


func _draw_building(data: Dictionary) -> void:
	var rect: Rect2 = data["rect"]
	var body: Color = data["body"]
	var roof: Color = data["roof"]
	var light: Color = data["light"]
	var id: String = data["id"]
	var ink := Color(0.12, 0.10, 0.09, 0.62)
	var sprite_name := _building_sprite_for_id(id)
	if not sprite_name.is_empty():
		_draw_atlas_building(rect, sprite_name)
		return

	_draw_cartoon_shadow(rect)
	_draw_cartoon_rect(rect, body, ink, 7.0)
	_draw_cartoon_rect(Rect2(rect.position + Vector2(4, 4), Vector2(rect.size.x - 8, 18)), roof, ink, 5.0)
	draw_line(rect.position + Vector2(8, 25), rect.position + Vector2(rect.size.x - 8, 23), Color(1.0, 0.92, 0.72, 0.12), 2.0)
	draw_line(rect.position + Vector2(9, rect.size.y - 8), rect.position + Vector2(rect.size.x - 9, rect.size.y - 10), Color(0.05, 0.04, 0.04, 0.13), 2.0)

	_draw_grid_building_details(id, rect, light)


func _building_sprite_for_id(id: String) -> String:
	match id:
		"rental":
			return "shanghai_lane_house"
		"store":
			return "shanghai_convenience_store"
		"restaurant":
			return "chengdu_noodle_shop"
		"metro":
			return "shanghai_office_tower"
		"office":
			return "shanghai_office_tower"
		"office_shop":
			return "guangzhou_qilou_shop"
		"delivery_station":
			return "shenzhen_tech_park"
		"media_company":
			return "shanghai_media_company"
		"internet_cafe":
			return "guangzhou_qilou_shop"
		"wet_market":
			return "wuhan_riverside_market"
		"community_clinic":
			return "nanjing_plane_tree_block"
		"talent_apartment":
			return "chongqing_slope_apartment"
		"rental_agency":
			return "guangzhou_qilou_shop"
	return ""


func _draw_atlas_building(rect: Rect2, sprite_name: String) -> void:
	var base_scale: float = min(rect.size.x / float(ArtAssetsScript.BUILDING_SPRITE_SIZE.x), rect.size.y / float(ArtAssetsScript.BUILDING_SPRITE_SIZE.y))
	var scale: float = base_scale
	var sprite_size: Vector2 = Vector2(ArtAssetsScript.BUILDING_SPRITE_SIZE) * scale
	var top_left: Vector2 = Vector2(rect.position.x + rect.size.x * 0.5 - sprite_size.x * 0.5, rect.end.y - sprite_size.y)
	_draw_cartoon_shadow(Rect2(top_left + Vector2(8, 12), sprite_size))
	ArtAssetsScript.draw_building_sprite(self, sprite_name, top_left, scale)


func _draw_showcase_buildings() -> void:
	var entries: Array[Dictionary] = [
		{"name": "beijing_hutong_courtyard", "pos": Vector2(5680, 1888)},
		{"name": "guangzhou_qilou_shop", "pos": Vector2(5888, 1888)},
		{"name": "hangzhou_waterside_house", "pos": Vector2(6096, 1888)},
		{"name": "nanjing_plane_tree_block", "pos": Vector2(5680, 2048)},
	]
	for entry in entries:
		var pos: Vector2 = entry["pos"]
		_draw_ground_patch(Rect2(pos + Vector2(0, 64), Vector2(128, 64)), "warm_sidewalk")
		ArtAssetsScript.draw_building_sprite(self, str(entry["name"]), pos, 0.66)


func _draw_cartoon_shadow(rect: Rect2) -> void:
	var shadow := Rect2(rect.position + Vector2(6, 8), rect.size)
	_draw_cartoon_rect(shadow, Color(0.04, 0.04, 0.05, 0.24), Color(0, 0, 0, 0), 8.0, false)


func _draw_cartoon_rect(rect: Rect2, fill: Color, stroke: Color, radius: float, draw_stroke: bool = true) -> void:
	var r: float = min(radius, min(rect.size.x, rect.size.y) * 0.5)
	draw_rect(Rect2(rect.position + Vector2(r, 0), Vector2(rect.size.x - r * 2.0, rect.size.y)), fill)
	draw_rect(Rect2(rect.position + Vector2(0, r), Vector2(rect.size.x, rect.size.y - r * 2.0)), fill)
	draw_circle(rect.position + Vector2(r, r), r, fill)
	draw_circle(rect.position + Vector2(rect.size.x - r, r), r, fill)
	draw_circle(rect.position + Vector2(r, rect.size.y - r), r, fill)
	draw_circle(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, fill)
	if draw_stroke:
		draw_line(rect.position + Vector2(r, 0), rect.position + Vector2(rect.size.x - r, 0), stroke, 2.0)
		draw_line(rect.position + Vector2(r, rect.size.y), rect.position + Vector2(rect.size.x - r, rect.size.y), stroke, 2.0)
		draw_line(rect.position + Vector2(0, r), rect.position + Vector2(0, rect.size.y - r), stroke, 2.0)
		draw_line(rect.position + Vector2(rect.size.x, r), rect.position + Vector2(rect.size.x, rect.size.y - r), stroke, 2.0)
		draw_arc(rect.position + Vector2(r, r), r, PI, PI * 1.5, 8, stroke, 2.0)
		draw_arc(rect.position + Vector2(rect.size.x - r, r), r, PI * 1.5, TAU, 8, stroke, 2.0)
		draw_arc(rect.position + Vector2(rect.size.x - r, rect.size.y - r), r, 0.0, PI * 0.5, 8, stroke, 2.0)
		draw_arc(rect.position + Vector2(r, rect.size.y - r), r, PI * 0.5, PI, 8, stroke, 2.0)


func _draw_grid_building_details(id: String, rect: Rect2, light: Color) -> void:
	var cols := int(rect.size.x / TILE_SIZE)
	var rows := int(rect.size.y / TILE_SIZE)
	var door_col: int = max(1, cols / 2 - 1)
	if id in ["restaurant", "office_shop", "delivery_station", "wet_market", "community_clinic", "rental_agency", "metro"]:
		door_col = max(1, cols - 3)
	for row in range(1, max(2, rows - 1)):
		for col in range(1, cols - 1):
			if row == rows - 2 and col >= door_col and col <= door_col + 1:
				continue
			if (row + col) % 2 == 0:
				_draw_grid_window(rect, col, row, light)
	_draw_grid_sign(id, rect)
	_draw_grid_door(rect, door_col, rows - 2, light)
	if id == "wet_market":
		_draw_grid_awning(rect, Color("#f0c77b"), Color("#6f7653"))
	elif id == "restaurant":
		_draw_grid_awning(rect, Color("#f2d78d"), Color("#a93f3a"))
	elif id == "delivery_station":
		_draw_grid_scooters(rect)


func _draw_grid_window(rect: Rect2, col: int, row: int, light: Color) -> void:
	var pos := rect.position + Vector2(col * TILE_SIZE + 3, row * TILE_SIZE + 3)
	var window_rect := Rect2(pos, Vector2(10, 8))
	_draw_cartoon_rect(window_rect, light, Color(0.10, 0.10, 0.12, 0.34), 2.5)
	draw_line(pos + Vector2(5, 1), pos + Vector2(5, 7), Color(0.10, 0.10, 0.12, 0.24), 1.0)
	draw_line(pos + Vector2(1, 4), pos + Vector2(9, 4), Color(1.0, 0.95, 0.70, 0.12), 1.0)


func _draw_grid_door(rect: Rect2, col: int, row: int, light: Color) -> void:
	var pos := rect.position + Vector2(col * TILE_SIZE, row * TILE_SIZE)
	var door_rect := Rect2(pos + Vector2(1, 1), Vector2(TILE_SIZE * 2 - 2, TILE_SIZE * 2 - 2))
	_draw_cartoon_rect(door_rect, Color("#2f2d2b"), Color(0.12, 0.10, 0.09, 0.62), 5.0)
	_draw_cartoon_rect(Rect2(pos + Vector2(5, 6), Vector2(TILE_SIZE * 2 - 10, 8)), light, Color(0.10, 0.10, 0.12, 0.26), 3.0)
	draw_circle(pos + Vector2(TILE_SIZE * 2 - 7, TILE_SIZE + 5), 1.4, Color("#d8b46f"))


func _draw_grid_sign(id: String, rect: Rect2) -> void:
	var sign_color := Color("#e8c879")
	if id in ["metro", "office", "talent_apartment"]:
		sign_color = Color("#a9d7ff")
	elif id in ["media_company"]:
		sign_color = Color("#ffc4d6")
	elif id in ["community_clinic"]:
		sign_color = Color("#d8fff0")
	var sign_rect := Rect2(rect.position + Vector2(TILE_SIZE, 5), Vector2(min(rect.size.x - TILE_SIZE * 2, TILE_SIZE * 4), 9))
	_draw_cartoon_rect(sign_rect, sign_color, Color(0.12, 0.10, 0.09, 0.42), 3.0)
	draw_line(sign_rect.position + Vector2(5, 4), sign_rect.position + Vector2(sign_rect.size.x - 5, 4), Color(0.10, 0.09, 0.08, 0.24), 1.0)


func _draw_grid_awning(rect: Rect2, a: Color, b: Color) -> void:
	for col in range(1, int(rect.size.x / TILE_SIZE) - 1):
		var awning_rect := Rect2(rect.position + Vector2(col * TILE_SIZE, TILE_SIZE + 2), Vector2(TILE_SIZE, 9))
		_draw_cartoon_rect(awning_rect, a if col % 2 == 0 else b, Color(0.12, 0.10, 0.09, 0.32), 2.0)


func _draw_grid_scooters(rect: Rect2) -> void:
	for i in range(3):
		var pos := rect.position + Vector2(8 + i * 28, rect.size.y + 2)
		_draw_cartoon_rect(Rect2(pos, Vector2(18, 6)), Color("#f1c232"), Color(0.12, 0.10, 0.09, 0.38), 3.0)
		draw_circle(pos + Vector2(5, 7), 2.6, Color("#26313d"))
		draw_circle(pos + Vector2(15, 7), 2.6, Color("#26313d"))


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
			var x: float = float((i * 37) % (MAP_SIZE.x * TILE_SIZE))
			var y: float = float((i * 53) % (MAP_SIZE.y * TILE_SIZE))
			draw_line(Vector2(x, y), Vector2(x - 5, y + 10), Color(0.75, 0.88, 0.95, 0.28), 1.0)

	if current_segment in ["evening", "late_night"]:
		draw_circle(Vector2(653, 202), 72, Color(1.0, 0.78, 0.36, 0.08))
		draw_circle(Vector2(368, 438), 58, Color(1.0, 0.55, 0.28, 0.07))
		draw_circle(Vector2(720, 448), 68, Color(0.45, 0.7, 1.0, 0.08))
		draw_circle(Vector2(896, 512), 54, Color(1.0, 0.82, 0.22, 0.08))
		draw_circle(Vector2(896, 192), 62, Color(1.0, 0.50, 0.68, 0.07))
		draw_circle(Vector2(560, 228), 90, Color(1.0, 0.82, 0.38, 0.06))
		draw_circle(Vector2(900, 252), 96, Color(0.50, 0.78, 1.0, 0.07))
		draw_circle(Vector2(1088, 366), 112, Color(0.55, 0.76, 1.0, 0.08))
		draw_circle(Vector2(304, 590), 72, Color(1.0, 0.70, 0.38, 0.06))


func _draw_metro_glow() -> void:
	if current_segment == "morning":
		return
	draw_line(Vector2(2068, 1182), Vector2(2198, 1182), Color(0.45, 0.72, 1.0, 0.35), 2.0)


func _draw_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.position + rect.size * 0.5
	var radius := rect.size * 0.5
	for i in range(24):
		var angle := TAU * float(i) / 24.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
