@tool
extends Node2D
class_name HistoricalCityMap

@export var map_id := "tang_changan"
@export var display_name := "唐长安"
@export var return_kind := "exit_tang_changan"

const TILE_SIZE := 64
const MAP_COLUMNS := 34
const MAP_ROWS := 24
const EXIT_TILE := Vector2i(17, 21)
const SPAWN_TILE := Vector2i(17, 19)

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")
const TilesetResource := preload("res://assets/tiles/polished_city_tileset_64.tres")

const T_GRASS := Vector2i(0, 0)
const T_GRASS_DETAIL := Vector2i(1, 0)
const T_PAVEMENT := Vector2i(2, 0)
const T_SIDEWALK_H := Vector2i(3, 0)
const T_SIDEWALK_V := Vector2i(4, 0)
const T_ASPHALT := Vector2i(0, 1)
const T_ROAD_V := Vector2i(1, 1)
const T_ROAD_H := Vector2i(2, 1)
const T_INTERSECTION := Vector2i(3, 1)
const T_RES_ROOF := Vector2i(0, 3)
const T_RES_WALL := Vector2i(1, 3)
const T_SHOP_ROOF := Vector2i(2, 3)
const T_SHOP_WALL := Vector2i(3, 3)
const T_OFFICE_ROOF := Vector2i(4, 3)
const T_OFFICE_WALL := Vector2i(5, 3)
const T_GLASS_TOWER := Vector2i(6, 3)
const T_STOREFRONT := Vector2i(1, 4)
const T_STREET_LAMP := Vector2i(6, 4)
const T_TREE := Vector2i(5, 4)
const T_BUILDING_SHADOW := Vector2i(4, 5)
const T_WINDOW_WALL := Vector2i(5, 5)
const T_RIVER := Vector2i(7, 5)

var tile_map: TileMap
var current_segment := "morning"
var current_weather := "overcast"


func _ready() -> void:
	z_index = 0
	_create_tile_map()
	if Engine.is_editor_hint():
		queue_redraw()
		return
	_create_boundaries()
	_create_interactables()
	queue_redraw()


func get_player_spawn() -> Vector2:
	return _tile_center(SPAWN_TILE)


func get_exit_spawn() -> Vector2:
	return _tile_center(EXIT_TILE)


func get_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(MAP_COLUMNS * TILE_SIZE, MAP_ROWS * TILE_SIZE))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func get_minimap_points() -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	points.append({"position": _tile_center(EXIT_TILE), "kind": "exit", "label": "返回", "color": Color("#e8c879"), "radius": 4.0})
	var landmarks: Array[Dictionary] = _get_landmarks()
	for landmark_index in range(landmarks.size()):
		var item: Dictionary = landmarks[landmark_index]
		points.append({"position": item["position"], "kind": "landmark", "label": item["label"], "color": Color("#e8c879"), "radius": 3.8})
	return points


func _draw() -> void:
	var accent := Color("#e8c879")
	if map_id == "republic_shanghai":
		accent = Color("#a9d7ff")
	if current_segment == "evening" or current_segment == "late_night":
		accent = Color("#f0c77b")
	var guide_lines: PackedInt32Array = PackedInt32Array([6, 12, 18])
	for y in guide_lines:
		draw_line(Vector2(4 * TILE_SIZE, y * TILE_SIZE), Vector2(30 * TILE_SIZE, y * TILE_SIZE), accent, 2.0)


func _create_tile_map() -> void:
	tile_map = get_node_or_null("HistoricalTileMap") as TileMap
	if tile_map == null:
		tile_map = TileMap.new()
		tile_map.name = "HistoricalTileMap"
		add_child(tile_map)
	tile_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if tile_map.tile_set == null:
		tile_map.tile_set = TilesetResource
	if not tile_map.get_used_cells(0).is_empty():
		return
	_fill_background()
	if map_id == "republic_shanghai":
		_paint_republic_shanghai()
	else:
		_paint_tang_changan()


func _fill_background() -> void:
	for y in range(MAP_ROWS):
		for x in range(MAP_COLUMNS):
			var tile: Vector2i = T_GRASS
			if (x * 5 + y * 7) % 9 == 0:
				tile = T_GRASS_DETAIL
			_set_tile(x, y, tile)


func _paint_tang_changan() -> void:
	for x in range(3, 31):
		_set_tile(x, 6, T_ROAD_H)
		_set_tile(x, 12, T_ROAD_H)
		_set_tile(x, 18, T_ROAD_H)
	var avenue_columns: PackedInt32Array = PackedInt32Array([8, 17, 26])
	for x in avenue_columns:
		for y in range(3, 22):
			_set_tile(x, y, T_ROAD_V)
	var avenue_rows: PackedInt32Array = PackedInt32Array([6, 12, 18])
	for x in avenue_columns:
		for y in avenue_rows:
			_set_tile(x, y, T_INTERSECTION)
	_paint_rect(Vector2i(14, 3), Vector2i(7, 3), T_RES_ROOF)
	_paint_rect(Vector2i(14, 6), Vector2i(7, 2), T_RES_WALL)
	_paint_rect(Vector2i(4, 9), Vector2i(5, 3), T_SHOP_WALL)
	_paint_rect(Vector2i(25, 9), Vector2i(5, 3), T_SHOP_WALL)
	_paint_rect(Vector2i(13, 14), Vector2i(9, 3), T_PAVEMENT)
	_set_tile(EXIT_TILE.x, EXIT_TILE.y, T_STOREFRONT)


func _paint_republic_shanghai() -> void:
	_paint_rect(Vector2i(26, 0), Vector2i(4, MAP_ROWS), T_RIVER)
	for x in range(3, 26):
		_set_tile(x, 7, T_ROAD_H)
		_set_tile(x, 14, T_ROAD_H)
		_set_tile(x, 20, T_ROAD_H)
	for y in range(2, 22):
		_set_tile(9, y, T_ROAD_V)
		_set_tile(18, y, T_ROAD_V)
	_paint_rect(Vector2i(20, 4), Vector2i(5, 4), T_OFFICE_WALL)
	_paint_rect(Vector2i(20, 3), Vector2i(5, 1), T_OFFICE_ROOF)
	_paint_rect(Vector2i(5, 10), Vector2i(6, 3), T_SHOP_WALL)
	_paint_rect(Vector2i(13, 15), Vector2i(5, 4), T_GLASS_TOWER)
	_set_tile(EXIT_TILE.x, EXIT_TILE.y, T_STOREFRONT)


func _create_boundaries() -> void:
	var boundaries := StaticBody2D.new()
	boundaries.name = "HistoricalBoundaries"
	add_child(boundaries)
	var size := Vector2(MAP_COLUMNS * TILE_SIZE, MAP_ROWS * TILE_SIZE)
	_add_wall(boundaries, Vector2(size.x * 0.5, -16), Vector2(size.x, 32))
	_add_wall(boundaries, Vector2(size.x * 0.5, size.y + 16), Vector2(size.x, 32))
	_add_wall(boundaries, Vector2(-16, size.y * 0.5), Vector2(32, size.y))
	_add_wall(boundaries, Vector2(size.x + 16, size.y * 0.5), Vector2(32, size.y))


func _add_wall(body: StaticBody2D, position: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.position = position
	collision.shape = shape
	body.add_child(collision)


func _create_interactables() -> void:
	_add_interactable({
		"id": "%s_exit" % map_id,
		"name": "返回现代城市",
		"kind": return_kind,
		"prompt": "按 E 返回",
		"position": _tile_center(EXIT_TILE),
		"size": Vector2(120, 42),
		"fill_color": Color(0.86, 0.64, 0.38, 0.20),
		"border_color": Color("#e8c879"),
	})
	var landmarks: Array[Dictionary] = _get_landmarks()
	for landmark_index in range(landmarks.size()):
		var item: Dictionary = landmarks[landmark_index]
		_add_interactable({
			"id": item["id"],
			"name": item["name"],
			"kind": "dialogue",
			"prompt": "按 E 查看",
			"position": item["position"],
			"size": Vector2(116, 40),
			"lines": {"default": item["lines"]},
			"fill_color": Color(0.86, 0.64, 0.38, 0.18),
			"border_color": Color("#e8c879"),
		})
	if map_id == "republic_shanghai":
		_add_interactable({
			"id": "republic_companion_writer",
			"name": "报馆女作者",
			"kind": "historical_companion",
			"prompt": "按 E 结识",
			"position": _tile_center(Vector2i(7, 13)),
			"size": Vector2(100, 36),
			"fill_color": Color(0.78, 0.55, 0.62, 0.22),
			"border_color": Color("#ffc4d6"),
		})
		_add_interactable({
			"id": "republic_companion_singer",
			"name": "爵士歌者",
			"kind": "historical_companion",
			"prompt": "按 E 结识",
			"position": _tile_center(Vector2i(15, 16)),
			"size": Vector2(100, 36),
			"fill_color": Color(0.78, 0.55, 0.62, 0.22),
			"border_color": Color("#ffc4d6"),
		})
	else:
		_add_interactable({
			"id": "artifact_tang_sancai",
			"name": "唐三彩碎片",
			"kind": "historical_collectible",
			"prompt": "按 E 采集文物",
			"position": _tile_center(Vector2i(6, 12)),
			"size": Vector2(96, 34),
			"fill_color": Color(0.72, 0.58, 0.38, 0.22),
			"border_color": Color("#e8c879"),
		})
		_add_interactable({
			"id": "artifact_bronze_mirror",
			"name": "铜镜残片",
			"kind": "historical_collectible",
			"prompt": "按 E 采集文物",
			"position": _tile_center(Vector2i(18, 15)),
			"size": Vector2(96, 34),
			"fill_color": Color(0.72, 0.58, 0.38, 0.22),
			"border_color": Color("#e8c879"),
		})
		_add_interactable({
			"id": "artifact_changan_tile",
			"name": "长安瓦当",
			"kind": "historical_collectible",
			"prompt": "按 E 采集文物",
			"position": _tile_center(Vector2i(25, 10)),
			"size": Vector2(96, 34),
			"fill_color": Color(0.72, 0.58, 0.38, 0.22),
			"border_color": Color("#e8c879"),
		})
		_add_interactable({
			"id": "artifact_market_token",
			"name": "西市铜筹",
			"kind": "historical_collectible",
			"prompt": "按 E 采集文物",
			"position": _tile_center(Vector2i(9, 18)),
			"size": Vector2(96, 34),
			"fill_color": Color(0.72, 0.58, 0.38, 0.22),
			"border_color": Color("#e8c879"),
		})
		_add_interactable({
			"id": "tang_companion_scholar",
			"name": "女史学者",
			"kind": "historical_companion",
			"prompt": "按 E 结识",
			"position": _tile_center(Vector2i(17, 5)),
			"size": Vector2(96, 34),
			"fill_color": Color(0.78, 0.55, 0.62, 0.22),
			"border_color": Color("#ffc4d6"),
		})


func _get_landmarks() -> Array[Dictionary]:
	var landmarks: Array[Dictionary] = []
	if map_id == "republic_shanghai":
		landmarks.append({"id": "republic_bund", "name": "民国外滩", "label": "外滩", "position": _tile_center(Vector2i(22, 6)), "lines": ["江风吹过旧式楼群，报馆、电车和码头声音混在一起。"]})
		landmarks.append({"id": "republic_lane", "name": "石库门里弄", "label": "里弄", "position": _tile_center(Vector2i(8, 12)), "lines": ["窄巷里晾着衣服，楼上有人把收音机声音调低。"]})
	else:
		landmarks.append({"id": "tang_daming_palace", "name": "大明宫方向", "label": "大明", "position": _tile_center(Vector2i(17, 5)), "lines": ["坊市格局笔直铺开，宫城方向显得格外开阔。"]})
		landmarks.append({"id": "tang_west_market", "name": "西市", "label": "西市", "position": _tile_center(Vector2i(6, 11)), "lines": ["驼铃、酒肆和胡商的招呼声让街道变得热闹。"]})
	return landmarks


func _add_interactable(data: Dictionary) -> void:
	var interactable: WorldInteractable = WorldInteractableScript.new()
	interactable.configure(data)
	add_child(interactable)


func _set_tile(x: int, y: int, tile: Vector2i) -> void:
	if x < 0 or y < 0 or x >= MAP_COLUMNS or y >= MAP_ROWS:
		return
	tile_map.set_cell(0, Vector2i(x, y), 0, tile)


func _paint_rect(origin: Vector2i, size: Vector2i, tile: Vector2i) -> void:
	for y in range(origin.y, origin.y + size.y):
		for x in range(origin.x, origin.x + size.x):
			_set_tile(x, y, tile)


func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE_SIZE + TILE_SIZE * 0.5, tile.y * TILE_SIZE + TILE_SIZE * 0.5)
