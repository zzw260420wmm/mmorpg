@tool
extends Node2D
class_name QikaiDistrictMap

const TILE_SIZE := 64
const MAP_COLUMNS := 34
const MAP_ROWS := 24
const FACTORY_GATE_TILE := Vector2i(17, 2)
const CITY_EXIT_TILE := Vector2i(5, 20)
const SPAWN_TILE := Vector2i(6, 19)

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
const T_CROSS_H := Vector2i(0, 2)
const T_OFFICE_ROOF := Vector2i(4, 3)
const T_OFFICE_WALL := Vector2i(5, 3)
const T_GLASS_TOWER := Vector2i(6, 3)
const T_STOREFRONT := Vector2i(1, 4)
const T_STREET_LAMP := Vector2i(6, 4)
const T_SCOOTER := Vector2i(7, 4)
const T_DELIVERY_FRONT := Vector2i(2, 5)
const T_BUILDING_SHADOW := Vector2i(4, 5)
const T_WINDOW_WALL := Vector2i(5, 5)
const T_ROOF_AC := Vector2i(6, 5)

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


func get_city_exit_spawn() -> Vector2:
	return _tile_center(CITY_EXIT_TILE)


func get_factory_gate_position() -> Vector2:
	return _tile_center(FACTORY_GATE_TILE)


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
	points.append({"position": get_factory_gate_position(), "kind": "factory", "label": "一汽", "color": Color("#c7d0d8"), "radius": 4.4})
	points.append({"position": _tile_center(CITY_EXIT_TILE), "kind": "exit", "label": "长春", "color": Color("#e8c879"), "radius": 4.0})
	points.append({"position": _tile_center(Vector2i(22, 10)), "kind": "work", "label": "零部件", "color": Color("#a9d7ff"), "radius": 3.8})
	points.append({"position": _tile_center(Vector2i(10, 10)), "kind": "district", "label": "生活区", "color": Color("#c4d8a8"), "radius": 3.8})
	return points


func _draw() -> void:
	_draw_district_signage()
	if current_weather == "rain":
		_draw_wet_road_marks()


func _create_tile_map() -> void:
	tile_map = get_node_or_null("QikaiTileMap") as TileMap
	if tile_map == null:
		tile_map = TileMap.new()
		tile_map.name = "QikaiTileMap"
		add_child(tile_map)
	tile_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if tile_map.tile_set == null:
		tile_map.tile_set = TilesetResource
	if not tile_map.get_used_cells(0).is_empty():
		return
	_fill_background()
	_paint_roads()
	_paint_factory_gate()
	_paint_industrial_blocks()
	_paint_living_blocks()
	_paint_details()


func _fill_background() -> void:
	for y in range(MAP_ROWS):
		for x in range(MAP_COLUMNS):
			var tile: Vector2i = T_GRASS
			if (x * 3 + y * 7) % 8 == 0:
				tile = T_GRASS_DETAIL
			_set_tile(x, y, tile)


func _paint_roads() -> void:
	for y in range(MAP_ROWS):
		_set_tile(17, y, T_ROAD_V)
		_set_tile(16, y, T_SIDEWALK_V)
		_set_tile(18, y, T_SIDEWALK_V)
	for x in range(MAP_COLUMNS):
		_set_tile(x, 18, T_ROAD_H)
		_set_tile(x, 17, T_SIDEWALK_H)
		_set_tile(x, 19, T_SIDEWALK_H)
	for x in range(5, 18):
		_set_tile(x, 20, T_ROAD_H)
	_set_tile(17, 18, T_INTERSECTION)
	_set_tile(17, 17, T_CROSS_H)


func _paint_factory_gate() -> void:
	var origin := FACTORY_GATE_TILE + Vector2i(-4, -1)
	_paint_rect(origin, Vector2i(9, 1), T_OFFICE_ROOF)
	_paint_rect(origin + Vector2i(0, 1), Vector2i(9, 2), T_OFFICE_WALL)
	_set_tile(FACTORY_GATE_TILE.x, FACTORY_GATE_TILE.y + 2, T_STOREFRONT)
	_set_tile(FACTORY_GATE_TILE.x - 4, FACTORY_GATE_TILE.y + 3, T_STREET_LAMP)
	_set_tile(FACTORY_GATE_TILE.x + 4, FACTORY_GATE_TILE.y + 3, T_STREET_LAMP)


