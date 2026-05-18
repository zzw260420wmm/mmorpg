extends Node2D
class_name InternetCafeInterior

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
	return Vector2(704, 548)


func get_world_rect() -> Rect2:
	return Rect2(Vector2(416, 128), Vector2(576, 448))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	var room := get_world_rect()
	var floor_rect := Rect2(room.position + Vector2(16, 96), Vector2(room.size.x - 32, room.size.y - 112))
	draw_rect(Rect2(room.position + Vector2(4, 4), room.size), Color(0.01, 0.02, 0.04, 0.34))
	draw_rect(room, Color("#253145"))
	draw_rect(Rect2(room.position + Vector2(16, 16), room.size - Vector2(32, 32)), Color("#334255"))
	draw_rect(Rect2(room.position + Vector2(16, 16), Vector2(room.size.x - 32, 78)), Color("#1e2a3d"))
	ArtAssetsScript.draw_tiled_rect(self, "office_tile", floor_rect, Color(0.70, 0.86, 1.0, 0.42))
	ArtAssetsScript.draw_pixel_grid(self, floor_rect, 32, Color(0.12, 0.20, 0.28, 0.26))
	_draw_wall_details(room)
	_draw_pc_rows(room)
	_draw_counter_and_snacks(room)
	_draw_clutter(room)
	_draw_exit(room.position + Vector2(256, 388))
	_draw_customers(room)
	_draw_light_overlay(room)


func _draw_wall_details(room: Rect2) -> void:
	ArtAssetsScript.draw_internet_cafe_prop(self, "rgb_sign", room.position + Vector2(42, 32), 1.28)
	ArtAssetsScript.draw_internet_cafe_prop(self, "blue_wall_poster", room.position + Vector2(188, 28), 1.0)
	ArtAssetsScript.draw_internet_cafe_prop(self, "blue_wall_poster", room.position + Vector2(382, 28), 1.0)
	ArtAssetsScript.draw_internet_cafe_prop(self, "router_stack", room.position + Vector2(502, 40), 0.85)
	for x in [96, 264, 432]:
		draw_circle(room.position + Vector2(x, 112), 86, Color(0.20, 0.58, 0.95, 0.08))


func _draw_pc_rows(room: Rect2) -> void:
	_draw_pc_row(room.position + Vector2(60, 138), 4, false)
	_draw_pc_row(room.position + Vector2(60, 246), 4, true)
	_draw_pc_row(room.position + Vector2(300, 138), 3, false)
	_draw_pc_row(room.position + Vector2(300, 246), 3, true)


func _draw_pc_row(pos: Vector2, count: int, flipped: bool) -> void:
	for i in range(count):
		var base := pos + Vector2(i * 72, 0)
		ArtAssetsScript.draw_internet_cafe_prop(self, "messy_desk", base, 1.0)
		ArtAssetsScript.draw_internet_cafe_prop(self, "gaming_pc", base + Vector2(4, -16), 0.82)
		ArtAssetsScript.draw_internet_cafe_prop(self, "keyboard_mouse", base + Vector2(10, 10), 0.72)
		if i % 2 == 0:
			ArtAssetsScript.draw_internet_cafe_prop(self, "noodle_cup", base + Vector2(38, 4), 0.42)
		if i % 3 == 1:
			ArtAssetsScript.draw_internet_cafe_prop(self, "soda_can", base + Vector2(48, 8), 0.36)
		var chair_offset := Vector2(4, 42) if not flipped else Vector2(4, -48)
		ArtAssetsScript.draw_internet_cafe_prop(self, "gaming_chair", base + chair_offset, 0.78)


func _draw_counter_and_snacks(room: Rect2) -> void:
	ArtAssetsScript.draw_internet_cafe_prop(self, "front_counter", room.position + Vector2(398, 330), 1.35)
	ArtAssetsScript.draw_internet_cafe_prop(self, "snack_shelf", room.position + Vector2(486, 284), 1.18)
	ArtAssetsScript.draw_internet_cafe_prop(self, "soda_can", room.position + Vector2(454, 344), 0.48)
	ArtAssetsScript.draw_internet_cafe_prop(self, "noodle_cup", room.position + Vector2(420, 338), 0.48)


func _draw_clutter(room: Rect2) -> void:
	ArtAssetsScript.draw_internet_cafe_prop(self, "sleeping_user", room.position + Vector2(112, 362), 1.0)
	ArtAssetsScript.draw_internet_cafe_prop(self, "floor_cable", room.position + Vector2(300, 364), 1.2)
	ArtAssetsScript.draw_internet_cafe_prop(self, "ashtray", room.position + Vector2(252, 198), 0.55)
	ArtAssetsScript.draw_internet_cafe_prop(self, "headset", room.position + Vector2(164, 214), 0.55)


