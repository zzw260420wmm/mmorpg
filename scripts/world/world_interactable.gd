extends Area2D
class_name WorldInteractable

const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

var interactable_id := ""
var display_name := ""
var kind := "dialogue"
var prompt := "按 E 互动"
var interaction_size := Vector2(28, 22)
var lines_by_segment: Dictionary = {}
var fill_color := Color(1.0, 0.86, 0.42, 0.24)
var border_color := Color("#f4d77a")
var task_guide_anim_clock := 0.0
var marker_pulse_clock := 0.0


func configure(data: Dictionary) -> void:
	interactable_id = data.get("id", "")
	display_name = data.get("name", "Interactable")
	kind = data.get("kind", "dialogue")
	prompt = data.get("prompt", "按 E 互动")
	interaction_size = data.get("size", interaction_size)
	lines_by_segment = data.get("lines", {})
	fill_color = data.get("fill_color", fill_color)
	border_color = data.get("border_color", border_color)
	global_position = data.get("position", Vector2.ZERO)
	if is_inside_tree():
		set_process(_uses_task_guide_sprite() or _uses_interaction_marker())
		queue_redraw()


func _ready() -> void:
	collision_layer = 4
	collision_mask = 0
	set_meta("interactable_node", self)
	_ensure_collision_shape()
	set_process(_uses_task_guide_sprite() or _uses_interaction_marker())
	queue_redraw()


func get_prompt() -> String:
	return prompt


func interact(game: Node) -> void:
	match kind:
		"enter_apartment":
			if game.has_method("enter_apartment_from"):
				game.call("enter_apartment_from", self)
			elif game.has_method("enter_apartment"):
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
		"enter_wet_market":
			if game.has_method("enter_wet_market"):
				game.call("enter_wet_market")
		"exit_wet_market":
			if game.has_method("exit_wet_market"):
				game.call("exit_wet_market")
		"enter_clinic":
			if game.has_method("enter_clinic"):
				game.call("enter_clinic")
		"exit_clinic":
			if game.has_method("exit_clinic"):
				game.call("exit_clinic")
		"metro_commute":
			if game.has_method("request_commute_work"):
				game.call("request_commute_work")
		"clinic":
			if game.has_method("request_clinic_visit"):
				game.call("request_clinic_visit")
		"rental_agency":
			if game.has_method("open_housing_agency"):
				game.call("open_housing_agency", self)
			elif game.has_method("inspect_rental_agency"):
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
		"internet_cafe":
			if game.has_method("enter_internet_cafe"):
				game.call("enter_internet_cafe")
		"job":
			if game.has_method("request_job_work"):
				game.call("request_job_work", interactable_id)
		"exit_office":
			if game.has_method("exit_office"):
				game.call("exit_office")
		"exit_media_company":
			if game.has_method("exit_media_company"):
				game.call("exit_media_company")
		"exit_internet_cafe":
			if game.has_method("exit_internet_cafe"):
				game.call("exit_internet_cafe")
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
		"high_speed_rail":
			if game.has_method("open_high_speed_rail"):
				game.call("open_high_speed_rail", self)
		"city_home":
			if game.has_method("rest_at_city_home"):
				game.call("rest_at_city_home", self)
		"city_work":
			if game.has_method("request_city_basic_work"):
				game.call("request_city_basic_work", self)
		"city_task":
			if game.has_method("request_city_task"):
				game.call("request_city_task", self)
		"enter_qikai_district":
			if game.has_method("enter_qikai_district_from"):
				game.call("enter_qikai_district_from", self)
		"exit_qikai_district":
			if game.has_method("exit_qikai_district"):
				game.call("exit_qikai_district")
		"enter_faw_factory":
			if game.has_method("enter_faw_factory_from"):
				game.call("enter_faw_factory_from", self)
		"exit_faw_factory":
			if game.has_method("exit_faw_factory"):
				game.call("exit_faw_factory")
		"enter_tang_changan":
			if game.has_method("enter_tang_changan_from"):
				game.call("enter_tang_changan_from", self)
		"exit_tang_changan":
			if game.has_method("exit_tang_changan"):
				game.call("exit_tang_changan")
		"enter_republic_shanghai":
			if game.has_method("enter_republic_shanghai_from"):
				game.call("enter_republic_shanghai_from", self)
		"exit_republic_shanghai":
			if game.has_method("exit_republic_shanghai"):
				game.call("exit_republic_shanghai")
		"enter_shanghai_mansion":
			if game.has_method("enter_shanghai_mansion_from"):
				game.call("enter_shanghai_mansion_from", self)
		"exit_shanghai_mansion":
			if game.has_method("exit_shanghai_mansion"):
				game.call("exit_shanghai_mansion")
		"mansion_guest":
			if game.has_method("interact_mansion_guest"):
				game.call("interact_mansion_guest", self)
		"archaeology_task":
			if game.has_method("request_archaeology_task"):
				game.call("request_archaeology_task", self)
		"private_museum":
			if game.has_method("inspect_private_museum"):
				game.call("inspect_private_museum", self)
		"historical_collectible":
			if game.has_method("collect_historical_item"):
				game.call("collect_historical_item", self)
		"historical_companion":
			if game.has_method("meet_historical_companion"):
				game.call("meet_historical_companion", self)
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
	var rect: Rect2 = Rect2(-interaction_size * 0.5, interaction_size)
	draw_rect(rect, fill_color)
	draw_rect(rect, border_color, false, 1.0)
	if _uses_task_guide_sprite():
		_draw_task_guide_sprite()
	elif _uses_interaction_marker():
		_draw_interaction_marker(Vector2(0.0, -24.0))


