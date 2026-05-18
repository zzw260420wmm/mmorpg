@tool
extends Node2D
class_name RegionalCityMap

@export var city_id := "changchun"
@export var city_name := "长春"
@export var station_name := "长春高铁站"
@export var map_columns := 36
@export var map_rows := 24
@export var station_tile := Vector2i(16, 8)

const TILE_SIZE := 64
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
const T_CROSS_V := Vector2i(1, 2)
const T_RES_ROOF := Vector2i(0, 3)
const T_RES_WALL := Vector2i(1, 3)
const T_SHOP_ROOF := Vector2i(2, 3)
const T_SHOP_WALL := Vector2i(3, 3)
const T_OFFICE_ROOF := Vector2i(4, 3)
const T_OFFICE_WALL := Vector2i(5, 3)
const T_GLASS_TOWER := Vector2i(6, 3)
const T_MEDIA_WALL := Vector2i(7, 3)
const T_STOREFRONT := Vector2i(1, 4)
const T_METRO_ENTRY := Vector2i(4, 4)
const T_TREE := Vector2i(5, 4)
const T_STREET_LAMP := Vector2i(6, 4)
const T_SCOOTER := Vector2i(7, 4)
const T_BUILDING_SHADOW := Vector2i(4, 5)
const T_WINDOW_WALL := Vector2i(5, 5)
const T_ROOF_AC := Vector2i(6, 5)
const T_RIVER := Vector2i(7, 5)
const CHANGCHUN_LON_MIN := 125.17
const CHANGCHUN_LON_MAX := 125.38
const CHANGCHUN_LAT_MIN := 43.80
const CHANGCHUN_LAT_MAX := 43.93
const CHANGCHUN_TILE_MIN := Vector2i(3, 3)
const CHANGCHUN_TILE_MAX := Vector2i(32, 21)
const CHANGCHUN_COORDS := {
	"west_station": Vector2(125.1950185, 43.8741184),
	"qikai": Vector2(125.178, 43.838),
	"eurasia_market": Vector2(125.245, 43.842),
	"animation_institute": Vector2(125.2552806, 43.8177),
	"film_studio": Vector2(125.291, 43.861),
	"zheyoushan": Vector2(125.294, 43.866),
	"zoo": Vector2(125.3283333, 43.8663889),
	"palace": Vector2(125.354, 43.904),
}

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
	return get_station_spawn()


func get_station_position() -> Vector2:
	if city_id == "changchun":
		var station_tile_for_city := _get_changchun_tile("west_station")
		return Vector2(station_tile_for_city.x * TILE_SIZE + TILE_SIZE * 0.5, station_tile_for_city.y * TILE_SIZE + TILE_SIZE * 1.5)
	return Vector2(station_tile.x * TILE_SIZE + TILE_SIZE * 0.5, station_tile.y * TILE_SIZE + TILE_SIZE * 1.5)


func get_station_spawn() -> Vector2:
	return get_station_position() + Vector2(0, 92)


func get_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, Vector2(map_columns * TILE_SIZE, map_rows * TILE_SIZE))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	_draw_life_loop_markers()
	_draw_station_canopy()
	if current_weather == "rain":
		_draw_rain_puddles()


func _draw_life_loop_markers() -> void:
	var station := get_station_position()
	_draw_life_marker(station + Vector2(-260, 210), "住", Color("#e8c879"), Color("#4b3724"))
	_draw_life_marker(station + Vector2(260, 190), "工", Color("#a9d7ff"), Color("#243849"))
	_draw_life_marker(station + Vector2(0, 270), "委", Color("#c4d8a8"), Color("#33452d"))


func _draw_life_marker(center: Vector2, glyph: String, accent: Color, body: Color) -> void:
	var base := Rect2(center - Vector2(30, 26), Vector2(60, 52))
	draw_rect(base.grow(4), Color(0.06, 0.05, 0.04, 0.22))
	draw_rect(base, body)
	draw_rect(base, accent, false, 3.0)
	draw_rect(Rect2(base.position + Vector2(8, 9), Vector2(44, 24)), Color(1.0, 0.92, 0.72, 0.16))
	_draw_marker_glyph(center + Vector2(-9, -12), glyph, accent)


