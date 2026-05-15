extends CanvasLayer
class_name GameHUD

const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

signal dialogue_closed
signal shop_closed
signal shop_item_selected(item: Dictionary)
signal inventory_item_used(index: int)

var status_panel: PanelContainer
var date_label: Label
var clock_label: Label
var segment_label: Label
var weather_label: Label
var money_label: Label
var energy_label: Label
var stress_label: Label
var work_label: Label
var rent_label: Label
var goals_panel: PanelContainer
var goals_label: Label
var prompt_panel: PanelContainer
var prompt_label: Label
var dialog_panel: PanelContainer
var speaker_label: Label
var dialog_label: Label
var dialog_hint: Label
var shop_panel: PanelContainer
var shop_title: Label
var shop_items_label: Label
var shop_message_label: Label
var status_icons: Control
var status_content: VBoxContainer
var sidebar_toggle_button: Button
var minimap_panel: PanelContainer
var minimap_title: Label
var minimap_canvas: Control
var function_bar_panel: PanelContainer
var function_detail_panel: PanelContainer
var function_bar_title: Label
var function_bar_hint: Label
var function_bar_message: Label
var character_tab_button: Button
var contacts_tab_button: Button
var inventory_tab_button: Button
var city_tab_button: Button
var tasks_tab_button: Button
var character_view: VBoxContainer
var character_summary_label: Label
var character_status_label: Label
var character_relationships_label: Label
var contacts_view: VBoxContainer
var contacts_summary_label: Label
var inventory_view: VBoxContainer
var inventory_empty_label: Label
var inventory_list: VBoxContainer
var city_view: VBoxContainer
var city_summary_label: Label
var tasks_view: VBoxContainer
var tasks_summary_label: Label

var dialogue_lines: Array = []
var dialogue_index := 0
var current_shop_items: Array[Dictionary] = []
var sidebar_collapsed := false
var minimap_scene_key := "street"
var minimap_world_rect := Rect2(Vector2.ZERO, Vector2.ONE)
var minimap_player_position := Vector2.ZERO
var minimap_player_facing := Vector2.DOWN
var minimap_points: Array[Dictionary] = []
var minimap_objective_active := false
var minimap_objective_position := Vector2.ZERO
var function_status: Dictionary = {}
var function_inventory: Array[Dictionary] = []
var current_function_tab := "closed"
var function_bar_notice := ""


func _ready() -> void:
	layer = 20
	_build_hud()
	_refresh_function_bar()


func update_status(status: Dictionary) -> void:
	var date_text: String = str(status.get("date", "6/1"))
	var clock_text: String = str(status.get("clock", "06:00"))
	var speed_text: String = str(status.get("time_speed", 96))
	var segment_text: String = str(status.get("segment", "上午"))
	var weather_text: String = str(status.get("weather", "晴天"))
	var money: int = int(status.get("money", 0))
	var energy: int = int(status.get("energy", 0))
	var max_energy: int = int(status.get("max_energy", 100))
	var stress: int = int(status.get("stress", 0))
	var max_stress: int = int(status.get("max_stress", 100))
	var rent_text: String = str(status.get("rent_label", "7天后到期"))
	var delivery_state: String = str(status.get("delivery_state", "none"))

	date_label.text = date_text
	clock_label.text = "%s  ·  %sx" % [clock_text, speed_text]
	segment_label.text = "时段 %s" % segment_text
	weather_label.text = "天气 %s" % weather_text
	money_label.text = "  现金 %d" % money
	energy_label.text = "  体力 %d/%d" % [energy, max_energy]
	stress_label.text = "  压力 %d/%d" % [stress, max_stress]
	if delivery_state == "accepted":
		work_label.text = "  外卖 去取餐"
	elif delivery_state == "picked":
		work_label.text = "  外卖 配送中"
	else:
		work_label.text = "  工作 %s" % str(status.get("work_performance", "未工作"))
	rent_label.text = "  房租 %s" % rent_text
	goals_label.text = _build_goals_text(status)


func update_function_bar(status: Dictionary, inventory: Array[Dictionary]) -> void:
	var status_copy: Dictionary = status.duplicate()
	function_status = status_copy
	function_inventory.clear()
	for entry_variant in inventory:
		var entry: Dictionary = entry_variant
		var entry_copy: Dictionary = entry.duplicate()
		function_inventory.append(entry_copy)
	_refresh_function_bar()


func focus_inventory_tab() -> void:
	_set_function_tab("inventory")


func set_function_bar_message(message: String) -> void:
	function_bar_notice = message
	_refresh_function_bar_message()


func update_minimap(scene_key: String, world_rect: Rect2, player_position: Vector2, player_facing: Vector2, points: Array[Dictionary], objective: Dictionary = {}) -> void:
	minimap_scene_key = scene_key
	minimap_world_rect = world_rect
	minimap_player_position = player_position
	minimap_player_facing = player_facing
	minimap_points = points
	minimap_objective_active = objective.has("position")
	if minimap_objective_active:
		var objective_position: Vector2 = objective["position"]
		minimap_objective_position = objective_position
	if minimap_title != null:
		minimap_title.text = _get_minimap_title(scene_key)
	if minimap_canvas != null:
		minimap_canvas.queue_redraw()


func show_prompt(text: String) -> void:
	prompt_label.text = _zh_prompt(text)
	prompt_panel.visible = true


func hide_prompt() -> void:
	prompt_panel.visible = false


func show_dialogue(speaker: String, lines: Array) -> void:
	var copied_lines: Array = lines.duplicate()
	dialogue_lines = copied_lines
	if dialogue_lines.is_empty():
		dialogue_lines = ["..."]
	dialogue_index = 0
	speaker_label.text = speaker
	dialog_panel.visible = true
	shop_panel.visible = false
	hide_prompt()
	_refresh_dialogue_line()
	_update_dialog_hint()


func show_shop(title: String, items: Array[Dictionary]) -> void:
	current_shop_items.clear()
	for item_variant in items:
		var item: Dictionary = item_variant
		var item_copy: Dictionary = item.duplicate()
		current_shop_items.append(item_copy)
	shop_title.text = title
	shop_message_label.text = "按 1-9 购买。按 E 或 Esc 关闭。"
	var lines := PackedStringArray()
	for i in range(current_shop_items.size()):
		var item: Dictionary = current_shop_items[i]
		if item.has("contract_id"):
			lines.append("%d  %s  手续费 %d  房租 %d  通勤 %d" % [i + 1, str(item.get("name", "合同")), int(item.get("price", 0)), int(item.get("rent_amount", 0)), int(item.get("commute_fare", 0))])
		else:
			lines.append("%d  %s  %d元  体力 +%d" % [i + 1, str(item.get("name", "物品")), int(item.get("price", 0)), int(item.get("energy", 0))])
	shop_items_label.text = "\n".join(lines)
	shop_panel.visible = true
	dialog_panel.visible = false
	hide_prompt()


func set_shop_message(message: String) -> void:
	shop_message_label.text = message


