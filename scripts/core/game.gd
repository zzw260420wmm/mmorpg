extends Node2D

const TimeManagerScript := preload("res://scripts/core/time_manager.gd")
const CityMapScript := preload("res://scripts/world/city_map.gd")
const ApartmentInteriorScript := preload("res://scripts/world/apartment_interior.gd")
const OfficeInteriorScript := preload("res://scripts/world/office_interior.gd")
const MediaCompanyInteriorScript := preload("res://scripts/world/media_company_interior.gd")
const MetroStationInteriorScript := preload("res://scripts/world/metro_station_interior.gd")
const WetMarketInteriorScript := preload("res://scripts/world/wet_market_interior.gd")
const ClinicInteriorScript := preload("res://scripts/world/clinic_interior.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")
const NpcScene := preload("res://scenes/npc/npc.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")

var time_manager: TimeManager
var city_map: CityMap
var apartment: ApartmentInterior
var office: OfficeInterior
var media_company: MediaCompanyInterior
var metro_station: MetroStationInterior
var wet_market: WetMarketInterior
var clinic: ClinicInterior
var player: Player
var hud: GameHUD
var canvas_modulate: CanvasModulate
var npcs: Array[LifeNpc] = []
var current_location := "street"
var last_street_position := Vector2.ZERO
var office_return_position := Vector2(1088, 278)
var media_return_position := Vector2(896, 214)
var metro_return_position := Vector2(720, 468)
var market_return_position := Vector2(272, 790)
var clinic_return_position := Vector2(528, 726)
var active_housing_id := "urban_village"
var home_street_position := Vector2(152, 190)
var housing_sleep_energy := 100
var housing_sleep_stress_relief := 28
var housing_fridge_energy := 8
var housing_fridge_stress_relief := 2
var housing_rent_stress_relief := 8
var housing_morning_line := "合租楼里的脚步声比闹钟更早。"
var delivery_state := "none"
var delivery_orders_completed_today := 0
var npc_relationships := {}
var npc_social_profiles := {}
var talked_today := {}
var pending_morning_notice: Array[String] = []
var inventory_items: Array[Dictionary] = []


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#1b2430"))

	time_manager = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	add_child(time_manager)

	canvas_modulate = CanvasModulate.new()
	canvas_modulate.name = "WorldLight"
	add_child(canvas_modulate)

	city_map = CityMapScript.new()
	city_map.name = "ShanghaiVillageMap"
	add_child(city_map)

	apartment = ApartmentInteriorScript.new()
	apartment.name = "ApartmentInterior"
	apartment.visible = false
	apartment.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(apartment)
	apartment.set_housing_variant(active_housing_id, "城中村合租")

	office = OfficeInteriorScript.new()
	office.name = "OfficeInterior"
	office.visible = false
	office.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(office)

	media_company = MediaCompanyInteriorScript.new()
	media_company.name = "MediaCompanyInterior"
	media_company.visible = false
	media_company.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(media_company)

	metro_station = MetroStationInteriorScript.new()
	metro_station.name = "MetroStationInterior"
	metro_station.visible = false
	metro_station.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(metro_station)

	wet_market = WetMarketInteriorScript.new()
	wet_market.name = "WetMarketInterior"
	wet_market.visible = false
	wet_market.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(wet_market)

	clinic = ClinicInteriorScript.new()
	clinic.name = "ClinicInterior"
	clinic.visible = false
	clinic.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(clinic)

	player = PlayerScene.instantiate() as Player
	player.name = "Player"
	player.global_position = city_map.get_player_spawn()
	last_street_position = player.global_position
	player.interact_pressed.connect(_on_player_interact_pressed)
	player.focused_interactable_changed.connect(_on_focused_interactable_changed)
	add_child(player)
	player.set_camera_limits(city_map.get_world_rect())

	_spawn_npcs()
	_set_collision_tree_enabled(apartment, false)
	_set_collision_tree_enabled(office, false)
	_set_collision_tree_enabled(media_company, false)
	_set_collision_tree_enabled(metro_station, false)
	_set_collision_tree_enabled(wet_market, false)
	_set_collision_tree_enabled(clinic, false)

	hud = HudScene.instantiate() as GameHUD
	add_child(hud)
	hud.dialogue_closed.connect(_resume_player_after_ui)
	hud.shop_closed.connect(_resume_player_after_ui)
	hud.shop_item_selected.connect(_on_shop_item_selected)
	hud.inventory_item_used.connect(_on_inventory_item_used)

	time_manager.status_changed.connect(_on_status_changed)
	time_manager.time_segment_changed.connect(_on_time_segment_changed)
	time_manager.weather_changed.connect(_on_weather_changed)
	time_manager.day_started.connect(_on_day_started)
	_on_status_changed(time_manager.get_status())
	_on_time_segment_changed(time_manager.get_segment_key(), time_manager.get_segment_label())
	_on_weather_changed(time_manager.weather_key, time_manager.get_weather_label())
	_update_time_flow()
	_update_hud_navigation()


func _process(_delta: float) -> void:
	_update_hud_navigation()


func show_dialogue(speaker: String, lines: Array) -> void:
	player.set_controls_enabled(false)
	time_manager.set_time_paused(true)
	hud.show_dialogue(speaker, lines)


func enter_apartment_from(source: Node) -> void:
	if active_housing_id != "urban_village":
		var source_id := ""
		if source != null:
			var interactable_id: Variant = source.get("interactable_id")
			if interactable_id is String:
				source_id = interactable_id
		if source_id == "rental_door":
			show_dialogue("旧出租屋", [
				"你已经从这里搬走了。",
				"现在的家在手机“城”里能看到，回去会从新的家门口出现。",
			])
			return
	enter_apartment()


func open_shop(source: Node) -> void:
	player.set_controls_enabled(false)
	time_manager.set_time_paused(true)
	var shop_title := "街角小店"
	var source_id := ""
	if source != null:
		var display_name: Variant = source.get("display_name")
		if display_name is String and not display_name.is_empty():
			shop_title = display_name
		var interactable_id: Variant = source.get("interactable_id")
		if interactable_id is String:
			source_id = interactable_id
	hud.show_shop(shop_title, _get_shop_items(source_id))