func _draw_marker_glyph(pos: Vector2, glyph: String, color: Color) -> void:
	if glyph == "住":
		draw_rect(Rect2(pos + Vector2(0, 10), Vector2(18, 14)), color)
		draw_polygon(PackedVector2Array([pos + Vector2(-2, 10), pos + Vector2(9, 0), pos + Vector2(20, 10)]), PackedColorArray([color]))
	elif glyph == "工":
		draw_rect(Rect2(pos + Vector2(0, 1), Vector2(18, 4)), color)
		draw_rect(Rect2(pos + Vector2(7, 5), Vector2(4, 17)), color)
		draw_rect(Rect2(pos + Vector2(0, 22), Vector2(18, 4)), color)
	else:
		draw_rect(Rect2(pos + Vector2(1, 0), Vector2(16, 22)), color)
		draw_rect(Rect2(pos + Vector2(5, 5), Vector2(8, 2)), Color("#33452d"))
		draw_rect(Rect2(pos + Vector2(5, 11), Vector2(8, 2)), Color("#33452d"))
		draw_rect(Rect2(pos + Vector2(5, 17), Vector2(6, 2)), Color("#33452d"))


func _create_tile_map() -> void:
	tile_map = get_node_or_null("RegionalTileMap") as TileMap
	if tile_map == null:
		tile_map = TileMap.new()
		tile_map.name = "RegionalTileMap"
		add_child(tile_map)
	tile_map.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	if tile_map.tile_set == null:
		tile_map.tile_set = TilesetResource
	if not tile_map.get_used_cells(0).is_empty():
		return

	_fill_background()
	_paint_roads()
	_paint_station()
	_paint_city_blocks()
	_paint_landmarks()
	_paint_details()


func _fill_background() -> void:
	for y in range(map_rows):
		for x in range(map_columns):
			var tile := T_GRASS
			if (x * 5 + y * 9) % 8 == 0:
				tile = T_GRASS_DETAIL
			_set_tile(x, y, tile)


func _paint_roads() -> void:
	if city_id == "changchun":
		_paint_changchun_roads()
		return
	var main_y := station_tile.y + 5
	var main_x := station_tile.x + 1
	for x in range(map_columns):
		_set_tile(x, main_y, T_ROAD_H)
		_set_tile(x, main_y - 1, T_SIDEWALK_H)
		_set_tile(x, main_y + 1, T_SIDEWALK_H)
	for y in range(map_rows):
		_set_tile(main_x, y, T_ROAD_V)
		_set_tile(main_x - 1, y, T_SIDEWALK_V)
		_set_tile(main_x + 1, y, T_SIDEWALK_V)
	_set_tile(main_x, main_y, T_INTERSECTION)
	_set_tile(main_x - 1, main_y, T_CROSS_H)
	_set_tile(main_x + 1, main_y, T_CROSS_H)
	_set_tile(main_x, main_y - 1, T_CROSS_V)
	_set_tile(main_x, main_y + 1, T_CROSS_V)


func _paint_changchun_roads() -> void:
	var west_station_tile := _get_changchun_tile("west_station")
	var qikai_tile := _get_changchun_tile("qikai")
	var eurasia_tile := _get_changchun_tile("eurasia_market")
	var animation_tile := _get_changchun_tile("animation_institute")
	var studio_tile := _get_changchun_tile("film_studio")
	var zoo_tile := _get_changchun_tile("zoo")
	var palace_tile := _get_changchun_tile("palace")
	var main_y := west_station_tile.y + 3
	var city_axis_x := 18
	_paint_road_h(qikai_tile.x, palace_tile.x, main_y)
	_paint_road_v(city_axis_x, palace_tile.y, animation_tile.y)
	_paint_road_h(city_axis_x, palace_tile.x, palace_tile.y + 1)
	_paint_road_h(city_axis_x, zoo_tile.x, zoo_tile.y + 1)
	_paint_road_h(qikai_tile.x, eurasia_tile.x, eurasia_tile.y + 1)
	_paint_road_h(city_axis_x, animation_tile.x, animation_tile.y - 1)
	_paint_road_h(west_station_tile.x, city_axis_x, west_station_tile.y + 1)
	_paint_road_h(studio_tile.x - 2, city_axis_x, studio_tile.y + 2)
	_set_tile(city_axis_x, main_y, T_INTERSECTION)
	_set_tile(city_axis_x, palace_tile.y + 1, T_INTERSECTION)
	_set_tile(city_axis_x, zoo_tile.y + 1, T_INTERSECTION)
	_set_tile(city_axis_x, animation_tile.y - 1, T_INTERSECTION)


func _paint_road_h(from_x: int, to_x: int, y: int) -> void:
	var start_x: int = mini(from_x, to_x)
	var end_x: int = maxi(from_x, to_x)
	for x in range(start_x, end_x + 1):
		_set_tile(x, y, T_ROAD_H)
		_set_tile(x, y - 1, T_SIDEWALK_H)
		_set_tile(x, y + 1, T_SIDEWALK_H)


