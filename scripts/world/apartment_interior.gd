extends Node2D
class_name ApartmentInterior

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")

const APARTMENT_TILE_SET := preload("res://assets/tiles/apartment_hd_tileset.tres")
const APARTMENT_PROP_ATLAS_TEXTURE := preload("res://assets/sprites/apartment_hd_props.png")
const IMAGE2_APARTMENT_PROP_PATH := "res://assets/art/image2/godot/apartment_props_v1.png"

const APARTMENT_PROP_REGIONS := {
	"bed": Rect2(0, 0, 128, 128),
	"desk": Rect2(128, 0, 128, 128),
	"fridge": Rect2(256, 0, 128, 128),
	"rent_notice": Rect2(384, 0, 128, 128),
	"laundry_rack": Rect2(0, 128, 128, 128),
	"shoe_rack": Rect2(128, 128, 128, 128),
	"box_stack": Rect2(256, 128, 128, 128),
	"window": Rect2(384, 128, 128, 128),
	"sink": Rect2(0, 256, 128, 128),
	"door": Rect2(128, 256, 128, 128),
	"rug": Rect2(256, 256, 128, 128),
}

@export var auto_fill_tile_map: bool = false

var tile_map: TileMap
var apartment_prop_texture: Texture2D = APARTMENT_PROP_ATLAS_TEXTURE
var current_segment: String = "morning"
var current_weather: String = "overcast"
var housing_variant: String = "urban_village"
var housing_display_name: String = "城中村合租"


func _ready() -> void:
	z_index = 0
	_load_image2_overrides()
	_setup_tile_map()
	_create_boundaries()
	_create_furniture_collisions()
	_create_interactables()
	queue_redraw()


func get_player_spawn() -> Vector2:
	return Vector2(318, 250)


func get_exit_spawn() -> Vector2:
	return Vector2(318, 302)


func get_world_rect() -> Rect2:
	return Rect2(Vector2(176, 96), Vector2(288, 224))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	if auto_fill_tile_map:
		_refresh_tile_map()
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	if auto_fill_tile_map:
		_refresh_tile_map()
	queue_redraw()


func set_housing_variant(variant_id: String, display_name: String) -> void:
	housing_variant = variant_id
	housing_display_name = display_name
	if auto_fill_tile_map:
		_refresh_tile_map()
	queue_redraw()


func _draw() -> void:
	var room: Rect2 = get_world_rect()
	_draw_room_shell(room)
	_draw_apartment_prop("window", room.position + Vector2(32, 24), Vector2(72, 56))
	_draw_apartment_prop("window", room.position + Vector2(184, 24), Vector2(72, 56))
	_draw_apartment_prop("bed", room.position + Vector2(24, 74), Vector2(104, 92))
	_draw_apartment_prop("desk", room.position + Vector2(154, 56), Vector2(104, 88))
	_draw_apartment_prop("fridge", room.position + Vector2(218, 128), Vector2(64, 96))
	_draw_apartment_prop("rent_notice", room.position + Vector2(124, 70), Vector2(56, 64))
	_draw_apartment_prop("laundry_rack", room.position + Vector2(24, 156), Vector2(104, 72))
	_draw_apartment_prop("shoe_rack", room.position + Vector2(168, 164), Vector2(72, 58))
	_draw_apartment_prop("box_stack", room.position + Vector2(104, 160), Vector2(72, 68))
	_draw_apartment_prop("rug", room.position + Vector2(118, 146), Vector2(84, 56))
	_draw_apartment_prop("door", room.position + Vector2(118, 184), Vector2(72, 72))
	_draw_housing_variant_details(room)
	_draw_room_light(room)


func _setup_tile_map() -> void:
	tile_map = get_node_or_null("ApartmentTileMap") as TileMap
	if tile_map == null:
		tile_map = TileMap.new()
		tile_map.name = "ApartmentTileMap"
		tile_map.position = get_world_rect().position + Vector2(16, 16)
		tile_map.z_index = -10
		add_child(tile_map)
	if tile_map.tile_set == null:
		tile_map.tile_set = APARTMENT_TILE_SET
	if auto_fill_tile_map:
		_refresh_tile_map()


func _load_image2_overrides() -> void:
	if ResourceLoader.exists(IMAGE2_APARTMENT_PROP_PATH):
		var loaded_texture: Resource = load(IMAGE2_APARTMENT_PROP_PATH)
		if loaded_texture is Texture2D:
			apartment_prop_texture = loaded_texture as Texture2D


func _refresh_tile_map() -> void:
	if tile_map == null:
		return
	tile_map.clear()
	var wall_tile: Vector2i = _wall_tile_for_variant()
	var floor_tile: Vector2i = _floor_tile_for_variant(false)
	var worn_floor_tile: Vector2i = _floor_tile_for_variant(true)
	for x in range(4):
		tile_map.set_cell(0, Vector2i(x, 0), 0, wall_tile)
	for y in range(1, 3):
		for x in range(4):
			var atlas_coords: Vector2i = floor_tile
			if (x + y) % 3 == 0:
				atlas_coords = worn_floor_tile
			if current_weather == "rain" and x == 3 and y == 2:
				atlas_coords = Vector2i(5, 0)
			tile_map.set_cell(0, Vector2i(x, y), 0, atlas_coords)


func _wall_tile_for_variant() -> Vector2i:
	match housing_variant:
		"far_suburb":
			return Vector2i(3, 1)
		"talent_apartment":
			return Vector2i(4, 1)
		_:
			return Vector2i(0, 1)


