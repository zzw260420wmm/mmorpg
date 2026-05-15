extends Node2D
class_name MetroStationInterior

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")
const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

var current_segment := "morning"
var current_weather := "overcast"


func _ready() -> void:
	z_index = 0
	_create_boundaries()
	_create_station_collisions()
	_create_interactables()
	queue_redraw()


func get_player_spawn() -> Vector2:
	return Vector2(640, 404)


func get_world_rect() -> Rect2:
	return Rect2(Vector2(352, 96), Vector2(576, 352))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	var room := get_world_rect()
	draw_rect(Rect2(room.position + Vector2(6, 7), room.size), Color(0.02, 0.03, 0.04, 0.32))
	draw_rect(room, Color("#46586a"))
	draw_rect(Rect2(room.position + Vector2(10, 10), room.size - Vector2(20, 20)), Color("#536577"))
	ArtAssetsScript.draw_tiled_rect(self, "metro_tile", Rect2(room.position + Vector2(10, 76), room.size - Vector2(20, 100)), Color(1, 1, 1, 0.86))
	ArtAssetsScript.draw_tiled_rect(self, "wet_asphalt", Rect2(room.position + Vector2(16, 40), Vector2(room.size.x - 32, 72)), Color(1, 1, 1, 0.70))

	_draw_tracks(room)
	_draw_floor_grid(room)
	_draw_station_signage(room)
	_draw_ticket_machines(room.position + Vector2(54, 198))
	_draw_ticket_gates(room.position + Vector2(154, 228))
	_draw_bench_and_commuters(room)
	_draw_stairs(room.position + Vector2(248, 304))
	_draw_light_overlay(room)


func _draw_tracks(room: Rect2) -> void:
	var track_rect := Rect2(room.position + Vector2(16, 40), Vector2(room.size.x - 32, 72))
	draw_rect(track_rect, Color("#24313d"))
	for i in range(3):
		var y := track_rect.position.y + 18 + i * 18
		draw_line(Vector2(track_rect.position.x + 18, y), Vector2(track_rect.end.x - 18, y), Color("#7d8790"), 2.0)
	for i in range(14):
		var x := track_rect.position.x + 28 + i * 36
		draw_rect(Rect2(Vector2(x, track_rect.position.y + 10), Vector2(12, 54)), Color("#3c4650"))
	draw_rect(Rect2(room.position + Vector2(16, 118), Vector2(room.size.x - 32, 8)), Color("#d5b642"))
	draw_rect(Rect2(room.position + Vector2(16, 128), Vector2(room.size.x - 32, 4)), Color("#6c5a48"))


func _draw_floor_grid(room: Rect2) -> void:
	for x in range(13):
		draw_line(room.position + Vector2(24 + x * 42, 136), room.position + Vector2(24 + x * 42, room.size.y - 18), Color(0.28, 0.35, 0.39, 0.34), 1.0)
	for y in range(6):
		draw_line(room.position + Vector2(16, 150 + y * 38), room.position + Vector2(room.size.x - 16, 150 + y * 38), Color(0.28, 0.35, 0.39, 0.34), 1.0)