func is_blocking() -> bool:
	return dialog_panel.visible or shop_panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if dialog_panel.visible:
		if event.is_action_pressed("ui_cancel"):
			get_viewport().set_input_as_handled()
			_close_dialogue()
		elif event.is_action_pressed("interact"):
			get_viewport().set_input_as_handled()
			if dialogue_index < dialogue_lines.size() - 1:
				_advance_dialogue()
	elif event.is_action_pressed("interact") and shop_panel.visible:
		get_viewport().set_input_as_handled()
		_close_shop()
	elif event.is_action_pressed("ui_cancel") and shop_panel.visible:
		get_viewport().set_input_as_handled()
		_close_shop()
	elif shop_panel.visible and event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		var index := -1
		if key_event.keycode >= KEY_1 and key_event.keycode <= KEY_9:
			index = key_event.keycode - KEY_1
		if index >= 0 and index < current_shop_items.size():
			get_viewport().set_input_as_handled()
			shop_item_selected.emit(current_shop_items[index])
	elif event.is_action_pressed("ui_cancel") and function_detail_panel != null and function_detail_panel.visible:
		get_viewport().set_input_as_handled()
		_close_function_panel()
	elif current_function_tab == "inventory" and event is InputEventKey and event.pressed and not event.echo:
		var inventory_key_event := event as InputEventKey
		var inventory_index := -1
		if inventory_key_event.keycode >= KEY_1 and inventory_key_event.keycode <= KEY_9:
			inventory_index = inventory_key_event.keycode - KEY_1
		if inventory_index >= 0 and inventory_index < function_inventory.size():
			get_viewport().set_input_as_handled()
			inventory_item_used.emit(inventory_index)


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		_close_dialogue()
	else:
		_refresh_dialogue_line()
		_update_dialog_hint()


func _refresh_dialogue_line() -> void:
	dialog_label.text = str(dialogue_lines[dialogue_index])
	dialog_hint.text = "按 E 继续" if dialogue_index < dialogue_lines.size() - 1 else "按 Esc 关闭"


func _update_dialog_hint() -> void:
	if dialogue_index < dialogue_lines.size() - 1:
		dialog_hint.text = "按 E 继续，Esc 关闭"
	else:
		dialog_hint.text = "按 Esc 关闭"


func _close_dialogue() -> void:
	dialog_panel.visible = false
	dialogue_closed.emit()


func _close_shop() -> void:
	shop_panel.visible = false
	shop_closed.emit()


func _build_hud() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

	_build_minimap(root)
	_build_function_bar(root)
	_build_status_panel(root)
	_build_goals_panel(root)
	_build_prompt_panel(root)
	_build_sidebar_toggle(root)
	_build_dialog(root)
	_build_shop(root)
	_apply_sidebar_state()


func _build_status_panel(root: Control) -> void:
	status_panel = PanelContainer.new()
	status_panel.name = "StatusPanel"
	status_panel.add_theme_stylebox_override("panel", _pixel_panel_style(Color("#f3dca2"), Color("#7f5d3c")))
	status_panel.anchor_left = 1.0
	status_panel.anchor_right = 1.0
	status_panel.offset_left = -192
	status_panel.offset_right = -16
	status_panel.offset_top = 16
	status_panel.offset_bottom = 192
	root.add_child(status_panel)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 8)
	status_margin.add_theme_constant_override("margin_right", 8)
	status_margin.add_theme_constant_override("margin_top", 8)
	status_margin.add_theme_constant_override("margin_bottom", 8)
	status_panel.add_child(status_margin)

	status_content = VBoxContainer.new()
	status_content.add_theme_constant_override("separation", 3)
	status_margin.add_child(status_content)

	date_label = _make_label("6/1", 15, Color("#3b2d23"))
	clock_label = _make_label("06:00  ·  96x", 15, Color("#68442f"))
	segment_label = _make_label("时段 上午", 12, Color("#68442f"))
	weather_label = _make_label("天气 晴天", 12, Color("#53666f"))
	money_label = _make_label("  现金 2600", 14, Color("#2f5d45"))
	energy_label = _make_label("  体力 78/100", 12, Color("#5b5047"))
	stress_label = _make_label("  压力 22/100", 12, Color("#8a4b42"))
	work_label = _make_label("  工作 未工作", 12, Color("#6f5a48"))
	rent_label = _make_label("  房租 7天后到期", 12, Color("#7b4f30"))
	status_content.add_child(date_label)
	status_content.add_child(clock_label)
	status_content.add_child(segment_label)
	status_content.add_child(weather_label)
	status_content.add_child(money_label)
	status_content.add_child(energy_label)
	status_content.add_child(stress_label)
	status_content.add_child(work_label)
	status_content.add_child(rent_label)
	_add_status_icons(status_panel)


func _build_goals_panel(root: Control) -> void:
	goals_panel = PanelContainer.new()
	goals_panel.name = "GoalsPanel"
	goals_panel.add_theme_stylebox_override("panel", _pixel_panel_style(Color(0.23, 0.19, 0.14, 0.90), Color("#d8b46f")))
	goals_panel.anchor_left = 1.0
	goals_panel.anchor_right = 1.0
	goals_panel.offset_left = -224
	goals_panel.offset_right = -16
	goals_panel.offset_top = 208
	goals_panel.offset_bottom = 320
	root.add_child(goals_panel)

	var goals_margin := MarginContainer.new()
	goals_margin.add_theme_constant_override("margin_left", 8)
	goals_margin.add_theme_constant_override("margin_right", 8)
	goals_margin.add_theme_constant_override("margin_top", 8)
	goals_margin.add_theme_constant_override("margin_bottom", 8)
	goals_panel.add_child(goals_margin)

	goals_label = _make_label("今日\n- 去工作\n- 吃点东西\n- 回家睡觉", 11, Color("#ffe9b8"))
	goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goals_margin.add_child(goals_label)


func _build_prompt_panel(root: Control) -> void:
	prompt_panel = PanelContainer.new()
	prompt_panel.name = "PromptPanel"
	prompt_panel.visible = false
	prompt_panel.add_theme_stylebox_override("panel", _pixel_panel_style(Color(0.17, 0.13, 0.10, 0.92), Color("#e8c879")))
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_left = -160
	prompt_panel.offset_right = 160
	prompt_panel.offset_top = -112
	prompt_panel.offset_bottom = -80
	root.add_child(prompt_panel)

	var prompt_margin := MarginContainer.new()
	prompt_margin.add_theme_constant_override("margin_left", 10)
	prompt_margin.add_theme_constant_override("margin_right", 10)
	prompt_margin.add_theme_constant_override("margin_top", 6)
	prompt_margin.add_theme_constant_override("margin_bottom", 6)
	prompt_panel.add_child(prompt_margin)

	prompt_label = _make_label("按 E 互动", 13, Color("#ffe6a3"))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	prompt_margin.add_child(prompt_label)


func _build_minimap(root: Control) -> void:
	minimap_panel = PanelContainer.new()
	minimap_panel.name = "MinimapPanel"
	minimap_panel.add_theme_stylebox_override("panel", _pixel_panel_style(Color(0.18, 0.16, 0.12, 0.92), Color("#d8b46f")))
	minimap_panel.offset_left = 16
	minimap_panel.offset_right = 208
	minimap_panel.offset_top = 16
	minimap_panel.offset_bottom = 224
	root.add_child(minimap_panel)

	var minimap_margin := MarginContainer.new()
	minimap_margin.add_theme_constant_override("margin_left", 8)
	minimap_margin.add_theme_constant_override("margin_right", 8)
	minimap_margin.add_theme_constant_override("margin_top", 8)
	minimap_margin.add_theme_constant_override("margin_bottom", 8)
	minimap_panel.add_child(minimap_margin)

	var minimap_box := VBoxContainer.new()
	minimap_box.add_theme_constant_override("separation", 6)
	minimap_margin.add_child(minimap_box)

	minimap_title = _make_label("上海街区", 13, Color("#f7e3b2"))
	minimap_box.add_child(minimap_title)

	minimap_canvas = Control.new()
	minimap_canvas.custom_minimum_size = Vector2(160, 144)
	minimap_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_canvas.draw.connect(func() -> void:
		_draw_minimap()
	)
	minimap_box.add_child(minimap_canvas)


