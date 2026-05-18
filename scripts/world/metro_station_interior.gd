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
	return Vector2(832, 616)


func get_world_rect() -> Rect2:
	return Rect2(Vector2(224, 80), Vector2(1216, 720))


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	queue_redraw()


func set_weather(weather_key: String) -> void:
	current_weather = weather_key
	queue_redraw()


func _draw() -> void:
	var room := get_world_rect()
	draw_rect(Rect2(room.position + Vector2(4, 4), room.size), Color(0.02, 0.03, 0.04, 0.32))
	draw_rect(room, Color("#394a55"))
	_draw_wall_band(room)
	_draw_floor(room)
	_draw_ceiling_lights(room)
	_draw_platform_doors(room)
	_draw_tactile_paths(room)
	_draw_floor_grid(room)
	_draw_station_signage(room)
	_draw_ticket_machines(room.position + Vector2(204, 342))
	_draw_ticket_gates(room.position + Vector2(752, 372))
	_draw_info_area(room)
	_draw_bench_and_commuters(room)
	_draw_stairs(room.position + Vector2(512, 590))
	_draw_light_overlay(room)


func _draw_wall_band(room: Rect2) -> void:
	draw_rect(Rect2(room.position + Vector2(16, 16), Vector2(room.size.x - 32, 176)), Color("#cbd8dc"))
	draw_rect(Rect2(room.position + Vector2(16, 96), Vector2(room.size.x - 32, 54)), Color("#a8c3ca"))
	for i in range(17):
		var x := room.position.x + 24 + i * 70
		draw_line(Vector2(x, room.position.y + 24), Vector2(x, room.position.y + 188), Color("#65747c"), 1.0)
	for y in [56, 96, 150, 190]:
		draw_line(Vector2(room.position.x + 16, room.position.y + y), Vector2(room.end.x - 16, room.position.y + y), Color("#65747c"), 2.0)
	draw_rect(Rect2(room.position + Vector2(16, 8), Vector2(room.size.x - 32, 16)), Color("#222d35"))
	draw_rect(Rect2(room.position + Vector2(16, 188), Vector2(room.size.x - 32, 10)), Color("#222d35"))


func _draw_floor(room: Rect2) -> void:
	draw_rect(Rect2(room.position + Vector2(16, 198), Vector2(room.size.x - 32, room.size.y - 234)), Color("#d6e0df"))
	draw_rect(Rect2(room.position + Vector2(16, room.size.y - 96), Vector2(room.size.x - 32, 72)), Color("#e4ba42"))
	for x in range(32, int(room.size.x) - 32, 64):
		for y in range(216, int(room.size.y) - 116, 64):
			draw_rect(Rect2(room.position + Vector2(x, y), Vector2(63, 63)), Color(0.12, 0.20, 0.22, 0.06), false, 1.0)
	for x in range(32, int(room.size.x) - 32, 64):
		ArtAssetsScript.draw_metro_prop(self, "tactile_straight", room.position + Vector2(x, room.size.y - 96))


func _draw_ceiling_lights(room: Rect2) -> void:
	for x in [80, 384, 688, 992]:
		ArtAssetsScript.draw_metro_prop(self, "ceiling_light", room.position + Vector2(x, 26), 1.15)
		draw_circle(room.position + Vector2(x + 38, 96), 86, Color(1.0, 0.88, 0.54, 0.06))


func _draw_platform_doors(room: Rect2) -> void:
	for x in range(64, int(room.size.x) - 96, 128):
		ArtAssetsScript.draw_metro_prop(self, "platform_door", room.position + Vector2(x, 124), 1.35)
	for x in [320, 800]:
		ArtAssetsScript.draw_metro_prop(self, "pillar", room.position + Vector2(x, 78), 1.55)


func _draw_floor_grid(room: Rect2) -> void:
	var floor_rect := Rect2(room.position + Vector2(16, 198), Vector2(room.size.x - 32, room.size.y - 222))
	ArtAssetsScript.draw_pixel_grid(self, floor_rect, 64, Color(0.28, 0.35, 0.39, 0.24))