func _paint_road_v(x: int, from_y: int, to_y: int) -> void:
	var start_y: int = mini(from_y, to_y)
	var end_y: int = maxi(from_y, to_y)
	for y in range(start_y, end_y + 1):
		_set_tile(x, y, T_ROAD_V)
		_set_tile(x - 1, y, T_SIDEWALK_V)
		_set_tile(x + 1, y, T_SIDEWALK_V)


func _paint_station() -> void:
	if city_id == "changchun":
		_paint_changchun_station_and_qikai_portal()
		return
	_paint_station_cluster(station_tile + Vector2i(-3, -3))
	_set_tile(station_tile.x, station_tile.y + 1, T_METRO_ENTRY)
	_set_tile(station_tile.x - 1, station_tile.y + 2, T_STREET_LAMP)
	_set_tile(station_tile.x + 1, station_tile.y + 2, T_STREET_LAMP)
	if city_id == "xian":
		_paint_tang_changan_portal()


func _paint_changchun_station_and_qikai_portal() -> void:
	var station_origin := _get_changchun_tile("west_station") + Vector2i(-3, -2)
	_paint_station_cluster(station_origin + Vector2i(0, -1))
	_set_tile(station_origin.x + 3, station_origin.y + 3, T_METRO_ENTRY)
	_set_tile(station_origin.x + 1, station_origin.y + 4, T_STREET_LAMP)
	_set_tile(station_origin.x + 5, station_origin.y + 4, T_STREET_LAMP)
	_paint_qikai_district_portal()


func _paint_station_cluster(origin: Vector2i) -> void:
	_paint_rect(origin + Vector2i(0, 3), Vector2i(7, 2), T_PAVEMENT)
	_paint_building_unit(origin, Vector2i(2, 2), T_OFFICE_ROOF, T_GLASS_TOWER)
	_paint_building_unit(origin + Vector2i(3, 0), Vector2i(2, 2), T_OFFICE_ROOF, T_GLASS_TOWER)
	_paint_building_unit(origin + Vector2i(6, 0), Vector2i(1, 2), T_OFFICE_ROOF, T_WINDOW_WALL)


func _paint_city_blocks() -> void:
	var blocks: Array[Dictionary] = [
		{"origin": Vector2i(4, 4), "size": Vector2i(2, 2), "roof": T_RES_ROOF, "wall": T_RES_WALL},
		{"origin": Vector2i(7, 4), "size": Vector2i(1, 2), "roof": T_RES_ROOF, "wall": T_RES_WALL},
		{"origin": Vector2i(6, 15), "size": Vector2i(2, 1), "roof": T_SHOP_ROOF, "wall": T_STOREFRONT},
		{"origin": Vector2i(9, 15), "size": Vector2i(2, 2), "roof": T_SHOP_ROOF, "wall": T_SHOP_WALL},
		{"origin": Vector2i(24, 5), "size": Vector2i(2, 2), "roof": T_OFFICE_ROOF, "wall": T_OFFICE_WALL},
		{"origin": Vector2i(27, 5), "size": Vector2i(2, 2), "roof": T_OFFICE_ROOF, "wall": T_GLASS_TOWER},
		{"origin": Vector2i(25, 16), "size": Vector2i(2, 2), "roof": T_OFFICE_ROOF, "wall": T_GLASS_TOWER},
		{"origin": Vector2i(28, 16), "size": Vector2i(1, 2), "roof": T_OFFICE_ROOF, "wall": T_OFFICE_WALL},
	]
	if city_id == "hangzhou":
		_paint_rect(Vector2i(0, 18), Vector2i(map_columns, 3), T_RIVER)
	if city_id == "chengdu":
		blocks.append({"origin": Vector2i(3, 10), "size": Vector2i(2, 1), "roof": T_RES_ROOF, "wall": T_STOREFRONT})
		blocks.append({"origin": Vector2i(6, 10), "size": Vector2i(1, 2), "roof": T_RES_ROOF, "wall": T_STOREFRONT})
	if city_id == "xian":
		_paint_rect(Vector2i(1, 2), Vector2i(map_columns - 2, 1), T_BUILDING_SHADOW)
	if city_id == "changchun":
		blocks.append({"origin": Vector2i(27, 11), "size": Vector2i(2, 2), "roof": T_RES_ROOF, "wall": T_WINDOW_WALL})
		blocks.append({"origin": Vector2i(30, 11), "size": Vector2i(1, 2), "roof": T_RES_ROOF, "wall": T_WINDOW_WALL})
	for block_index in range(blocks.size()):
		var block: Dictionary = blocks[block_index]
		_paint_building(block)