func _build_function_bar(root: Control) -> void:
	function_bar_panel = PanelContainer.new()
	function_bar_panel.name = "FunctionBarPanel"
	function_bar_panel.add_theme_stylebox_override("panel", _pixel_panel_style(Color(0.14, 0.12, 0.10, 0.94), Color("#d8b46f")))
	function_bar_panel.anchor_left = 0.5
	function_bar_panel.anchor_right = 0.5
	function_bar_panel.anchor_top = 1.0
	function_bar_panel.anchor_bottom = 1.0
	function_bar_panel.offset_left = -148
	function_bar_panel.offset_right = 148
	function_bar_panel.offset_top = -64
	function_bar_panel.offset_bottom = -16
	root.add_child(function_bar_panel)

	var function_margin := MarginContainer.new()
	function_margin.add_theme_constant_override("margin_left", 8)
	function_margin.add_theme_constant_override("margin_right", 8)
	function_margin.add_theme_constant_override("margin_top", 6)
	function_margin.add_theme_constant_override("margin_bottom", 6)
	function_bar_panel.add_child(function_margin)

	var dock_row := HBoxContainer.new()
	dock_row.add_theme_constant_override("separation", 8)
	function_margin.add_child(dock_row)

	character_tab_button = _make_dock_icon_button("character", "角色状态")
	character_tab_button.pressed.connect(func() -> void:
		_set_function_tab("attributes")
	)
	dock_row.add_child(character_tab_button)

	contacts_tab_button = _make_dock_icon_button("contacts", "联系人")
	contacts_tab_button.pressed.connect(func() -> void:
		_set_function_tab("contacts")
	)
	dock_row.add_child(contacts_tab_button)

	inventory_tab_button = _make_dock_icon_button("bag", "背包")
	inventory_tab_button.pressed.connect(func() -> void:
		_set_function_tab("inventory")
	)
	dock_row.add_child(inventory_tab_button)

	city_tab_button = _make_dock_icon_button("city", "城市地图")
	city_tab_button.pressed.connect(func() -> void:
		_set_function_tab("city")
	)
	dock_row.add_child(city_tab_button)

	tasks_tab_button = _make_dock_icon_button("tasks", "今日事项")
	tasks_tab_button.pressed.connect(func() -> void:
		_set_function_tab("tasks")
	)
	dock_row.add_child(tasks_tab_button)

	function_detail_panel = PanelContainer.new()
	function_detail_panel.name = "PhoneDetailPanel"
	function_detail_panel.visible = false
	function_detail_panel.add_theme_stylebox_override("panel", _pixel_panel_style(Color(0.16, 0.13, 0.10, 0.96), Color("#d8b46f")))
	function_detail_panel.anchor_left = 0.5
	function_detail_panel.anchor_right = 0.5
	function_detail_panel.anchor_top = 1.0
	function_detail_panel.anchor_bottom = 1.0
	function_detail_panel.offset_left = -192
	function_detail_panel.offset_right = 192
	function_detail_panel.offset_top = -240
	function_detail_panel.offset_bottom = -80
	root.add_child(function_detail_panel)

	var detail_margin := MarginContainer.new()
	detail_margin.add_theme_constant_override("margin_left", 12)
	detail_margin.add_theme_constant_override("margin_right", 12)
	detail_margin.add_theme_constant_override("margin_top", 10)
	detail_margin.add_theme_constant_override("margin_bottom", 10)
	function_detail_panel.add_child(detail_margin)

	var function_box := VBoxContainer.new()
	function_box.add_theme_constant_override("separation", 7)
	detail_margin.add_child(function_box)

	var header_row := HBoxContainer.new()
	header_row.add_theme_constant_override("separation", 8)
	function_box.add_child(header_row)

	function_bar_title = _make_label("手机", 14, Color("#f7e3b2"))
	header_row.add_child(function_bar_title)

	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header_row.add_child(spacer)

	var close_button := Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(32, 24)
	_apply_pixel_button_style(close_button)
	close_button.pressed.connect(_close_function_panel)
	header_row.add_child(close_button)

	function_bar_hint = _make_label("", 11, Color("#d7c6a2"))
	function_bar_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	function_box.add_child(function_bar_hint)

	character_view = VBoxContainer.new()
	character_view.add_theme_constant_override("separation", 6)
	function_box.add_child(character_view)

	character_summary_label = _make_label("", 13, Color("#fff4cf"))
	character_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_view.add_child(character_summary_label)

	character_status_label = _make_label("", 12, Color("#d5cabd"))
	character_status_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_view.add_child(character_status_label)

	character_relationships_label = _make_label("", 12, Color("#f0dfb5"))
	character_relationships_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	character_view.add_child(character_relationships_label)

	contacts_view = VBoxContainer.new()
	contacts_view.add_theme_constant_override("separation", 6)
	function_box.add_child(contacts_view)

	contacts_summary_label = _make_label("", 12, Color("#f0dfb5"))
	contacts_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	contacts_view.add_child(contacts_summary_label)

	inventory_view = VBoxContainer.new()
	inventory_view.add_theme_constant_override("separation", 6)
	function_box.add_child(inventory_view)

	inventory_empty_label = _make_label("", 12, Color("#d5cabd"))
	inventory_empty_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	inventory_view.add_child(inventory_empty_label)

	inventory_list = VBoxContainer.new()
	inventory_list.add_theme_constant_override("separation", 4)
	inventory_view.add_child(inventory_list)

	city_view = VBoxContainer.new()
	city_view.add_theme_constant_override("separation", 6)
	function_box.add_child(city_view)

	city_summary_label = _make_label("", 12, Color("#d5cabd"))
	city_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	city_view.add_child(city_summary_label)

	tasks_view = VBoxContainer.new()
	tasks_view.add_theme_constant_override("separation", 6)
	function_box.add_child(tasks_view)

	tasks_summary_label = _make_label("", 12, Color("#d5cabd"))
	tasks_summary_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tasks_view.add_child(tasks_summary_label)

	function_bar_message = _make_label("", 11, Color("#cdbb94"))
	function_bar_message.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	function_box.add_child(function_bar_message)


func _build_sidebar_toggle(root: Control) -> void:
	sidebar_toggle_button = Button.new()
	sidebar_toggle_button.name = "SidebarToggle"
	sidebar_toggle_button.anchor_left = 1.0
	sidebar_toggle_button.anchor_right = 1.0
	sidebar_toggle_button.offset_left = -44
	sidebar_toggle_button.offset_right = -12
	sidebar_toggle_button.offset_top = 12
	sidebar_toggle_button.offset_bottom = 40
	sidebar_toggle_button.text = "-"
	sidebar_toggle_button.focus_mode = Control.FOCUS_NONE
	_apply_pixel_button_style(sidebar_toggle_button)
	sidebar_toggle_button.pressed.connect(_toggle_sidebar)
	root.add_child(sidebar_toggle_button)


func _build_dialog(root: Control) -> void:
	dialog_panel = PanelContainer.new()
	dialog_panel.name = "DialoguePanel"
	dialog_panel.visible = false
	dialog_panel.add_theme_stylebox_override("panel", _pixel_panel_style(Color("#f5dfad"), Color("#704f37")))
	dialog_panel.anchor_left = 0.05
	dialog_panel.anchor_right = 0.95
	dialog_panel.anchor_top = 1.0
	dialog_panel.anchor_bottom = 1.0
	dialog_panel.offset_top = -304
	dialog_panel.offset_bottom = -200
	root.add_child(dialog_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 8)
	dialog_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	margin.add_child(box)

	speaker_label = _make_label("Speaker", 14, Color("#68442f"))
	dialog_label = _make_label("Hello.", 13, Color("#302821"))
	dialog_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	dialog_hint = _make_label("按 E 继续", 11, Color("#7b6a56"))
	dialog_hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	box.add_child(speaker_label)
	box.add_child(dialog_label)
	box.add_child(dialog_hint)


