@tool
extends TileMap
class_name MainRoadTileMap

@export var map_columns := 99
@export var map_rows := 57
@export var auto_fill_when_empty := true

const T_GRASS := Vector2i(0, 0)
const T_GRASS_DETAIL := Vector2i(1, 0)
const T_PAVEMENT := Vector2i(2, 0)
const T_SIDEWALK_H := Vector2i(3, 0)
const T_SIDEWALK_V := Vector2i(4, 0)
const T_SIDEWALK_CORNER := Vector2i(5, 0)
const T_CURB_H := Vector2i(6, 0)
const T_CURB_V := Vector2i(7, 0)
const T_ASPHALT := Vector2i(0, 1)
const T_ROAD_V := Vector2i(1, 1)
const T_ROAD_H := Vector2i(2, 1)
const T_INTERSECTION := Vector2i(3, 1)
const T_LANE_V := Vector2i(4, 1)
const T_LANE_H := Vector2i(5, 1)
const T_WET_ASPHALT := Vector2i(6, 1)
const T_ROAD_SHADOW := Vector2i(7, 1)
const T_CROSS_H := Vector2i(0, 2)
const T_CROSS_V := Vector2i(1, 2)
const T_ROUND_NW := Vector2i(2, 2)
const T_ROUND_NE := Vector2i(3, 2)
const T_ROUND_SW := Vector2i(4, 2)
const T_ROUND_SE := Vector2i(5, 2)
const T_PUDDLE := Vector2i(6, 2)
const T_MANHOLE := Vector2i(7, 2)
const T_RES_ROOF := Vector2i(0, 3)
const T_RES_WALL := Vector2i(1, 3)
const T_SHOP_ROOF := Vector2i(2, 3)
const T_SHOP_WALL := Vector2i(3, 3)
const T_OFFICE_ROOF := Vector2i(4, 3)
const T_OFFICE_WALL := Vector2i(5, 3)
const T_GLASS_TOWER := Vector2i(6, 3)
const T_MEDIA_WALL := Vector2i(7, 3)
const T_RES_DOOR := Vector2i(0, 4)
const T_STOREFRONT := Vector2i(1, 4)
const T_OFFICE_DOOR := Vector2i(2, 4)
const T_CLINIC_FRONT := Vector2i(3, 4)
const T_METRO_ENTRY := Vector2i(4, 4)
const T_TREE := Vector2i(5, 4)
const T_STREET_LAMP := Vector2i(6, 4)
const T_SCOOTER := Vector2i(7, 4)
const T_MARKET_FRONT := Vector2i(0, 5)
const T_AGENCY_FRONT := Vector2i(1, 5)
const T_DELIVERY_FRONT := Vector2i(2, 5)
const T_TALENT_WALL := Vector2i(3, 5)
const T_BUILDING_SHADOW := Vector2i(4, 5)
const T_WINDOW_WALL := Vector2i(5, 5)
const T_ROOF_AC := Vector2i(6, 5)
const T_RIVER := Vector2i(7, 5)


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	call_deferred("_fill_when_empty")


func _fill_when_empty() -> void:
	if not auto_fill_when_empty:
		return
	if tile_set == null:
		return
	if not get_used_cells(0).is_empty():
		return

	_fill_background()
	_paint_river()
	_paint_district_pavement()
	_paint_sidewalks()
	_paint_transport_grid()
	_paint_access_roads()
	_paint_crossings()
	_paint_buildings()
	_paint_city_details()


func _fill_background() -> void:
	for y in range(map_rows):
		for x in range(map_columns):
			var tile: Vector2i = T_GRASS
			if (x * 7 + y * 11) % 9 == 0:
				tile = T_GRASS_DETAIL
			_set_tile(x, y, tile)


func _paint_river() -> void:
	for y in range(map_rows):
		for x in range(82, 86):
			_set_tile(x, y, T_RIVER)


func _paint_district_pavement() -> void:
	_paint_rect(Vector2i(2, 2), Vector2i(5, 5), T_PAVEMENT)
	_paint_rect(Vector2i(16, 2), Vector2i(7, 5), T_PAVEMENT)
	_paint_rect(Vector2i(40, 2), Vector2i(7, 5), T_PAVEMENT)
	_paint_rect(Vector2i(52, 6), Vector2i(8, 6), T_PAVEMENT)
	_paint_rect(Vector2i(70, 6), Vector2i(7, 6), T_PAVEMENT)
	_paint_rect(Vector2i(10, 13), Vector2i(8, 5), T_PAVEMENT)
	_paint_rect(Vector2i(30, 16), Vector2i(6, 5), T_PAVEMENT)
	_paint_rect(Vector2i(43, 19), Vector2i(8, 5), T_PAVEMENT)
	_paint_rect(Vector2i(58, 19), Vector2i(8, 5), T_PAVEMENT)
	_paint_rect(Vector2i(67, 23), Vector2i(7, 5), T_PAVEMENT)
	_paint_rect(Vector2i(7, 36), Vector2i(7, 5), T_PAVEMENT)
	_paint_rect(Vector2i(19, 34), Vector2i(7, 5), T_PAVEMENT)
	_paint_rect(Vector2i(87, 9), Vector2i(7, 7), T_PAVEMENT)


func _paint_sidewalks() -> void:
	_paint_horizontal_sidewalk(27, 0, map_columns)
	_paint_vertical_sidewalk(48, 0, map_rows)
	_paint_horizontal_sidewalk(15, 8, 67)
	_paint_vertical_sidewalk(66, 6, 46)
	_paint_horizontal_sidewalk(45, 6, 35)
	_paint_vertical_sidewalk(30, 15, 46)


func _paint_transport_grid() -> void:
	_paint_horizontal_road(27, 0, map_columns)
	_paint_vertical_road(48, 0, map_rows)
	_paint_horizontal_road(15, 8, 67)
	_paint_vertical_road(66, 6, 46)
	_paint_horizontal_road(45, 6, 35)
	_paint_vertical_road(30, 15, 46)

	for x in range(82, 86):
		_set_tile(x, 15, T_ROAD_H)
		_set_tile(x, 27, T_ROAD_H)
		_set_tile(x, 45, T_ROAD_H)


func _paint_access_roads() -> void:
	_paint_minor_horizontal_road(7, 3, 24)
	_paint_minor_vertical_road(23, 7, 16)
	_paint_minor_horizontal_road(7, 40, 49)
	_paint_minor_vertical_road(56, 10, 16)
	_paint_minor_horizontal_road(10, 66, 77)
	_paint_minor_horizontal_road(15, 67, 93)
	_paint_minor_horizontal_road(17, 13, 31)
	_paint_minor_horizontal_road(19, 30, 35)
	_paint_minor_horizontal_road(22, 45, 67)
	_paint_minor_vertical_road(70, 25, 28)
	_paint_minor_vertical_road(11, 38, 46)
	_paint_minor_vertical_road(23, 36, 46)


func _paint_horizontal_road(y: int, start_x: int, end_x: int) -> void:
	for x in range(start_x, end_x):
		var tile: Vector2i = T_ROAD_H
		if x % 2 == 0:
			tile = T_LANE_H
		_set_tile(x, y, tile)


func _paint_vertical_road(x: int, start_y: int, end_y: int) -> void:
	for y in range(start_y, end_y):
		var tile: Vector2i = T_ROAD_V
		if y % 2 == 0:
			tile = T_LANE_V
		_set_tile(x, y, tile)


func _paint_minor_horizontal_road(y: int, start_x: int, end_x: int) -> void:
	for x in range(start_x, end_x):
		var tile: Vector2i = T_ASPHALT
		if x == start_x or x == end_x - 1:
			tile = T_ROAD_H
		_set_tile(x, y, tile)


func _paint_minor_vertical_road(x: int, start_y: int, end_y: int) -> void:
	for y in range(start_y, end_y):
		var tile: Vector2i = T_ASPHALT
		if y == start_y or y == end_y - 1:
			tile = T_ROAD_V
		_set_tile(x, y, tile)