func _paint_landmarks() -> void:
	match city_id:
		"changchun":
			_paint_landmark_palace(_get_changchun_tile("palace") + Vector2i(-2, -2))
			_paint_landmark_studio(_get_changchun_tile("film_studio") + Vector2i(-2, -1))
			_paint_landmark_zheyoushan(_get_changchun_tile("zheyoushan") + Vector2i(-2, -2))
			_paint_landmark_eurasia_market(_get_changchun_tile("eurasia_market") + Vector2i(-3, -2))
			_paint_landmark_zoo(_get_changchun_tile("zoo") + Vector2i(-3, -2))
			_paint_landmark_animation_institute(_get_changchun_tile("animation_institute") + Vector2i(-3, -3))
		"xian":
			_paint_landmark_bell_tower(Vector2i(6, 10))
			_paint_landmark_city_wall(Vector2i(25, 3))
		"chengdu":
			_paint_landmark_panda_tower(Vector2i(5, 5))
			_paint_landmark_alley(Vector2i(25, 11))
		"hangzhou":
			_paint_landmark_leifeng_tower(Vector2i(6, 6))
			_paint_landmark_lakefront(Vector2i(24, 13))


func _paint_landmark_palace(origin: Vector2i) -> void:
	_paint_building_unit(origin, Vector2i(2, 2), T_RES_ROOF, T_WINDOW_WALL)
	_paint_building_unit(origin + Vector2i(3, 0), Vector2i(2, 2), T_RES_ROOF, T_WINDOW_WALL)
	_set_tile(origin.x + 2, origin.y + 2, T_STOREFRONT)
	_set_tile(origin.x - 1, origin.y + 2, T_TREE)
	_set_tile(origin.x + 5, origin.y + 2, T_TREE)


func _paint_landmark_studio(origin: Vector2i) -> void:
	_paint_building_unit(origin, Vector2i(2, 2), T_OFFICE_ROOF, T_GLASS_TOWER)
	_paint_building_unit(origin + Vector2i(3, 0), Vector2i(1, 2), T_OFFICE_ROOF, T_GLASS_TOWER)
	_set_tile(origin.x + 1, origin.y + 2, T_STOREFRONT)
	_set_tile(origin.x + 3, origin.y + 3, T_STREET_LAMP)


func _paint_landmark_zheyoushan(origin: Vector2i) -> void:
	_paint_building_unit(origin, Vector2i(2, 2), T_SHOP_ROOF, T_SHOP_WALL)
	_paint_building_unit(origin + Vector2i(3, 0), Vector2i(2, 2), T_SHOP_ROOF, T_SHOP_WALL)
	_set_tile(origin.x + 2, origin.y + 3, T_TREE)
	_set_tile(origin.x + 1, origin.y + 4, T_STOREFRONT)
	_set_tile(origin.x + 3, origin.y + 4, T_STREET_LAMP)


func _paint_landmark_eurasia_market(origin: Vector2i) -> void:
	_paint_building_unit(origin, Vector2i(2, 2), T_SHOP_ROOF, T_SHOP_WALL)
	_paint_building_unit(origin + Vector2i(3, 0), Vector2i(2, 2), T_SHOP_ROOF, T_SHOP_WALL)
	_paint_building_unit(origin + Vector2i(6, 0), Vector2i(1, 2), T_SHOP_ROOF, T_SHOP_WALL)
	_set_tile(origin.x + 3, origin.y + 2, T_STOREFRONT)
	_set_tile(origin.x + 1, origin.y + 4, T_STREET_LAMP)
	_set_tile(origin.x + 5, origin.y + 4, T_STREET_LAMP)


func _paint_landmark_zoo(origin: Vector2i) -> void:
	_paint_rect(origin, Vector2i(6, 4), T_GRASS_DETAIL)
	_set_tile(origin.x, origin.y, T_TREE)
	_set_tile(origin.x + 5, origin.y, T_TREE)
	_set_tile(origin.x + 1, origin.y + 2, T_TREE)
	_set_tile(origin.x + 4, origin.y + 2, T_TREE)
	_set_tile(origin.x + 3, origin.y + 4, T_STOREFRONT)


func _paint_landmark_animation_institute(origin: Vector2i) -> void:
	_paint_building_unit(origin, Vector2i(2, 2), T_OFFICE_ROOF, T_MEDIA_WALL)
	_paint_building_unit(origin + Vector2i(3, 0), Vector2i(2, 2), T_OFFICE_ROOF, T_MEDIA_WALL)
	_set_tile(origin.x + 2, origin.y + 2, T_STOREFRONT)
	_set_tile(origin.x + 4, origin.y + 4, T_STREET_LAMP)
	_set_tile(origin.x + 5, origin.y, T_ROOF_AC)