func _build_shop(root: Control) -> void:
	shop_panel = PanelContainer.new()
	shop_panel.name = "ShopPanel"
	shop_panel.visible = false
	shop_panel.add_theme_stylebox_override("panel", _pixel_panel_style(Color("#edf0c7"), Color("#60704f")))
	shop_panel.anchor_left = 0.5
	shop_panel.anchor_right = 0.5
	shop_panel.anchor_top = 0.5
	shop_panel.anchor_bottom = 0.5
	shop_panel.offset_left = -152
	shop_panel.offset_right = 152
	shop_panel.offset_top = -112
	shop_panel.offset_bottom = 112
	root.add_child(shop_panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 12)
	margin.add_theme_constant_override("margin_bottom", 10)
	shop_panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 8)
	margin.add_child(box)

	shop_title = _make_label("商店", 16, Color("#3b4b34"))
	shop_items_label = _make_label("", 13, Color("#2f342d"))
	shop_message_label = _make_label("", 11, Color("#68704e"))
	shop_items_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(shop_title)
	box.add_child(shop_items_label)
	box.add_child(shop_message_label)


func _toggle_sidebar() -> void:
	sidebar_collapsed = not sidebar_collapsed
	_apply_sidebar_state()


func _apply_sidebar_state() -> void:
	var show_sidebar := not sidebar_collapsed
	if status_panel != null:
		status_panel.visible = show_sidebar
	if goals_panel != null:
		goals_panel.visible = show_sidebar
	if sidebar_toggle_button != null:
		sidebar_toggle_button.text = "+" if sidebar_collapsed else "-"


func _add_status_icons(parent: Control) -> void:
	status_icons = Control.new()
	status_icons.name = "StatusIcons"
	status_icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	status_icons.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(status_icons)
	status_icons.draw.connect(func() -> void:
		ArtAssetsScript.draw_icon(status_icons, "money", Vector2(13, 69), 0.75)
		ArtAssetsScript.draw_icon(status_icons, "energy", Vector2(13, 88), 0.75)
		ArtAssetsScript.draw_icon(status_icons, "stress", Vector2(13, 107), 0.75)
		ArtAssetsScript.draw_icon(status_icons, "work", Vector2(13, 126), 0.75)
		ArtAssetsScript.draw_icon(status_icons, "rent", Vector2(13, 145), 0.75)
	)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _make_dock_icon_button(icon_name: String, tooltip: String) -> Button:
	var button := Button.new()
	button.icon = ArtAssetsScript.make_icon_texture(icon_name)
	button.expand_icon = false
	button.toggle_mode = true
	button.custom_minimum_size = Vector2(40, 32)
	button.tooltip_text = tooltip
	button.focus_mode = Control.FOCUS_NONE
	_apply_pixel_button_style(button)
	return button


func _set_function_tab(tab_name: String) -> void:
	if current_function_tab == tab_name and function_detail_panel != null and function_detail_panel.visible:
		_close_function_panel()
		return
	current_function_tab = tab_name
	if function_detail_panel != null:
		function_detail_panel.visible = true
	_refresh_function_bar()


func _close_function_panel() -> void:
	current_function_tab = "closed"
	if function_detail_panel != null:
		function_detail_panel.visible = false
	_refresh_function_bar()


func _refresh_function_bar() -> void:
	if function_bar_panel == null:
		return
	var showing_character := current_function_tab == "attributes"
	var showing_contacts := current_function_tab == "contacts"
	var showing_inventory := current_function_tab == "inventory"
	var showing_city := current_function_tab == "city"
	var showing_tasks := current_function_tab == "tasks"
	if character_tab_button != null:
		character_tab_button.button_pressed = showing_character
	if contacts_tab_button != null:
		contacts_tab_button.button_pressed = showing_contacts
	if inventory_tab_button != null:
		inventory_tab_button.button_pressed = showing_inventory
	if city_tab_button != null:
		city_tab_button.button_pressed = showing_city
	if tasks_tab_button != null:
		tasks_tab_button.button_pressed = showing_tasks
	if function_bar_title != null:
		if showing_inventory:
			function_bar_title.text = "背包"
		elif showing_contacts:
			function_bar_title.text = "联系人"
		elif showing_city:
			function_bar_title.text = "城市"
		elif showing_tasks:
			function_bar_title.text = "今日事项"
		else:
			function_bar_title.text = "角色状态"
	if function_bar_hint != null:
		if showing_inventory:
			function_bar_hint.text = "按 1-9 或点击物品使用。"
		elif showing_contacts:
			function_bar_hint.text = "每天聊天一次；当天聊过后再互动，会分享包里的食物。"
		elif showing_city:
			function_bar_hint.text = "用手机确认当前位置、住处和通勤压力。"
		elif showing_tasks:
			function_bar_hint.text = "今天先做最紧急的事，不要把自己耗空。"
		else:
			function_bar_hint.text = "规划工作、吃饭和休息前，先看清自己的状态。"
	if character_view != null:
		character_view.visible = showing_character
	if contacts_view != null:
		contacts_view.visible = showing_contacts
	if inventory_view != null:
		inventory_view.visible = showing_inventory
	if city_view != null:
		city_view.visible = showing_city
	if tasks_view != null:
		tasks_view.visible = showing_tasks
	_refresh_character_view()
	_refresh_contacts_view()
	_refresh_inventory_view()
	_refresh_city_view()
	_refresh_tasks_view()
	_refresh_function_bar_message()


func _refresh_character_view() -> void:
	if character_summary_label == null or character_status_label == null or character_relationships_label == null:
		return
	var money: int = int(function_status.get("money", 0))
	var energy: int = int(function_status.get("energy", 0))
	var max_energy: int = int(function_status.get("max_energy", 100))
	var stress: int = int(function_status.get("stress", 0))
	var max_stress: int = int(function_status.get("max_stress", 100))
	var date_text: String = str(function_status.get("date", "6/1"))
	var clock_text: String = str(function_status.get("clock", "06:00"))
	var segment_text: String = str(function_status.get("segment", "上午"))
	var weather_text: String = str(function_status.get("weather", "晴天"))
	var work_text: String = str(function_status.get("work_performance", "未工作"))
	var rent_text: String = str(function_status.get("rent_label", "7天后到期"))
	var housing_text: String = str(function_status.get("housing_label", "城中村合租"))
	var commute_fare: int = int(function_status.get("commute_fare", 6))
	character_summary_label.text = "现金 %d    体力 %d/%d    压力 %d/%d" % [money, energy, max_energy, stress, max_stress]
	character_status_label.text = "日期 %s    时间 %s / %s    天气 %s\n工作 %s\n住房 %s    通勤 %d元\n房租 %s" % [date_text, clock_text, segment_text, weather_text, work_text, housing_text, commute_fare, rent_text]
	character_relationships_label.text = "联系人已拆到独立页面。点底部第二个图标查看关系、赠礼和熟人加成。"


func _refresh_contacts_view() -> void:
	if contacts_summary_label == null:
		return
	var talked_count: int = int(function_status.get("talked_today_count", 0))
	var npc_count: int = int(function_status.get("npc_count", 0))
	var lines := PackedStringArray()
	lines.append("今日已聊 %d/%d" % [talked_count, npc_count])
	lines.append(_build_relationships_text())
	var perks: Array = function_status.get("relationship_perks", [])
	if perks.is_empty():
		lines.append("熟人加成：暂无。先每天打招呼，关系到 7/12 会开始影响生活。")
	else:
		lines.append("熟人加成")
		for perk_variant in perks:
			lines.append("- %s" % str(perk_variant))
	lines.append("赠礼：当天聊过后，再和 NPC 互动会分享包里的第一份食物。")
	contacts_summary_label.text = "\n".join(lines)


