extends CharacterBody2D
class_name Player

signal interact_pressed(interactable: Node)
signal focused_interactable_changed(interactable: Node)

const WALK_SPEED := 82.0
const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

@onready var body_shape: CollisionShape2D = $CollisionShape2D
@onready var interaction_area: Area2D = $InteractionArea
@onready var interaction_shape: CollisionShape2D = $InteractionArea/InteractionShape
@onready var camera: Camera2D = $Camera2D

var controls_enabled := true
var facing := Vector2.DOWN
var nearby_interactables: Array[Node] = []
var focused_interactable: Node = null
var walk_clock := 0.0


func _ready() -> void:
	add_to_group("player")
	z_index = 10

	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 9)
	body_shape.shape = shape
	body_shape.position = Vector2(0, 5)

	var interact_shape := CircleShape2D.new()
	interact_shape.radius = 15
	interaction_shape.shape = interact_shape

	interaction_area.area_entered.connect(_on_interaction_area_entered)
	interaction_area.area_exited.connect(_on_interaction_area_exited)
	camera.make_current()
	_update_interaction_area()
	queue_redraw()


func set_controls_enabled(enabled: bool) -> void:
	controls_enabled = enabled
	if not enabled:
		velocity = Vector2.ZERO
		queue_redraw()


func set_camera_limits(world_rect: Rect2) -> void:
	camera.limit_left = int(world_rect.position.x)
	camera.limit_top = int(world_rect.position.y)
	camera.limit_right = int(world_rect.end.x)
	camera.limit_bottom = int(world_rect.end.y)


func clear_interaction_focus() -> void:
	nearby_interactables.clear()
	focused_interactable = null
	focused_interactable_changed.emit(null)


func _physics_process(delta: float) -> void:
	var input_vector := Vector2.ZERO
	if controls_enabled:
		input_vector = Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if input_vector.length() > 0.0:
			input_vector = input_vector.normalized()
			facing = _snap_facing(input_vector)

	velocity = input_vector * WALK_SPEED
	move_and_slide()

	if velocity.length() > 0.1:
		walk_clock += delta

	_update_interaction_area()
	_refresh_focus()
	queue_redraw()

	if controls_enabled and Input.is_action_just_pressed("interact"):
		var target := _get_best_interactable()
		if target != null:
			interact_pressed.emit(target)


func _draw() -> void:
	var stepping := velocity.length() > 0.1
	var bob := 0
	if stepping:
		bob = int(sin(walk_clock * 18.0))

	var shadow_color := Color(0.05, 0.06, 0.07, 0.32)
	_draw_ellipse(Rect2(Vector2(-7, 7), Vector2(14, 5)), shadow_color)

	ArtAssetsScript.draw_character_centered(self, "player_grad", Vector2(0, -5 + bob), stepping, 0.42, Color.WHITE, facing)


func _snap_facing(direction: Vector2) -> Vector2:
	if absf(direction.x) > absf(direction.y):
		return Vector2.RIGHT if direction.x > 0.0 else Vector2.LEFT
	return Vector2.DOWN if direction.y > 0.0 else Vector2.UP


func _draw_ellipse(rect: Rect2, color: Color) -> void:
	var points := PackedVector2Array()
	var center := rect.position + rect.size * 0.5
	var radius := rect.size * 0.5
	for i in range(18):
		var angle := TAU * float(i) / 18.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)


func _update_interaction_area() -> void:
	interaction_area.position = facing * 14.0 + Vector2(0, 2)


func _on_interaction_area_entered(area: Area2D) -> void:
	var interactable := _resolve_interactable(area)
	if interactable != null and not nearby_interactables.has(interactable):
		nearby_interactables.append(interactable)
		_refresh_focus()


func _on_interaction_area_exited(area: Area2D) -> void:
	var interactable := _resolve_interactable(area)
	if interactable != null:
		nearby_interactables.erase(interactable)
		_refresh_focus()


func _resolve_interactable(area: Area2D) -> Node:
	if area.has_meta("interactable_node"):
		var meta_value: Variant = area.get_meta("interactable_node")
		if meta_value is Node:
			return meta_value

	var node: Node = area
	while node != null:
		if node.has_method("interact"):
			return node
		node = node.get_parent()
	return null


func _refresh_focus() -> void:
	var next_focus := _get_best_interactable()
	if next_focus != focused_interactable:
		focused_interactable = next_focus
		focused_interactable_changed.emit(focused_interactable)


func _get_best_interactable() -> Node:
	var best: Node = null
	var best_distance := INF
	for interactable in nearby_interactables:
		if not is_instance_valid(interactable):
			continue
		var interactable_2d := interactable as Node2D
		if interactable_2d == null:
			continue
		var distance := global_position.distance_squared_to(interactable_2d.global_position)
		if distance < best_distance:
			best_distance = distance
			best = interactable
	return best