func _paint_industrial_blocks() -> void:
	_paint_rect(Vector2i(20, 7), Vector2i(8, 1), T_OFFICE_ROOF)
	_paint_rect(Vector2i(20, 8), Vector2i(8, 4), T_OFFICE_WALL)
	_paint_rect(Vector2i(21, 9), Vector2i(6, 2), T_WINDOW_WALL)
	_set_tile(24, 12, T_DELIVERY_FRONT)
	_set_tile(27, 7, T_ROOF_AC)
	_paint_rect(Vector2i(23, 14), Vector2i(6, 2), T_ASPHALT)
	for x in range(23, 29, 2):
		_set_tile(x, 15, T_SCOOTER)


func _paint_living_blocks() -> void:
	_paint_rect(Vector2i(7, 8), Vector2i(7, 1), T_OFFICE_ROOF)
	_paint_rect(Vector2i(7, 9), Vector2i(7, 4), T_GLASS_TOWER)
	_set_tile(10, 13, T_STOREFRONT)
	_paint_rect(Vector2i(5, 15), Vector2i(8, 2), T_PAVEMENT)
	for x in range(5, 13, 2):
		_set_tile(x, 16, T_STREET_LAMP)


func _paint_details() -> void:
	_set_tile(CITY_EXIT_TILE.x, CITY_EXIT_TILE.y, T_STOREFRONT)
	for x in range(2, MAP_COLUMNS, 5):
		_set_tile(x, 4, T_STREET_LAMP)
	for x in range(20, 31, 4):
		_set_tile(x, 18, T_BUILDING_SHADOW)


func _create_boundaries() -> void:
	var boundaries := StaticBody2D.new()
	boundaries.name = "QikaiBoundaries"
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
		"id": "qikai_to_factory",
		"name": "第一汽车制造厂入口",
		"kind": "enter_faw_factory",
		"prompt": "按 E 进入一汽",
		"position": get_factory_gate_position(),
		"size": Vector2(136, 44),
		"fill_color": Color(0.68, 0.72, 0.78, 0.24),
		"border_color": Color("#c7d0d8"),
	})
	_add_interactable({
		"id": "qikai_to_changchun",
		"name": "返回长春市区",
		"kind": "exit_qikai_district",
		"prompt": "按 E 返回长春",
		"position": _tile_center(CITY_EXIT_TILE),
		"size": Vector2(120, 42),
		"fill_color": Color(0.86, 0.64, 0.38, 0.20),
		"border_color": Color("#e8c879"),
	})
	_add_interactable({
		"id": "qikai_parts_cluster",
		"name": "汽车零部件园",
		"kind": "dialogue",
		"prompt": "按 E 查看园区",
		"position": _tile_center(Vector2i(22, 10)),
		"size": Vector2(128, 42),
		"lines": {"default": ["厂房之间停着物流车，零部件、班车和通勤人流把这里连接成一整套节奏。"]},
		"fill_color": Color(0.48, 0.68, 0.88, 0.18),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "qikai_living_area",
		"name": "汽开生活区",
		"kind": "dialogue",
		"prompt": "按 E 查看生活区",
		"position": _tile_center(Vector2i(10, 10)),
		"size": Vector2(120, 42),
		"lines": {"default": ["小区、便利店和班车站挤在一起，工业区的日常生活也有自己的烟火气。"]},
		"fill_color": Color(0.56, 0.72, 0.52, 0.18),
		"border_color": Color("#c4d8a8"),
	})


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


func _draw_district_signage() -> void:
	var accent := Color("#c7d0d8")
	if current_segment == "evening" or current_segment == "late_night":
		accent = Color("#f0c77b")
	draw_line(Vector2(13 * TILE_SIZE, 4 * TILE_SIZE), Vector2(22 * TILE_SIZE, 4 * TILE_SIZE), accent, 3.0)


func _draw_wet_road_marks() -> void:
	for i in range(6):
		var p := Vector2(420 + i * 180, 1120 + (i % 2) * 60)
		draw_rect(Rect2(p, Vector2(64, 12)), Color(0.45, 0.65, 0.78, 0.18))