func _refresh_inventory_view() -> void:
	if inventory_view == null or inventory_empty_label == null or inventory_list == null:
		return
	for child in inventory_list.get_children():
		child.queue_free()
	if function_inventory.is_empty():
		inventory_empty_label.visible = true
		inventory_empty_label.text = "包里是空的。先去买点吃的或喝的，需要时再回来使用。"
		return
	inventory_empty_label.visible = false
	for i in range(function_inventory.size()):
		var item: Dictionary = function_inventory[i]
		var quantity: int = int(item.get("quantity", 1))
		var energy: int = int(item.get("energy", 0))
		var stress_relief: int = int(item.get("stress_relief", 0))
		var stress_text := "压力 -%d" % stress_relief
		if stress_relief < 0:
			stress_text = "压力 +%d" % abs(stress_relief)
		var use_button := Button.new()
		use_button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		use_button.text = "%d. %s x%d   体力 +%d   %s" % [i + 1, str(item.get("name", "物品")), quantity, energy, stress_text]
		use_button.tooltip_text = "使用这个物品。"
		_apply_pixel_button_style(use_button)
		var use_index := i
		use_button.pressed.connect(func() -> void:
			inventory_item_used.emit(use_index)
		)
		inventory_list.add_child(use_button)


func _build_relationships_text() -> String:
	var relationships: Array = function_status.get("relationships", [])
	if relationships.is_empty():
		return "- 还没认识谁。"
	var sorted: Array = relationships.duplicate()
	sorted.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var a_talked := bool(a.get("talked_today", false))
		var b_talked := bool(b.get("talked_today", false))
		if a_talked != b_talked:
			return not a_talked
		return int(a.get("value", 0)) > int(b.get("value", 0))
	)
	var lines := PackedStringArray()
	for i in range(min(5, sorted.size())):
		var entry: Dictionary = sorted[i]
		var value: int = int(entry.get("value", 0))
		var talked := bool(entry.get("talked_today", false))
		var state := "已聊" if talked else "可聊"
		lines.append("- %s  %s %s  %s" % [
			str(entry.get("name", "NPC")),
			str(entry.get("level", "陌生")),
			_relationship_bar(value),
			state,
		])
	return "\n".join(lines)


func _relationship_bar(value: int) -> String:
	var filled := clampi(int(ceil(float(value) / 3.0)), 0, 4)
	var chunks := PackedStringArray()
	for i in range(4):
		chunks.append("■" if i < filled else "□")
	return "".join(chunks)


func _refresh_city_view() -> void:
	if city_summary_label == null:
		return
	var housing_text: String = str(function_status.get("housing_label", "城中村合租"))
	var commute_fare: int = int(function_status.get("commute_fare", 6))
	var commute_energy: int = int(function_status.get("commute_energy_cost", 4))
	var commute_stress: int = int(function_status.get("commute_stress_gain", 2))
	var housing_id: String = str(function_status.get("housing_id", "urban_village"))
	city_summary_label.text = "当前位置：%s\n当前住处：%s\n通勤成本：%d元 / 体力 -%d / 压力 +%d\n住处影响：%s\n地图提示：左上角小地图会标出当前目标。" % [
		_get_scene_label(minimap_scene_key),
		housing_text,
		commute_fare,
		commute_energy,
		commute_stress,
		_get_housing_effect_label(housing_id),
	]


func _refresh_tasks_view() -> void:
	if tasks_summary_label == null:
		return
	tasks_summary_label.text = _build_goals_text(function_status)


func _refresh_function_bar_message() -> void:
	if function_bar_message == null:
		return
	if not function_bar_notice.is_empty():
		function_bar_message.text = function_bar_notice
		return
	if current_function_tab == "inventory":
		function_bar_message.text = "购买的食物会先进入背包，只有使用后才恢复状态。"
	elif current_function_tab == "contacts":
		function_bar_message.text = "关系不是恋爱系统，是上海生活里一点点熟人帮助。"
	elif current_function_tab == "city":
		function_bar_message.text = "租房会改变家门口、屋内风格和通勤消耗。"
	elif current_function_tab == "tasks":
		function_bar_message.text = "这不是任务清单，只是今天活下去的提醒。"
	elif current_function_tab == "closed":
		function_bar_message.text = ""
	else:
		function_bar_message.text = "底部手机已经收起，点图标打开具体面板。"


func _build_goals_text(status: Dictionary) -> String:
	var goals := PackedStringArray()
	var rent_due_in: int = int(status.get("rent_due_in", 7))
	var rent_overdue: int = int(status.get("rent_overdue_days", 0))
	var segment_key: String = str(status.get("segment_key", "morning"))
	var energy: int = int(status.get("energy", 100))
	var stress: int = int(status.get("stress", 0))
	var worked_today: bool = bool(status.get("worked_this_day", false))
	var current_delivery_state: String = str(status.get("delivery_state", "none"))
	var talked_count: int = int(status.get("talked_today_count", 0))
	var npc_count: int = int(status.get("npc_count", 0))

	if rent_overdue > 0:
		goals.append("- 房租逾期了，回家交房租。")
	elif rent_due_in == 0:
		goals.append("- 房租今天到期。")
	elif rent_due_in <= 2:
		goals.append("- 留现金准备交房租。")

	if current_delivery_state == "accepted":
		goals.append("- 去取外卖订单。")
	elif current_delivery_state == "picked":
		goals.append("- 去完成外卖送达。")
	elif not worked_today and segment_key in ["morning", "afternoon"]:
		goals.append("- 选一条今天的工作路线。")
	elif not worked_today and segment_key == "evening":
		goals.append("- 传媒公司还能接晚间活。")
	elif worked_today:
		goals.append("- 今天工作完成，先恢复。")

	if energy < 45:
		goals.append("- 买吃的，或用包里的食物。")
	if stress >= 60:
		goals.append("- 聊天、休息或去诊所降压。")
	elif talked_count < npc_count and segment_key in ["afternoon", "evening"]:
		goals.append("- 和附近的人聊聊，关系也能帮你喘口气。")
	if segment_key in ["evening", "late_night"]:
		goals.append("- 回家睡觉，进入下一天。")
	if goals.is_empty():
		goals.append("- 逛逛街区，和人说说话。")
		goals.append("- 规划工作、吃饭和房租。")

	var selected := PackedStringArray()
	for i in range(min(3, goals.size())):
		selected.append(goals[i])
	return "今日\n%s" % "\n".join(selected)


func _get_scene_label(scene_key: String) -> String:
	match scene_key:
		"apartment":
			return "出租屋"
		"office":
			return "公司工位"
		"media_company":
			return "传媒公司"
		"metro_station":
			return "地铁站"
		"wet_market":
			return "菜场"
		"clinic":
			return "社区诊所"
		_:
			return "上海街区"


func _get_housing_effect_label(housing_id: String) -> String:
	match housing_id:
		"far_suburb":
			return "房租低，但睡眠恢复和冰箱较弱，通勤压力更高。"
		"talent_apartment":
			return "睡眠和冰箱更好，交租后更安心，但房租很高。"
		_:
			return "恢复中等，房租和通勤都比较折中。"


func _zh_prompt(text: String) -> String:
	match text:
		"Press E to enter the apartment":
			return "按 E 回家"
		"Press E to shop":
			return "按 E 购物"
		"Press E to enter the metro":
			return "按 E 进地铁站"
		"Press E to buy food":
			return "按 E 买饭"
		"Press E to buy coffee":
			return "按 E 买咖啡"
		"Press E to enter the office":
			return "按 E 进公司"
		"Press E to enter the media company":
			return "按 E 进传媒公司"
		"Press E to accept a delivery order":
			return "按 E 接外卖单"
		"Press E to pick up food":
			return "按 E 取餐"
		"Press E to deliver food":
			return "按 E 送达"
		"Press E to enter the wet market":
			return "按 E 进菜场"
		"Press E to enter the clinic":
			return "按 E 进诊所"
		"Press E to inspect the talent apartment":
			return "按 E 查看人才公寓"
		"Press E to check rental listings":
			return "按 E 看租房信息"
		"Press E to interact":
			return "按 E 互动"
		_:
			return text


