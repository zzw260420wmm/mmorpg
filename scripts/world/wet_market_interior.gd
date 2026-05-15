extends Node2D
class_name WetMarketInterior

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")
const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

var current_segment := "morning"
var current_weather := "overcast"


func _ready() -> void:
	z_index = 0
	_create_boundaries()
	_create_stall_collisions()
	_create_interactables()
	queue_redraw()


func get_player_spawn() -> Vector2:
	return Vector2(384, 620)


func get_world_rect() -> Rect2:
	return Rect2(Vector2(176, 416), Vector2(416, 240))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	var room := get_world_rect()
	draw_rect(Rect2(room.position + Vector2(5, 6), room.size), Color(0.03, 0.04, 0.03, 0.30))
	draw_rect(room, Color("#5b6046"))
	draw_rect(Rect2(room.position + Vector2(10, 10), room.size - Vector2(20, 20)), Color("#737267"))
	ArtAssetsScript.draw_tiled_rect(self, "wet_asphalt", Rect2(room.position + Vector2(10, 58), room.size - Vector2(20, 76)), Color(1, 1, 1, 0.82))
	ArtAssetsScript.draw_tiled_rect(self, "delivery_wall", Rect2(room.position + Vector2(10, 10), Vector2(room.size.x - 20, 48)), Color(1, 1, 1, 0.70))
	for x in range(9):
		draw_line(room.position + Vector2(20 + x * 42, 64), room.position + Vector2(20 + x * 42, room.size.y - 20), Color(0.36, 0.40, 0.36, 0.34), 1.0)
	for y in range(4):
		draw_line(room.position + Vector2(16, 78 + y * 36), room.position + Vector2(room.size.x - 16, 78 + y * 36), Color(0.36, 0.40, 0.36, 0.34), 1.0)
	_draw_stall(room.position + Vector2(36, 86), "#6d8d83", "#bdd3a0")
	_draw_stall(room.position + Vector2(158, 86), "#a45d45", "#e08772")
	_draw_stall(room.position + Vector2(280, 86), "#806b52", "#f0c77b")
	ArtAssetsScript.draw_prop(self, "product_boxes", room.position + Vector2(62, 154), 0.95)
	ArtAssetsScript.draw_prop(self, "food_sign", room.position + Vector2(318, 42), 0.9)
	_draw_exit(room.position + Vector2(178, 218))
	if current_weather == "rain":
		draw_rect(room, Color(0.08, 0.12, 0.14, 0.10))


func _draw_stall(pos: Vector2, table_color: String, food_color: String) -> void:
	draw_rect(Rect2(pos + Vector2(3, 4), Vector2(92, 58)), Color(0.03, 0.03, 0.02, 0.22))
	draw_rect(Rect2(pos, Vector2(92, 56)), Color(table_color))
	draw_rect(Rect2(pos + Vector2(8, 8), Vector2(76, 16)), Color("#efe2bb"))
	for i in range(6):
		draw_circle(pos + Vector2(14 + i * 12, 36), 4, Color(food_color))
	draw_rect(Rect2(pos + Vector2(12, -12), Vector2(68, 10)), Color("#f0c77b"))
	draw_rect(Rect2(pos + Vector2(18, -9), Vector2(18, 4)), Color("#4d5738"))
	draw_rect(Rect2(pos + Vector2(44, -9), Vector2(18, 4)), Color("#4d5738"))


func _draw_exit(pos: Vector2) -> void:
	draw_rect(Rect2(pos, Vector2(62, 12)), Color("#303225"))
	draw_rect(Rect2(pos + Vector2(5, 2), Vector2(52, 8)), Color("#d8c886"))


func _create_boundaries() -> void:
	var room := get_world_rect()
	_add_collision_rect("market_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("market_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(176, 12))
	_add_collision_rect("market_south_wall_right", room.position + Vector2(240, room.size.y - 12), Vector2(176, 12))
	_add_collision_rect("market_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("market_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_stall_collisions() -> void:
	var origin := get_world_rect().position
	_add_collision_rect("veg_stall_collision", origin + Vector2(36, 86), Vector2(92, 56))
	_add_collision_rect("meat_stall_collision", origin + Vector2(158, 86), Vector2(92, 56))
	_add_collision_rect("fruit_stall_collision", origin + Vector2(280, 86), Vector2(92, 56))


func _create_interactables() -> void:
	var origin := get_world_rect().position
	_add_interactable({
		"id": "wet_market",
		"name": "社区菜场",
		"kind": "shop",
		"prompt": "按 E 买便宜菜",
		"position": origin + Vector2(204, 166),
		"size": Vector2(112, 34),
		"fill_color": Color(0.72, 0.84, 0.42, 0.18),
		"border_color": Color("#d8c886"),
	})
	_add_interactable({
		"id": "market_exit",
		"name": "菜场出口",
		"kind": "exit_wet_market",
		"prompt": "按 E 离开菜场",
		"position": origin + Vector2(208, 220),
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
