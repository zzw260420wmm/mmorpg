extends Area2D
class_name WorldInteractable

var interactable_id := ""
var display_name := ""
var kind := "dialogue"
var prompt := "按 E 互动"
var interaction_size := Vector2(28, 22)
var lines_by_segment: Dictionary = {}
var fill_color := Color(1.0, 0.86, 0.42, 0.24)
var border_color := Color("#f4d77a")


func configure(data: Dictionary) -> void:
	interactable_id = data.get("id", "")
	display_name = data.get("name", "互动点")
	kind = data.get("kind", "dialogue")
	prompt = data.get("prompt", "按 E 互动")
	interaction_size = data.get("size", interaction_size)
	lines_by_segment = data.get("lines", {})
	fill_color = data.get("fill_color", fill_color)
	border_color = data.get("border_color", border_color)
	global_position = data.get("position", Vector2.ZERO)


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable_node", self)
	_ensure_collision_shape()
	queue_redraw()


func get_prompt() -> String:
	return prompt


func interact(game: Node) -> void:
	match kind:
		"enter_apartment":
			if game.has_method("enter_apartment"):
				game.call("enter_apartment")
		"exit_apartment":
			if game.has_method("exit_apartment"):
				game.call("exit_apartment")
		"commute":
			if game.has_method("request_commute_work"):
				game.call("request_commute_work")
		"enter_metro":
			if game.has_method("inspect_metro_station"):
				game.call("inspect_metro_station", self)
			elif game.has_method("enter_metro_station"):
				game.call("enter_metro_station")
		"exit_metro":
			if game.has_method("exit_metro_station"):
				game.call("exit_metro_station")
		"metro_commute":
			if game.has_method("request_commute_work"):
				game.call("request_commute_work")
		"clinic":
			if game.has_method("request_clinic_visit"):
				game.call("request_clinic_visit")
		"rental_agency":
			if game.has_method("inspect_rental_agency"):
				game.call("inspect_rental_agency", self)
		"talent_apartment":
			if game.has_method("inspect_talent_apartment"):
				game.call("inspect_talent_apartment", self)
		"office":
			if game.has_method("inspect_office"):
				game.call("inspect_office", self)
		"media_company":
			if game.has_method("inspect_media_company"):
				game.call("inspect_media_company", self)
		"job":
			if game.has_method("request_job_work"):
				game.call("request_job_work", interactable_id)
		"exit_office":
			if game.has_method("exit_office"):
				game.call("exit_office")
		"exit_media_company":
			if game.has_method("exit_media_company"):
				game.call("exit_media_company")
		"delivery_station":
			if game.has_method("request_delivery_order"):
				game.call("request_delivery_order")
		"delivery_pickup":
			if game.has_method("request_delivery_pickup"):
				game.call("request_delivery_pickup")
		"delivery_dropoff":
			if game.has_method("request_delivery_dropoff"):
				game.call("request_delivery_dropoff")
		"sleep":
			if game.has_method("request_sleep"):
				game.call("request_sleep")
		"shop":
			if game.has_method("open_shop"):
				game.call("open_shop", self)
		"fridge":
			if game.has_method("request_fridge_food"):
				game.call("request_fridge_food")
		"rent":
			if game.has_method("request_pay_rent"):
				game.call("request_pay_rent")
		_:
			if game.has_method("show_dialogue"):
				game.call("show_dialogue", display_name, _get_lines(game))


func _draw() -> void:
	var rect := Rect2(-interaction_size * 0.5, interaction_size)
	draw_rect(rect, fill_color)
	draw_rect(rect, border_color, false, 1.0)


func _ensure_collision_shape() -> void:
	var collision_shape: CollisionShape2D = null
	for child in get_children():
		if child is CollisionShape2D:
			collision_shape = child
			break

	if collision_shape == null:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)

	var shape := RectangleShape2D.new()
	shape.size = interaction_size
	collision_shape.shape = shape


func _get_lines(game: Node) -> Array:
	var key := "default"
	if game != null:
		var manager = game.get("time_manager")
		if manager != null and manager.has_method("get_segment_key"):
			key = str(manager.call("get_segment_key"))
	var fallback := lines_by_segment.get("default", ["这里暂时没有更多事情。"])
	return lines_by_segment.get(key, fallback)