func _paint_landmark_bell_tower(origin: Vector2i) -> void:
	_set_tile(origin.x + 1, origin.y, T_RES_ROOF)
	_paint_building_unit(origin + Vector2i(0, 1), Vector2i(2, 2), T_OFFICE_ROOF, T_WINDOW_WALL)
	_set_tile(origin.x + 1, origin.y + 4, T_STOREFRONT)
	_set_tile(origin.x, origin.y + 5, T_PAVEMENT)
	_set_tile(origin.x + 1, origin.y + 5, T_PAVEMENT)
	_set_tile(origin.x + 2, origin.y + 5, T_PAVEMENT)


func _paint_landmark_city_wall(origin: Vector2i) -> void:
	_paint_rect(origin, Vector2i(7, 1), T_BUILDING_SHADOW)
	for i in range(4):
		_paint_building_unit(origin + Vector2i(i * 2, 1), Vector2i(2, 1), T_RES_ROOF, T_RES_WALL)
	_set_tile(origin.x, origin.y + 2, T_RES_ROOF)
	_set_tile(origin.x + 6, origin.y + 2, T_RES_ROOF)


func _paint_landmark_panda_tower(origin: Vector2i) -> void:
	_paint_building_unit(origin + Vector2i(1, 0), Vector2i(2, 2), T_OFFICE_ROOF, T_GLASS_TOWER)
	_paint_building_unit(origin + Vector2i(1, 2), Vector2i(2, 2), T_OFFICE_ROOF, T_GLASS_TOWER)
	_set_tile(origin.x, origin.y + 4, T_TREE)
	_set_tile(origin.x + 1, origin.y + 4, T_STOREFRONT)
	_set_tile(origin.x + 2, origin.y + 4, T_TREE)
	_set_tile(origin.x + 3, origin.y + 4, T_STREET_LAMP)


func _paint_landmark_alley(origin: Vector2i) -> void:
	_paint_building_unit(origin, Vector2i(2, 1), T_RES_ROOF, T_STOREFRONT)
	_paint_building_unit(origin + Vector2i(3, 0), Vector2i(2, 1), T_RES_ROOF, T_STOREFRONT)
	_set_tile(origin.x + 1, origin.y + 3, T_TREE)
	_set_tile(origin.x + 4, origin.y + 3, T_TREE)


func _paint_landmark_leifeng_tower(origin: Vector2i) -> void:
	_set_tile(origin.x + 1, origin.y, T_RES_ROOF)
	_paint_building_unit(origin + Vector2i(0, 1), Vector2i(2, 2), T_OFFICE_ROOF, T_RES_WALL)
	_paint_building_unit(origin + Vector2i(1, 3), Vector2i(2, 2), T_OFFICE_ROOF, T_RES_WALL)
	_set_tile(origin.x + 1, origin.y + 5, T_STOREFRONT)
	_set_tile(origin.x - 1, origin.y + 4, T_TREE)
	_set_tile(origin.x + 3, origin.y + 4, T_TREE)


func _paint_landmark_lakefront(origin: Vector2i) -> void:
	_paint_rect(origin, Vector2i(6, 2), T_RIVER)
	_paint_rect(origin + Vector2i(0, 2), Vector2i(6, 1), T_SIDEWALK_H)
	_set_tile(origin.x + 1, origin.y + 3, T_TREE)
	_set_tile(origin.x + 3, origin.y + 3, T_STREET_LAMP)


func _paint_qikai_district_portal() -> void:
	var origin := _get_changchun_tile("qikai") + Vector2i(-2, -2)
	_paint_building_unit(origin + Vector2i(-1, -1), Vector2i(2, 2), T_OFFICE_ROOF, T_OFFICE_WALL)
	_paint_building_unit(origin + Vector2i(2, -1), Vector2i(2, 2), T_OFFICE_ROOF, T_OFFICE_WALL)
	_set_tile(origin.x + 1, origin.y + 2, T_STOREFRONT)
	_set_tile(origin.x - 1, origin.y + 3, T_STREET_LAMP)
	_set_tile(origin.x + 3, origin.y + 3, T_STREET_LAMP)
	_set_tile(origin.x, origin.y + 4, T_SCOOTER)


func _paint_tang_changan_portal() -> void:
	var origin := Vector2i(17, 3)
	_paint_building_unit(origin + Vector2i(-3, -1), Vector2i(2, 2), T_RES_ROOF, T_RES_WALL)
	_paint_building_unit(origin, Vector2i(2, 2), T_RES_ROOF, T_RES_WALL)
	_paint_building_unit(origin + Vector2i(3, -1), Vector2i(1, 2), T_RES_ROOF, T_RES_WALL)
	_set_tile(origin.x, origin.y + 2, T_STOREFRONT)
	_set_tile(origin.x - 3, origin.y + 3, T_STREET_LAMP)
	_set_tile(origin.x + 3, origin.y + 3, T_STREET_LAMP)


