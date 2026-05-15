extends Node2D
class_name ClinicInterior

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
	return Vector2(704, 626)


func get_world_rect() -> Rect2:
	return Rect2(Vector2(520, 416), Vector2(368, 240))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	var room := get_world_rect()
	draw_rect(Rect2(room.position + Vector2(5, 6), room.size), Color(0.03, 0.04, 0.04, 0.28))
	draw_rect(room, Color("#668a7d"))
	draw_rect(Rect2(room.position + Vector2(10, 10), room.size - Vector2(20, 20)), Color("#d7ded5"))
	draw_rect(Rect2(room.position + Vector2(10, 10), Vector2(room.size.x - 20, 50)), Color("#6d8d83"))
	ArtAssetsScript.draw_tiled_rect(self, "office_tile", Rect2(room.position + Vector2(10, 66), room.size - Vector2(20, 84)), Color(1, 1, 1, 0.66))
	for x in range(8):
		draw_line(room.position + Vector2(22 + x * 40, 72), room.position + Vector2(22 + x * 40, room.size.y - 18), Color(0.47, 0.55, 0.54, 0.25), 1.0)
	for y in range(4):
		draw_line(room.position + Vector2(16, 86 + y * 36), room.position + Vector2(room.size.x - 16, 86 + y * 36), Color(0.47, 0.55, 0.54, 0.25), 1.0)
	_draw_reception(room.position + Vector2(32, 86))
	_draw_waiting_chairs(room.position + Vector2(220, 92))
	_draw_notice_board(room.position + Vector2(224, 28))
	_draw_consult_room(room.position + Vector2(38, 160))
	_draw_exit(room.position + Vector2(154, 218))
	if current_segment == "late_night":
		draw_rect(room, Color(0.08, 0.12, 0.18, 0.16))


func _draw_reception(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(3, 4), Vector2(126, 52)), Color(0.03, 0.03, 0.03, 0.20))
	draw_rect(Rect2(pos, Vector2(126, 50)), Color("#e9fff7"))
	draw_rect(Rect2(pos + Vector2(12, 10), Vector2(34, 18)), Color("#26313d"))
	draw_rect(Rect2(pos + Vector2(16, 13), Vector2(26, 12)), Color("#9fc6d0"))
	draw_rect(Rect2(pos + Vector2(66, 12), Vector2(16, 16)), Color("#c76b6d"))
	draw_rect(Rect2(pos + Vector2(60, 18), Vector2(28, 5)), Color("#c76b6d"))


func _draw_waiting_chairs(pos: Vector2) -> void:
	for i in range(3):
		draw_rect(Rect2(pos + Vector2(i * 34, 0), Vector2(24, 18)), Color("#536577"))
		draw_rect(Rect2(pos + Vector2(i * 34 + 4, 18), Vector2(4, 16)), Color("#344a50"))
		draw_rect(Rect2(pos + Vector2(i * 34 + 16, 18), Vector2(4, 16)), Color("#344a50"))
	ArtAssetsScript.draw_character_frame(self, "metro_commuter", pos + Vector2(36, 34), false, 0.68, Color(1, 1, 1, 0.88), Vector2.LEFT)


func _draw_notice_board(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(102, 34)), Color("#f5e5bd"))
	draw_rect(Rect2(pos + Vector2(8, 8), Vector2(34, 4)), Color("#3d635f"))
	draw_rect(Rect2(pos + Vector2(8, 18), Vector2(52, 4)), Color("#8a4b42"))
	draw_rect(Rect2(pos + Vector2(68, 8), Vector2(20, 18)), Color("#d8fff0"))


func _draw_consult_room(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(110, 42)), Color("#b8d8c4"))
	draw_rect(Rect2(pos + Vector2(12, 10), Vector2(42, 20)), Color("#e9fff7"))
	draw_rect(Rect2(pos + Vector2(70, 8), Vector2(24, 24)), Color("#4d635f"))


func _draw_exit(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(62, 12)), Color("#2f4c4a"))
	draw_rect(Rect2(pos + Vector2(5, 2), Vector2(52, 8)), Color("#d8fff0"))


func _create_boundaries() -> void:
	var room := get_world_rect()
	_add_collision_rect("clinic_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("clinic_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(150, 12))
	_add_collision_rect("clinic_south_wall_right", room.position + Vector2(218, room.size.y - 12), Vector2(150, 12))
	_add_collision_rect("clinic_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("clinic_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_furniture_collisions() -> void:
	var origin := get_world_rect().position
	_add_collision_rect("clinic_reception_collision", origin + Vector2(32, 86), Vector2(126, 50))
	_add_collision_rect("clinic_chairs_collision", origin + Vector2(220, 92), Vector2(96, 34))
	_add_collision_rect("clinic_consult_collision", origin + Vector2(38, 160), Vector2(110, 42))


func _create_interactables() -> void:
	var origin := get_world_rect().position
	_add_interactable({
		"id": "community_clinic",
		"name": "社区诊所",
		"kind": "clinic",
		"prompt": "按 E 挂号休息",
		"position": origin + Vector2(96, 146),
		"size": Vector2(104, 34),
		"fill_color": Color(0.62, 0.90, 0.78, 0.18),
		"border_color": Color("#d8fff0"),
	})
	_add_interactable({
		"id": "clinic_exit",
		"name": "诊所出口",
		"kind": "exit_clinic",
		"prompt": "按 E 离开诊所",
		"position": origin + Vector2(184, 220),
		"size": Vector2(78, 30),
		"fill_color": Color(0.90, 0.74, 0.45, 0.18),
		"border_color": Color("#e8c879"),
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
