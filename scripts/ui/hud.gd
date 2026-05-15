extends CanvasLayer
class_name GameHUD

const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

signal dialogue_closed
signal shop_closed
signal shop_item_selected(item: Dictionary)
signal inventory_item_used(index: int)

var status_panel: PanelContainer
var date_label: Label
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
var inventory_tab_button: Button
var city_tab_button: Button
var tasks_tab_button: Button
var character_view: VBoxContainer
var character_summary_label: Label
var character_status_label: Label
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
	segment_label.text = segment_text
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
	status_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f3dca2"), Color("#7f5d3c")))
	status_panel.anchor_left = 1.0
	status_panel.anchor_right = 1.0
	status_panel.offset_left = -184
	status_panel.offset_right = -12
	status_panel.offset_top = 12
	status_panel.offset_bottom = 176
	root.add_child(status_panel)

	var status_margin := MarginContainer.new()
	status_margin.add_theme_constant_override("margin_left", 10)
	status_margin.add_theme_constant_override("margin_right", 10)
	status_margin.add_theme_constant_override("margin_top", 8)
	status_margin.add_theme_constant_override("margin_bottom", 8)
	status_panel.add_child(status_margin)

	status_content = VBoxContainer.new()
	status_content.add_theme_constant_override("separation", 3)
	status_margin.add_child(status_content)

	date_label = _make_label("6/1", 15, Color("#3b2d23"))
	segment_label = _make_label("上午", 14, Color("#68442f"))
	weather_label = _make_label("天气 晴天", 12, Color("#53666f"))
	money_label = _make_label("  现金 2600", 14, Color("#2f5d45"))
	energy_label = _make_label("  体力 78/100", 12, Color("#5b5047"))
	stress_label = _make_label("  压力 22/100", 12, Color("#8a4b42"))
	work_label = _make_label("  工作 未工作", 12, Color("#6f5a48"))
	rent_label = _make_label("  房租 7天后到期", 12, Color("#7b4f30"))
	status_content.add_child(date_label)
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
	goals_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.23, 0.19, 0.14, 0.86), Color("#d8b46f")))
	goals_panel.anchor_left = 1.0
	goals_panel.anchor_right = 1.0
	goals_panel.offset_left = -220
	goals_panel.offset_right = -12
	goals_panel.offset_top = 188
	goals_panel.offset_bottom = 292
	root.add_child(goals_panel)

	var goals_margin := MarginContainer.new()
	goals_margin.add_theme_constant_override("margin_left", 10)
	goals_margin.add_theme_constant_override("margin_right", 10)
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
	prompt_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.17, 0.13, 0.10, 0.88), Color("#e8c879")))
	prompt_panel.anchor_left = 0.5
	prompt_panel.anchor_right = 0.5
	prompt_panel.anchor_top = 1.0
	prompt_panel.anchor_bottom = 1.0
	prompt_panel.offset_left = -150
	prompt_panel.offset_right = 150
	prompt_panel.offset_top = -116
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
	minimap_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.18, 0.16, 0.12, 0.88), Color("#d8b46f")))
	minimap_panel.offset_left = 12
	minimap_panel.offset_right = 180
	minimap_panel.offset_top = 12
	minimap_panel.offset_bottom = 176
	root.add_child(minimap_panel)

	var minimap_margin := MarginContainer.new()
	minimap_margin.add_theme_constant_override("margin_left", 10)
	minimap_margin.add_theme_constant_override("margin_right", 10)
	minimap_margin.add_theme_constant_override("margin_top", 8)
	minimap_margin.add_theme_constant_override("margin_bottom", 8)
	minimap_panel.add_child(minimap_margin)

	var minimap_box := VBoxContainer.new()
	minimap_box.add_theme_constant_override("separation", 6)
	minimap_margin.add_child(minimap_box)

	minimap_title = _make_label("上海街区", 13, Color("#f7e3b2"))
	minimap_box.add_child(minimap_title)

	minimap_canvas = Control.new()
	minimap_canvas.custom_minimum_size = Vector2(148, 112)
	minimap_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	minimap_canvas.draw.connect(func() -> void:
		_draw_minimap()
	)
	minimap_box.add_child(minimap_canvas)