func _pixel_panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(0)
	style.shadow_color = Color(0.04, 0.03, 0.02, 0.35)
	style.shadow_size = 0
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


func _apply_pixel_button_style(button: Button) -> void:
	button.add_theme_stylebox_override("normal", _pixel_panel_style(Color("#2b241d"), Color("#d8b46f")))
	button.add_theme_stylebox_override("hover", _pixel_panel_style(Color("#3a3026"), Color("#f0c77b")))
	button.add_theme_stylebox_override("pressed", _pixel_panel_style(Color("#5a4630"), Color("#ffe0a3")))
	button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color("#ffe9b8"))
	button.add_theme_color_override("font_hover_color", Color("#fff4cf"))
	button.add_theme_color_override("font_pressed_color", Color("#fff4cf"))
	button.add_theme_font_size_override("font_size", 14)


func _get_minimap_title(scene_key: String) -> String:
	match scene_key:
		"apartment":
			return "出租屋"
		"office":
			return "公司"
		"media_company":
			return "直播间"
		"metro_station":
			return "地铁"
		"wet_market":
			return "菜场"
		"clinic":
			return "诊所"
		_:
			return "上海街区"


func _draw_minimap() -> void:
	if minimap_canvas == null:
		return
	var frame_rect := Rect2(Vector2(4, 4), minimap_canvas.size - Vector2(8, 8))
	var map_rect := Rect2(frame_rect.position + Vector2(6, 6), Vector2(frame_rect.size.x - 12, frame_rect.size.y - 34))
	var legend_rect := Rect2(frame_rect.position + Vector2(6, frame_rect.size.y - 22), Vector2(frame_rect.size.x - 12, 18))
	minimap_canvas.draw_rect(frame_rect, Color(0.10, 0.11, 0.13, 0.92))
	minimap_canvas.draw_rect(frame_rect, Color("#d8b46f"), false, 1.0)
	minimap_canvas.draw_rect(map_rect, Color(0.18, 0.20, 0.22, 0.94))
	_draw_minimap_scene_background(map_rect)
	_draw_minimap_grid(map_rect)
	_draw_minimap_points(map_rect)
	_draw_minimap_objective(map_rect)
	_draw_minimap_objective_arrow(map_rect)
	_draw_minimap_player(map_rect)
	_draw_minimap_legend(legend_rect)


func _draw_minimap_scene_background(inner_rect: Rect2) -> void:
	match minimap_scene_key:
		"apartment":
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.05, 0.08, 0.28, 0.26)), Color(0.76, 0.46, 0.46, 0.45))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.58, 0.18, 0.18, 0.18)), Color(0.56, 0.64, 0.70, 0.45))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.70, 0.46, 0.12, 0.20)), Color(0.82, 0.88, 0.82, 0.48))
		"office":
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.10, 0.18, 0.18, 0.18)), Color(0.55, 0.68, 0.76, 0.44))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.40, 0.18, 0.18, 0.18)), Color(0.56, 0.66, 0.46, 0.44))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.70, 0.18, 0.18, 0.18)), Color(0.76, 0.52, 0.42, 0.44))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.22, 0.58, 0.34, 0.16)), Color(0.50, 0.42, 0.34, 0.40))
		"media_company":
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.10, 0.16, 0.28, 0.26)), Color(0.86, 0.46, 0.56, 0.42))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.52, 0.18, 0.30, 0.20)), Color(0.54, 0.64, 0.72, 0.40))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.14, 0.62, 0.20, 0.12)), Color(0.74, 0.56, 0.52, 0.38))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.64, 0.62, 0.18, 0.14)), Color(0.50, 0.40, 0.44, 0.40))
		"metro_station":
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.02, 0.08, 0.96, 0.26)), Color(0.18, 0.24, 0.30, 0.82))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.02, 0.36, 0.96, 0.04)), Color(0.90, 0.74, 0.24, 0.72))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.10, 0.60, 0.20, 0.12)), Color(0.64, 0.78, 0.72, 0.40))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.34, 0.68, 0.42, 0.12)), Color(0.48, 0.60, 0.66, 0.42))
		"wet_market":
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.08, 0.20, 0.22, 0.24)), Color(0.44, 0.56, 0.32, 0.54))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.38, 0.20, 0.22, 0.24)), Color(0.64, 0.36, 0.32, 0.48))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.68, 0.20, 0.22, 0.24)), Color(0.75, 0.62, 0.32, 0.48))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.42, 0.76, 0.18, 0.08)), Color(0.88, 0.76, 0.44, 0.60))
		"clinic":
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.08, 0.22, 0.34, 0.20)), Color(0.82, 0.95, 0.88, 0.54))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.58, 0.24, 0.28, 0.14)), Color(0.35, 0.46, 0.52, 0.46))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.16, 0.62, 0.30, 0.16)), Color(0.66, 0.82, 0.74, 0.44))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.42, 0.82, 0.18, 0.08)), Color(0.86, 0.96, 0.90, 0.62))
		_:
			minimap_canvas.draw_line(_minimap_point(inner_rect, Vector2(0.28, 0.10)), _minimap_point(inner_rect, Vector2(0.28, 0.90)), Color(0.46, 0.44, 0.38, 0.55), 3.0)
			minimap_canvas.draw_line(_minimap_point(inner_rect, Vector2(0.14, 0.32)), _minimap_point(inner_rect, Vector2(0.76, 0.34)), Color(0.46, 0.44, 0.38, 0.52), 3.0)
			minimap_canvas.draw_line(_minimap_point(inner_rect, Vector2(0.10, 0.74)), _minimap_point(inner_rect, Vector2(0.64, 0.48)), Color(0.46, 0.44, 0.38, 0.52), 3.0)
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.68, 0.02, 0.10, 0.96)), Color(0.26, 0.40, 0.48, 0.72))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.38, 0.12, 0.10, 0.08)), Color(0.38, 0.50, 0.34, 0.42))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.82, 0.12, 0.12, 0.16)), Color(0.48, 0.62, 0.72, 0.42))
			minimap_canvas.draw_rect(_minimap_subrect(inner_rect, Rect2(0.18, 0.72, 0.16, 0.10)), Color(0.75, 0.58, 0.36, 0.42))


func _draw_minimap_grid(inner_rect: Rect2) -> void:
	for i in range(1, 4):
		var x := inner_rect.position.x + inner_rect.size.x * float(i) / 4.0
		var y := inner_rect.position.y + inner_rect.size.y * float(i) / 4.0
		minimap_canvas.draw_line(Vector2(x, inner_rect.position.y), Vector2(x, inner_rect.end.y), Color(1, 1, 1, 0.05), 1.0)
		minimap_canvas.draw_line(Vector2(inner_rect.position.x, y), Vector2(inner_rect.end.x, y), Color(1, 1, 1, 0.05), 1.0)


func _draw_minimap_points(inner_rect: Rect2) -> void:
	for point_variant in minimap_points:
		var point: Dictionary = point_variant
		if not point.has("position"):
			continue
		var point_position: Vector2 = point["position"]
		var point_color: Color = point.get("color", Color("#f0c77b"))
		var point_radius: float = float(point.get("radius", 3.0))
		var point_kind: String = str(point.get("kind", "place"))
		var canvas_point := _minimap_world_to_canvas(inner_rect, point_position)
		_draw_minimap_marker(canvas_point, point_kind, point_color, point_radius)


