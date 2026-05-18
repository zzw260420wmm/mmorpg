extends Node2D
class_name ShanghaiMansionInterior

const WorldInteractableScript := preload("res://scripts/world/world_interactable.gd")

const ROOM_SIZE := Vector2(960, 640)

var invited_guests: Array[String] = []


func _ready() -> void:
	z_index = 0
	_create_boundaries()
	_create_interactables()
	queue_redraw()


func get_player_spawn() -> Vector2:
	return Vector2(480, 540)


func get_exit_spawn() -> Vector2:
	return Vector2(480, 590)


func get_world_rect() -> Rect2:
	return Rect2(Vector2.ZERO, ROOM_SIZE)


func set_guests(guests: Array[String]) -> void:
	invited_guests = guests.duplicate()
	_refresh_guest_interactables()
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, ROOM_SIZE), Color("#2f2a24"))
	draw_rect(Rect2(Vector2(72, 72), Vector2(816, 496)), Color("#4a3828"))
	draw_rect(Rect2(Vector2(104, 104), Vector2(752, 432)), Color("#6b4f34"), false, 4.0)
	draw_rect(Rect2(Vector2(140, 124), Vector2(220, 86)), Color("#2d3b42"))
	draw_rect(Rect2(Vector2(600, 124), Vector2(180, 86)), Color("#2d3b42"))
	draw_rect(Rect2(Vector2(374, 238), Vector2(212, 92)), Color("#8a673d"))
	draw_rect(Rect2(Vector2(406, 270), Vector2(148, 24)), Color("#e8c879"))
	draw_rect(Rect2(Vector2(180, 420), Vector2(600, 42)), Color("#3d2d21"))
	draw_rect(Rect2(Vector2(430, 548), Vector2(100, 46)), Color("#1b1a18"))
	for i in range(5):
		var x := 172 + i * 150
		draw_rect(Rect2(Vector2(x, 426), Vector2(58, 28)), Color("#caa66a"))


func _create_boundaries() -> void:
	var boundaries := StaticBody2D.new()
	boundaries.name = "MansionBoundaries"
	add_child(boundaries)
	_add_wall(boundaries, Vector2(ROOM_SIZE.x * 0.5, -16), Vector2(ROOM_SIZE.x, 32))
	_add_wall(boundaries, Vector2(ROOM_SIZE.x * 0.5, ROOM_SIZE.y + 16), Vector2(ROOM_SIZE.x, 32))
	_add_wall(boundaries, Vector2(-16, ROOM_SIZE.y * 0.5), Vector2(32, ROOM_SIZE.y))
	_add_wall(boundaries, Vector2(ROOM_SIZE.x + 16, ROOM_SIZE.y * 0.5), Vector2(32, ROOM_SIZE.y))


func _add_wall(body: StaticBody2D, position: Vector2, size: Vector2) -> void:
	var shape := RectangleShape2D.new()
	shape.size = size
	var collision := CollisionShape2D.new()
	collision.position = position
	collision.shape = shape
	body.add_child(collision)


func _create_interactables() -> void:
	_add_interactable({
		"id": "mansion_exit",
		"name": "返回上海街头",
		"kind": "exit_shanghai_mansion",
		"prompt": "按 E 离开公馆",
		"position": get_exit_spawn(),
		"size": Vector2(116, 38),
		"fill_color": Color(0.86, 0.64, 0.38, 0.20),
		"border_color": Color("#e8c879"),
	})
	_refresh_guest_interactables()


func _refresh_guest_interactables() -> void:
	for child in get_children():
		if child is WorldInteractable and (child as WorldInteractable).kind == "mansion_guest":
			child.queue_free()
	var guest_positions := [Vector2(236, 396), Vector2(480, 388), Vector2(708, 396), Vector2(330, 250), Vector2(634, 250)]
	for i in range(invited_guests.size()):
		var guest_id := str(invited_guests[i])
		_add_interactable({
			"id": guest_id,
			"name": _get_guest_name(guest_id),
			"kind": "mansion_guest",
			"prompt": "按 E 交谈",
			"position": guest_positions[i % guest_positions.size()],
			"size": Vector2(96, 34),
			"fill_color": Color(0.78, 0.55, 0.62, 0.22),
			"border_color": Color("#ffc4d6"),
		})


func _get_guest_name(guest_id: String) -> String:
	match guest_id:
		"republic_companion_writer":
			return "报馆女作者"
		"republic_companion_singer":
			return "爵士歌者"
		"tang_companion_scholar":
			return "女史学者"
		_:
			return "历史来客"


func _add_interactable(data: Dictionary) -> void:
	var interactable: WorldInteractable = WorldInteractableScript.new()
	interactable.configure(data)
	add_child(interactable)