func _paint_details() -> void:
	for x in range(3, map_columns, 6):
		_set_tile(x, 2, T_TREE)
	for x in range(5, map_columns, 7):
		_set_tile(x, map_rows - 3, T_TREE)
	_set_tile(station_tile.x + 4, station_tile.y + 3, T_SCOOTER)
	_set_tile(station_tile.x - 4, station_tile.y + 3, T_SCOOTER)
	_set_tile(station_tile.x + 5, station_tile.y + 4, T_STREET_LAMP)
	_set_tile(station_tile.x - 5, station_tile.y + 4, T_STREET_LAMP)


func _paint_building(block: Dictionary) -> void:
	var origin: Vector2i = block["origin"]
	var size: Vector2i = block["size"]
	var roof: Vector2i = block["roof"]
	var wall: Vector2i = block["wall"]
	_paint_building_unit(origin, size, roof, wall)


func _paint_building_unit(origin: Vector2i, size: Vector2i, roof: Vector2i, wall: Vector2i) -> void:
	size = Vector2i(clampi(size.x, 1, 2), clampi(size.y, 1, 2))
	_paint_rect(origin, Vector2i(size.x, 1), roof)
	if size.y > 1:
		_paint_rect(origin + Vector2i(0, 1), Vector2i(size.x, size.y - 1), wall)
	_set_tile(origin.x + int(size.x / 2), origin.y + size.y - 1, T_STOREFRONT)
	_set_tile(origin.x + size.x - 1, origin.y, T_ROOF_AC)


func _paint_rect(origin: Vector2i, size: Vector2i, tile: Vector2i) -> void:
	for y in range(origin.y, origin.y + size.y):
		for x in range(origin.x, origin.x + size.x):
			_set_tile(x, y, tile)


func _set_tile(x: int, y: int, tile: Vector2i) -> void:
	if x < 0 or y < 0 or x >= map_columns or y >= map_rows:
		return
	tile_map.set_cell(0, Vector2i(x, y), 0, tile)


func _create_boundaries() -> void:
	var boundaries := StaticBody2D.new()
	boundaries.name = "MapBoundaries"
	add_child(boundaries)
	var size := Vector2(map_columns * TILE_SIZE, map_rows * TILE_SIZE)
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
	var interactable: WorldInteractable = WorldInteractableScript.new()
	interactable.configure({
		"id": "hsr_%s" % city_id,
		"name": station_name,
		"kind": "high_speed_rail",
		"prompt": "按 E 乘高铁",
		"position": get_station_position(),
		"size": Vector2(120, 42),
		"fill_color": Color(0.48, 0.68, 0.88, 0.24),
		"border_color": Color("#a9d7ff"),
	})
	add_child(interactable)
	_create_life_loop_interactables()
	_create_landmark_interactables()
	_create_city_portal_interactables()


func _create_life_loop_interactables() -> void:
	var station := get_station_position()
	var configs: Array[Dictionary] = [
		{
			"id": "city_home_%s" % city_id,
			"name": "%s local room" % city_name,
			"kind": "city_home",
			"prompt": "Press E to rest",
			"position": station + Vector2(-260, 210),
			"size": Vector2(96, 36),
			"fill_color": Color(0.86, 0.68, 0.38, 0.22),
			"border_color": Color("#e8c879"),
		},
		{
			"id": "city_work_%s" % city_id,
			"name": "%s day work" % city_name,
			"kind": "city_work",
			"prompt": "Press E to work",
			"position": station + Vector2(260, 190),
			"size": Vector2(104, 38),
			"fill_color": Color(0.46, 0.62, 0.86, 0.22),
			"border_color": Color("#a9d7ff"),
		},
		{
			"id": "city_task_%s" % city_id,
			"name": "%s task board" % city_name,
			"kind": "city_task",
			"prompt": "Press E for task",
			"position": station + Vector2(0, 270),
			"size": Vector2(112, 38),
			"fill_color": Color(0.56, 0.72, 0.52, 0.20),
			"border_color": Color("#c4d8a8"),
		},
	]
	for config in configs:
		var local_interactable: WorldInteractable = WorldInteractableScript.new()
		local_interactable.configure(config)
		add_child(local_interactable)