func _draw_tactile_paths(room: Rect2) -> void:
	for x in range(32, int(room.size.x) - 32, 64):
		ArtAssetsScript.draw_metro_prop(self, "tactile_straight", room.position + Vector2(x, 264))
	for y in range(264, int(room.size.y) - 96, 64):
		ArtAssetsScript.draw_metro_prop(self, "tactile_straight", room.position + Vector2(960, y))
	ArtAssetsScript.draw_metro_prop(self, "tactile_turn", room.position + Vector2(960, 264))
	ArtAssetsScript.draw_metro_prop(self, "floor_arrow", room.position + Vector2(400, room.size.y - 142))
	ArtAssetsScript.draw_metro_prop(self, "floor_arrow", room.position + Vector2(760, room.size.y - 142))


func _draw_station_signage(room: Rect2) -> void:
	ArtAssetsScript.draw_metro_prop(self, "line_sign", room.position + Vector2(486, 142), 1.75)
	ArtAssetsScript.draw_metro_prop(self, "exit_sign", room.position + Vector2(928, 142), 1.75)
	ArtAssetsScript.draw_metro_prop(self, "ad_lightbox", room.position + Vector2(72, 104), 1.45)
	ArtAssetsScript.draw_metro_prop(self, "ad_lightbox", room.position + Vector2(504, 104), 1.45)
	ArtAssetsScript.draw_metro_prop(self, "ad_lightbox", room.position + Vector2(1030, 104), 1.25)
	ArtAssetsScript.draw_metro_prop(self, "warning_sign", room.position + Vector2(808, 124), 0.86)


func _draw_ticket_machines(pos: Vector2) -> void:
	for i in range(4):
		ArtAssetsScript.draw_metro_prop(self, "ticket_machine", pos + Vector2(i * 94, 0), 1.18)


func _draw_ticket_gates(pos: Vector2) -> void:
	for i in range(5):
		var prop_name := "ticket_gate_open" if i == 1 or i == 4 else "ticket_gate_closed"
		ArtAssetsScript.draw_metro_prop(self, prop_name, pos + Vector2(i * 78, 0), 1.1)
	ArtAssetsScript.draw_metro_prop(self, "rail_barrier", pos + Vector2(-148, 14), 1.2)


func _draw_info_area(room: Rect2) -> void:
	ArtAssetsScript.draw_metro_prop(self, "info_kiosk", room.position + Vector2(48, 404), 1.24)
	ArtAssetsScript.draw_metro_prop(self, "trash_bin", room.position + Vector2(1066, 292), 1.0)
	ArtAssetsScript.draw_metro_prop(self, "rail_barrier", room.position + Vector2(642, 430), 1.7)


func _draw_bench_and_commuters(room: Rect2) -> void:
	var bench_pos := room.position + Vector2(76, 552)
	draw_rect(Rect2(bench_pos, Vector2(114, 16)), Color("#4b4540"))
	for i in range(4):
		draw_rect(Rect2(bench_pos + Vector2(8 + i * 26, 16), Vector2(4, 18)), Color("#2f343a"))
	ArtAssetsScript.draw_character_frame(self, "metro_commuter", room.position + Vector2(174, 594), false, 0.70, Color(1, 1, 1, 0.92), Vector2.LEFT)
	ArtAssetsScript.draw_character_frame(self, "office_worker", room.position + Vector2(664, 250), false, 0.70, Color(1, 1, 1, 0.88), Vector2.DOWN)
	ArtAssetsScript.draw_character_frame(self, "drifter_girl", room.position + Vector2(776, 522), false, 0.70, Color(1, 1, 1, 0.88), Vector2.RIGHT)
	ArtAssetsScript.draw_character_frame(self, "metro_commuter", room.position + Vector2(486, 628), false, 0.70, Color(1, 1, 1, 0.88), Vector2.RIGHT)
	ArtAssetsScript.draw_character_frame(self, "office_worker", room.position + Vector2(1054, 240), false, 0.70, Color(1, 1, 1, 0.86), Vector2.UP)