func _paint_horizontal_sidewalk(y: int, start_x: int, end_x: int) -> void:
	for x in range(start_x, end_x):
		_set_sidewalk_tile(x, y - 1, T_CURB_H)
		_set_sidewalk_tile(x, y + 1, T_SIDEWALK_H)


func _paint_vertical_sidewalk(x: int, start_y: int, end_y: int) -> void:
	for y in range(start_y, end_y):
		_set_sidewalk_tile(x - 1, y, T_CURB_V)
		_set_sidewalk_tile(x + 1, y, T_SIDEWALK_V)


func _paint_crossings() -> void:
	_set_tile(48, 27, T_INTERSECTION)
	_set_tile(48, 15, T_INTERSECTION)
	_set_tile(66, 15, T_INTERSECTION)
	_set_tile(66, 27, T_INTERSECTION)
	_set_tile(30, 27, T_INTERSECTION)
	_set_tile(30, 45, T_INTERSECTION)
	_set_tile(23, 15, T_INTERSECTION)
	_set_tile(48, 7, T_INTERSECTION)
	_set_tile(56, 15, T_INTERSECTION)
	_set_tile(66, 10, T_INTERSECTION)
	_set_tile(66, 22, T_INTERSECTION)
	_set_tile(70, 27, T_INTERSECTION)
	_set_tile(30, 17, T_INTERSECTION)
	_set_tile(30, 19, T_INTERSECTION)
	_set_tile(11, 45, T_INTERSECTION)
	_set_tile(23, 45, T_INTERSECTION)

	for x in range(45, 52):
		if x != 48:
			_set_tile(x, 27, T_CROSS_H)
	for y in range(24, 31):
		if y != 27:
			_set_tile(48, y, T_CROSS_V)
	_set_tile(48, 27, T_INTERSECTION)


func _paint_buildings() -> void:
	_paint_building_block(Vector2i(4, 4), Vector2i(2, 2), T_RES_ROOF, T_RES_WALL, T_RES_DOOR)
	_paint_building_block(Vector2i(18, 4), Vector2i(2, 2), T_SHOP_ROOF, T_SHOP_WALL, T_STOREFRONT)
	_paint_building_block(Vector2i(12, 15), Vector2i(2, 1), T_SHOP_ROOF, T_SHOP_WALL, T_STOREFRONT)
	_paint_building_block(Vector2i(32, 18), Vector2i(2, 1), T_METRO_ENTRY, T_METRO_ENTRY, T_METRO_ENTRY)
	_paint_building_block(Vector2i(54, 8), Vector2i(2, 2), T_OFFICE_ROOF, T_OFFICE_WALL, T_OFFICE_DOOR)
	_paint_building_block(Vector2i(60, 21), Vector2i(2, 1), T_SHOP_ROOF, T_SHOP_WALL, T_STOREFRONT)
	_paint_building_block(Vector2i(45, 21), Vector2i(2, 1), T_DELIVERY_FRONT, T_DELIVERY_FRONT, T_DELIVERY_FRONT)
	_paint_building_block(Vector2i(42, 4), Vector2i(2, 2), T_MEDIA_WALL, T_MEDIA_WALL, T_STOREFRONT)
	_paint_building_block(Vector2i(9, 38), Vector2i(2, 1), T_MARKET_FRONT, T_MARKET_FRONT, T_MARKET_FRONT)
	_paint_building_block(Vector2i(21, 36), Vector2i(2, 1), T_CLINIC_FRONT, T_CLINIC_FRONT, T_CLINIC_FRONT)
	_paint_building_block(Vector2i(72, 8), Vector2i(2, 2), T_TALENT_WALL, T_WINDOW_WALL, T_OFFICE_DOOR)
	_paint_building_block(Vector2i(69, 25), Vector2i(2, 1), T_AGENCY_FRONT, T_AGENCY_FRONT, T_AGENCY_FRONT)
	_paint_building_block(Vector2i(88, 12), Vector2i(2, 2), T_GLASS_TOWER, T_WINDOW_WALL, T_OFFICE_DOOR)


