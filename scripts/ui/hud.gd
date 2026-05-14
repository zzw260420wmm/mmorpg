extends CanvasLayer
class_name GameHUD

const ArtAssetsScript := preload("res://scripts/core/art_assets.gd")

signal dialogue_closed
signal shop_closed
signal shop_item_selected(item: Dictionary)

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

var dialogue_lines: Array = []
var dialogue_index := 0
var current_shop_items: Array[Dictionary] = []


func _ready() -> void:
	layer = 20
	_build_hud()


func update_status(status: Dictionary) -> void:
	date_label.text = status.get("date", "6月1日")
	segment_label.text = status.get("segment", "上午")
	weather_label.text = "天气 %s" % status.get("weather", "阴")
	money_label.text = "  ¥ %d" % status.get("money", 0)
	energy_label.text = "  体力 %d/%d" % [status.get("energy", 0), status.get("max_energy", 100)]
	stress_label.text = "  压力 %d/%d" % [status.get("stress", 0), status.get("max_stress", 100)]
	var delivery_state := str(status.get("delivery_state", "none"))
	if delivery_state == "accepted":
		work_label.text = "  外卖 去取餐"
	elif delivery_state == "picked":
		work_label.text = "  外卖 待送达"
	else:
		work_label.text = "  工作 %s" % status.get("work_performance", "未上班")
	rent_label.text = "  房租 %s" % status.get("rent_label", "7天后交租")
	goals_label.text = _build_goals_text(status)


func show_prompt(text: String) -> void:
	prompt_label.text = text
	prompt_panel.visible = true


func hide_prompt() -> void:
	prompt_panel.visible = false


func show_dialogue(speaker: String, lines: Array) -> void:
	dialogue_lines = lines.duplicate()
	if dialogue_lines.is_empty():
		dialogue_lines = ["……"]
	dialogue_index = 0
	speaker_label.text = speaker
	dialog_panel.visible = true
	shop_panel.visible = false
	hide_prompt()
	_refresh_dialogue_line()


func show_shop(title: String, items: Array[Dictionary]) -> void:
	current_shop_items = items.duplicate()
	shop_title.text = title
	shop_message_label.text = "按数字键购买，按 E 或 Esc 离开。"
	var lines := PackedStringArray()
	for i in range(current_shop_items.size()):
		var item := current_shop_items[i]
		lines.append("%d  %s  ¥%d  体力 +%d" % [i + 1, item.get("name", "商品"), item.get("price", 0), item.get("energy", 0)])
	shop_items_label.text = "\n".join(lines)
	shop_panel.visible = true
	dialog_panel.visible = false
	hide_prompt()


func set_shop_message(message: String) -> void:
	shop_message_label.text = message


func is_blocking() -> bool:
	return dialog_panel.visible or shop_panel.visible


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("interact"):
		if dialog_panel.visible:
			get_viewport().set_input_as_handled()
			_advance_dialogue()
		elif shop_panel.visible:
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


func _advance_dialogue() -> void:
	dialogue_index += 1
	if dialogue_index >= dialogue_lines.size():
		dialog_panel.visible = false
		dialogue_closed.emit()
	else:
		_refresh_dialogue_line()


func _refresh_dialogue_line() -> void:
	dialog_label.text = dialogue_lines[dialogue_index]
	dialog_hint.text = "按 E 继续" if dialogue_index < dialogue_lines.size() - 1 else "按 E 结束"


func _close_shop() -> void:
	shop_panel.visible = false
	shop_closed.emit()


func _build_hud() -> void:
	var root := Control.new()
	root.name = "HUDRoot"
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(root)

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

	var status_box := VBoxContainer.new()
	status_box.add_theme_constant_override("separation", 3)
	status_margin.add_child(status_box)

	date_label = _make_label("6月1日", 15, Color("#3b2d23"))
	segment_label = _make_label("上午", 14, Color("#68442f"))
	weather_label = _make_label("天气 阴", 12, Color("#53666f"))
	money_label = _make_label("¥ 2600", 14, Color("#2f5d45"))
	energy_label = _make_label("体力 78/100", 12, Color("#5b5047"))
	stress_label = _make_label("压力 22/100", 12, Color("#8a4b42"))
	work_label = _make_label("工作 未上班", 12, Color("#6f5a48"))
	rent_label = _make_label("房租 7天后交租", 12, Color("#7b4f30"))
	status_box.add_child(date_label)
	status_box.add_child(segment_label)
	status_box.add_child(weather_label)
	status_box.add_child(money_label)
	status_box.add_child(energy_label)
	status_box.add_child(stress_label)
	status_box.add_child(work_label)
	status_box.add_child(rent_label)
	_add_status_icons(status_panel)

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
	goals_label = _make_label("今日目标\n- 去公司上班\n- 吃点东西\n- 回家睡觉", 11, Color("#ffe9b8"))
	goals_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	goals_margin.add_child(goals_label)

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
	prompt_panel.offset_top = -70
	prompt_panel.offset_bottom = -34
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

	_build_dialog(root)
	_build_shop(root)


