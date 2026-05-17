@tool
extends Node2D
class_name FawFactoryMap

const TILE_SIZE := 64
const MAP_COLUMNS := 34
const MAP_ROWS := 22
const EXIT_TILE := Vector2i(3, 18)
const SPAWN_TILE := Vector2i(4, 17)

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")
const TilesetResource := preload("res://assets/tiles/polished_city_tileset_64.tres")

const T_GRASS := Vector2i(0, 0)
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
	points.append({"position": _tile_center(EXIT_TILE), "kind": "exit", "label": "出口", "color": Color("#e8c879"), "radius": 4.0})
	points.append({"position": _tile_center(Vector2i(15, 9)), "kind": "factory", "label": "总装", "color": Color("#c7d0d8"), "radius": 4.2})
	points.append({"position": _tile_center(Vector2i(25, 16)), "kind": "factory", "label": "试车", "color": Color("#a9d7ff"), "radius": 4.0})
	points.append({"position": _tile_center(Vector2i(8, 5)), "kind": "landmark", "label": "厂史", "color": Color("#e8c879"), "radius": 3.8})
	return points


func _draw() -> void:
	_draw_factory_roof_lines()
	if current_weather == "rain":
		_draw_wet_floor_marks()


func _create_tile_map() -> void:
	tile_map = get_node_or_null("FactoryTileMap") as TileMap
	if tile_map == null:
		tile_map = TileMap.new()
		tile_map.name = "FactoryTileMap"
		add_child(tile_map)
	tile_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if tile_map.tile_set == null:
		tile_map.tile_set = TilesetResource
	if not tile_map.get_used_cells(0).is_empty():
		return
	_fill_floor()
	_paint_roads()
	_paint_main_plant()
	_paint_assembly_line()
	_paint_test_track()
	_paint_parking_yard()
	_paint_factory_details()


func _fill_floor() -> void:
	for y in range(MAP_ROWS):
		for x in range(MAP_COLUMNS):
			_set_tile(x, y, T_PAVEMENT)


func _paint_roads() -> void:
	for x in range(MAP_COLUMNS):
		_set_tile(x, 18, T_ROAD_H)
		_set_tile(x, 17, T_SIDEWALK_H)
		_set_tile(x, 19, T_SIDEWALK_H)
	for y in range(2, MAP_ROWS):
		_set_tile(4, y, T_ROAD_V)
		_set_tile(3, y, T_SIDEWALK_V)
		_set_tile(5, y, T_SIDEWALK_V)
	_set_tile(4, 18, T_INTERSECTION)
	_set_tile(4, 17, T_CROSS_H)


func _paint_main_plant() -> void:
	_paint_rect(Vector2i(10, 4), Vector2i(14, 1), T_OFFICE_ROOF)
	_paint_rect(Vector2i(10, 5), Vector2i(14, 7), T_OFFICE_WALL)
	_paint_rect(Vector2i(12, 6), Vector2i(10, 4), T_WINDOW_WALL)
	_set_tile(16, 12, T_STOREFRONT)
	_set_tile(23, 4, T_ROOF_AC)
	_paint_rect(Vector2i(7, 4), Vector2i(3, 4), T_GLASS_TOWER)
	_set_tile(8, 8, T_STOREFRONT)


func _paint_assembly_line() -> void:
	for x in range(12, 22):
		_set_tile(x, 9, T_BUILDING_SHADOW)
		if x % 2 == 0:
			_set_tile(x, 10, T_DELIVERY_FRONT)
		else:
			_set_tile(x, 10, T_SCOOTER)
	_paint_rect(Vector2i(13, 7), Vector2i(8, 1), T_ASPHALT)


func _paint_test_track() -> void:
	for x in range(22, 31):
		_set_tile(x, 15, T_ROAD_H)
		_set_tile(x, 17, T_ROAD_H)
	for y in range(15, 18):
		_set_tile(22, y, T_ROAD_V)
		_set_tile(30, y, T_ROAD_V)
	_set_tile(22, 15, T_INTERSECTION)
	_set_tile(30, 17, T_INTERSECTION)


func _paint_parking_yard() -> void:
	_paint_rect(Vector2i(7, 14), Vector2i(8, 3), T_ASPHALT)
	for x in range(8, 15, 2):
		_set_tile(x, 15, T_SCOOTER)
		_set_tile(x, 16, T_BUILDING_SHADOW)


func _paint_factory_details() -> void:
	_set_tile(EXIT_TILE.x, EXIT_TILE.y, T_STOREFRONT)
	for x in range(2, MAP_COLUMNS, 5):
		_set_tile(x, 2, T_STREET_LAMP)
	for x in range(9, 25, 4):
		_set_tile(x, 13, T_STREET_LAMP)


func _create_boundaries() -> void:
	var boundaries := StaticBody2D.new()
	boundaries.name = "FactoryBoundaries"
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
		"id": "faw_exit",
		"name": "返回汽开区",
		"kind": "exit_faw_factory",
		"prompt": "按 E 返回汽开区",
		"position": _tile_center(EXIT_TILE),
		"size": Vector2(116, 42),
		"fill_color": Color(0.86, 0.64, 0.38, 0.20),
		"border_color": Color("#e8c879"),
	})
	_add_interactable({
		"id": "faw_history_wall",
		"name": "一汽车史墙",
		"kind": "dialogue",
		"prompt": "按 E 查看厂史",
		"position": _tile_center(Vector2i(8, 5)),
		"size": Vector2(108, 36),
		"lines": {"default": ["墙上挂着老照片和生产标语，东北工业城市的时间感在这里变得很具体。"]},
		"fill_color": Color(0.86, 0.64, 0.38, 0.18),
		"border_color": Color("#e8c879"),
	})
	_add_interactable({
		"id": "faw_assembly_line",
		"name": "总装线",
		"kind": "dialogue",
		"prompt": "按 E 观察总装线",
		"position": _tile_center(Vector2i(15, 9)),
		"size": Vector2(128, 42),
		"lines": {"default": ["车身沿着传送线缓慢前进，机器声、脚步声和调度广播混在一起。"]},
		"fill_color": Color(0.68, 0.72, 0.78, 0.20),
		"border_color": Color("#c7d0d8"),
	})
	_add_interactable({
		"id": "faw_test_track",
		"name": "试车道",
		"kind": "dialogue",
		"prompt": "按 E 查看试车道",
		"position": _tile_center(Vector2i(25, 16)),
		"size": Vector2(120, 42),
		"lines": {"default": ["新车在短短一圈里完成检查，轮胎声从厂房背后划过去。"]},
		"fill_color": Color(0.48, 0.68, 0.88, 0.18),
		"border_color": Color("#a9d7ff"),
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


func _draw_factory_roof_lines() -> void:
	var accent := Color("#c7d0d8")
	if current_segment == "evening" or current_segment == "late_night":
		accent = Color("#f0c77b")
	var roof_lines := PackedInt32Array([4, 6, 8, 10])
	for y in roof_lines:
		draw_line(Vector2(10 * TILE_SIZE, y * TILE_SIZE), Vector2(24 * TILE_SIZE, y * TILE_SIZE), accent, 2.0)


func _draw_wet_floor_marks() -> void:
	for i in range(7):
		var p := Vector2(360 + i * 180, 930 + (i % 2) * 80)
		draw_rect(Rect2(p, Vector2(70, 12)), Color(0.45, 0.65, 0.78, 0.18))
