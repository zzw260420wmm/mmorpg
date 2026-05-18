extends Control
class_name StartScreen

const MAIN_SCENE_PATH := "res://scenes/world/main.tscn"

var start_button: Button


func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	_build_ui()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if key_event.keycode in [KEY_ENTER, KEY_KP_ENTER, KEY_SPACE, KEY_E]:
			get_viewport().set_input_as_handled()
			_start_game()


func _build_ui() -> void:
	var backdrop := ColorRect.new()
	backdrop.set_anchors_preset(Control.PRESET_FULL_RECT)
	backdrop.color = Color("#191f2b")
	add_child(backdrop)

	var skyline := ColorRect.new()
	skyline.set_anchors_preset(Control.PRESET_FULL_RECT)
	skyline.color = Color(0.38, 0.27, 0.19, 0.20)
	skyline.offset_top = 120
	skyline.offset_bottom = -60
	add_child(skyline)

	var panel := PanelContainer.new()
	panel.anchor_left = 0.5
	panel.anchor_right = 0.5
	panel.anchor_top = 0.5
	panel.anchor_bottom = 0.5
	panel.offset_left = -220
	panel.offset_right = 220
	panel.offset_top = -140
	panel.offset_bottom = 140
	panel.add_theme_stylebox_override("panel", _panel_style(Color(0.16, 0.13, 0.10, 0.90), Color("#e2bf76")))
	add_child(panel)

	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_top", 20)
	margin.add_theme_constant_override("margin_bottom", 18)
	panel.add_child(margin)

	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 10)
	margin.add_child(box)

	var eyebrow := _make_label("五城发展生活模拟 DEMO", 12, Color("#f1d58a"))
	box.add_child(eyebrow)

	var title := _make_label("新路故城", 26, Color("#fff1cf"))
	box.add_child(title)

	var subtitle := _make_label("选择一座城市落脚，从住处、工作和城市委托开始，把人生曲线一点点推上去。", 13, Color("#d5c7b3"))
	subtitle.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	box.add_child(subtitle)

	var bullet_1 := _make_label("方向键移动  互动键操作  取消键关闭对话或面板", 12, Color("#cdbca7"))
	box.add_child(bullet_1)
	var bullet_2 := _make_label("左上小地图显示位置、附近的人和当前目标。", 12, Color("#cdbca7"))
	box.add_child(bullet_2)
	var bullet_3 := _make_label("底部手机图标会打开角色、背包、城市和今日事项。", 12, Color("#cdbca7"))
	box.add_child(bullet_3)

	start_button = Button.new()
	start_button.text = "进入游戏"
	start_button.custom_minimum_size = Vector2(0, 42)
	start_button.focus_mode = Control.FOCUS_NONE
	start_button.pressed.connect(_start_game)
	box.add_child(start_button)

	var hint := _make_label("按确认键、空格键或互动键开始", 11, Color("#9e9386"))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(hint)


func _start_game() -> void:
	get_tree().change_scene_to_file(MAIN_SCENE_PATH)


func _make_label(text: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	return label


func _panel_style(bg: Color, border: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(2)
	style.set_corner_radius_all(8)
	style.shadow_color = Color(0.03, 0.03, 0.04, 0.28)
	style.shadow_size = 6
	style.content_margin_left = 4
	style.content_margin_right = 4
	style.content_margin_top = 4
	style.content_margin_bottom = 4
	return style