func _draw_stairs(pos: Vector2) -> void:
	draw_rect(Rect2(pos + Vector2(2, 3), Vector2(156, 64)), Color(0.02, 0.03, 0.04, 0.24))
	draw_rect(Rect2(pos, Vector2(156, 64)), Color("#38485a"))
	for i in range(5):
		draw_line(pos + Vector2(12, 12 + i * 10), pos + Vector2(144, 12 + i * 10), Color("#7d8790"), 2.0)
	draw_rect(Rect2(pos + Vector2(48, -18), Vector2(64, 12)), Color("#a9d7ff"))
	draw_rect(Rect2(pos + Vector2(56, -14), Vector2(48, 4)), Color("#2f3d4f"))


func _draw_light_overlay(room: Rect2) -> void:
	if current_weather == "rain":
		draw_rect(room, Color(0.08, 0.12, 0.16, 0.12))
	if current_segment == "morning":
		draw_circle(room.position + Vector2(608, 420), 220, Color(0.70, 0.88, 1.0, 0.05))
	elif current_segment == "evening":
		draw_rect(room, Color(0.10, 0.10, 0.17, 0.12))
		draw_circle(room.position + Vector2(608, 340), 260, Color(1.0, 0.77, 0.38, 0.05))
	elif current_segment == "late_night":
		draw_rect(room, Color(0.06, 0.08, 0.18, 0.26))
		draw_circle(room.position + Vector2(608, 350), 220, Color(0.55, 0.78, 1.0, 0.05))


func _create_boundaries() -> void:
	var room := get_world_rect()
	_add_collision_rect("metro_north_wall", room.position, Vector2(room.size.x, 12))
	_add_collision_rect("metro_south_wall_left", room.position + Vector2(0, room.size.y - 12), Vector2(496, 12))
	_add_collision_rect("metro_south_wall_right", room.position + Vector2(692, room.size.y - 12), Vector2(room.size.x - 692, 12))
	_add_collision_rect("metro_west_wall", room.position, Vector2(12, room.size.y))
	_add_collision_rect("metro_east_wall", room.position + Vector2(room.size.x - 12, 0), Vector2(12, room.size.y))


func _create_station_collisions() -> void:
	var origin := get_world_rect().position
	_add_collision_rect("metro_platform_wall", origin + Vector2(16, 16), Vector2(1184, 182))
	_add_collision_rect("metro_ticket_machines_collision", origin + Vector2(204, 342), Vector2(356, 76))
	_add_collision_rect("metro_gate_collision", origin + Vector2(752, 372), Vector2(390, 78))
	_add_collision_rect("metro_info_kiosk_collision", origin + Vector2(48, 404), Vector2(78, 78))
	_add_collision_rect("metro_rail_barrier_collision", origin + Vector2(642, 430), Vector2(108, 48))
	_add_collision_rect("metro_trash_collision", origin + Vector2(1066, 292), Vector2(64, 58))
	_add_collision_rect("metro_bench_collision", origin + Vector2(76, 552), Vector2(114, 34))
	_add_collision_rect("metro_stairs_collision", origin + Vector2(512, 590), Vector2(156, 64))


func _create_interactables() -> void:
	var origin := get_world_rect().position
	_add_interactable({
		"id": "metro_gate",
		"name": "地铁闸机",
		"kind": "metro_commute",
		"prompt": "按 E 通勤去公司",
		"position": origin + Vector2(948, 468),
		"size": Vector2(148, 44),
		"fill_color": Color(0.55, 0.76, 0.95, 0.18),
		"border_color": Color("#a9d7ff"),
	})
	_add_interactable({
		"id": "ticket_machine",
		"name": "售票机",
		"kind": "dialogue",
		"prompt": "按 E 查看车票",
		"position": origin + Vector2(382, 430),
		"size": Vector2(220, 42),
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
		"position": origin + Vector2(620, 244),
		"size": Vector2(160, 42),
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
		"position": origin + Vector2(594, 646),
		"size": Vector2(160, 48),
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