func _draw_exit(pos: Vector2) -> void:
	ArtAssetsScript.draw_internet_cafe_prop(self, "exit_door", pos, 1.0)


func _draw_customers(room: Rect2) -> void:
	ArtAssetsScript.draw_character_frame(self, "metro_commuter", room.position + Vector2(86, 196), false, 0.66, Color(0.82, 0.94, 1.0, 0.90), Vector2.UP)
	ArtAssetsScript.draw_character_frame(self, "office_worker", room.position + Vector2(344, 302), false, 0.66, Color(0.80, 0.92, 1.0, 0.84), Vector2.LEFT)
	ArtAssetsScript.draw_character_frame(self, "drifter_girl", room.position + Vector2(504, 356), false, 0.68, Color(0.86, 0.94, 1.0, 0.90), Vector2.DOWN)


func _draw_light_overlay(room: Rect2) -> void:
	draw_rect(room, Color(0.02, 0.04, 0.11, 0.22))
	if current_weather == "rain":
		draw_rect(room, Color(0.05, 0.10, 0.18, 0.10))
	if current_segment in ["evening", "late_night"]:
		draw_rect(room, Color(0.02, 0.04, 0.14, 0.16))
		draw_circle(room.position + Vector2(290, 220), 190, Color(0.16, 0.48, 1.0, 0.09))
	if current_segment == "late_night":
		draw_rect(room, Color(0.01, 0.02, 0.07, 0.18))
		draw_circle(room.position + Vector2(120, 388), 96, Color(0.75, 0.38, 1.0, 0.07))


func _create_boundaries() -> void:
	var room := get_world_rect()
	_add_collision_rect("internet_cafe_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("internet_cafe_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(252, 12))
	_add_collision_rect("internet_cafe_south_wall_right", room.position + Vector2(332, room.size.y - 12), Vector2(244, 12))
	_add_collision_rect("internet_cafe_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("internet_cafe_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_furniture_collisions() -> void:
	var origin := get_world_rect().position
	_add_collision_rect("internet_cafe_pc_left_top", origin + Vector2(58, 126), Vector2(276, 70))
	_add_collision_rect("internet_cafe_pc_left_bottom", origin + Vector2(58, 234), Vector2(276, 70))
	_add_collision_rect("internet_cafe_pc_right_top", origin + Vector2(298, 126), Vector2(216, 70))
	_add_collision_rect("internet_cafe_pc_right_bottom", origin + Vector2(298, 234), Vector2(216, 70))
	_add_collision_rect("internet_cafe_counter_collision", origin + Vector2(398, 330), Vector2(86, 64))
	_add_collision_rect("internet_cafe_snack_shelf_collision", origin + Vector2(486, 284), Vector2(66, 76))
	_add_collision_rect("internet_cafe_sleeping_user_collision", origin + Vector2(112, 362), Vector2(66, 38))


func _create_interactables() -> void:
	var origin := get_world_rect().position
	_add_interactable({
		"id": "internet_cafe_pc",
		"name": "网吧电脑",
		"kind": "dialogue",
		"prompt": "按 E 上机",
		"position": origin + Vector2(252, 338),
		"size": Vector2(96, 34),
		"lines": {
			"default": ["屏幕蓝光照着泡面杯和键盘缝里的灰。", "一小时 8 元。你可以在这里短暂逃离现实。"],
			"evening": ["下班的人开始坐满角落，耳机里传来团战和短视频声。"],
			"late_night": ["有人趴在桌上睡着了，机器还在发光。"],
		},
		"fill_color": Color(0.22, 0.54, 1.0, 0.18),
		"border_color": Color("#6fd2ff"),
	})
	_add_interactable({
		"id": "internet_cafe_counter",
		"name": "网吧前台",
		"kind": "dialogue",
		"prompt": "按 E 问前台",
		"position": origin + Vector2(452, 404),
		"size": Vector2(96, 34),
		"lines": {
			"default": ["前台抬头看了你一眼：身份证带了吗？"],
			"late_night": ["前台小声说：包夜便宜点，但明天别迟到。"],
		},
		"fill_color": Color(0.75, 0.48, 0.95, 0.15),
		"border_color": Color("#9fd9ff"),
	})
	_add_interactable({
		"id": "internet_cafe_exit",
		"name": "网吧出口",
		"kind": "exit_internet_cafe",
		"prompt": "按 E 离开网吧",
		"position": origin + Vector2(286, 422),
		"size": Vector2(78, 30),
		"fill_color": Color(0.9, 0.74, 0.45, 0.18),
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
