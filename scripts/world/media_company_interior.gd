extends Node2D
class_name MediaCompanyInterior

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
	return Vector2(704, 408)


func get_world_rect() -> Rect2:
	return Rect2(Vector2(500, 128), Vector2(416, 304))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	var room := get_world_rect()
	draw_rect(Rect2(room.position + Vector2(6, 7), room.size), Color(0.03, 0.02, 0.03, 0.30))
	draw_rect(room, Color("#655363"))
	draw_rect(Rect2(room.position + Vector2(10, 10), room.size - Vector2(20, 20)), Color("#806f7d"))
	draw_rect(Rect2(room.position + Vector2(10, 10), Vector2(room.size.x - 20, 54)), Color("#514657"))
	ArtAssetsScript.draw_tiled_rect(self, "media_floor", Rect2(room.position + Vector2(10, 76), room.size - Vector2(20, 94)), Color(1, 1, 1, 0.82))
	ArtAssetsScript.draw_tiled_rect(self, "media_wall", Rect2(room.position + Vector2(10, 10), Vector2(room.size.x - 20, 54)), Color(1, 1, 1, 0.74))

	for x in range(10):
		draw_line(room.position + Vector2(20 + x * 38, 76), room.position + Vector2(20 + x * 38, room.size.y - 18), Color(0.28, 0.23, 0.29, 0.36), 1.0)
	for y in range(5):
		draw_line(room.position + Vector2(18, 92 + y * 38), room.position + Vector2(room.size.x - 18, 92 + y * 38), Color(0.28, 0.23, 0.29, 0.36), 1.0)

	_draw_city_windows(room.position + Vector2(28, 23))
	_draw_live_set(room.position + Vector2(42, 98))
	ArtAssetsScript.draw_prop(self, "ring_light", room.position + Vector2(82, 84), 1.15)
	ArtAssetsScript.draw_prop(self, "camera", room.position + Vector2(134, 114), 1.0)
	_draw_operator_table(room.position + Vector2(218, 98))
	_draw_makeup_table(room.position + Vector2(52, 214))
	_draw_storage_shelf(room.position + Vector2(296, 214))
	ArtAssetsScript.draw_prop(self, "product_boxes", room.position + Vector2(306, 220), 1.1)
	ArtAssetsScript.draw_character_frame(self, "streamer", room.position + Vector2(84, 150), false, 0.9, Color(1, 1, 1, 0.92))
	_draw_exit(room.position + Vector2(178, 282))
	_draw_light_overlay(room)


func _draw_city_windows(pos: Vector2) -> void:
	var lit := current_segment in ["evening", "late_night"]
	for i in range(4):
		draw_rect(Rect2(pos + Vector2(i * 44, 0), Vector2(34, 26)), Color("#d8eef2") if not lit else Color("#ffe1a1"))
		draw_line(pos + Vector2(i * 44 + 16, 2), pos + Vector2(i * 44 + 16, 24), Color("#5c5361"), 1.0)


func _draw_live_set(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(3, 4), Vector2(126, 84)), Color(0.03, 0.02, 0.03, 0.26))
	draw_rect(Rect2(pos, Vector2(126, 82)), Color("#4a3d4f"))
	draw_rect(Rect2(pos + Vector2(14, 14), Vector2(52, 50)), Color("#c26c74"))
	draw_rect(Rect2(pos + Vector2(74, 12), Vector2(32, 26)), Color("#26313a"))
	draw_rect(Rect2(pos + Vector2(77, 15), Vector2(26, 18)), Color("#80c7d5"))
	draw_circle(pos + Vector2(92, 56), 14, Color("#ffe6b7"))
	draw_circle(pos + Vector2(34, 68), 12, Color("#ffe6b7"))
	draw_rect(Rect2(pos + Vector2(58, -16), Vector2(52, 10)), Color("#f6e3ba"))
	draw_rect(Rect2(pos + Vector2(64, -13), Vector2(12, 4)), Color("#453a44"))
	draw_rect(Rect2(pos + Vector2(82, -13), Vector2(12, 4)), Color("#453a44"))