func _draw_minimap_marker(center: Vector2, kind: String, color: Color, radius: float) -> void:
	var shadow := Color(0.02, 0.03, 0.04, 0.50)
	match kind:
		"home":
			minimap_canvas.draw_rect(Rect2(center + Vector2(-4, -1), Vector2(8, 6)), shadow)
			minimap_canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-5, -1), center + Vector2(0, -6), center + Vector2(5, -1)]), shadow)
			minimap_canvas.draw_rect(Rect2(center + Vector2(-3, 0), Vector2(6, 5)), color)
			minimap_canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(-4, 0), center + Vector2(0, -4), center + Vector2(4, 0)]), color)
		"work", "media", "delivery":
			minimap_canvas.draw_rect(Rect2(center - Vector2(radius + 2, radius + 2), Vector2(radius * 2.0 + 4.0, radius * 2.0 + 4.0)), shadow)
			minimap_canvas.draw_rect(Rect2(center - Vector2(radius, radius), Vector2(radius * 2.0, radius * 2.0)), color)
		"metro":
			minimap_canvas.draw_rect(Rect2(center - Vector2(5, 5), Vector2(10, 10)), shadow)
			minimap_canvas.draw_rect(Rect2(center - Vector2(4, 4), Vector2(8, 8)), color)
			minimap_canvas.draw_rect(Rect2(center - Vector2(1, 1), Vector2(2, 6)), Color("#26313d"))
		"food", "clinic", "rent":
			minimap_canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius - 2), center + Vector2(radius + 2, 0), center + Vector2(0, radius + 2), center + Vector2(-radius - 2, 0)]), shadow)
			minimap_canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -radius), center + Vector2(radius, 0), center + Vector2(0, radius), center + Vector2(-radius, 0)]), color)
		"npc":
			minimap_canvas.draw_circle(center, radius + 1.5, shadow)
			minimap_canvas.draw_circle(center, radius, color)
		_:
			minimap_canvas.draw_circle(center, radius + 2.0, shadow)
			minimap_canvas.draw_circle(center, radius, color)


func _draw_minimap_legend(legend_rect: Rect2) -> void:
	minimap_canvas.draw_rect(legend_rect, Color(0.08, 0.08, 0.07, 0.58))
	minimap_canvas.draw_rect(legend_rect, Color(0.85, 0.70, 0.42, 0.30), false, 1.0)
	var entries := _get_minimap_legend_entries()
	for i in range(entries.size()):
		var entry: Dictionary = entries[i]
		var col := i % 3
		var row := int(i / 3)
		var origin := legend_rect.position + Vector2(6 + col * 48, 4 + row * 8)
		_draw_minimap_legend_marker(origin + Vector2(3, 3), str(entry.get("kind", "place")), entry.get("color", Color("#f0c77b")))
		_draw_minimap_tiny_text(origin + Vector2(9, 0), str(entry.get("label", "")), Color("#f7e3b2"))


func _get_minimap_legend_entries() -> Array[Dictionary]:
	if minimap_objective_active:
		return [
			{"kind": "objective", "label": "目标", "color": Color("#ffd37a")},
			{"kind": "player", "label": "你", "color": Color("#f08f5a")},
			{"kind": "exit", "label": "出口", "color": Color("#e8c879")},
		]
	match minimap_scene_key:
		"street":
			return [
				{"kind": "home", "label": "家", "color": Color("#efc36f")},
				{"kind": "work", "label": "工作", "color": Color("#c7e7ff")},
				{"kind": "metro", "label": "地铁", "color": Color("#a9d7ff")},
				{"kind": "food", "label": "吃饭", "color": Color("#d8c886")},
				{"kind": "clinic", "label": "诊所", "color": Color("#d8fff0")},
				{"kind": "rent", "label": "租房", "color": Color("#e8c879")},
			]
		"office":
			return [
				{"kind": "work", "label": "工位", "color": Color("#c7e7ff")},
				{"kind": "exit", "label": "出口", "color": Color("#e8c879")},
				{"kind": "player", "label": "你", "color": Color("#f08f5a")},
			]
		"media_company":
			return [
				{"kind": "media", "label": "直播", "color": Color("#ffc4d6")},
				{"kind": "exit", "label": "出口", "color": Color("#e8c879")},
				{"kind": "player", "label": "你", "color": Color("#f08f5a")},
			]
		"metro_station":
			return [
				{"kind": "metro", "label": "闸机", "color": Color("#a9d7ff")},
				{"kind": "info", "label": "售票", "color": Color("#b8d8c4")},
				{"kind": "exit", "label": "出口", "color": Color("#e8c879")},
			]
		"apartment":
			return [
				{"kind": "home", "label": "床", "color": Color("#d98a8a")},
				{"kind": "food", "label": "冰箱", "color": Color("#b8d8c4")},
				{"kind": "rent", "label": "房租", "color": Color("#efc36f")},
			]
		"wet_market":
			return [
				{"kind": "food", "label": "买菜", "color": Color("#d8c886")},
				{"kind": "exit", "label": "出口", "color": Color("#e8c879")},
				{"kind": "player", "label": "你", "color": Color("#f08f5a")},
			]
		"clinic":
			return [
				{"kind": "clinic", "label": "挂号", "color": Color("#d8fff0")},
				{"kind": "exit", "label": "出口", "color": Color("#e8c879")},
				{"kind": "player", "label": "你", "color": Color("#f08f5a")},
			]
	return [
		{"kind": "player", "label": "你", "color": Color("#f08f5a")},
		{"kind": "exit", "label": "出口", "color": Color("#e8c879")},
	]


func _draw_minimap_legend_marker(center: Vector2, kind: String, color: Color) -> void:
	if kind == "objective":
		minimap_canvas.draw_circle(center, 3.0, color)
	elif kind == "player":
		minimap_canvas.draw_colored_polygon(PackedVector2Array([center + Vector2(0, -4), center + Vector2(3, 3), center + Vector2(-3, 3)]), color)
	else:
		_draw_minimap_marker(center, kind, color, 2.5)


func _draw_minimap_tiny_text(pos: Vector2, text: String, color: Color) -> void:
	var cursor_x := int(pos.x)
	var cursor_y := int(pos.y)
	for i in range(text.length()):
		var glyph := text.substr(i, 1)
		_draw_minimap_glyph(Vector2(cursor_x, cursor_y), glyph, color)
		cursor_x += 6