func _create_landmark_interactables() -> void:
	var landmarks: Array[Dictionary] = _get_landmark_configs()
	for landmark_index in range(landmarks.size()):
		var landmark: Dictionary = landmarks[landmark_index]
		var landmark_interactable: WorldInteractable = WorldInteractableScript.new()
		landmark_interactable.configure({
			"id": landmark["id"],
			"name": landmark["name"],
			"kind": "dialogue",
			"prompt": "按 E 查看地标",
			"position": landmark["position"],
			"size": Vector2(104, 38),
			"lines": {"default": landmark["lines"]},
			"fill_color": Color(0.86, 0.64, 0.38, 0.18),
			"border_color": Color("#e8c879"),
		})
		add_child(landmark_interactable)


func _create_city_portal_interactables() -> void:
	if city_id == "changchun":
		var qikai_portal: WorldInteractable = WorldInteractableScript.new()
		qikai_portal.configure({
			"id": "changchun_qikai_district_portal",
			"name": "汽开区方向",
			"kind": "enter_qikai_district",
			"prompt": "按 E 前往汽开区",
			"position": get_qikai_district_portal_position(),
			"size": Vector2(128, 42),
			"fill_color": Color(0.68, 0.72, 0.78, 0.22),
			"border_color": Color("#c7d0d8"),
		})
		add_child(qikai_portal)
	if city_id == "xian":
		var museum: WorldInteractable = WorldInteractableScript.new()
		museum.configure({
			"id": "xian_private_museum",
			"name": "私人博物馆",
			"kind": "private_museum",
			"prompt": "按 E 查看博物馆",
			"position": _tile_center(Vector2i(22, 8)),
			"size": Vector2(118, 40),
			"fill_color": Color(0.72, 0.58, 0.38, 0.20),
			"border_color": Color("#e8c879"),
		})
		add_child(museum)
		var archaeology_board: WorldInteractable = WorldInteractableScript.new()
		archaeology_board.configure({
			"id": "xian_archaeology_board",
			"name": "考古委托栏",
			"kind": "archaeology_task",
			"prompt": "按 E 接考古委托",
			"position": _tile_center(Vector2i(20, 10)),
			"size": Vector2(118, 40),
			"fill_color": Color(0.56, 0.72, 0.52, 0.20),
			"border_color": Color("#c4d8a8"),
		})
		add_child(archaeology_board)
		var tang_portal: WorldInteractable = WorldInteractableScript.new()
		tang_portal.configure({
			"id": "xian_tang_changan_portal",
			"name": "唐长安遗址入口",
			"kind": "enter_tang_changan",
			"prompt": "按 E 前往唐长安",
			"position": _tile_center(Vector2i(17, 5)),
			"size": Vector2(132, 42),
			"fill_color": Color(0.86, 0.64, 0.38, 0.22),
			"border_color": Color("#e8c879"),
		})
		add_child(tang_portal)


func get_qikai_district_portal_position() -> Vector2:
	return _tile_center(_get_changchun_tile("qikai"))


func get_landmark_minimap_points() -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	var landmarks: Array[Dictionary] = _get_landmark_configs()
	for landmark_index in range(landmarks.size()):
		var landmark: Dictionary = landmarks[landmark_index]
		points.append({
			"position": landmark["position"],
			"kind": "landmark",
			"label": landmark["short_label"],
			"color": Color("#e8c879"),
			"radius": 3.8,
		})
	if city_id == "changchun":
		points.append({
			"position": get_qikai_district_portal_position(),
			"kind": "district",
			"label": "汽开",
			"color": Color("#c7d0d8"),
			"radius": 4.2,
		})
	if city_id == "xian":
		points.append({
			"position": _tile_center(Vector2i(17, 5)),
			"kind": "history",
			"label": "唐长安",
			"color": Color("#e8c879"),
			"radius": 4.2,
		})
	return points