func _draw_operator_table(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(2, 3), Vector2(126, 72)), Color(0.03, 0.02, 0.03, 0.24))
	draw_rect(Rect2(pos, Vector2(126, 70)), Color("#4c4447"))
	for i in range(3):
		draw_rect(Rect2(pos + Vector2(12 + i * 36, 9), Vector2(26, 19)), Color("#22313b"))
		draw_rect(Rect2(pos + Vector2(15 + i * 36, 12), Vector2(20, 13)), Color("#9fcbd8") if i != 1 else Color("#e9a66d"))
	draw_rect(Rect2(pos + Vector2(22, 46), Vector2(84, 12)), Color("#2e3339"))


func _draw_makeup_table(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(2, 3), Vector2(92, 48)), Color(0.03, 0.02, 0.03, 0.22))
	draw_rect(Rect2(pos, Vector2(92, 46)), Color("#6b5148"))
	draw_rect(Rect2(pos + Vector2(12, -24), Vector2(34, 24)), Color("#eadcc0"))
	for i in range(5):
		draw_circle(pos + Vector2(8 + i * 9, -12), 2, Color("#ffe8b7"))
	draw_rect(Rect2(pos + Vector2(60, 10), Vector2(18, 18)), Color("#d58a8e"))


func _draw_storage_shelf(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(72, 58)), Color("#4b3e43"))
	for y in range(3):
		draw_line(pos + Vector2(4, 14 + y * 18), pos + Vector2(68, 14 + y * 18), Color("#806a61"), 1.0)
	draw_rect(Rect2(pos + Vector2(8, 8), Vector2(16, 10)), Color("#e4c06d"))
	draw_rect(Rect2(pos + Vector2(32, 24), Vector2(20, 12)), Color("#8bc2c9"))
	draw_rect(Rect2(pos + Vector2(14, 42), Vector2(34, 10)), Color("#c76b6d"))


func _draw_exit(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(62, 12)), Color("#2d2730"))
	draw_rect(Rect2(pos + Vector2(5, 2), Vector2(52, 8)), Color("#806f7d"))


func _draw_light_overlay(room: Rect2) -> void:
	if current_weather == "rain":
		draw_rect(room, Color(0.08, 0.11, 0.16, 0.10))
	if current_segment == "late_night":
		draw_rect(room, Color(0.11, 0.08, 0.18, 0.25))
	elif current_segment == "evening":
		draw_circle(room.position + Vector2(124, 138), 132, Color(1.0, 0.68, 0.54, 0.08))


func _create_boundaries() -> void:
	var room := get_world_rect()
	_add_collision_rect("media_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("media_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(174, 12))
	_add_collision_rect("media_south_wall_right", room.position + Vector2(240, room.size.y - 12), Vector2(176, 12))
	_add_collision_rect("media_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("media_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_furniture_collisions() -> void:
	var origin := get_world_rect().position
	_add_collision_rect("live_set_collision", origin + Vector2(42, 98), Vector2(126, 82))
	_add_collision_rect("operator_table_collision", origin + Vector2(218, 98), Vector2(126, 70))
	_add_collision_rect("makeup_table_collision", origin + Vector2(52, 190), Vector2(92, 72))
	_add_collision_rect("storage_shelf_collision", origin + Vector2(296, 214), Vector2(72, 58))


func _create_interactables() -> void:
	var origin := get_world_rect().position
	_add_interactable({
		"id": "job_streamer",
		"name": "直播间机位",
		"kind": "job",
		"prompt": "按 E 开始直播",
		"position": origin + Vector2(106, 188),
		"size": Vector2(92, 34),
		"fill_color": Color(1.0, 0.45, 0.52, 0.18),
		"border_color": Color("#ffd0d5"),
	})
	_add_interactable({
		"id": "media_exit",
		"name": "传媒公司出口",
		"kind": "exit_media_company",
		"prompt": "按 E 离开传媒公司",
		"position": origin + Vector2(210, 284),
		"size": Vector2(74, 28),
		"fill_color": Color(0.75, 0.64, 0.80, 0.18),
		"border_color": Color("#e3c7f0"),
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
