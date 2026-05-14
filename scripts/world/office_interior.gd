extends Node2D
class_name OfficeInterior

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")
const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

var current_segment := "morning"
var current_weather := "overcast"


func _ready() -> void:
	z_index = 0
	_create_boundaries()
	_create_furniture_collisions()
	_create_interactables()
	queue_redraw()


func get_player_spawn() -> Vector2:
	return Vector2(700, 420)


func get_world_rect() -> Rect2:
	return Rect2(Vector2(512, 176), Vector2(384, 288))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	var room := get_world_rect()
	draw_rect(Rect2(room.position + Vector2(5, 6), room.size), Color(0.03, 0.04, 0.05, 0.28))
	draw_rect(room, Color("#5d6870"))
	draw_rect(Rect2(room.position + Vector2(10, 10), room.size - Vector2(20, 20)), Color("#7d8588"))
	draw_rect(Rect2(room.position + Vector2(10, 10), Vector2(room.size.x - 20, 52)), Color("#56636c"))
	ArtAssetsScript.draw_tiled_rect(self, "office_tile", Rect2(room.position + Vector2(10, 68), room.size - Vector2(20, 86)), Color(1, 1, 1, 0.85))
	ArtAssetsScript.draw_tiled_rect(self, "metro_tile", Rect2(room.position + Vector2(10, 10), Vector2(room.size.x - 20, 52)), Color(1, 1, 1, 0.62))

	for x in range(9):
		draw_line(room.position + Vector2(22 + x * 38, 70), room.position + Vector2(22 + x * 38, room.size.y - 18), Color(0.37, 0.42, 0.43, 0.36), 1.0)
	for y in range(5):
		draw_line(room.position + Vector2(16, 86 + y * 38), room.position + Vector2(room.size.x - 16, 86 + y * 38), Color(0.37, 0.42, 0.43, 0.36), 1.0)

	_draw_windows(room.position + Vector2(28, 22))
	_draw_windows(room.position + Vector2(230, 22))
	_draw_workstation(room.position + Vector2(42, 100), "#6f8b9b", "运营")
	_draw_workstation(room.position + Vector2(156, 100), "#728164", "程序")
	_draw_workstation(room.position + Vector2(270, 100), "#a07158", "销售")
	ArtAssetsScript.draw_prop(self, "office_desk", room.position + Vector2(58, 110), 1.25)
	ArtAssetsScript.draw_prop(self, "office_desk", room.position + Vector2(172, 110), 1.25)
	ArtAssetsScript.draw_prop(self, "office_desk", room.position + Vector2(286, 110), 1.25)
	ArtAssetsScript.draw_prop(self, "product_boxes", room.position + Vector2(32, 218), 0.9)
	_draw_meeting_table(room.position + Vector2(92, 202))
	_draw_water_cooler(room.position + Vector2(324, 206))
	_draw_exit(room.position + Vector2(170, 266))
	_draw_light_overlay(room)


func _draw_windows(pos: Vector2) -> void:
	var lit := current_segment in ["evening", "late_night"]
	for i in range(3):
		draw_rect(Rect2(pos + Vector2(i * 38, 0), Vector2(30, 26)), Color("#d9ecf2") if not lit else Color("#ffe2a1"))
		draw_line(pos + Vector2(i * 38 + 14, 2), pos + Vector2(i * 38 + 14, 24), Color("#53636f"), 1.0)


func _draw_workstation(pos: Vector2, color_hex: String, label: String) -> void:
	draw_rect(Rect2(pos + Vector2(2, 3), Vector2(72, 52)), Color(0.03, 0.03, 0.03, 0.22))
	draw_rect(Rect2(pos, Vector2(72, 50)), Color("#4b4540"))
	draw_rect(Rect2(pos + Vector2(8, 8), Vector2(28, 18)), Color("#24313a"))
	draw_rect(Rect2(pos + Vector2(11, 11), Vector2(22, 12)), Color(color_hex))
	draw_rect(Rect2(pos + Vector2(44, 9), Vector2(18, 24)), Color("#e2d0a4"))
	draw_rect(Rect2(pos + Vector2(20, 36), Vector2(32, 12)), Color("#343b42"))
	_draw_label_blocks(pos + Vector2(10, -13), label)