func _draw_minimap_glyph(pos: Vector2, glyph: String, color: Color) -> void:
	var p := Vector2(round(pos.x), round(pos.y))
	match glyph:
		"你":
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 0), Vector2(3, 1)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(2, 1), Vector2(1, 5)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 3), Vector2(5, 1)), color)
		"家":
			minimap_canvas.draw_colored_polygon(PackedVector2Array([p + Vector2(0, 3), p + Vector2(2, 0), p + Vector2(5, 3)]), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 3), Vector2(4, 3)), color)
		"工", "作":
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 0), Vector2(5, 1)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(2, 1), Vector2(1, 4)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 5), Vector2(5, 1)), color)
		"地", "铁":
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 0), Vector2(5, 1)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 1), Vector2(1, 5)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(3, 1), Vector2(1, 5)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 5), Vector2(5, 1)), color)
		"吃", "饭", "菜":
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 1), Vector2(2, 4)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(3, 0), Vector2(2, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(2, 3), Vector2(3, 1)), color)
		"诊", "所", "挂", "号":
			minimap_canvas.draw_rect(Rect2(p + Vector2(2, 0), Vector2(1, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 2), Vector2(5, 1)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 4), Vector2(3, 1)), color)
		"租", "房":
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 0), Vector2(3, 1)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 2), Vector2(5, 1)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 3), Vector2(1, 3)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(4, 3), Vector2(1, 3)), color)
		"目", "标":
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 0), Vector2(3, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 2), Vector2(5, 1)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 4), Vector2(5, 1)), color)
		"出", "口":
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 1), Vector2(5, 4)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 2), Vector2(3, 2)), Color(0.08, 0.08, 0.07, 0.58))
		"直", "播":
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 1), Vector2(3, 3)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(2, 4), Vector2(1, 2)), color)
		"售", "票":
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 0), Vector2(5, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 1), Vector2(3, 1)), Color(0.08, 0.08, 0.07, 0.58))
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 4), Vector2(3, 1)), Color(0.08, 0.08, 0.07, 0.58))
		"闸", "机":
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 0), Vector2(1, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(4, 0), Vector2(1, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 2), Vector2(3, 1)), color)
		"格":
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 0), Vector2(1, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(2, 0), Vector2(1, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(4, 0), Vector2(1, 6)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 2), Vector2(5, 1)), color)
			minimap_canvas.draw_rect(Rect2(p + Vector2(0, 5), Vector2(5, 1)), color)
		_:
			minimap_canvas.draw_rect(Rect2(p + Vector2(1, 1), Vector2(3, 3)), color)


func _draw_minimap_player(inner_rect: Rect2) -> void:
	var canvas_point := _minimap_world_to_canvas(inner_rect, minimap_player_position)
	minimap_canvas.draw_circle(canvas_point, 7.0, Color(1.0, 1.0, 1.0, 0.10))
	minimap_canvas.draw_circle(canvas_point, 4.0, Color("#fff4cf"))
	minimap_canvas.draw_circle(canvas_point, 1.8, Color("#f08f5a"))
	var facing_vector := minimap_player_facing.normalized()
	if facing_vector.length() <= 0.0:
		facing_vector = Vector2.DOWN
	var tip := canvas_point + facing_vector * 9.0
	var side := Vector2(-facing_vector.y, facing_vector.x) * 4.0
	minimap_canvas.draw_colored_polygon(PackedVector2Array([tip, canvas_point - facing_vector * 3.0 + side, canvas_point - facing_vector * 3.0 - side]), Color("#f08f5a"))


func _draw_minimap_objective(inner_rect: Rect2) -> void:
	if not minimap_objective_active:
		return
	var objective_point := _minimap_world_to_canvas(inner_rect, minimap_objective_position)
	minimap_canvas.draw_circle(objective_point, 10.0, Color(1.0, 0.88, 0.42, 0.10))
	minimap_canvas.draw_circle(objective_point, 6.0, Color(1.0, 0.82, 0.32, 0.16))
	minimap_canvas.draw_circle(objective_point, 3.0, Color("#ffd37a"))


func _draw_minimap_objective_arrow(inner_rect: Rect2) -> void:
	if not minimap_objective_active:
		return
	var world_delta := minimap_objective_position - minimap_player_position
	if world_delta.length() < 96.0:
		return
	var player_point := _minimap_world_to_canvas(inner_rect, minimap_player_position)
	var target_point := _minimap_world_to_canvas_unclamped(inner_rect, minimap_objective_position)
	var direction := target_point - player_point
	if direction.length() <= 0.01:
		direction = world_delta
	if direction.length() <= 0.01:
		return
	direction = direction.normalized()
	var edge_rect := inner_rect.grow(-8)
	var arrow_point := player_point + direction * 999.0
	arrow_point.x = clampf(arrow_point.x, edge_rect.position.x, edge_rect.end.x)
	arrow_point.y = clampf(arrow_point.y, edge_rect.position.y, edge_rect.end.y)
	if absf(direction.x) > absf(direction.y):
		arrow_point.y = clampf(player_point.y + direction.y * absf((arrow_point.x - player_point.x) / direction.x), edge_rect.position.y, edge_rect.end.y)
	else:
		arrow_point.x = clampf(player_point.x + direction.x * absf((arrow_point.y - player_point.y) / direction.y), edge_rect.position.x, edge_rect.end.x)
	_draw_minimap_arrow(arrow_point, direction)
	_draw_minimap_distance_label(inner_rect, arrow_point, world_delta.length())


func _draw_minimap_arrow(center: Vector2, direction: Vector2) -> void:
	var forward := direction.normalized()
	var side := Vector2(-forward.y, forward.x)
	var tip := center + forward * 7.0
	var back := center - forward * 5.0
	var left := back + side * 5.0
	var right := back - side * 5.0
	var shadow_offset := Vector2(1, 1)
	minimap_canvas.draw_colored_polygon(PackedVector2Array([tip + shadow_offset, left + shadow_offset, center + shadow_offset, right + shadow_offset]), Color(0.02, 0.02, 0.02, 0.55))
	minimap_canvas.draw_colored_polygon(PackedVector2Array([tip, left, center, right]), Color("#ffd37a"))
	minimap_canvas.draw_line(back, tip, Color("#7f5d3c"), 1.0)


func _draw_minimap_distance_label(inner_rect: Rect2, arrow_point: Vector2, distance: float) -> void:
	var steps := max(1, int(round(distance / 64.0)))
	var text := "%d格" % steps
	var label_pos := arrow_point + Vector2(8, -4)
	if label_pos.x + 22 > inner_rect.end.x:
		label_pos.x = arrow_point.x - 26
	if label_pos.y < inner_rect.position.y + 2:
		label_pos.y = arrow_point.y + 7
	if label_pos.y + 7 > inner_rect.end.y:
		label_pos.y = arrow_point.y - 11
	minimap_canvas.draw_rect(Rect2(label_pos + Vector2(-2, -1), Vector2(24, 8)), Color(0.08, 0.07, 0.05, 0.70))
	_draw_minimap_tiny_text(label_pos, text, Color("#ffd37a"))


func _minimap_world_to_canvas(inner_rect: Rect2, world_position: Vector2) -> Vector2:
	var origin := minimap_world_rect.position
	var size := minimap_world_rect.size
	if size.x <= 0.0 or size.y <= 0.0:
		return inner_rect.position + inner_rect.size * 0.5
	var normalized_x := clampf((world_position.x - origin.x) / size.x, 0.0, 1.0)
	var normalized_y := clampf((world_position.y - origin.y) / size.y, 0.0, 1.0)
	return inner_rect.position + Vector2(inner_rect.size.x * normalized_x, inner_rect.size.y * normalized_y)


func _minimap_world_to_canvas_unclamped(inner_rect: Rect2, world_position: Vector2) -> Vector2:
	var origin := minimap_world_rect.position
	var size := minimap_world_rect.size
	if size.x <= 0.0 or size.y <= 0.0:
		return inner_rect.position + inner_rect.size * 0.5
	var normalized_x := (world_position.x - origin.x) / size.x
	var normalized_y := (world_position.y - origin.y) / size.y
	return inner_rect.position + Vector2(inner_rect.size.x * normalized_x, inner_rect.size.y * normalized_y)


func _minimap_subrect(inner_rect: Rect2, normalized_rect: Rect2) -> Rect2:
	return Rect2(
		inner_rect.position + Vector2(inner_rect.size.x * normalized_rect.position.x, inner_rect.size.y * normalized_rect.position.y),
		Vector2(inner_rect.size.x * normalized_rect.size.x, inner_rect.size.y * normalized_rect.size.y)
	)


func _minimap_point(inner_rect: Rect2, normalized_point: Vector2) -> Vector2:
	return inner_rect.position + Vector2(inner_rect.size.x * normalized_point.x, inner_rect.size.y * normalized_point.y)