func _build_function_bar(root: Control) -> void:
	function_bar_panel = PanelContainer.new()
	function_bar_panel.name = "FunctionBarPanel"
	function_bar_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.14, 0.12, 0.10, 0.92), Color("#d8b46f")))
	function_bar_panel.anchor_left = 0.5
	function_bar_panel.anchor_right = 0.5
	function_bar_panel.anchor_top = 1.0
	function_bar_panel.anchor_bottom = 1.0
	function_bar_panel.offset_left = -132
	function_bar_panel.offset_right = 132
	function_bar_panel.offset_top = -62
	function_bar_panel.offset_bottom = -12
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

	character_tab_button = Button.new()
	character_tab_button.text = "人"
	character_tab_button.toggle_mode = true
	character_tab_button.custom_minimum_size = Vector2(52, 38)
	character_tab_button.tooltip_text = "角色状态"
	character_tab_button.pressed.connect(func() -> void:
		_set_function_tab("attributes")
	)
	dock_row.add_child(character_tab_button)

	inventory_tab_button = Button.new()
	inventory_tab_button.text = "包"
	inventory_tab_button.toggle_mode = true
	inventory_tab_button.custom_minimum_size = Vector2(52, 38)
	inventory_tab_button.tooltip_text = "背包"
	inventory_tab_button.pressed.connect(func() -> void:
		_set_function_tab("inventory")
	)
	dock_row.add_child(inventory_tab_button)

	city_tab_button = Button.new()
	city_tab_button.text = "城"
	city_tab_button.toggle_mode = true
	city_tab_button.custom_minimum_size = Vector2(52, 38)
	city_tab_button.tooltip_text = "城市地图"
	city_tab_button.pressed.connect(func() -> void:
		_set_function_tab("city")
	)
	dock_row.add_child(city_tab_button)

	tasks_tab_button = Button.new()
	tasks_tab_button.text = "事"
	tasks_tab_button.toggle_mode = true
	tasks_tab_button.custom_minimum_size = Vector2(52, 38)
	tasks_tab_button.tooltip_text = "今日事项"
	tasks_tab_button.pressed.connect(func() -> void:
		_set_function_tab("tasks")
	)
	dock_row.add_child(tasks_tab_button)

	function_detail_panel = PanelContainer.new()
	function_detail_panel.name = "PhoneDetailPanel"
	function_detail_panel.visible = false
	function_detail_panel.add_theme_stylebox_override("panel", _panel_style(Color(0.16, 0.13, 0.10, 0.96), Color("#d8b46f")))
	function_detail_panel.anchor_left = 0.5
	function_detail_panel.anchor_right = 0.5
	function_detail_panel.anchor_top = 1.0
	function_detail_panel.anchor_bottom = 1.0
	function_detail_panel.offset_left = -196
	function_detail_panel.offset_right = 196
	function_detail_panel.offset_top = -242
	function_detail_panel.offset_bottom = -74
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
	close_button.custom_minimum_size = Vector2(32, 26)
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
	sidebar_toggle_button.pressed.connect(_toggle_sidebar)
	root.add_child(sidebar_toggle_button)


func _build_dialog(root: Control) -> void:
	dialog_panel = PanelContainer.new()
	dialog_panel.name = "DialoguePanel"
	dialog_panel.visible = false
	dialog_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f5dfad"), Color("#704f37")))
	dialog_panel.anchor_left = 0.05
	dialog_panel.anchor_right = 0.95
	dialog_panel.anchor_top = 1.0
	dialog_panel.anchor_bottom = 1.0
	dialog_panel.offset_top = -300
	dialog_panel.offset_bottom = -196
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
	shop_panel.add_theme_stylebox_override("panel", _panel_style(Color("#edf0c7"), Color("#60704f")))
	shop_panel.anchor_left = 0.5
	shop_panel.anchor_right = 0.5
	shop_panel.anchor_top = 0.5
	shop_panel.anchor_bottom = 0.5
	shop_panel.offset_left = -150
	shop_panel.offset_right = 150
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
	var showing_inventory := current_function_tab == "inventory"
	var showing_city := current_function_tab == "city"
	var showing_tasks := current_function_tab == "tasks"
	if character_tab_button != null:
		character_tab_button.button_pressed = showing_character
	if inventory_tab_button != null:
		inventory_tab_button.button_pressed = showing_inventory
	if city_tab_button != null:
		city_tab_button.button_pressed = showing_city
	if tasks_tab_button != null:
		tasks_tab_button.button_pressed = showing_tasks
	if function_bar_title != null:
		if showing_inventory:
			function_bar_title.text = "背包"
		elif showing_city:
			function_bar_title.text = "城市"
		elif showing_tasks:
			function_bar_title.text = "今日事项"
		else:
			function_bar_title.text = "角色状态"
	if function_bar_hint != null:
		if showing_inventory:
			function_bar_hint.text = "按 1-9 或点击物品使用。"
		elif showing_city:
			function_bar_hint.text = "用手机确认当前位置、住处和通勤压力。"
		elif showing_tasks:
			function_bar_hint.text = "今天先做最紧急的事，不要把自己耗空。"
		else:
			function_bar_hint.text = "规划工作、吃饭和休息前，先看清自己的状态。"
	if character_view != null:
		character_view.visible = showing_character
	if inventory_view != null:
		inventory_view.visible = showing_inventory
	if city_view != null:
		city_view.visible = showing_city
	if tasks_view != null:
		tasks_view.visible = showing_tasks
	_refresh_character_view()
	_refresh_inventory_view()
	_refresh_city_view()
	_refresh_tasks_view()
	_refresh_function_bar_message()