func _draw_station_signage(room: Rect2) -> void:
	draw_rect(Rect2(room.position + Vector2(24, 18), Vector2(528, 18)), Color("#2f3d4f"))
	draw_rect(Rect2(room.position + Vector2(36, 23), Vector2(52, 6)), Color("#a9d7ff"))
	draw_rect(Rect2(room.position + Vector2(100, 23), Vector2(78, 6)), Color("#d8eef2"))
	draw_rect(Rect2(room.position + Vector2(416, 23), Vector2(42, 6)), Color("#e8c879"))
	draw_rect(Rect2(room.position + Vector2(470, 23), Vector2(54, 6)), Color("#d8eef2"))
	draw_rect(Rect2(room.position + Vector2(408, 150), Vector2(104, 62)), Color("#26313d"))
	draw_rect(Rect2(room.position + Vector2(416, 158), Vector2(88, 18)), Color("#a9d7ff"))
	draw_rect(Rect2(room.position + Vector2(420, 186), Vector2(22, 4)), Color("#e8c879"))
	draw_rect(Rect2(room.position + Vector2(448, 186), Vector2(34, 4)), Color("#d8eef2"))
	draw_rect(Rect2(room.position + Vector2(420, 198), Vector2(64, 4)), Color("#d8eef2"))
	draw_rect(Rect2(room.position + Vector2(60, 146), Vector2(82, 48)), Color("#efe2bb"))
	draw_rect(Rect2(room.position + Vector2(68, 154), Vector2(64, 10)), Color("#5d7980"))
	draw_rect(Rect2(room.position + Vector2(68, 170), Vector2(42, 6)), Color("#c76b6d"))


func _draw_ticket_machines(pos: Vector2) -> void:
	for i in range(3):
		var machine_pos := pos + Vector2(i * 38, 0)
		draw_rect(Rect2(machine_pos + Vector2(2, 3), Vector2(28, 42)), Color(0.03, 0.04, 0.05, 0.24))
		draw_rect(Rect2(machine_pos, Vector2(28, 42)), Color("#6d8d83"))
		draw_rect(Rect2(machine_pos + Vector2(5, 6), Vector2(18, 10)), Color("#c8e3dc"))
		draw_rect(Rect2(machine_pos + Vector2(7, 22), Vector2(14, 4)), Color("#344a50"))
		draw_rect(Rect2(machine_pos + Vector2(10, 31), Vector2(8, 5)), Color("#efc36f"))


func _draw_ticket_gates(pos: Vector2) -> void:
	for i in range(7):
		var gate_pos := pos + Vector2(i * 38, 0)
		draw_rect(Rect2(gate_pos, Vector2(26, 38)), Color("#344a50"))
		draw_rect(Rect2(gate_pos + Vector2(4, 4), Vector2(18, 8)), Color("#7fc8a0") if i == 3 else Color("#a9d7ff"))
		draw_rect(Rect2(gate_pos + Vector2(10, 16), Vector2(6, 22)), Color("#1f2a33"))
	draw_rect(Rect2(pos + Vector2(114, -14), Vector2(60, 10)), Color("#e8c879"))
	draw_rect(Rect2(pos + Vector2(124, -11), Vector2(40, 4)), Color("#2f3d4f"))


func _draw_bench_and_commuters(room: Rect2) -> void:
	var bench_pos := room.position + Vector2(52, 268)
	draw_rect(Rect2(bench_pos, Vector2(114, 16)), Color("#4b4540"))
	for i in range(4):
		draw_rect(Rect2(bench_pos + Vector2(8 + i * 26, 16), Vector2(4, 18)), Color("#2f343a"))
	ArtAssetsScript.draw_character_frame(self, "metro_commuter", room.position + Vector2(214, 270), false, 0.70, Color(1, 1, 1, 0.92), Vector2.LEFT)
	ArtAssetsScript.draw_character_frame(self, "office_worker", room.position + Vector2(298, 164), false, 0.70, Color(1, 1, 1, 0.88), Vector2.DOWN)
	ArtAssetsScript.draw_character_frame(self, "drifter_girl", room.position + Vector2(476, 266), false, 0.70, Color(1, 1, 1, 0.88), Vector2.RIGHT)
	ArtAssetsScript.draw_prop(self, "vending_machine", room.position + Vector2(506, 212), 0.90)


func _draw_stairs(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(2, 3), Vector2(80, 48)), Color(0.02, 0.03, 0.04, 0.24))
	draw_rect(Rect2(pos, Vector2(80, 48)), Color("#38485a"))
	for i in range(5):
		draw_line(pos + Vector2(8, 8 + i * 8), pos + Vector2(72, 8 + i * 8), Color("#7d8790"), 1.0)
	draw_rect(Rect2(pos + Vector2(18, -12), Vector2(44, 10)), Color("#a9d7ff"))
	draw_rect(Rect2(pos + Vector2(24, -9), Vector2(32, 4)), Color("#2f3d4f"))