func _build_dialog(root: Control) -> void:
	dialog_panel = PanelContainer.new()
	dialog_panel.name = "DialoguePanel"
	dialog_panel.visible = false
	dialog_panel.add_theme_stylebox_override("panel", _panel_style(Color("#f5dfad"), Color("#704f37")))
	dialog_panel.anchor_left = 0.05
	dialog_panel.anchor_right = 0.95
	dialog_panel.anchor_top = 1.0
	dialog_panel.anchor_bottom = 1.0
	dialog_panel.offset_top = -118
	dialog_panel.offset_bottom = -14
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

	speaker_label = _make_label("房东", 14, Color("#68442f"))
	dialog_label = _make_label("你好。", 13, Color("#302821"))
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

	shop_title = _make_label("雨夜便利店", 16, Color("#3b4b34"))
	shop_items_label = _make_label("", 13, Color("#2f342d"))
	shop_message_label = _make_label("", 11, Color("#68704e"))
	shop_items_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	shop_message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(shop_title)
	box.add_child(shop_items_label)
	box.add_child(shop_message_label)


func _add_status_icons(parent: Control) -> void:
	var icons := Control.new()
	icons.name = "StatusIcons"
	icons.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icons.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(icons)
	icons.draw.connect(func() -> void:
		ArtAssetsScript.draw_icon(icons, "money", Vector2(13, 69), 0.75)
		ArtAssetsScript.draw_icon(icons, "energy", Vector2(13, 88), 0.75)
		ArtAssetsScript.draw_icon(icons, "stress", Vector2(13, 107), 0.75)
		ArtAssetsScript.draw_icon(icons, "work", Vector2(13, 126), 0.75)
		ArtAssetsScript.draw_icon(icons, "rent", Vector2(13, 145), 0.75)
	)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _build_goals_text(status: Dictionary) -> String:
	var goals := PackedStringArray()
	var rent_due_in := int(status.get("rent_due_in", 7))
	var rent_overdue := int(status.get("rent_overdue_days", 0))
	var segment_key := str(status.get("segment_key", "morning"))
	var energy := int(status.get("energy", 100))
	var stress := int(status.get("stress", 0))
	var work_performance := str(status.get("work_performance", "未上班"))
	var current_delivery_state := str(status.get("delivery_state", "none"))

	if rent_overdue > 0:
		goals.append("- 房租逾期了，回出租屋交租")
	elif rent_due_in == 0:
		goals.append("- 今天要交房租")
	elif rent_due_in <= 2:
		goals.append("- 准备 ¥%d 房租" % int(status.get("rent_amount", 1200)))

	if current_delivery_state == "accepted":
		goals.append("- 去小饭馆取外卖")
	elif current_delivery_state == "picked":
		goals.append("- 把外卖送到出租楼")
	elif work_performance == "未上班" and segment_key in ["morning", "afternoon"]:
		goals.append("- 选择工作：地铁去写字楼/配送站/传媒公司")
	elif work_performance == "未上班" and segment_key == "evening":
		goals.append("- 想赚钱可去传媒公司晚间开播")
	elif work_performance != "未上班":
		goals.append("- 今天已上班，别忘了恢复状态")

	if energy < 45:
		goals.append("- 去菜场/小饭馆/冰箱恢复体力")
	if stress >= 60:
		goals.append("- 聊天、社区医院或睡觉降低压力")
	if segment_key in ["evening", "late_night"]:
		goals.append("- 回出租屋睡觉进入下一天")
	if goals.is_empty():
		goals.append("- 探索街区，和 NPC 聊聊")
		goals.append("- 规划今天的工作和开销")

	var selected := PackedStringArray()
	for i in range(min(3, goals.size())):
		selected.append(goals[i])
	return "今日目标\n%s" % "\n".join(selected)


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
