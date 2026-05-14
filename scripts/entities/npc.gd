extends CharacterBody2D
class_name LifeNpc

const WALK_SPEED := 34.0
const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $Interactable
@onready var interaction_shape: CollisionShape2D = $Interactable/InteractionShape

var npc_id := ""
var npc_name := "NPC"
var role := ""
var palette := {
	"hair": Color("#2b2527"),
	"skin": Color("#d0a06f"),
	"shirt": Color("#7b8b5d"),
}
var dialogue_by_segment: Dictionary = {}
var routes_by_segment: Dictionary = {}
var current_segment := "morning"
var relationship := 0
var route_points: Array[Vector2] = []
var route_index := 0
var walk_clock := 0.0
var facing := Vector2.DOWN


func configure(data: Dictionary) -> void:
	npc_id = data.get("id", "")
	npc_name = data.get("name", "NPC")
	role = data.get("role", "")
	palette = data.get("palette", palette)
	dialogue_by_segment = data.get("dialogue", {})
	routes_by_segment = data.get("routes", {})
	global_position = data.get("position", Vector2.ZERO)
	current_segment = data.get("segment", "morning")
	_apply_segment_route(current_segment, false)


func _ready() -> void:
	z_index = 9

	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 9)
	body_shape.shape = shape
	body_shape.position = Vector2(0, 5)

	var interact_shape := CircleShape2D.new()
	interact_shape.radius = 16
	interaction_shape.shape = interact_shape
	interaction_area.collision_layer = 4
	interaction_area.collision_mask = 0
	interaction_area.set_meta("interactable_node", self)
	queue_redraw()


func set_time_segment(segment_key: String) -> void:
	current_segment = segment_key
	_apply_segment_route(segment_key, true)


func get_prompt() -> String:
	return "按 E 与%s说话  好感 %d" % [npc_name, relationship]


func set_relationship(value: int) -> void:
	relationship = value


func interact(game: Node) -> void:
	var lines := _get_dialogue_lines()
	if game.has_method("register_npc_talk"):
		var result = game.call("register_npc_talk", npc_id)
		if result is String and not result.is_empty():
			lines = lines.duplicate()
			lines.append(result)
	if game.has_method("show_dialogue"):
		game.call("show_dialogue", npc_name, lines)


func _physics_process(delta: float) -> void:
	if route_points.size() <= 1:
		velocity = Vector2.ZERO
		queue_redraw()
		return

	var target := route_points[route_index]
	var to_target := target - global_position
	if to_target.length() <= 2.0:
		route_index = (route_index + 1) % route_points.size()
		target = route_points[route_index]
		to_target = target - global_position

	var direction := to_target.normalized()
	velocity = direction * WALK_SPEED
	move_and_slide()
	if velocity.length() > 0.1:
		walk_clock += delta
		facing = _snap_facing(direction)
	queue_redraw()


func _draw() -> void:
	var stepping := velocity.length() > 0.1
	var bob := 0
	if stepping:
		bob = int(sin(walk_clock * 14.0))

	_draw_ellipse(Rect2(Vector2(-7, 7), Vector2(14, 5)), Color(0.04, 0.04, 0.05, 0.28))
	ArtAssetsScript.draw_character_centered(self, _get_character_asset_name(), Vector2(0, -1 + bob), stepping, 0.72, Color.WHITE, facing)

	if role == "shopkeeper":
		draw_rect(Rect2(-6, 1 + bob, 12, 2), Color("#f2d06b"))
	elif role == "landlord":
		draw_rect(Rect2(-6, 3 + bob, 12, 2), Color("#66594c"))
	elif role == "drifter":
		draw_rect(Rect2(5, -2 + bob, 3, 8), Color("#b84253"))
	elif role == "delivery_rider":
		draw_rect(Rect2(-6, 3 + bob, 12, 2), Color("#7a5d23"))
	elif role == "streamer":
		draw_rect(Rect2(-5, -9 + bob, 10, 1), Color("#ffc4d6"))
	elif role == "office_worker":
		draw_rect(Rect2(-1, 1 + bob, 2, 7), Color("#3b4650"))
	elif role == "metro_commuter":
		draw_rect(Rect2(5, -1 + bob, 3, 8), Color("#2f5d45"))


func _apply_segment_route(segment_key: String, warp_to_first_point: bool) -> void:
	var raw_route = routes_by_segment.get(segment_key, routes_by_segment.get("default", []))
	route_points.clear()
	for point in raw_route:
		if point is Vector2:
			route_points.append(point)

	route_index = 0
	if warp_to_first_point and route_points.size() > 0:
		global_position = route_points[0]


func _draw_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.position + rect.size * 0.5
	var radius := rect.size * 0.5
	for i in range(18):
		var angle := TAU * float(i) / 18.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _get_dialogue_lines() -> Array:
	var fallback := dialogue_by_segment.get("default", ["今天也要好好活着。"])
	return dialogue_by_segment.get(current_segment, fallback)


func _get_character_asset_name() -> String:
	match role:
		"landlord":
			return "landlord"
		"shopkeeper":
			return "shopkeeper"
		"drifter":
			return "drifter_girl"
		"delivery_rider":
			return "delivery_rider"
		"streamer":
			return "streamer"
		"office_worker":
			return "office_worker"
		"metro_commuter":
			return "metro_commuter"
		_:
			return "office_worker"


func _snap_facing(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP
