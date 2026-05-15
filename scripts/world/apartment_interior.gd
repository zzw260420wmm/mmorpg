extends Node2D
class_name ApartmentInterior

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")
const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

var current_segment := "morning"
var current_weather := "overcast"
var housing_variant := "urban_village"
var housing_display_name := "城中村合租"


func _ready() -> void:
	z_index = 0
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
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func set_housing_variant(variant_id: String, display_name: String) -> void:
	housing_variant = variant_id
	housing_display_name = display_name
	queue_redraw()


func _draw() -> void:
	var room := get_world_rect()
	var shell_color := Color("#746858")
	var floor_tint := Color(1, 1, 1, 0.88)
	var wall_tint := Color(1, 1, 1, 0.78)
	if housing_variant == "far_suburb":
		shell_color = Color("#5f6668")
		floor_tint = Color(0.78, 0.86, 0.90, 0.82)
		wall_tint = Color(0.72, 0.78, 0.80, 0.72)
	elif housing_variant == "talent_apartment":
		shell_color = Color("#6f7d82")
		floor_tint = Color(0.92, 0.96, 0.90, 0.90)
		wall_tint = Color(0.86, 0.94, 0.92, 0.82)
	draw_rect(Rect2(room.position + Vector2(5, 6), room.size), Color(0.04, 0.03, 0.03, 0.30))
	draw_rect(room, shell_color)
	draw_rect(Rect2(room.position + Vector2(8, 8), room.size - Vector2(16, 16)), Color("#9b8971"))
	draw_rect(Rect2(room.position + Vector2(8, 8), Vector2(room.size.x - 16, 48)), Color("#796955"))
	ArtAssetsScript.draw_tiled_rect(self, "rental_floor", Rect2(room.position + Vector2(8, 64), room.size - Vector2(16, 78)), floor_tint)
	ArtAssetsScript.draw_tiled_rect(self, "warm_wall", Rect2(room.position + Vector2(8, 8), Vector2(room.size.x - 16, 48)), wall_tint)

	for x in range(10):
		draw_line(room.position + Vector2(16 + x * 26, 65), room.position + Vector2(16 + x * 26, room.size.y - 14), Color(0.42, 0.34, 0.25, 0.35), 1.0)
	for y in range(7):
		draw_line(room.position + Vector2(12, 70 + y * 26), room.position + Vector2(room.size.x - 12, 70 + y * 26), Color(0.42, 0.34, 0.25, 0.35), 1.0)

	_draw_bed(room.position + Vector2(34, 80))
	_draw_desk(room.position + Vector2(184, 72))
	_draw_fridge(room.position + Vector2(218, 142))
	_draw_rent_notice(room.position + Vector2(136, 76))
	ArtAssetsScript.draw_prop(self, "bed", room.position + Vector2(48, 92), 1.25)
	ArtAssetsScript.draw_prop(self, "fridge", room.position + Vector2(219, 154), 1.0)
	ArtAssetsScript.draw_prop(self, "rent_notice", room.position + Vector2(136, 74), 1.0)
	ArtAssetsScript.draw_prop(self, "laundry_rack", room.position + Vector2(42, 186), 0.9)
	_draw_housing_variant_details(room)
	_draw_door(room.position + Vector2(126, 204))
	_draw_window(room.position + Vector2(34, 24))
	_draw_window(room.position + Vector2(198, 24))
	_draw_room_light(room)


func _draw_housing_variant_details(room: Rect2) -> void:
	if housing_variant == "far_suburb":
		draw_rect(Rect2(room.position + Vector2(28, 166), Vector2(34, 24)), Color("#59616a"))
		draw_rect(Rect2(room.position + Vector2(32, 160), Vector2(24, 8)), Color("#343b42"))
		draw_rect(Rect2(room.position + Vector2(166, 178), Vector2(46, 10)), Color("#6c5a48"))
		draw_rect(Rect2(room.position + Vector2(170, 170), Vector2(36, 8)), Color("#d7c37d"))
	elif housing_variant == "talent_apartment":
		draw_rect(Rect2(room.position + Vector2(30, 160), Vector2(34, 28)), Color("#4d635f"))
		draw_circle(room.position + Vector2(47, 154), 13, Color("#8fbf8a"))
		draw_rect(Rect2(room.position + Vector2(178, 142), Vector2(56, 12)), Color("#d8fff0"))
		draw_rect(Rect2(room.position + Vector2(184, 146), Vector2(42, 4)), Color("#6d8d83"))
	else:
		draw_line(room.position + Vector2(24, 184), room.position + Vector2(112, 184), Color("#d8c8a0"), 1.0)
		draw_rect(Rect2(room.position + Vector2(32, 180), Vector2(18, 8)), Color("#bdd3e0"))
		draw_rect(Rect2(room.position + Vector2(58, 180), Vector2(20, 8)), Color("#e08772"))