func _process(delta: float) -> void:
	if not _uses_task_guide_sprite() and not _uses_interaction_marker():
		return
	if _uses_task_guide_sprite():
		task_guide_anim_clock += delta
	if _uses_interaction_marker():
		marker_pulse_clock += delta
	queue_redraw()


func _uses_task_guide_sprite() -> bool:
	return kind == "city_task" or kind == "archaeology_task" or kind == "historical_collectible"


func _task_guide_direction() -> Vector2:
	if kind == "archaeology_task":
		return Vector2.LEFT
	if kind == "historical_collectible":
		return Vector2.RIGHT
	return Vector2.DOWN


func _draw_task_guide_sprite() -> void:
	var frame_index: int = int(floor(task_guide_anim_clock * 6.0)) % 4
	var guide_center: Vector2 = Vector2(0.0, -44.0)
	var marker_center: Vector2 = Vector2(0.0, -86.0)
	ArtAssetsScript.draw_task_guide_frame(self, guide_center, frame_index, _task_guide_direction(), 0.42)
	_draw_interaction_marker(marker_center)


func _uses_interaction_marker() -> bool:
	return _get_marker_category() != "none"


func _get_marker_category() -> String:
	match kind:
		"city_task", "archaeology_task":
			return "quest"
		"historical_collectible", "historical_companion", "enter_republic_shanghai", "enter_tang_changan", "enter_shanghai_mansion", "mansion_guest", "private_museum":
			return "history"
		"delivery_station", "delivery_pickup", "delivery_dropoff":
			return "delivery"
		"city_work", "office", "media_company", "job":
			return "work"
		"city_home", "enter_apartment", "sleep", "fridge", "rent", "shop", "clinic", "rental_agency":
			return "life"
		"high_speed_rail", "enter_metro", "metro_commute", "commute":
			return "travel"
	return "none"


func _get_marker_color(category: String) -> Color:
	match category:
		"quest":
			return Color("#ffe08a")
		"history":
			return Color("#9ed5ff")
		"delivery":
			return Color("#9fe7a4")
		"work":
			return Color("#f0b96d")
		"life":
			return Color("#f4d7a1")
		"travel":
			return Color("#a8c7ff")
	return Color("#ffe08a")


func _draw_interaction_marker(center: Vector2) -> void:
	var category: String = _get_marker_category()
	if category == "none":
		return
	var pulse: float = sin(marker_pulse_clock * 4.0) * 0.8
	var radius: float = 8.0 + pulse
	var color: Color = _get_marker_color(category)
	draw_circle(center + Vector2(1.0, 2.0), radius + 0.8, Color(0.18, 0.12, 0.07, 0.30))
	draw_circle(center, radius, color)
	draw_arc(center, radius + 2.0, -PI * 0.15, PI * 1.15, 14, Color(color.r, color.g, color.b, 0.32), 1.0)
	_draw_marker_symbol(category, center)


func _draw_marker_symbol(category: String, center: Vector2) -> void:
	var ink: Color = Color(0.20, 0.14, 0.08, 0.95)
	match category:
		"quest":
			draw_line(center + Vector2(0.0, -4.5), center + Vector2(0.0, 1.5), ink, 2.0)
			draw_circle(center + Vector2(0.0, 4.5), 1.4, ink)
		"history":
			var points: PackedVector2Array = PackedVector2Array([
				center + Vector2(0.0, -5.5),
				center + Vector2(2.0, -1.5),
				center + Vector2(5.5, 0.0),
				center + Vector2(2.0, 1.5),
				center + Vector2(0.0, 5.5),
				center + Vector2(-2.0, 1.5),
				center + Vector2(-5.5, 0.0),
				center + Vector2(-2.0, -1.5),
			])
			draw_colored_polygon(points, ink)
		"delivery":
			draw_line(center + Vector2(-4.0, -3.0), center + Vector2(4.0, -3.0), ink, 2.0)
			draw_line(center + Vector2(4.0, -3.0), center + Vector2(4.0, 3.0), ink, 2.0)
			draw_line(center + Vector2(4.0, 3.0), center + Vector2(-1.0, 3.0), ink, 2.0)
			draw_line(center + Vector2(-1.0, 3.0), center + Vector2(-4.0, 0.0), ink, 2.0)
			draw_line(center + Vector2(-4.0, 0.0), center + Vector2(-1.0, -3.0), ink, 2.0)
		"work":
			draw_rect(Rect2(center + Vector2(-5.0, -2.0), Vector2(10.0, 7.0)), ink, false, 2.0)
			draw_line(center + Vector2(-2.5, -3.0), center + Vector2(2.5, -3.0), ink, 2.0)
		"life":
			draw_line(center + Vector2(-5.0, 0.0), center + Vector2(0.0, -5.0), ink, 2.0)
			draw_line(center + Vector2(0.0, -5.0), center + Vector2(5.0, 0.0), ink, 2.0)
			draw_rect(Rect2(center + Vector2(-3.5, 0.0), Vector2(7.0, 5.0)), ink, false, 2.0)
		"travel":
			draw_line(center + Vector2(-5.0, 2.0), center + Vector2(4.0, -3.5), ink, 2.0)
			draw_line(center + Vector2(4.0, -3.5), center + Vector2(2.0, 3.5), ink, 2.0)
			draw_line(center + Vector2(2.0, 3.5), center + Vector2(-1.0, 0.5), ink, 2.0)


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
		var manager: Variant = game.get("time_manager")
		if manager != null and manager.has_method("get_segment_key"):
			key = str(manager.call("get_segment_key"))
	var fallback: Array = lines_by_segment.get("default", ["这里暂时没有别的事可做。"])
	var lines: Array = lines_by_segment.get(key, fallback)
	return lines