func _paint_building_block(origin: Vector2i, size: Vector2i, roof_tile: Vector2i, wall_tile: Vector2i, door_tile: Vector2i) -> void:
	for y in range(size.y):
		for x in range(size.x):
			var tile: Vector2i = wall_tile
			if size.y > 1 and y == 0:
				tile = roof_tile
			elif size.y <= 1 and x == 0:
				tile = roof_tile

			var door_x: int = size.x - 1
			if y == size.y - 1 and x == door_x:
				tile = door_tile
			_set_tile(origin.x + x, origin.y + y, tile)


func _paint_city_details() -> void:
	var tree_positions: Array[Vector2i] = [
		Vector2i(8, 6),
		Vector2i(24, 8),
		Vector2i(38, 20),
		Vector2i(57, 14),
		Vector2i(76, 14),
		Vector2i(14, 42),
		Vector2i(26, 39),
		Vector2i(92, 17),
	]
	for pos: Vector2i in tree_positions:
		_set_tile(pos.x, pos.y, T_TREE)

	var lamp_positions: Array[Vector2i] = [
		Vector2i(7, 26),
		Vector2i(18, 26),
		Vector2i(32, 26),
		Vector2i(46, 26),
		Vector2i(52, 28),
		Vector2i(64, 28),
		Vector2i(72, 28),
		Vector2i(11, 44),
		Vector2i(23, 44),
	]
	for pos: Vector2i in lamp_positions:
		_set_tile(pos.x, pos.y, T_STREET_LAMP)

	var puddle_positions: Array[Vector2i] = [
		Vector2i(20, 27),
		Vector2i(35, 15),
		Vector2i(53, 27),
		Vector2i(63, 27),
		Vector2i(25, 45),
	]
	for pos: Vector2i in puddle_positions:
		_set_tile(pos.x, pos.y, T_PUDDLE)

	var manhole_positions: Array[Vector2i] = [
		Vector2i(43, 27),
		Vector2i(58, 15),
		Vector2i(66, 34),
		Vector2i(30, 34),
	]
	for pos: Vector2i in manhole_positions:
		_set_tile(pos.x, pos.y, T_MANHOLE)

	var scooter_positions: Array[Vector2i] = [
		Vector2i(44, 22),
		Vector2i(47, 22),
		Vector2i(59, 22),
		Vector2i(62, 22),
	]
	for pos: Vector2i in scooter_positions:
		_set_tile(pos.x, pos.y, T_SCOOTER)

	_set_tile(55, 8, T_ROOF_AC)
	_set_tile(89, 11, T_GLASS_TOWER)
	_set_tile(90, 12, T_WINDOW_WALL)
	_set_tile(5, 6, T_BUILDING_SHADOW)


func _paint_rect(origin: Vector2i, size: Vector2i, tile: Vector2i) -> void:
	for y in range(origin.y, origin.y + size.y):
		for x in range(origin.x, origin.x + size.x):
			_set_tile(x, y, tile)


func _set_sidewalk_tile(x: int, y: int, tile: Vector2i) -> void:
	if x < 0 or y < 0 or x >= map_columns or y >= map_rows:
		return
	var current_tile := get_cell_atlas_coords(0, Vector2i(x, y))
	if _is_transport_tile(current_tile):
		return
	_set_tile(x, y, tile)


func _is_transport_tile(tile: Vector2i) -> bool:
	return (
		tile == T_ASPHALT
		or tile == T_ROAD_V
		or tile == T_ROAD_H
		or tile == T_INTERSECTION
		or tile == T_LANE_V
		or tile == T_LANE_H
		or tile == T_WET_ASPHALT
		or tile == T_ROAD_SHADOW
		or tile == T_CROSS_H
		or tile == T_CROSS_V
		or tile == T_RIVER
	)


func _set_tile(x: int, y: int, tile: Vector2i) -> void:
	if x < 0 or y < 0 or x >= map_columns or y >= map_rows:
		return
	set_cell(0, Vector2i(x, y), 0, tile, 0)