func _draw_label_blocks(pos: Vector2, _label: String) -> void:
	draw_rect(Rect2(pos, Vector2(50, 9)), Color("#f1e4bb"))
	draw_rect(Rect2(pos + Vector2(4, 3), Vector2(10, 3)), Color("#4b4b45"))
	draw_rect(Rect2(pos + Vector2(18, 3), Vector2(10, 3)), Color("#4b4b45"))
	draw_rect(Rect2(pos + Vector2(32, 3), Vector2(10, 3)), Color("#4b4b45"))


func _draw_meeting_table(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(3, 4), Vector2(124, 44)), Color(0.03, 0.03, 0.03, 0.20))
	draw_rect(Rect2(pos, Vector2(124, 42)), Color("#5c4b3d"))
	for i in range(4):
		draw_rect(Rect2(pos + Vector2(14 + i * 28, -10), Vector2(18, 10)), Color("#394854"))
		draw_rect(Rect2(pos + Vector2(14 + i * 28, 42), Vector2(18, 10)), Color("#394854"))


func _draw_water_cooler(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(28, 44)), Color("#d4ddd8"))
	draw_rect(Rect2(pos + Vector2(5, -16), Vector2(18, 18)), Color("#9fd3e0"))
	draw_rect(Rect2(pos + Vector2(8, 22), Vector2(12, 6)), Color("#71807b"))


func _draw_exit(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(54, 12)), Color("#28323b"))
	draw_rect(Rect2(pos + Vector2(5, 2), Vector2(44, 8)), Color("#6c7c86"))


func _draw_light_overlay(room: Rect2) -> void:
	if current_weather == "rain":
		draw_rect(room, Color(0.08, 0.12, 0.16, 0.10))
	if current_segment == "late_night":
		draw_rect(room, Color(0.08, 0.10, 0.20, 0.24))
	elif current_segment == "evening":
		draw_circle(room.position + Vector2(room.size.x * 0.5, 86), 120, Color(1.0, 0.76, 0.42, 0.06))


func _create_boundaries() -> void:
	var room := get_world_rect()
	_add_collision_rect("office_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("office_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(166, 12))
	_add_collision_rect("office_south_wall_right", room.position + Vector2(220, room.size.y - 12), Vector2(164, 12))
	_add_collision_rect("office_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("office_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_furniture_collisions() -> void:
	var origin := get_world_rect().position
	_add_collision_rect("operations_desk_collision", origin + Vector2(42, 100), Vector2(72, 50))
	_add_collision_rect("developer_desk_collision", origin + Vector2(156, 100), Vector2(72, 50))
	_add_collision_rect("sales_desk_collision", origin + Vector2(270, 100), Vector2(72, 50))
	_add_collision_rect("meeting_table_collision", origin + Vector2(92, 202), Vector2(124, 42))
	_add_collision_rect("water_cooler_collision", origin + Vector2(324, 190), Vector2(28, 60))


func _create_interactables() -> void:
	var origin := get_world_rect().position
	_add_interactable({
		"id": "job_operations",
		"name": "运营岗",
		"kind": "job",
		"prompt": "按 E 做运营工作",
		"position": origin + Vector2(78, 164),
		"size": Vector2(76, 30),
		"fill_color": Color(0.45, 0.62, 0.72, 0.18),
		"border_color": Color("#b8d9e8"),
	})
	_add_interactable({
		"id": "job_developer",
		"name": "程序岗",
		"kind": "job",
		"prompt": "按 E 做程序工作",
		"position": origin + Vector2(192, 164),
		"size": Vector2(76, 30),
		"fill_color": Color(0.45, 0.58, 0.42, 0.18),
		"border_color": Color("#c4d8a8"),
	})
	_add_interactable({
		"id": "job_sales",
		"name": "销售岗",
		"kind": "job",
		"prompt": "按 E 做销售工作",
		"position": origin + Vector2(306, 164),
		"size": Vector2(76, 30),
		"fill_color": Color(0.78, 0.48, 0.34, 0.18),
		"border_color": Color("#e9b293"),
	})
	_add_interactable({
		"id": "office_exit",
		"name": "公司门",
		"kind": "exit_office",
		"prompt": "按 E 离开公司",
		"position": origin + Vector2(198, 268),
		"size": Vector2(64, 28),
		"fill_color": Color(0.58, 0.72, 0.78, 0.18),
		"border_color": Color("#c7e7ff"),
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