func _floor_tile_for_variant(worn: bool) -> Vector2i:
	match housing_variant:
		"far_suburb":
			return Vector2i(5, 0) if worn else Vector2i(3, 0)
		"talent_apartment":
			return Vector2i(5, 0) if worn else Vector2i(4, 0)
		_:
			return Vector2i(1, 0) if worn else Vector2i(0, 0)


func _draw_room_shell(room: Rect2) -> void:
	var shell_color: Color = Color("#746858")
	if housing_variant == "far_suburb":
		shell_color = Color("#5f6668")
	elif housing_variant == "talent_apartment":
		shell_color = Color("#6f7d82")
	draw_rect(Rect2(room.position + Vector2(4, 4), room.size), Color(0.04, 0.03, 0.03, 0.30))
	draw_rect(Rect2(room.position, Vector2(room.size.x, 16)), shell_color)
	draw_rect(Rect2(room.position + Vector2(0, room.size.y - 16), Vector2(room.size.x, 16)), shell_color)
	draw_rect(Rect2(room.position, Vector2(16, room.size.y)), shell_color)
	draw_rect(Rect2(room.position + Vector2(room.size.x - 16, 0), Vector2(16, room.size.y)), shell_color)
	draw_rect(room, Color("#3c3028"), false, 2.0)


func _draw_apartment_prop(name: String, top_left: Vector2, size: Vector2) -> void:
	var region: Rect2 = APARTMENT_PROP_REGIONS["box_stack"]
	if APARTMENT_PROP_REGIONS.has(name):
		region = APARTMENT_PROP_REGIONS[name]
	draw_texture_rect_region(apartment_prop_texture, Rect2(top_left, size), region)


func _draw_housing_variant_details(room: Rect2) -> void:
	if housing_variant == "far_suburb":
		draw_rect(Rect2(room.position + Vector2(34, 170), Vector2(42, 28)), Color("#59616a"))
		draw_rect(Rect2(room.position + Vector2(42, 152), Vector2(30, 18)), Color("#343b42"))
		draw_rect(Rect2(room.position + Vector2(202, 166), Vector2(32, 22)), Color("#d7c37d"))
	elif housing_variant == "talent_apartment":
		draw_circle(room.position + Vector2(52, 154), 13, Color("#8fbf8a"))
		draw_rect(Rect2(room.position + Vector2(184, 144), Vector2(58, 16)), Color("#d8fff0"))
		draw_rect(Rect2(room.position + Vector2(198, 144), Vector2(28, 8)), Color("#6d8d83"))
	else:
		draw_line(room.position + Vector2(34, 194), room.position + Vector2(116, 194), Color("#d8c8a0"), 2.0)
		draw_rect(Rect2(room.position + Vector2(36, 178), Vector2(16, 18)), Color("#bdd3e0"))
		draw_rect(Rect2(room.position + Vector2(68, 178), Vector2(16, 18)), Color("#e08772"))


func _draw_room_light(room: Rect2) -> void:
	if current_weather == "rain":
		draw_rect(room, Color(0.10, 0.14, 0.18, 0.12))
	if current_segment == "late_night":
		draw_rect(room, Color(0.13, 0.16, 0.28, 0.22))
	elif current_segment == "evening":
		draw_circle(room.position + Vector2(room.size.x * 0.5, 70), 86, Color(1.0, 0.72, 0.36, 0.07))


func _create_boundaries() -> void:
	var room: Rect2 = get_world_rect()
	_add_collision_rect("apartment_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("apartment_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(122, 12))
	_add_collision_rect("apartment_south_wall_right", room.position + Vector2(166, room.size.y - 12), Vector2(122, 12))
	_add_collision_rect("apartment_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("apartment_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_furniture_collisions() -> void:
	var origin: Vector2 = get_world_rect().position
	_add_collision_rect("bed_collision", origin + Vector2(32, 80), Vector2(64, 48))
	_add_collision_rect("desk_collision", origin + Vector2(176, 48), Vector2(64, 48))
	_add_collision_rect("fridge_collision", origin + Vector2(224, 144), Vector2(32, 48))


func _create_interactables() -> void:
	var origin: Vector2 = get_world_rect().position
	_add_interactable({
		"id": "apartment_bed",
		"name": "床",
		"kind": "sleep",
		"prompt": "按互动键睡觉",
		"position": origin + Vector2(70, 144),
		"size": Vector2(62, 26),
		"fill_color": Color(0.86, 0.56, 0.56, 0.22),
	})
	_add_interactable({
		"id": "apartment_fridge",
		"name": "合租冰箱",
		"kind": "fridge",
		"prompt": "按互动键翻冰箱",
		"position": origin + Vector2(236, 204),
		"size": Vector2(36, 28),
		"fill_color": Color(0.7, 0.9, 0.8, 0.18),
		"border_color": Color("#b8d8c4"),
	})
	_add_interactable({
		"id": "rent_notice",
		"name": "房租单",
		"kind": "rent",
		"prompt": "按互动键交房租",
		"position": origin + Vector2(154, 112),
		"size": Vector2(44, 26),
		"fill_color": Color(0.95, 0.75, 0.42, 0.18),
		"border_color": Color("#e3bc70"),
	})
	_add_interactable({
		"id": "apartment_door",
		"name": "出租屋门",
		"kind": "exit_apartment",
		"prompt": "按互动键出门",
		"position": origin + Vector2(146, 208),
		"size": Vector2(52, 30),
		"fill_color": Color(0.9, 0.74, 0.45, 0.18),
	})


func _add_interactable(data: Dictionary) -> void:
	var interactable := WorldInteractableScript.new() as WorldInteractable
	interactable.configure(data)
	add_child(interactable)


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