func _refresh_character_view() -> void:
	if character_summary_label == null or character_status_label == null:
		return
	var money: int = int(function_status.get("money", 0))
	var energy: int = int(function_status.get("energy", 0))
	var max_energy: int = int(function_status.get("max_energy", 100))
	var stress: int = int(function_status.get("stress", 0))
	var max_stress: int = int(function_status.get("max_stress", 100))
	var date_text: String = str(function_status.get("date", "6/1"))
	var segment_text: String = str(function_status.get("segment", "上午"))
	var weather_text: String = str(function_status.get("weather", "晴天"))
	var work_text: String = str(function_status.get("work_performance", "未工作"))
	var rent_text: String = str(function_status.get("rent_label", "7天后到期"))
	var housing_text: String = str(function_status.get("housing_label", "城中村合租"))
	var commute_fare: int = int(function_status.get("commute_fare", 6))
	character_summary_label.text = "现金 %d    体力 %d/%d    压力 %d/%d" % [money, energy, max_energy, stress, max_stress]
	character_status_label.text = "日期 %s    时间 %s    天气 %s\n工作 %s\n住房 %s    通勤 %d元\n房租 %s" % [date_text, segment_text, weather_text, work_text, housing_text, commute_fare, rent_text]


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
		var use_index := i
		use_button.pressed.connect(func() -> void:
			inventory_item_used.emit(use_index)
		)
		inventory_list.add_child(use_button)


func _refresh_city_view() -> void:
	if city_summary_label == null:
		return
	var housing_text: String = str(function_status.get("housing_label", "城中村合租"))
	var commute_fare: int = int(function_status.get("commute_fare", 6))
	var commute_energy: int = int(function_status.get("commute_energy_cost", 4))
	var commute_stress: int = int(function_status.get("commute_stress_gain", 2))
	city_summary_label.text = "当前位置：%s\n当前住处：%s\n通勤成本：%d元 / 体力 -%d / 压力 +%d\n地图提示：左上角小地图会标出当前目标。" % [
		_get_scene_label(minimap_scene_key),
		housing_text,
		commute_fare,
		commute_energy,
		commute_stress,
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


func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(7)
	style.shadow_color = Color(0.04, 0.03, 0.02, 0.25)
	style.shadow_size = 4
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style


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
	var inner_rect := frame_rect.grow(-6)
	minimap_canvas.draw_rect(frame_rect, Color(0.10, 0.11, 0.13, 0.92))
	minimap_canvas.draw_rect(frame_rect, Color("#d8b46f"), false, 1.0)
	minimap_canvas.draw_rect(inner_rect, Color(0.18, 0.20, 0.22, 0.94))
	_draw_minimap_scene_background(inner_rect)
	_draw_minimap_grid(inner_rect)
	_draw_minimap_points(inner_rect)
	_draw_minimap_objective(inner_rect)
	_draw_minimap_player(inner_rect)


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
		var canvas_point := _minimap_world_to_canvas(inner_rect, point_position)
		minimap_canvas.draw_circle(canvas_point, point_radius + 2.0, Color(0.02, 0.03, 0.04, 0.45))
		minimap_canvas.draw_circle(canvas_point, point_radius, point_color)


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


func _minimap_world_to_canvas(inner_rect: Rect2, world_position: Vector2) -> Vector2:
	var origin := minimap_world_rect.position
	var size := minimap_world_rect.size
	if size.x <= 0.0 or size.y <= 0.0:
		return inner_rect.position + inner_rect.size * 0.5
	var normalized_x := clampf((world_position.x - origin.x) / size.x, 0.0, 1.0)
	var normalized_y := clampf((world_position.y - origin.y) / size.y, 0.0, 1.0)
	return inner_rect.position + Vector2(inner_rect.size.x * normalized_x, inner_rect.size.y * normalized_y)


func _minimap_subrect(inner_rect: Rect2, normalized_rect: Rect2) -> Rect2:
	return Rect2(
		inner_rect.position + Vector2(inner_rect.size.x * normalized_rect.position.x, inner_rect.size.y * normalized_rect.position.y),
		Vector2(inner_rect.size.x * normalized_rect.size.x, inner_rect.size.y * normalized_rect.size.y)
	)


func _minimap_point(inner_rect: Rect2, normalized_point: Vector2) -> Vector2:
	return inner_rect.position + Vector2(inner_rect.size.x * normalized_point.x, inner_rect.size.y * normalized_point.y)