func _draw_light_overlay(room: Rect2) -> void:
	if current_weather == "rain":
		draw_rect(room, Color(0.08, 0.12, 0.16, 0.12))
	if current_segment == "morning":
		draw_circle(room.position + Vector2(288, 270), 140, Color(0.70, 0.88, 1.0, 0.05))
	elif current_segment == "evening":
		draw_rect(room, Color(0.10, 0.10, 0.17, 0.12))
		draw_circle(room.position + Vector2(288, 188), 168, Color(1.0, 0.77, 0.38, 0.05))
	elif current_segment == "late_night":
		draw_rect(room, Color(0.06, 0.08, 0.18, 0.26))
		draw_circle(room.position + Vector2(288, 190), 128, Color(0.55, 0.78, 1.0, 0.05))


func _create_boundaries() -> void:
	var room := get_world_rect()
	_add_collision_rect("metro_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("metro_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(248, 12))
	_add_collision_rect("metro_south_wall_right", room.position + Vector2(328, room.size.y - 12), Vector2(248, 12))
	_add_collision_rect("metro_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("metro_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_station_collisions() -> void:
	var origin := get_world_rect().position
	_add_collision_rect("metro_track_barrier", origin + Vector2(16, 40), Vector2(544, 72))
	_add_collision_rect("metro_ticket_machines_collision", origin + Vector2(54, 198), Vector2(104, 42))
	_add_collision_rect("metro_map_collision", origin + Vector2(408, 150), Vector2(104, 62))
	_add_collision_rect("metro_vending_collision", origin + Vector2(506, 212), Vector2(30, 34))
	_add_collision_rect("metro_gate_left_collision", origin + Vector2(154, 228), Vector2(112, 38))
	_add_collision_rect("metro_gate_right_collision", origin + Vector2(314, 228), Vector2(104, 38))
	_add_collision_rect("metro_bench_collision", origin + Vector2(52, 268), Vector2(114, 24))


func _create_interactables() -> void:
	var origin := get_world_rect().position
	_add_interactable({
		"id": "metro_gate",
		"name": "地铁闸机",
		"kind": "metro_commute",
		"prompt": "按 E 通勤去公司",
		"position": origin + Vector2(288, 248),
		"size": Vector2(74, 32),
		"fill_color": Color(0.55, 0.76, 0.95, 0.18),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "ticket_machine",
		"name": "售票机",
		"kind": "dialogue",
		"prompt": "按 E 查看车票",
		"position": origin + Vector2(102, 250),
		"size": Vector2(88, 28),
		"lines": {
			"default": ["单程票价：6 元。", "连通勤也要算进今天的预算里。"],
			"morning": ["早高峰没有给犹豫留空间。"],
			"late_night": ["末班车倒计时在屏幕角落闪着。"],
		},
		"fill_color": Color(0.62, 0.84, 0.72, 0.16),
		"border_color": Color("#b8d8c4"),
	})
	_add_interactable({
		"id": "line_map",
		"name": "线路图",
		"kind": "dialogue",
		"prompt": "按 E 查看线路图",
		"position": origin + Vector2(462, 218),
		"size": Vector2(92, 28),
		"lines": {
			"default": ["这张图把城市折成一条条彩色线路。", "当前 DEMO 中，闸机会直接把你带到公司片区。"],
			"evening": ["招聘广告在返程线路旁边发亮。"],
		},
		"fill_color": Color(0.42, 0.66, 0.91, 0.16),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "metro_exit",
		"name": "地铁站出口",
		"kind": "exit_metro",
		"prompt": "按 E 回到街面",
		"position": origin + Vector2(288, 330),
		"size": Vector2(82, 30),
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