func _draw_bed(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(3, 4), Vector2(70, 50)), Color(0.06, 0.05, 0.04, 0.24))
	draw_rect(Rect2(pos, Vector2(70, 50)), Color("#5c4b45"))
	draw_rect(Rect2(pos + Vector2(6, 7), Vector2(58, 36)), Color("#b45c62"))
	draw_rect(Rect2(pos + Vector2(8, 9), Vector2(22, 14)), Color("#e3d3b8"))


func _draw_desk(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(2, 3), Vector2(60, 32)), Color(0.05, 0.04, 0.03, 0.22))
	draw_rect(Rect2(pos, Vector2(60, 30)), Color("#624a35"))
	draw_rect(Rect2(pos + Vector2(10, -16), Vector2(34, 18)), Color("#26323d"))
	draw_rect(Rect2(pos + Vector2(13, -13), Vector2(28, 12)), Color("#9fc6d0"))
	draw_rect(Rect2(pos + Vector2(42, 6), Vector2(10, 12)), Color("#f1d379"))


func _draw_fridge(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(2, 3), Vector2(34, 54)), Color(0.05, 0.04, 0.03, 0.22))
	draw_rect(Rect2(pos, Vector2(34, 54)), Color("#d7ded5"))
	draw_rect(Rect2(pos, Vector2(34, 19)), Color("#c5d1cb"))
	draw_rect(Rect2(pos + Vector2(26, 23), Vector2(3, 18)), Color("#6f7c78"))


func _draw_rent_notice(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(2, 2), Vector2(34, 22)), Color(0.04, 0.03, 0.02, 0.18))
	draw_rect(Rect2(pos, Vector2(34, 22)), Color("#efe0b2"))
	draw_rect(Rect2(pos + Vector2(5, 5), Vector2(24, 3)), Color("#8a4b42"))
	draw_rect(Rect2(pos + Vector2(5, 12), Vector2(18, 3)), Color("#6c5a48"))


func _draw_door(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(42, 12)), Color("#3c3028"))
	draw_rect(Rect2(pos + Vector2(4, 2), Vector2(34, 8)), Color("#6b4e38"))


func _draw_window(pos: Vector2) -> void:
	var lit := current_segment in ["evening", "late_night"]
	draw_rect(Rect2(pos, Vector2(54, 24)), Color("#2d3b48"))
	draw_rect(Rect2(pos + Vector2(4, 4), Vector2(20, 16)), Color("#f0ca7d") if lit else Color("#9ec2cf"))
	draw_rect(Rect2(pos + Vector2(30, 4), Vector2(20, 16)), Color("#f0ca7d") if lit else Color("#9ec2cf"))
	draw_line(pos + Vector2(27, 3), pos + Vector2(27, 21), Color("#41505d"), 1.0)


func _draw_room_light(room: Rect2) -> void:
	if current_weather == "rain":
		draw_rect(room, Color(0.10, 0.14, 0.18, 0.12))
	if current_segment == "late_night":
		draw_rect(room, Color(0.13, 0.16, 0.28, 0.22))
	elif current_segment == "evening":
		draw_circle(room.position + Vector2(room.size.x * 0.5, 70), 86, Color(1.0, 0.72, 0.36, 0.07))


func _create_boundaries() -> void:
	var room := get_world_rect()
	_add_collision_rect("apartment_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("apartment_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(122, 12))
	_add_collision_rect("apartment_south_wall_right", room.position + Vector2(166, room.size.y - 12), Vector2(122, 12))
	_add_collision_rect("apartment_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("apartment_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_furniture_collisions() -> void:
	var origin := get_world_rect().position
	_add_collision_rect("bed_collision", origin + Vector2(34, 80), Vector2(70, 50))
	_add_collision_rect("desk_collision", origin + Vector2(184, 56), Vector2(60, 46))
	_add_collision_rect("fridge_collision", origin + Vector2(218, 142), Vector2(34, 54))


func _create_interactables() -> void:
	var origin := get_world_rect().position
	_add_interactable({
		"id": "apartment_bed",
		"name": "床",
		"kind": "sleep",
		"prompt": "按 E 睡觉",
		"position": origin + Vector2(70, 144),
		"size": Vector2(62, 26),
		"fill_color": Color(0.86, 0.56, 0.56, 0.22),
	})
	_add_interactable({
		"id": "apartment_fridge",
		"name": "合租冰箱",
		"kind": "fridge",
		"prompt": "按 E 翻冰箱",
		"position": origin + Vector2(236, 204),
		"size": Vector2(36, 28),
		"fill_color": Color(0.7, 0.9, 0.8, 0.18),
		"border_color": Color("#b8d8c4"),
	})
	_add_interactable({
		"id": "rent_notice",
		"name": "房租单",
		"kind": "rent",
		"prompt": "按 E 交房租",
		"position": origin + Vector2(154, 112),
		"size": Vector2(44, 26),
		"fill_color": Color(0.95, 0.75, 0.42, 0.18),
		"border_color": Color("#e3bc70"),
	})
	_add_interactable({
		"id": "apartment_door",
		"name": "出租屋门",
		"kind": "exit_apartment",
		"prompt": "按 E 出门",
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