func enter_apartment() -> void:
	last_street_position = player.global_position + Vector2(0, 18)
	current_location = "apartment"
	city_map.visible = false
	city_map.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, false)
	for npc in npcs:
		npc.visible = false
		npc.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(npc, false)
	apartment.visible = true
	apartment.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(apartment, true)
	player.global_position = apartment.get_player_spawn()
	player.set_camera_limits(apartment.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_office(from_commute: bool = false) -> void:
	if not from_commute:
		office_return_position = player.global_position + Vector2(0, 20)
	current_location = "office"
	city_map.visible = false
	city_map.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, false)
	for npc in npcs:
		npc.visible = false
		npc.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(npc, false)
	if metro_station != null:
		metro_station.visible = false
		metro_station.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(metro_station, false)
	office.visible = true
	office.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(office, true)
	player.global_position = office.get_player_spawn()
	player.set_camera_limits(office.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_media_company() -> void:
	media_return_position = player.global_position + Vector2(0, 20)
	current_location = "media_company"
	city_map.visible = false
	city_map.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, false)
	for npc in npcs:
		npc.visible = false
		npc.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(npc, false)
	media_company.visible = true
	media_company.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(media_company, true)
	player.global_position = media_company.get_player_spawn()
	player.set_camera_limits(media_company.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_metro_station() -> void:
	metro_return_position = player.global_position + Vector2(0, 20)
	current_location = "metro_station"
	city_map.visible = false
	city_map.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, false)
	for npc in npcs:
		npc.visible = false
		npc.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(npc, false)
	metro_station.visible = true
	metro_station.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(metro_station, true)
	player.global_position = metro_station.get_player_spawn()
	player.set_camera_limits(metro_station.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_wet_market() -> void:
	market_return_position = player.global_position + Vector2(0, 20)
	current_location = "wet_market"
	city_map.visible = false
	city_map.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, false)
	for npc in npcs:
		npc.visible = false
		npc.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(npc, false)
	wet_market.visible = true
	wet_market.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(wet_market, true)
	player.global_position = wet_market.get_player_spawn()
	player.set_camera_limits(wet_market.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_clinic() -> void:
	clinic_return_position = player.global_position + Vector2(0, 20)
	current_location = "clinic"
	city_map.visible = false
	city_map.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, false)
	for npc in npcs:
		npc.visible = false
		npc.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(npc, false)
	clinic.visible = true
	clinic.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(clinic, true)
	player.global_position = clinic.get_player_spawn()
	player.set_camera_limits(clinic.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_apartment() -> void:
	current_location = "street"
	apartment.visible = false
	apartment.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(apartment, false)
	city_map.visible = true
	city_map.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(city_map, true)
	for npc in npcs:
		npc.visible = true
		npc.process_mode = Node.PROCESS_MODE_INHERIT
		_set_collision_tree_enabled(npc, true)
	player.global_position = home_street_position
	player.set_camera_limits(city_map.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_office() -> void:
	current_location = "street"
	office.visible = false
	office.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(office, false)
	city_map.visible = true
	city_map.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(city_map, true)
	for npc in npcs:
		npc.visible = true
		npc.process_mode = Node.PROCESS_MODE_INHERIT
		_set_collision_tree_enabled(npc, true)
	player.global_position = office_return_position
	player.set_camera_limits(city_map.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_media_company() -> void:
	current_location = "street"
	media_company.visible = false
	media_company.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(media_company, false)
	city_map.visible = true
	city_map.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(city_map, true)
	for npc in npcs:
		npc.visible = true
		npc.process_mode = Node.PROCESS_MODE_INHERIT
		_set_collision_tree_enabled(npc, true)
	player.global_position = media_return_position
	player.set_camera_limits(city_map.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_metro_station() -> void:
	current_location = "street"
	metro_station.visible = false
	metro_station.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(metro_station, false)
	city_map.visible = true
	city_map.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(city_map, true)
	for npc in npcs:
		npc.visible = true
		npc.process_mode = Node.PROCESS_MODE_INHERIT
		_set_collision_tree_enabled(npc, true)
	player.global_position = metro_return_position
	player.set_camera_limits(city_map.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_wet_market() -> void:
	current_location = "street"
	wet_market.visible = false
	wet_market.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(wet_market, false)
	city_map.visible = true
	city_map.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(city_map, true)
	for npc in npcs:
		npc.visible = true
		npc.process_mode = Node.PROCESS_MODE_INHERIT
		_set_collision_tree_enabled(npc, true)
	player.global_position = market_return_position
	player.set_camera_limits(city_map.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_clinic() -> void:
	current_location = "street"
	clinic.visible = false
	clinic.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(clinic, false)
	city_map.visible = true
	city_map.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(city_map, true)
	for npc in npcs:
		npc.visible = true
		npc.process_mode = Node.PROCESS_MODE_INHERIT
		_set_collision_tree_enabled(npc, true)
	player.global_position = clinic_return_position
	player.set_camera_limits(city_map.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func request_commute_work() -> void:
	player.set_controls_enabled(false)
	var fare: int = time_manager.commute_fare
	var commute_speaker := "地铁闸机" if current_location == "metro_station" else "地铁口"
	if time_manager.get_segment_key() in ["evening", "late_night"]:
		hud.show_dialogue(commute_speaker, [
			"这个点再去公司，只会变成无意义的加班。",
			"还是留到明天上午吧。",
		])
		return
	if time_manager.energy < time_manager.commute_energy_cost:
		hud.show_dialogue(commute_speaker, [
			"你现在太累了，撑不过这一趟通勤。",
			"先吃点东西，或者回去缓一缓。",
		])
		return
	if not time_manager.spend(fare):
		hud.show_dialogue(commute_speaker, [
			"交通卡余额不够。",
			"进闸至少需要 %d 元。" % fare,
		])
		return

	_apply_commute_time_jump()
	office_return_position = Vector2(1088, 278)
	enter_office(true)
	var commute_lines := [
		_get_commute_line(),
	]
	commute_lines.append_array(_apply_commute_day_event())
	commute_lines.append("你到了公司。去工位选择今天要做的工作。")
	hud.show_dialogue("通勤", commute_lines)



func request_job_work(job_id: String) -> void:
	player.set_controls_enabled(false)
	var work_result: Dictionary = _calculate_work_result(job_id)
	var wage: int = int(work_result["wage"])
	var energy_cost: int = int(work_result["energy_cost"])
	var stress_gain: int = int(work_result["stress_gain"])
	var performance: String = str(work_result["performance"])
	var job_name: String = str(work_result["job_name"])
	if time_manager.get_segment_key() in ["evening", "late_night"]:
		if job_id == "job_streamer" and time_manager.get_segment_key() == "evening":
			energy_cost += 6
			stress_gain += 8
		else:
			hud.show_dialogue(job_name, [
				"现在开始这份班太晚了。",
				"明天上午再来，或者去找适合夜间的工作。",
			])
			return
	if time_manager.energy < energy_cost:
		hud.show_dialogue(job_name, [
			"你坐到工位前，发现自己根本集中不了。",
			"体力太低了。先吃点包里的东西，或者回去休息。",
		])
		return

	var work_event := _apply_workday_event(job_id, wage, energy_cost, stress_gain)
	wage = int(work_event["wage"])
	energy_cost = int(work_event["energy_cost"])
	stress_gain = int(work_event["stress_gain"])
	var event_lines: Array = work_event["lines"]
	var return_segment: String = "late_night" if job_id == "job_streamer" and time_manager.get_segment_key() == "evening" else "evening"
	var worked: bool = time_manager.complete_work_shift(wage, energy_cost, return_segment, performance)
	if not worked:
		var fail_lines := event_lines.duplicate()
		fail_lines.append("临时状况让这份工作比预想更耗体力，你今天撑不完。")
		hud.show_dialogue(job_name, fail_lines)
		return
	time_manager.add_stress(stress_gain)
	if current_location == "media_company":
		media_return_position = Vector2(896, 214)
		exit_media_company()
	else:
		office_return_position = Vector2(1088, 278)
		exit_office()
	var result_lines: Array = [str(work_result["work_line"])]
	result_lines.append_array(event_lines)
	result_lines.append("结果：%s。收入 +%d，体力 -%d，压力 +%d。" % [performance, wage, energy_cost, stress_gain])
	result_lines.append(_get_work_return_line(job_id))
	hud.show_dialogue(job_name, result_lines)

func request_fridge_food() -> void:
	player.set_controls_enabled(false)
	time_manager.recover_energy(housing_fridge_energy)
	time_manager.relieve_stress(housing_fridge_stress_relief)
	hud.show_dialogue(_get_housing_fridge_title(), [
		_get_housing_fridge_line(),
		"体力 +%d，压力 -%d。" % [housing_fridge_energy, housing_fridge_stress_relief],
	])




func request_pay_rent() -> void:
	player.set_controls_enabled(false)
	if time_manager.pay_rent():
		var timing_line := "转账完成。房租 -%d。" % time_manager.rent_amount
		if time_manager.get_rent_due_in_days() > time_manager.rent_cycle_days:
			timing_line = "你提前交了房租。房租 -%d。" % time_manager.rent_amount
		time_manager.add_stress(8 - housing_rent_stress_relief)
		var rent_lines := [
			timing_line,
			_get_housing_rent_relief_line(),
		]
		if _get_relationship_value("landlord") >= 7:
			time_manager.relieve_stress(3)
			rent_lines.append("陈房东没有多催你，还提醒你下次提前留现金。熟人关系让压力额外 -3。")
		hud.show_dialogue("房租单", rent_lines)
	else:
		hud.show_dialogue("房租单", [
			"你的钱不够交房租，还需要 %d。" % time_manager.rent_amount,
			"这意味着明天大概率又是工作日。",
		])



func request_clinic_visit() -> void:
	player.set_controls_enabled(false)
	var fee := 48
	if time_manager.energy >= 82 and time_manager.stress < 35:
		hud.show_dialogue("社区诊所", [
			"你在自助机前停了一下，发现自己今天还能撑。",
			"挂号费还是留到真正需要的时候吧。",
		])
		return
	if not time_manager.spend(fee):
		hud.show_dialogue("社区诊所", [
			"挂号需要 %d 元。" % fee,
			"你现金不够，只能在候诊椅上坐一会儿，慢慢喘口气。",
		])
		return
	time_manager.recover_energy(16)
	time_manager.relieve_stress(22)
	hud.show_dialogue("社区诊所", [
		"医生说你主要是太累，作息也乱了。",
		"挂号费 %d。体力 +16，压力 -22。" % fee,
	])




func inspect_rental_agency(_source: Node) -> void:
	player.set_controls_enabled(false)
	var due_in := time_manager.get_rent_due_in_days()
	var lines := [
		"中介墙上贴满了取舍：通勤近的更贵，便宜的离地铁更远。",
	]
	if due_in < 0:
		lines.append("你现在的房租已经逾期，搬家也不太现实。")
	elif due_in <= 2:
		lines.append("房租快到期了，每一笔额外开销都会更重。")
	else:
		lines.append("离下次房租还有点时间，可以认真比较一下。")
	lines.append("住房压力会改变之后每一天的通勤、体力和心情。")
	hud.show_dialogue("房产中介", lines)


func open_housing_agency(source: Node) -> void:
	player.set_controls_enabled(false)
	time_manager.set_time_paused(true)
	var shop_title := "房产中介"
	if source != null:
		var display_name: Variant = source.get("display_name")
		if display_name is String and not display_name.is_empty():
			shop_title = display_name
	hud.show_shop(shop_title, _get_shop_items("rental_agency"))




func inspect_talent_apartment(_source: Node) -> void:
	player.set_controls_enabled(false)
	if active_housing_id == "talent_apartment":
		enter_apartment()
		show_dialogue("人才公寓", [
			"你刷门禁进了现在的住处。",
			"这里比城中村干净一些，但房租也更像一只计时器。",
		])
		return
	var lines := [
		"人才公寓看起来比你现在住的地方体面不少，也贵不少。",
	]
	if time_manager.money >= time_manager.rent_amount:
		lines.append("如果存款继续涨，之后升级住房也许说得过去。")
	else:
		lines.append("现在还是便宜房租和能活下去更重要。")
	lines.append("如果在中介签了人才公寓合同，这里会变成你的新家门口。")
	hud.show_dialogue("人才公寓", lines)




func inspect_office(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"写字楼大堂干净、冷，安静得像在催你赶紧变专业。",
	]
	if time_manager.stress >= 70:
		lines.append("光是看到这栋楼，你肩膀就开始发紧。")
	elif time_manager.stress >= 40:
		lines.append("你还能撑一份班，但肯定会付出点代价。")
	else:
		lines.append("你今天还有余力把事情做完。")
	lines.append("你上楼进公司，可以在工位选择今天的白领工作。")
	office_return_position = player.global_position + Vector2(0, 20)
	enter_office(false)
	show_dialogue("写字楼入口", lines)




func inspect_media_company(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"传媒公司这一层很亮、很精致，也有点消耗人。",
	]
	if time_manager.get_segment_key() == "morning":
		lines.append("直播间刚醒，这是准备主播工作的好时间。")
	elif time_manager.get_segment_key() == "late_night":
		lines.append("这个点的灯光比收入更刺眼。")
	else:
		lines.append("主播工作用体力和压力换钱，也用表情管理换奖励。")
	lines.append("你走进去，可以决定今晚要不要继续硬撑。")
	enter_media_company()
	show_dialogue("传媒公司", lines)




func inspect_metro_station(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"地铁站里全是闸机声、脚步声和远处进站的风。",
	]
	if active_housing_id == "far_suburb" and time_manager.get_segment_key() in ["evening", "late_night"]:
		enter_apartment()
		show_dialogue("远郊回家路", [
			"你从这里转回远郊单间。",
			"房租低一点，但每次回家都像多走了一截人生。",
		])
		return
	if time_manager.get_segment_key() == "morning":
		lines.append("早高峰已经挤起来了，这是去公司的最快方式。")
	elif time_manager.get_segment_key() == "evening":
		lines.append("晚高峰让每个平台都像变窄了一点。")
	elif time_manager.get_segment_key() == "late_night":
		lines.append("班次已经变少了。没必要的话，回家更聪明。")
	else:
		lines.append("当你想用钱换时间，地铁仍然是最稳定的捷径。")
	enter_metro_station()
	show_dialogue("地铁站", lines)




func request_delivery_order() -> void:
	player.set_controls_enabled(false)
	if time_manager.get_segment_key() == "late_night":
		hud.show_dialogue("配送站", [
			"这个点已经不派新单了。",
			"白天早点再来。",
		])
		return
	if delivery_state != "none":
		hud.show_dialogue("配送站", [
			"你手上已经有一单了。",
			_get_delivery_instruction(),
		])
		return
	if delivery_orders_completed_today >= 1:
		hud.show_dialogue("配送站", [
			"当前 DEMO 每天只开放一单外卖配送。",
			"可以试试别的工作，或者明天再来。",
		])
		return
	if time_manager.energy < 32:
		hud.show_dialogue("配送站", [
			"你太累了，不适合接新的路线。",
			"先吃点东西或者回去休息。",
		])
		return

	delivery_state = "accepted"
	time_manager.consume_energy(6)
	time_manager.add_stress(3)
	hud.show_dialogue("配送站", [
		"你从站点板上接了一单外卖。",
		"体力 -6，压力 +3。现在去取餐。",
	])
	_on_status_changed(time_manager.get_status())




func request_delivery_pickup() -> void:
	player.set_controls_enabled(false)
	if delivery_state == "none":
		hud.show_dialogue("取餐点", [
			"你还没有接单。",
			"先去配送站接一单。",
		])
		return
	if delivery_state == "picked":
		hud.show_dialogue("取餐点", [
			"你已经取过餐了。",
			"去顾客那里完成配送。",
		])
		return

	delivery_state = "picked"
	time_manager.consume_energy(8)
	hud.show_dialogue("取餐点", [
		"餐已经打包好，可以走了。",
		"体力 -8。现在去送餐。",
	])
	_on_status_changed(time_manager.get_status())



func request_delivery_dropoff() -> void:
	player.set_controls_enabled(false)
	if delivery_state == "none":
		hud.show_dialogue("送达点", [
			"你现在没有进行中的订单。",
			"先接单、取餐，再来送达。",
		])
		return
	if delivery_state != "picked":
		hud.show_dialogue("送达点", [
			"这单还没取餐，不能送达。",
			"先去取餐，再来顾客这里。",
		])
		return

	var reward := 58
	var energy_cost := 14
	var stress_gain := 8
	var performance := "稳定"
	var line := "你穿过街区，在饭菜变凉前把外卖送到。"
	if time_manager.is_rainy():
		reward += 18
		stress_gain += 6
		line = "雨天拖慢了所有人，但额外配送费让这趟还算值得。"
	if time_manager.energy >= 70:
		reward += 12
		performance = "专注"
	elif time_manager.energy < 38:
		reward -= 10
		stress_gain += 4
		performance = "透支"
	var bonus_line := ""
	if _get_relationship_value("delivery_captain") >= 7:
		reward += 18
		stress_gain = max(0, stress_gain - 2)
		bonus_line = "赵队提前把电梯口和小区门的位置告诉你，少绕了一圈。熟人加成：收入 +18，压力 -2。"

	if not time_manager.consume_energy(energy_cost):
		hud.show_dialogue("送达点", [
			"你太累了，已经不适合安全完成这趟路线。",
			"先吃点东西或者休息一下。",
		])
		return

	delivery_state = "none"
	delivery_orders_completed_today += 1
	time_manager.add_money(max(35, reward))
	time_manager.add_stress(stress_gain)
	time_manager.record_work_performance("外卖%s" % performance)
	time_manager.set_segment("evening")
	var result_lines := [
		line,
		"结果：%s。收入 +%d，体力 -%d，压力 +%d。" % [performance, max(35, reward), energy_cost, stress_gain],
		"这趟结束了。你可以恢复一下、买补给，或者回家。",
	]
	if not bonus_line.is_empty():
		result_lines.insert(1, bonus_line)
	hud.show_dialogue("送达点", result_lines)



func request_sleep() -> void:
	player.set_controls_enabled(false)
	time_manager.sleep_to_next_day(housing_sleep_energy, housing_sleep_stress_relief)
	if current_location == "street":
		enter_apartment()
	var lines := [
		"你终于睡了一觉。",
		_get_housing_sleep_line(),
	]
	lines.append_array(pending_morning_notice)
	pending_morning_notice.clear()
	hud.show_dialogue("睡觉", lines)




func _spawn_npcs() -> void:
	var npc_data: Array[Dictionary] = [
		{
			"id": "landlord",
			"name": "陈房东",
			"role": "landlord",
			"position": Vector2(204, 214),
			"palette": {"hair": Color("#3a3029"), "skin": Color("#c49167"), "shirt": Color("#8d7560")},
			"routes": {
				"morning": [Vector2(206, 214), Vector2(216, 258), Vector2(154, 258), Vector2(154, 214)],
				"afternoon": [Vector2(188, 198), Vector2(236, 226), Vector2(1280, 576), Vector2(218, 276)],
				"evening": [Vector2(132, 204), Vector2(202, 204)],
				"late_night": [Vector2(118, 190)],
			},
			"dialogue": {
				"default": ["房租不只是数字，它决定你还有多少喘气的空间。"],
				"morning": ["早。趁这一周还没跑远，先看看钱包。"],
				"afternoon": ["今天弄堂很吵。街越吵，拖房租的人越多。"],
				"evening": ["又这么晚回来？上海不会因为人累就慢下来。"],
				"late_night": ["轻一点，整栋楼都在努力睡着。"],
			},
		},
		{
			"id": "shopkeeper",
			"name": "林阿姨",
			"role": "shopkeeper",
			"position": Vector2(612, 222),
			"palette": {"hair": Color("#25262b"), "skin": Color("#d6a373"), "shirt": Color("#3f806f")},
			"routes": {
				"morning": [Vector2(612, 222), Vector2(704, 222), Vector2(272, 768)],
				"afternoon": [Vector2(636, 212), Vector2(710, 212), Vector2(710, 248)],
				"evening": [Vector2(618, 228), Vector2(690, 228), Vector2(690, 252)],
				"late_night": [Vector2(646, 214)],
			},
			"dialogue": {
				"default": ["买的东西会先进包里，等日子咬人的时候再用。"],
				"morning": ["豆浆是热的，鸡蛋是新鲜的，你老板可不一定。"],
				"afternoon": ["午高峰过去了，现在买东西不用被人挤。"],
				"evening": ["便利店食物不浪漫，但能救一个晚上。"],
				"late_night": ["只剩快手东西了，连货架都显得累。"],
			},
		},
		{
			"id": "girl",
			"name": "小米",
			"role": "drifter",
			"position": Vector2(332, 260),
			"palette": {"hair": Color("#241b22"), "skin": Color("#d8a17b"), "shirt": Color("#c55b70")},
			"routes": {
				"morning": [Vector2(170, 248), Vector2(380, 296), Vector2(704, 382)],
				"afternoon": [Vector2(338, 286), Vector2(528, 704), Vector2(316, 360)],
				"evening": [Vector2(716, 386), Vector2(1344, 278), Vector2(658, 218)],
				"late_night": [Vector2(656, 238), Vector2(520, 268), Vector2(340, 354)],
			},
			"dialogue": {
				"default": ["这里的人一直在动。你停太久，城市就会开始问你问题。"],
				"morning": ["我喜欢第一班地铁的声音，好像每个人今天都有计划。"],
				"afternoon": ["压力高的时候，先走一圈，别急着再买咖啡。"],
				"evening": ["霓虹灯会把街照得比我们任何人都富。"],
				"late_night": ["深夜的空气很诚实，会直接告诉你有多累。"],
			},
		},
		{
			"id": "delivery_captain",
			"name": "赵队",
			"role": "delivery_rider",
			"position": Vector2(1044, 520),
			"palette": {"hair": Color("#1f2428"), "skin": Color("#c49167"), "shirt": Color("#d29b2e")},
			"routes": {
				"morning": [Vector2(1044, 520), Vector2(1118, 496), Vector2(1216, 512)],
				"afternoon": [Vector2(1038, 520), Vector2(1120, 548), Vector2(1210, 532)],
				"evening": [Vector2(1084, 518), Vector2(1216, 512), Vector2(1078, 552)],
				"late_night": [Vector2(1052, 520), Vector2(1070, 520)],
			},
			"dialogue": {
				"default": ["单子来钱快，但城市先收你的体力。"],
				"morning": ["早餐单短，能跑的话适合热身。"],
				"afternoon": ["下雨会让每一单都变成和路面的谈判。"],
				"evening": ["晚高峰是钱、压力和车流一起砸过来。"],
				"late_night": ["这个点别逞英雄，只接你能送完的。"],
			},
		},
		{
			"id": "streamer_npc",
			"name": "露娜",
			"role": "streamer",
			"position": Vector2(936, 220),
			"palette": {"hair": Color("#2b2527"), "skin": Color("#d8a17b"), "shirt": Color("#c26c74")},
			"routes": {
				"morning": [Vector2(936, 220), Vector2(902, 220), Vector2(930, 252)],
				"afternoon": [Vector2(934, 222), Vector2(1012, 316), Vector2(1216, 512)],
				"evening": [Vector2(936, 220), Vector2(960, 220), Vector2(936, 220)],
				"late_night": [Vector2(934, 224), Vector2(900, 224)],
			},
			"dialogue": {
				"default": ["镜头喜欢自信，算法喜欢耗尽的人。"],
				"morning": ["早场直播很安静，但安静有时候也有用。"],
				"afternoon": ["天气差的时候，下午场观众反而更容易打赏。"],
				"evening": ["黄金档会给钱，然后从你的神经上收利息。"],
				"late_night": ["在直播结束你之前，先结束直播。"],
			},
		},
		{
			"id": "office_worker_npc",
			"name": "徐同事",
			"role": "office_worker",
			"position": Vector2(1088, 330),
			"palette": {"hair": Color("#24292f"), "skin": Color("#d6a373"), "shirt": Color("#5d6870")},
			"routes": {
				"morning": [Vector2(716, 386), Vector2(1050, 330), Vector2(1138, 318)],
				"afternoon": [Vector2(1088, 278), Vector2(1216, 512), Vector2(1280, 576), Vector2(1088, 278)],
				"evening": [Vector2(1088, 278), Vector2(1344, 278), Vector2(716, 386)],
				"late_night": [Vector2(1138, 318), Vector2(1038, 336)],
			},
			"dialogue": {
				"default": ["白领工作大多是在选择哪种压力先暴露出来。"],
				"morning": ["会前到显得你准备充分，会后到你就会变成议题。"],
				"afternoon": ["午饭后，每张表格都像天气预报。"],
				"evening": ["准点下班是一门技能，不是每个人都能学会。"],
				"late_night": ["如果你还在这里，至少把灯当成星星吧。"],
			},
		},
		{
			"id": "metro_commuter_npc",
			"name": "孙通勤",
			"role": "metro_commuter",
			"position": Vector2(706, 386),
			"palette": {"hair": Color("#3b302b"), "skin": Color("#c49167"), "shirt": Color("#6b7280")},
			"routes": {
				"morning": [Vector2(650, 398), Vector2(706, 386), Vector2(742, 390)],
				"afternoon": [Vector2(704, 382), Vector2(528, 704), Vector2(704, 382)],
				"evening": [Vector2(742, 390), Vector2(706, 386), Vector2(650, 398)],
				"late_night": [Vector2(704, 382), Vector2(718, 382)],
			},
			"dialogue": {
				"default": ["地铁不在乎你的计划，只在乎你有没有赶到闸机前。"],
				"morning": ["第一波人最诚实，大家都还半醒。"],
				"afternoon": ["非高峰坐车，像是从城市那里借到一点时间。"],
				"evening": ["晚班车把所有没说完的话一起带回家。"],
				"late_night": ["末班车会让人很快计算自己的人生。"],
			},
		},
	]

	for data in npc_data:
		var npc := NpcScene.instantiate() as LifeNpc
		npc.configure(data)
		npc_relationships[npc.npc_id] = 0
		npc_social_profiles[npc.npc_id] = {
			"name": npc.npc_name,
			"role": npc.role,
		}
		add_child(npc)
		npcs.append(npc)

func register_npc_talk(npc_id: String) -> String:
	var current_value: int = int(npc_relationships.get(npc_id, 0))
	if talked_today.has(npc_id):
		if _has_shareable_gift():
			return _give_first_shareable_item(npc_id)
		if npc_id == "landlord":
			return "今天已经聊过了。%s。%s 包里有食物时，再互动可以分享。" % [_get_relationship_summary_line(npc_id), _get_landlord_rent_line()]
		return "今天已经聊过了。%s。包里有食物时，再互动可以分享。" % _get_relationship_summary_line(npc_id)

	var old_value := current_value
	current_value = min(12, current_value + 1)
	npc_relationships[npc_id] = current_value
	talked_today[npc_id] = true
	var stress_relief := _get_relationship_stress_relief(current_value)
	time_manager.relieve_stress(stress_relief)
	_update_npc_relationship_visual(npc_id)
	_on_status_changed(time_manager.get_status())
	var event_line := _get_relationship_event_line(npc_id, old_value, current_value)
	var relationship_gain: int = current_value - old_value
	if npc_id == "landlord":
		var landlord_line := "和房东聊了几句。关系 +%d，压力 -%d。%s。%s" % [relationship_gain, stress_relief, _get_relationship_summary_line(npc_id), _get_landlord_rent_line()]
		if not event_line.is_empty():
			return "%s %s" % [landlord_line, event_line]
		return landlord_line
	var profile: Dictionary = npc_social_profiles.get(npc_id, {})
	var npc_name := str(profile.get("name", "对方"))
	var talk_line := "你和%s在街边短短聊了一会儿。关系 +%d，压力 -%d。%s。" % [npc_name, relationship_gain, stress_relief, _get_relationship_summary_line(npc_id)]
	if not event_line.is_empty():
		return "%s %s" % [talk_line, event_line]
	return talk_line

func _on_player_interact_pressed(interactable: Node) -> void:
	if hud != null and hud.is_blocking():
		return
	if interactable != null and interactable.has_method("interact"):
		hud.hide_prompt()
		interactable.call("interact", self)


func _on_focused_interactable_changed(interactable: Node) -> void:
	if hud == null or hud.is_blocking():
		return
	if interactable != null and interactable.has_method("get_prompt"):
		hud.show_prompt(str(interactable.call("get_prompt")))
	else:
		hud.hide_prompt()


func _on_status_changed(status: Dictionary) -> void:
	if hud != null:
		var display_status: Dictionary = status.duplicate()
		display_status["delivery_state"] = delivery_state
		display_status["delivery_orders_completed"] = delivery_orders_completed_today
		display_status["relationships"] = _get_relationship_snapshot()
		display_status["talked_today_count"] = talked_today.size()
		display_status["npc_count"] = npc_relationships.size()
		display_status["relationship_perks"] = _get_relationship_perk_lines()
		hud.update_status(display_status)
		hud.update_function_bar(display_status, _get_inventory_snapshot())
		_update_hud_navigation()


func _get_inventory_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for item_variant in inventory_items:
		var item: Dictionary = item_variant
		var item_copy: Dictionary = item.duplicate()
		snapshot.append(item_copy)
	return snapshot


func _store_inventory_item(item: Dictionary) -> void:
	var item_id: String = str(item.get("id", str(item.get("name", "item"))))
	for i in range(inventory_items.size()):
		var stored_item: Dictionary = inventory_items[i]
		if str(stored_item.get("id", "")) != item_id:
			continue
		stored_item["quantity"] = int(stored_item.get("quantity", 1)) + 1
		inventory_items[i] = stored_item
		_on_status_changed(time_manager.get_status())
		return

	var new_item := {
		"id": item_id,
		"name": str(item.get("name", "物品")),
		"price": int(item.get("price", 0)),
		"energy": int(item.get("energy", 0)),
		"stress_relief": int(item.get("stress_relief", 0)),
		"quantity": 1,
	}
	inventory_items.append(new_item)
	_on_status_changed(time_manager.get_status())


func _get_relationship_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for npc in npcs:
		var value: int = int(npc_relationships.get(npc.npc_id, 0))
		var profile: Dictionary = npc_social_profiles.get(npc.npc_id, {})
		snapshot.append({
			"id": npc.npc_id,
			"name": str(profile.get("name", npc.npc_name)),
			"role": str(profile.get("role", npc.role)),
			"value": value,
			"level": _get_relationship_level(value),
			"progress": _get_relationship_progress(value),
			"talked_today": talked_today.has(npc.npc_id),
		})
	return snapshot


func _get_relationship_value(npc_id: String) -> int:
	return int(npc_relationships.get(npc_id, 0))


func _get_relationship_level(value: int) -> String:
	if value >= 12:
		return "可靠"
	if value >= 7:
		return "熟人"
	if value >= 3:
		return "点头之交"
	return "陌生"


func _get_relationship_progress(value: int) -> int:
	if value >= 12:
		return 4
	if value >= 7:
		return 3
	if value >= 3:
		return 2
	if value >= 1:
		return 1
	return 0


func _get_relationship_stress_relief(value: int) -> int:
	if value >= 12:
		return 6
	if value >= 7:
		return 5
	if value >= 3:
		return 4
	return 3


func _get_relationship_summary_line(npc_id: String) -> String:
	var value: int = int(npc_relationships.get(npc_id, 0))
	return "关系 %s %d/12" % [_get_relationship_level(value), value]


func _has_shareable_gift() -> bool:
	for item_variant in inventory_items:
		var item: Dictionary = item_variant
		if int(item.get("energy", 0)) > 0:
			return true
	return false


func _give_first_shareable_item(npc_id: String) -> String:
	if _get_relationship_value(npc_id) >= 12:
		return "%s已经很信任你了。今天不用再送东西，食物还是留给自己撑过明天吧。" % _get_relationship_npc_name(npc_id)
	for i in range(inventory_items.size()):
		var item: Dictionary = inventory_items[i]
		if int(item.get("energy", 0)) <= 0:
			continue
		var item_name := str(item.get("name", "食物"))
		var profile: Dictionary = npc_social_profiles.get(npc_id, {})
		var npc_name := str(profile.get("name", "对方"))
		var old_value: int = _get_relationship_value(npc_id)
		var gift_gain := 1
		if int(item.get("stress_relief", 0)) >= 4:
			gift_gain = 2
		var new_value: int = min(12, old_value + gift_gain)
		npc_relationships[npc_id] = new_value
		_consume_inventory_item_at(i)
		_update_npc_relationship_visual(npc_id)
		_on_status_changed(time_manager.get_status())
		var event_line := _get_relationship_event_line(npc_id, old_value, new_value)
		var gift_line := "你把%s分给了%s。关系 +%d。%s。" % [item_name, npc_name, new_value - old_value, _get_relationship_summary_line(npc_id)]
		if not event_line.is_empty():
			gift_line = "%s %s" % [gift_line, event_line]
		return gift_line
	return "包里没有适合分享的食物。"


func _consume_inventory_item_at(index: int) -> void:
	if index < 0 or index >= inventory_items.size():
		return
	var item: Dictionary = inventory_items[index]
	var quantity: int = int(item.get("quantity", 1)) - 1
	if quantity > 0:
		item["quantity"] = quantity
		inventory_items[index] = item
	else:
		inventory_items.remove_at(index)


func _get_relationship_event_line(npc_id: String, old_value: int, new_value: int) -> String:
	if old_value < 12 and new_value >= 12:
		match npc_id:
			"landlord":
				return "关系事件：陈房东说有事可以提前讲，别一个人硬扛。"
			"shopkeeper":
				return "关系事件：便利店老板开始给你留临期但还能吃的便当。"
			"girl":
				return "关系事件：小米把一条便宜好住的租房群发给了你。"
			"delivery_captain":
				return "关系事件：赵队把几个好送的小区入口标给了你。"
			"office_worker_npc":
				return "关系事件：徐同事愿意提前提醒你会上的坑。"
			"streamer_npc":
				return "关系事件：阿雅教你怎么把直播间节奏撑过去。"
			_:
				return "关系事件：这座城市里，你终于多了一个能说上话的人。"
	if old_value < 7 and new_value >= 7:
		return "关系提升：%s关系变成熟人，部分生活和工作会得到小帮助。" % _get_relationship_npc_name(npc_id)
	if old_value < 3 and new_value >= 3:
		return "关系提升：%s现在会主动和你打招呼。" % _get_relationship_npc_name(npc_id)
	return ""


func _get_relationship_npc_name(npc_id: String) -> String:
	var profile: Dictionary = npc_social_profiles.get(npc_id, {})
	return str(profile.get("name", "对方"))


func _get_relationship_perk_lines() -> Array[String]:
	var lines: Array[String] = []
	if _get_relationship_value("shopkeeper") >= 7:
		lines.append("便利店熟人价：部分食物 -2 元。")
	if _get_relationship_value("landlord") >= 7:
		lines.append("房东熟人：交租后额外压力 -3。")
	if _get_relationship_value("office_worker_npc") >= 7:
		lines.append("办公室熟人：白领班次压力 -2。")
	if _get_relationship_value("delivery_captain") >= 7:
		lines.append("配送站熟人：完成外卖收入 +18、压力 -2。")
	if _get_relationship_value("streamer_npc") >= 7:
		lines.append("传媒熟人：主播班收入 +25、压力 -2。")
	return lines


func _update_hud_navigation() -> void:
	if hud == null or player == null:
		return
	hud.update_minimap(current_location, _get_active_world_rect(), player.global_position, player.facing, _get_minimap_points(), _get_minimap_objective())


func _get_active_world_rect() -> Rect2:
	match current_location:
		"apartment":
			return apartment.get_world_rect()
		"office":
			return office.get_world_rect()
		"media_company":
			return media_company.get_world_rect()
		"metro_station":
			return metro_station.get_world_rect()
		"wet_market":
			return wet_market.get_world_rect()
		"clinic":
			return clinic.get_world_rect()
		_:
			return city_map.get_world_rect()


func _get_minimap_points() -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	match current_location:
		"apartment":
			points.append(_minimap_point(Vector2(246, 240), "home", "床", Color("#d98a8a"), 4.0))
			points.append(_minimap_point(Vector2(412, 300), "food", "冰箱", Color("#b8d8c4"), 3.0))
			points.append(_minimap_point(Vector2(322, 208), "rent", "房租", Color("#efc36f"), 3.0))
			points.append(_minimap_point(Vector2(322, 304), "exit", "出口", Color("#f0c77b"), 4.0))
		"office":
			points.append(_minimap_point(Vector2(590, 340), "work", "运营", Color("#b8d9e8"), 4.0))
			points.append(_minimap_point(Vector2(704, 340), "work", "开发", Color("#c4d8a8"), 4.0))
			points.append(_minimap_point(Vector2(818, 340), "work", "销售", Color("#e9b293"), 4.0))
			points.append(_minimap_point(Vector2(710, 444), "exit", "出口", Color("#c7e7ff"), 4.0))
		"media_company":
			points.append(_minimap_point(Vector2(606, 316), "media", "直播", Color("#ffd0d5"), 5.0))
			points.append(_minimap_point(Vector2(710, 412), "exit", "出口", Color("#e3c7f0"), 4.0))
		"metro_station":
			points.append(_minimap_point(Vector2(640, 344), "metro", "闸机", Color("#a9d7ff"), 5.0))
			points.append(_minimap_point(Vector2(454, 346), "info", "售票", Color("#b8d8c4"), 3.0))
			points.append(_minimap_point(Vector2(640, 426), "exit", "出口", Color("#e8c879"), 4.0))
		"wet_market":
			points.append(_minimap_point(Vector2(380, 582), "food", "菜场", Color("#d8c886"), 5.0))
			points.append(_minimap_point(Vector2(384, 636), "exit", "出口", Color("#e8c879"), 4.0))
		"clinic":
			points.append(_minimap_point(Vector2(616, 562), "clinic", "诊所", Color("#d8fff0"), 5.0))
			points.append(_minimap_point(Vector2(704, 636), "exit", "出口", Color("#e8c879"), 4.0))
		_:
			points.append(_minimap_point(home_street_position, "home", "家", Color("#efc36f"), 4.0))
			points.append(_minimap_point(Vector2(656, 202), "food", "便利", Color("#f5d37b"), 4.0))
			points.append(_minimap_point(Vector2(720, 448), "metro", "地铁", Color("#a9d7ff"), 5.0))
			points.append(_minimap_point(Vector2(1088, 278), "work", "公司", Color("#c7e7ff"), 5.0))
			points.append(_minimap_point(Vector2(896, 512), "delivery", "配送", Color("#f3cf6b"), 4.0))
			points.append(_minimap_point(Vector2(896, 192), "media", "传媒", Color("#ffc4d6"), 4.0))
			points.append(_minimap_point(Vector2(272, 768), "food", "菜场", Color("#d8c886"), 4.0))
			points.append(_minimap_point(Vector2(528, 704), "clinic", "诊所", Color("#d8fff0"), 4.0))
			points.append(_minimap_point(Vector2(1344, 278), "home", "公寓", Color("#c7e7ff"), 4.0))
			points.append(_minimap_point(Vector2(1280, 576), "rent", "中介", Color("#e8c879"), 4.0))
			points.append(_minimap_point(Vector2(560, 228), "landmark", "人广", Color("#c4d8a8"), 3.6))
			points.append(_minimap_point(Vector2(900, 252), "landmark", "外滩", Color("#a9d7ff"), 3.6))
			points.append(_minimap_point(Vector2(1088, 366), "landmark", "陆家嘴", Color("#8fc4d4"), 3.8))
			for npc in npcs:
				if npc.visible:
					points.append(_minimap_point(npc.global_position, "npc", "NPC", Color("#f4dcb1"), 2.6))
	return points


func _minimap_point(position: Vector2, kind: String, label: String, color: Color, radius: float) -> Dictionary:
	return {
		"position": position,
		"kind": kind,
		"label": label,
		"color": color,
		"radius": radius,
	}


func _get_minimap_objective() -> Dictionary:
	if delivery_state == "accepted":
		return {"position": Vector2(458, 440)}
	if delivery_state == "picked":
		return {"position": Vector2(228, 206)}
	if current_location == "office":
		if time_manager.get_segment_key() in ["morning", "afternoon"] and not time_manager.worked_this_day:
			return {"position": Vector2(704, 340)}
		return {"position": Vector2(710, 444)}
	if current_location == "media_company":
		if time_manager.get_segment_key() in ["afternoon", "evening"] and not time_manager.worked_this_day:
			return {"position": Vector2(606, 316)}
		return {"position": Vector2(710, 412)}

	match current_location:
		"apartment":
			if time_manager.get_rent_due_in_days() <= 1:
				return {"position": Vector2(330, 208)}
			if time_manager.energy < 45:
				return {"position": Vector2(412, 300)}
			return {"position": Vector2(246, 240)}
		"metro_station":
			return {"position": Vector2(640, 344)}
		"wet_market":
			return {"position": Vector2(380, 582)}
		"clinic":
			return {"position": Vector2(616, 562)}
		_:
			if time_manager.get_rent_due_in_days() <= 1:
				return {"position": home_street_position}
			if time_manager.energy < 45:
				return {"position": Vector2(272, 768)}
			if time_manager.stress >= 60:
				return {"position": Vector2(528, 704)}
			if not time_manager.worked_this_day and time_manager.get_segment_key() in ["morning", "afternoon"]:
				return {"position": Vector2(720, 448)}
			if not time_manager.worked_this_day and time_manager.get_segment_key() == "evening":
				return {"position": Vector2(896, 192)}
	return {}

func _on_time_segment_changed(segment_key: String, _segment_label: String) -> void:
	if city_map != null:
		city_map.set_time_segment(segment_key)
	if apartment != null:
		apartment.set_time_segment(segment_key)
	if office != null:
		office.set_time_segment(segment_key)
	if media_company != null:
		media_company.set_time_segment(segment_key)
	if metro_station != null:
		metro_station.set_time_segment(segment_key)
	if wet_market != null:
		wet_market.set_time_segment(segment_key)
	if clinic != null:
		clinic.set_time_segment(segment_key)
	for npc in npcs:
		npc.set_time_segment(segment_key)
	_apply_world_light(segment_key)


func _on_weather_changed(weather_key: String, _weather_label: String) -> void:
	if city_map != null:
		city_map.set_weather(weather_key)
	if apartment != null:
		apartment.set_weather(weather_key)
	if office != null:
		office.set_weather(weather_key)
	if media_company != null:
		media_company.set_weather(weather_key)
	if metro_station != null:
		metro_station.set_weather(weather_key)
	if wet_market != null:
		wet_market.set_weather(weather_key)
	if clinic != null:
		clinic.set_weather(weather_key)
	_apply_world_light(time_manager.get_segment_key())
	_on_status_changed(time_manager.get_status())


func _on_day_started(_day: int) -> void:
	talked_today.clear()
	delivery_state = "none"
	delivery_orders_completed_today = 0
	pending_morning_notice.clear()
	pending_morning_notice.append(housing_morning_line)
	if time_manager.get_rent_overdue_days() > 0:
		pending_morning_notice.append_array([
			"房租已经逾期了，房东不会一直当没看见。",
			"逾期 %d 天。能交的时候，回家在房租单那里处理。" % time_manager.get_rent_overdue_days(),
		])

func _on_shop_item_selected(item: Dictionary) -> void:
	if item.has("contract_id"):
		_apply_housing_choice(item)
		return
	var price: int = int(item.get("price", 0))
	if time_manager.spend(price):
		_store_inventory_item(item)
		hud.focus_inventory_tab()
		hud.set_function_bar_message("%s 已放进包里，需要时点底部“包”使用。" % item.get("name", "物品"))
		var buy_line := "已购买 %s。效果会在你使用时生效。" % item.get("name", "物品")
		if int(item.get("relationship_discount", 0)) > 0:
			buy_line = "熟人价已生效。%s" % buy_line
		hud.set_shop_message(buy_line)
	else:
		hud.set_shop_message("钱不够。")


func _apply_housing_choice(item: Dictionary) -> void:
	var deposit: int = int(item.get("price", 0))
	if not time_manager.spend(deposit):
		hud.set_shop_message("押金和中介费不够。")
		return
	var contract_id := str(item.get("contract_id", "urban_village"))
	time_manager.apply_housing_contract(
		contract_id,
		str(item.get("name", "租房合同")),
		int(item.get("rent_amount", time_manager.rent_amount)),
		int(item.get("commute_fare", time_manager.commute_fare)),
		int(item.get("commute_energy_cost", time_manager.commute_energy_cost)),
		int(item.get("commute_stress_gain", time_manager.commute_stress_gain))
	)
	_apply_housing_profile(contract_id, str(item.get("name", "租房合同")))
	time_manager.relieve_stress(int(item.get("stress_relief", 0)))
	_on_status_changed(time_manager.get_status())
	hud.set_shop_message("已签约：%s。房租 %d，通勤 %d。" % [
		item.get("name", "合同"),
		int(item.get("rent_amount", time_manager.rent_amount)),
		int(item.get("commute_fare", time_manager.commute_fare)),
	])
	hud.set_function_bar_message("已搬家：%s。家门口、屋内风格和通勤压力已更新。" % item.get("name", "合同"))


func _apply_housing_profile(housing_id: String, display_name: String) -> void:
	active_housing_id = housing_id
	match housing_id:
		"far_suburb":
			home_street_position = Vector2(720, 468)
			housing_sleep_energy = 88
			housing_sleep_stress_relief = 20
			housing_fridge_energy = 6
			housing_fridge_stress_relief = 1
			housing_rent_stress_relief = 4
			housing_morning_line = "远郊房租低一点，但醒来时通勤已经在心里排队。"
		"talent_apartment":
			home_street_position = Vector2(1344, 278)
			housing_sleep_energy = 100
			housing_sleep_stress_relief = 36
			housing_fridge_energy = 14
			housing_fridge_stress_relief = 5
			housing_rent_stress_relief = 12
			housing_morning_line = "人才公寓的早晨更安静，但高房租会提醒你继续往前跑。"
		_:
			home_street_position = Vector2(152, 190)
			housing_sleep_energy = 100
			housing_sleep_stress_relief = 28
			housing_fridge_energy = 8
			housing_fridge_stress_relief = 2
			housing_rent_stress_relief = 8
			housing_morning_line = "合租楼里的脚步声比闹钟更早。"
	apartment.set_housing_variant(active_housing_id, display_name)
	last_street_position = home_street_position


func _get_housing_fridge_title() -> String:
	match active_housing_id:
		"far_suburb":
			return "小冰箱"
		"talent_apartment":
			return "公寓冰箱"
		_:
			return "合租冰箱"


func _get_housing_fridge_line() -> String:
	match active_housing_id:
		"far_suburb":
			return "远郊单间的小冰箱里只剩一点速冻食品。"
		"talent_apartment":
			return "公寓冰箱空间更干净，你终于能好好放点吃的。"
		_:
			return "你从合租冰箱角落翻出一份简单剩饭。"


func _get_housing_sleep_line() -> String:
	match active_housing_id:
		"far_suburb":
			return "远郊夜里安静，但想到明天还要早起赶地铁，恢复得没那么满。"
		"talent_apartment":
			return "公寓隔音好很多，你久违地睡得像一个真正有房间的人。"
		_:
			return "新的一天开始了，至少还有一点重新安排的空间。"


func _get_housing_rent_relief_line() -> String:
	match active_housing_id:
		"far_suburb":
			return "房租便宜些，但通勤压力还在。压力 -4。"
		"talent_apartment":
			return "贵是贵，但至少这几天不用担心门外有人催租。压力 -12。"
		_:
			return "至少接下来几天，房东不会再敲门了。压力 -8。"





func _on_inventory_item_used(index: int) -> void:
	if index < 0 or index >= inventory_items.size():
		return
	var item: Dictionary = inventory_items[index]
	var item_name: String = str(item.get("name", "物品"))
	var energy: int = int(item.get("energy", 0))
	var stress_relief: int = int(item.get("stress_relief", 0))
	if energy > 0:
		time_manager.recover_energy(energy)
	if stress_relief >= 0:
		time_manager.relieve_stress(stress_relief)
	else:
		time_manager.add_stress(abs(stress_relief))
	var quantity: int = int(item.get("quantity", 1)) - 1
	if quantity > 0:
		item["quantity"] = quantity
		inventory_items[index] = item
	else:
		inventory_items.remove_at(index)
	_on_status_changed(time_manager.get_status())
	var stress_text := "压力 -%d" % stress_relief
	if stress_relief < 0:
		stress_text = "压力 +%d" % abs(stress_relief)
	else:
		stress_text = "压力 -%d" % stress_relief
	hud.set_function_bar_message("使用了 %s。体力 +%d，%s。" % [item_name, energy, stress_text])


func _resume_player_after_ui() -> void:
	time_manager.set_time_paused(false)
	player.set_controls_enabled(true)
	var focus = player.focused_interactable
	if focus != null and focus.has_method("get_prompt"):
		hud.show_prompt(str(focus.call("get_prompt")))


func _update_time_flow() -> void:
	if time_manager == null:
		return
	time_manager.set_flow_multiplier(1.0)


func _apply_commute_time_jump() -> void:
	time_manager.consume_energy(time_manager.commute_energy_cost)
	time_manager.add_stress(time_manager.commute_stress_gain)
	if time_manager.get_segment_key() == "morning":
		time_manager.set_segment("afternoon")
	elif time_manager.get_segment_key() == "afternoon":
		time_manager.add_stress(1)


func _apply_world_light(segment_key: String) -> void:
	var rainy_tint := Color.WHITE
	if time_manager != null and time_manager.is_rainy():
		rainy_tint = Color("#d5deea")
	if time_manager != null and time_manager.stress >= 70:
		rainy_tint = _tint_color(rainy_tint, Color("#e6d6d1"))
	match segment_key:
		"morning":
			canvas_modulate.color = _tint_color(Color("#fff2d4"), rainy_tint)
		"afternoon":
			canvas_modulate.color = _tint_color(Color("#f6d6a0"), rainy_tint)
		"evening":
			canvas_modulate.color = _tint_color(Color("#b8a1c0"), rainy_tint)
		"late_night":
			canvas_modulate.color = _tint_color(Color("#66718f"), rainy_tint)
		_:
			canvas_modulate.color = Color.WHITE


func _tint_color(base: Color, tint: Color) -> Color:
	return Color(base.r * tint.r, base.g * tint.g, base.b * tint.b, base.a)


func _set_collision_tree_enabled(root: Node, enabled: bool) -> void:
	if root == null:
		return
	if root is CollisionObject2D:
		var collision_object := root as CollisionObject2D
		if not collision_object.has_meta("base_collision_layer"):
			collision_object.set_meta("base_collision_layer", collision_object.collision_layer)
			collision_object.set_meta("base_collision_mask", collision_object.collision_mask)
		if enabled:
			collision_object.collision_layer = int(collision_object.get_meta("base_collision_layer"))
			collision_object.collision_mask = int(collision_object.get_meta("base_collision_mask"))
		else:
			collision_object.collision_layer = 0
			collision_object.collision_mask = 0
	if root is CollisionShape2D:
		var collision_shape := root as CollisionShape2D
		if not collision_shape.has_meta("base_disabled"):
			collision_shape.set_meta("base_disabled", collision_shape.disabled)
		collision_shape.disabled = bool(collision_shape.get_meta("base_disabled")) if enabled else true
	for child in root.get_children():
		_set_collision_tree_enabled(child, enabled)


func _get_shop_items(source_id: String) -> Array[Dictionary]:
	if source_id == "wet_market":
		return [
			{"id": "wet_market_veg_egg", "name": "青菜鸡蛋包", "price": 14, "energy": 16, "stress_relief": 2},
			{"id": "wet_market_noodle_bowl", "name": "热汤面", "price": 18, "energy": 24, "stress_relief": 3},
			{"id": "wet_market_fruit_bag", "name": "水果袋", "price": 16, "energy": 12, "stress_relief": 6},
		]
	if source_id == "convenience_store":
		return _apply_relationship_shop_discount([
			{"id": "store_rice_ball", "name": "饭团", "price": 10, "energy": 12, "stress_relief": 1},
			{"id": "store_coffee", "name": "冰咖啡", "price": 12, "energy": 18, "stress_relief": -3},
			{"id": "store_late_snack", "name": "夜宵便当", "price": 22, "energy": 28, "stress_relief": 4},
		], "shopkeeper")
	if source_id == "rental_agency":
		return [
			{"id": "contract_urban_village", "contract_id": "urban_village", "name": "城中村合租", "price": 0, "rent_amount": 1200, "commute_fare": 6, "commute_energy_cost": 4, "commute_stress_gain": 2, "energy": 0, "stress_relief": 0},
			{"id": "contract_far_suburb", "contract_id": "far_suburb", "name": "远郊单间", "price": 260, "rent_amount": 850, "commute_fare": 8, "commute_energy_cost": 8, "commute_stress_gain": 6, "energy": 0, "stress_relief": 0},
			{"id": "contract_talent_apartment", "contract_id": "talent_apartment", "name": "人才公寓试住", "price": 520, "rent_amount": 1650, "commute_fare": 4, "commute_energy_cost": 2, "commute_stress_gain": 1, "energy": 0, "stress_relief": 6},
		]
	return [
		{"id": "canteen_set", "name": "小饭馆套餐", "price": 26, "energy": 34, "stress_relief": 4},
		{"id": "comfort_soup", "name": "暖汤", "price": 32, "energy": 22, "stress_relief": 10},
		{"id": "quick_lunch", "name": "快餐盒饭", "price": 20, "energy": 26, "stress_relief": 2},
	]


func _apply_relationship_shop_discount(items: Array[Dictionary], npc_id: String) -> Array[Dictionary]:
	if _get_relationship_value(npc_id) < 7:
		return items
	var discounted: Array[Dictionary] = []
	for item_variant in items:
		var item: Dictionary = item_variant.duplicate()
		var old_price: int = int(item.get("price", 0))
		item["price"] = max(1, old_price - 2)
		item["relationship_discount"] = old_price - int(item["price"])
		discounted.append(item)
	return discounted

func _get_commute_line() -> String:
	var pressure := " 车费 %d，体力 -%d，压力 +%d。" % [time_manager.commute_fare, time_manager.commute_energy_cost, time_manager.commute_stress_gain]
	if time_manager.is_rainy():
		return "你带着潮湿的袖口挤进地铁，四十分钟后到达公司附近。%s" % pressure
	return "你刷卡进闸，坐地铁穿过城市去上班。%s" % pressure


func _apply_commute_day_event() -> Array[String]:
	var lines: Array[String] = []
	if active_housing_id == "far_suburb" and time_manager.get_segment_key() == "morning":
		time_manager.add_stress(3)
		lines.append("远郊通勤比你预想的更挤，早高峰额外压力 +3。")
	if time_manager.is_rainy():
		time_manager.consume_energy(2)
		lines.append("雨水让换乘更慢，你多消耗了 2 点体力。")
	if time_manager.get_clock_total_minutes() >= 690 and time_manager.get_segment_key() == "morning":
		time_manager.add_stress(4)
		lines.append("你接近午前才到公司，打卡时间让人有点心虚。压力 +4。")
	return lines


func _get_work_return_line(job_id: String) -> String:
	if job_id == "job_streamer":
		return "你走出直播间时，眼前还晃着环形灯的白光。"
	return "你走出写字楼，城市的灯已经一盏盏亮起来。"


func _apply_workday_event(job_id: String, wage: int, energy_cost: int, stress_gain: int) -> Dictionary:
	var lines: Array[String] = []
	if job_id == "job_sales" and time_manager.is_rainy():
		wage += 35
		stress_gain += 4
		lines.append("雨天客户临时改期，你改成电话跟进，反而拿到一点提成。收入 +35，压力 +4。")
	elif job_id == "job_developer" and time_manager.energy >= 70:
		wage += 45
		energy_cost += 4
		lines.append("你顺手修掉一个线上小问题，主管记了一笔绩效。收入 +45，体力 -4。")
	elif job_id == "job_operations" and active_housing_id == "far_suburb":
		stress_gain += 5
		lines.append("远郊通勤后的疲惫让表格错误多了一点，返工让压力 +5。")
	elif job_id == "job_streamer" and time_manager.get_segment_key() == "evening":
		wage += 60
		stress_gain += 8
		lines.append("晚间流量更好，但弹幕节奏也更凶。收入 +60，压力 +8。")
	elif time_manager.stress >= 70:
		wage -= 25
		stress_gain += 4
		lines.append("压力太高，你今天反应慢了半拍。收入 -25，压力 +4。")
	if job_id in ["job_operations", "job_developer", "job_sales"] and _get_relationship_value("office_worker_npc") >= 7:
		stress_gain = max(0, stress_gain - 2)
		lines.append("徐同事提前提醒了今天的坑。熟人加成：压力 -2。")
	if job_id == "job_streamer" and _get_relationship_value("streamer_npc") >= 7:
		wage += 25
		stress_gain = max(0, stress_gain - 2)
		lines.append("阿雅帮你调了直播间节奏。熟人加成：收入 +25，压力 -2。")
	return {
		"wage": max(100, wage),
		"energy_cost": max(12, energy_cost),
		"stress_gain": max(0, stress_gain),
		"lines": lines,
	}

func _calculate_work_result(job_id: String = "job_operations") -> Dictionary:
	var job: Dictionary = _get_job_profile(job_id)
	var start_energy: int = time_manager.energy
	var energy_cost: int = int(job["energy_cost"])
	var wage: int = int(job["base_wage"])
	var stress_gain: int = int(job["stress_gain"])
	var performance: String = "稳定"
	var work_line: String = str(job["work_line"])

	if start_energy >= 86:
		performance = "专注"
		wage += int(job["high_energy_bonus"])
		energy_cost += 6
		stress_gain += 3
	elif start_energy >= 58:
		performance = "稳定"
		wage += int(job["stable_bonus"])
	elif start_energy < 42:
		performance = "透支"
		wage -= int(job["low_energy_penalty"])
		energy_cost -= 4
		stress_gain += 6

	if time_manager.is_rainy():
		work_line = str(job["rain_line"])
		wage -= 10
		stress_gain += 5
		if performance == "专注":
			performance = "稳定"
		elif performance == "稳定":
			performance = "透支"

	if job_id == "job_streamer" and time_manager.get_segment_key() == "afternoon":
		wage += 30
		stress_gain += 4
		work_line = "%s 下午场直播多了一些流量。" % work_line

	return {
		"wage": max(120, wage),
		"energy_cost": max(20, energy_cost),
		"stress_gain": max(6, stress_gain),
		"performance": performance,
		"job_name": job["name"],
		"work_line": work_line,
	}




func _get_job_profile(job_id: String) -> Dictionary:
	match job_id:
		"job_developer":
			return {
				"name": "软件开发",
				"base_wage": 240,
				"energy_cost": 38,
				"stress_gain": 16,
				"high_energy_bonus": 80,
				"stable_bonus": 30,
				"low_energy_penalty": 50,
				"work_line": "你把一整个班次花在修线上问题和看合并请求上。",
				"rain_line": "雨敲着办公室玻璃，你在旧日志里追一个线上 bug。",
			}
		"job_sales":
			return {
				"name": "销售专员",
				"base_wage": 210,
				"energy_cost": 36,
				"stress_gain": 22,
				"high_energy_bonus": 95,
				"stable_bonus": 35,
				"low_energy_penalty": 55,
				"work_line": "你一边打客户电话，一边补演示记录，还要应付经理不断追加的跟进。",
				"rain_line": "雨天拖慢了每一次客户拜访，每条迟到的回复都让销售表更沉。",
			}
		"job_streamer":
			return {
				"name": "主播班",
				"base_wage": 190,
				"energy_cost": 32,
				"stress_gain": 24,
				"high_energy_bonus": 110,
				"stable_bonus": 35,
				"low_energy_penalty": 65,
				"work_line": "你在发烫的灯光下保持笑容，弹幕要的活力其实你已经不太有了。",
				"rain_line": "下雨让更多观众留在室内，但留住他们几乎耗光你剩下的力气。",
			}
		_:
			return {
				"name": "运营助理",
				"base_wage": 220,
				"energy_cost": 34,
				"stress_gain": 14,
				"high_energy_bonus": 45,
				"stable_bonus": 15,
				"low_energy_penalty": 35,
				"work_line": "你处理供应商消息、核对表格，努力让办公室这台机器别散架。",
				"rain_line": "雨天拖慢了配送，运营收件箱像自己长出了一套天气系统。",
			}

func _update_npc_relationship_visual(npc_id: String) -> void:
	for npc in npcs:
		if npc.npc_id == npc_id:
			npc.set_relationship(int(npc_relationships.get(npc_id, 0)))
			return


func _get_landlord_rent_line() -> String:
	var due_in: int = time_manager.get_rent_due_in_days()
	if due_in > 0:
		return "房租还有 %d 天到期，记得留现金。" % due_in
	if due_in == 0:
		return "房租今天到期，睡前能交就交。"
	return "房租已经逾期 %d 天，压力会继续涨。" % abs(due_in)

func _get_delivery_instruction() -> String:
	if delivery_state == "accepted":
		return "已接单。去取餐点拿餐。"
	if delivery_state == "picked":
		return "已取餐。去送达点，别让城市吃掉你的奖金。"
	return "去配送站找赵队接一条路线。"