func _get_landmark_configs() -> Array[Dictionary]:
	var configs: Array[Dictionary] = []
	match city_id:
		"changchun":
			configs = [
				{"id": "changchun_palace", "name": "伪满皇宫建筑群", "short_label": "皇宫", "position": _tile_center(_get_changchun_tile("palace")), "lines": ["旧建筑的屋檐压得很低，像把一段复杂的城市记忆留在街角。"]},
				{"id": "changchun_studio", "name": "长影旧址", "short_label": "长影", "position": _tile_center(_get_changchun_tile("film_studio")), "lines": ["老电影厂的墙面安静发黄，门口还贴着褪色的海报。"]},
				{"id": "changchun_zheyoushan", "name": "这有山", "short_label": "这山", "position": _tile_center(_get_changchun_tile("zheyoushan")), "lines": ["红旗街商圈里藏着一座室内山丘，店铺和灯光沿着坡道层层往上。"]},
				{"id": "changchun_eurasia_market", "name": "欧亚卖场", "short_label": "欧亚", "position": _tile_center(_get_changchun_tile("eurasia_market")), "lines": ["巨大的商业体贴着开运街展开，停车场、广告牌和人流把西南方向照得很亮。"]},
				{"id": "changchun_zoo", "name": "长春市动植物园", "short_label": "动植", "position": _tile_center(_get_changchun_tile("zoo")), "lines": ["树影和兽舍藏在城市道路之间，喧闹的车流在围栏外慢慢退远。"]},
				{"id": "changchun_animation_institute", "name": "吉林动画学院", "short_label": "动画", "position": _tile_center(_get_changchun_tile("animation_institute")), "lines": ["一位美丽的女士在2020年~2024年就读于这里。"]},
			]
		"xian":
			configs = [
				{"id": "xian_bell_tower", "name": "西安钟楼", "short_label": "钟楼", "position": _tile_center(Vector2i(7, 15)), "lines": ["钟楼立在路口中央，车流绕着它转，像现代城市绕着旧时间转。"]},
				{"id": "xian_city_wall", "name": "西安城墙", "short_label": "城墙", "position": _tile_center(Vector2i(28, 5)), "lines": ["城墙把街道切成古老的边界，墙下的人群依然赶着今天的生活。"]},
			]
		"chengdu":
			configs = [
				{"id": "chengdu_panda_tower", "name": "天府熊猫塔", "short_label": "熊猫塔", "position": _tile_center(Vector2i(6, 9)), "lines": ["塔身从低矮街区后面冒出来，夜里会像一枚温柔的坐标。"]},
				{"id": "chengdu_alley", "name": "宽窄巷子", "short_label": "宽窄", "position": _tile_center(Vector2i(28, 14)), "lines": ["巷子里有茶香、游客和慢下来的脚步，连压力也像被雨棚挡了一点。"]},
			]
		"hangzhou":
			configs = [
				{"id": "hangzhou_leifeng_tower", "name": "雷峰塔", "short_label": "雷峰", "position": _tile_center(Vector2i(7, 11)), "lines": ["塔影靠着湖风，像从明信片里走出来的一段傍晚。"]},
				{"id": "hangzhou_lakefront", "name": "西湖湖滨", "short_label": "西湖", "position": _tile_center(Vector2i(27, 16)), "lines": ["湖边的路很平，风从水面过来，把城市的噪音压低了一些。"]},
			]
	return configs


func _tile_center(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * TILE_SIZE + TILE_SIZE * 0.5, tile.y * TILE_SIZE + TILE_SIZE * 0.5)


func _get_changchun_tile(place_id: String) -> Vector2i:
	var coord: Vector2 = CHANGCHUN_COORDS.get(place_id, CHANGCHUN_COORDS["west_station"])
	var x_ratio := clampf((coord.x - CHANGCHUN_LON_MIN) / (CHANGCHUN_LON_MAX - CHANGCHUN_LON_MIN), 0.0, 1.0)
	var y_ratio := clampf((CHANGCHUN_LAT_MAX - coord.y) / (CHANGCHUN_LAT_MAX - CHANGCHUN_LAT_MIN), 0.0, 1.0)
	var tile_x := int(round(lerpf(float(CHANGCHUN_TILE_MIN.x), float(CHANGCHUN_TILE_MAX.x), x_ratio)))
	var tile_y := int(round(lerpf(float(CHANGCHUN_TILE_MIN.y), float(CHANGCHUN_TILE_MAX.y), y_ratio)))
	return Vector2i(tile_x, tile_y)


func _draw_station_canopy() -> void:
	var p := Vector2(station_tile.x * TILE_SIZE, (station_tile.y - 3) * TILE_SIZE)
	var canopy := Rect2(p + Vector2(-3 * TILE_SIZE, 12), Vector2(7 * TILE_SIZE, 34))
	var accent := Color("#a9d7ff")
	if current_segment == "evening" or current_segment == "late_night":
		accent = Color("#f0c77b")
	draw_rect(canopy, Color(0.18, 0.27, 0.34, 0.78))
	draw_rect(canopy, accent, false, 3.0)
	draw_line(canopy.position + Vector2(18, canopy.size.y + 10), canopy.position + Vector2(canopy.size.x - 18, canopy.size.y + 10), accent, 4.0)


func _draw_rain_puddles() -> void:
	for i in range(6):
		var p := Vector2(180 + i * 260, 920 + (i % 2) * 120)
		draw_rect(Rect2(p, Vector2(54, 14)), Color(0.45, 0.65, 0.78, 0.22))
