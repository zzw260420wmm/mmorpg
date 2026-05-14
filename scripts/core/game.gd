extends Node2D

const TimeManagerScript := preload("res://scripts/core/time_manager.gd")
const CityMapScript := preload("res://scripts/world/city_map.gd")
const ApartmentInteriorScript := preload("res://scripts/world/apartment_interior.gd")
const OfficeInteriorScript := preload("res://scripts/world/office_interior.gd")
const MediaCompanyInteriorScript := preload("res://scripts/world/media_company_interior.gd")
const MetroStationInteriorScript := preload("res://scripts/world/metro_station_interior.gd")
const PlayerScene := preload("res://scenes/player/player.tscn")
const NpcScene := preload("res://scenes/npc/npc.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")

var time_manager: TimeManager
var city_map: CityMap
var apartment: ApartmentInterior
var office: OfficeInterior
var media_company: MediaCompanyInterior
var metro_station: MetroStationInterior
var player: Player
var hud: GameHUD
var canvas_modulate: CanvasModulate
var npcs: Array[LifeNpc] = []
var current_location := "street"
var last_street_position := Vector2.ZERO
var office_return_position := Vector2(1112, 338)
var media_return_position := Vector2(898, 242)
var metro_return_position := Vector2(720, 410)
var delivery_state := "none"
var delivery_orders_completed_today := 0
var npc_relationships := {}
var talked_today := {}
var pending_morning_notice: Array[String] = []


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

	hud = HudScene.instantiate() as GameHUD
	add_child(hud)
	hud.dialogue_closed.connect(_resume_player_after_ui)
	hud.shop_closed.connect(_resume_player_after_ui)
	hud.shop_item_selected.connect(_on_shop_item_selected)

	time_manager.status_changed.connect(_on_status_changed)
	time_manager.time_segment_changed.connect(_on_time_segment_changed)
	time_manager.weather_changed.connect(_on_weather_changed)
	time_manager.day_started.connect(_on_day_started)
	_on_status_changed(time_manager.get_status())
	_on_time_segment_changed(time_manager.get_segment_key(), time_manager.get_segment_label())
	_on_weather_changed(time_manager.weather_key, time_manager.get_weather_label())


func show_dialogue(speaker: String, lines: Array) -> void:
	player.set_controls_enabled(false)
	hud.show_dialogue(speaker, lines)


func open_shop(source: Node) -> void:
	player.set_controls_enabled(false)
	var shop_title := "雨夜便利店"
	var source_id := ""
	if source != null:
		var display_name = source.get("display_name")
		if display_name is String and not display_name.is_empty():
			shop_title = display_name
		var interactable_id = source.get("interactable_id")
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
	player.global_position = last_street_position
	player.set_camera_limits(city_map.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()


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


func request_commute_work() -> void:
	player.set_controls_enabled(false)
	var fare := 6
	var commute_speaker := "地铁闸机" if current_location == "metro_station" else "地铁口"
	if time_manager.get_segment_key() in ["evening", "late_night"]:
		hud.show_dialogue(commute_speaker, [
			"这个点再去公司，只会赶上一盏冷白色的灯。",
			"今天还是算了，明天上午再出发吧。",
		])
		return
	if not time_manager.spend(fare):
		hud.show_dialogue(commute_speaker, [
			"交通卡余额不足。",
			"上海很大，但现在你连进站的六块钱都要想一想。",
		])
		return

	office_return_position = Vector2(1112, 338)
	enter_office(true)
	hud.show_dialogue("通勤", [
		_get_commute_line(),
		"你到了公司。今天想做哪类白领工作，由你在工位前选择。",
	])


func request_job_work(job_id: String) -> void:
	player.set_controls_enabled(false)
	var work_result := _calculate_work_result(job_id)
	var wage := int(work_result["wage"])
	var energy_cost := int(work_result["energy_cost"])
	var stress_gain := int(work_result["stress_gain"])
	var performance := str(work_result["performance"])
	var job_name := str(work_result["job_name"])
	if time_manager.get_segment_key() in ["evening", "late_night"]:
		if job_id == "job_streamer" and time_manager.get_segment_key() == "evening":
			energy_cost += 6
			stress_gain += 8
		else:
			hud.show_dialogue(job_name, [
				"这个点再开工，基本就是加班了。",
				"DEMO 里先不让你把命交给工位，明天上午再来吧。",
			])
			return
	if time_manager.energy < energy_cost:
		hud.show_dialogue(job_name, [
			"你坐到工位前，却发现自己连打开电脑都觉得费劲。",
			"体力不足。先吃点东西，或者回去睡一觉。",
		])
		return

	var return_segment := "late_night" if job_id == "job_streamer" and time_manager.get_segment_key() == "evening" else "evening"
	var worked := time_manager.complete_work_shift(wage, energy_cost, return_segment, performance)
	if not worked:
		hud.show_dialogue(job_name, ["你太累了，没法完成今天的工作。"])
		return
	time_manager.add_stress(stress_gain)
	if current_location == "media_company":
		media_return_position = Vector2(898, 242)
		exit_media_company()
	else:
		office_return_position = Vector2(1112, 338)
		exit_office()
	hud.show_dialogue(job_name, [
		work_result["work_line"],
		"今天工作表现：%s。工资到账 ¥%d，体力少了 %d，压力 +%d。" % [performance, wage, energy_cost, stress_gain],
		_get_work_return_line(job_id),
	])


func request_fridge_food() -> void:
	player.set_controls_enabled(false)
	time_manager.recover_energy(8)
	time_manager.relieve_stress(2)
	hud.show_dialogue("合租冰箱", [
		"你从冰箱角落翻出半盒酸奶和昨晚剩下的面包。",
		"不算好吃，但至少让胃不再空着。体力 +8，压力 -2。",
	])


func request_pay_rent() -> void:
	player.set_controls_enabled(false)
	if time_manager.pay_rent():
		var timing_line := "转账成功。¥%d 从账户里消失。" % time_manager.rent_amount
		if time_manager.get_rent_due_in_days() > time_manager.rent_cycle_days:
			timing_line = "你提前把房租转了出去。¥%d 从账户里消失。" % time_manager.rent_amount
		hud.show_dialogue("房租账单", [
			timing_line,
			"至少接下来几天，房东不会再敲你的门。压力 -8。",
		])
	else:
		hud.show_dialogue("房租账单", [
			"余额不够交 ¥%d 的房租。" % time_manager.rent_amount,
			"你盯着账单看了一会儿，决定明天必须去上班。",
		])


func request_clinic_visit() -> void:
	player.set_controls_enabled(false)
	var fee := 48
	if time_manager.energy >= 82 and time_manager.stress < 35:
		hud.show_dialogue("社区医院", [
			"你在自助机前站了一会儿，发现自己今天其实还撑得住。",
			"这笔挂号费先省下来吧。真正不舒服的时候再来。",
		])
		return
	if not time_manager.spend(fee):
		hud.show_dialogue("社区医院", [
			"挂号费 ¥%d。" % fee,
			"你看了眼余额，最后只是坐在门口缓了一会儿。钱不够，没挂上号。",
		])
		return
	time_manager.recover_energy(16)
	time_manager.relieve_stress(22)
	hud.show_dialogue("社区医院", [
		"医生说你只是太累了，睡眠不够，饮食也不规律。",
		"你拿着一张很普通的处方走出来。花费 ¥%d，体力 +16，压力 -22。" % fee,
	])


func inspect_rental_agency(_source: Node) -> void:
	player.set_controls_enabled(false)
	var due_in := time_manager.get_rent_due_in_days()
	var lines := [
		"中介把几套房源写在白板上：离地铁近的贵，便宜的要多换乘。",
	]
	if due_in < 0:
		lines.append("你现在房租已经逾期。中介说得很客气，但你知道换房也要押金。")
	elif due_in <= 2:
		lines.append("房租快到期了。你看着押一付三几个字，感觉比地图上的路还长。")
	else:
		lines.append("你暂时还没到必须搬家的时候，但这些价格已经提前把压力写出来了。")
	lines.append("后续可以把这里扩展成换房、押金和通勤距离系统。")
	hud.show_dialogue("房产中介", lines)


func inspect_talent_apartment(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"人才公寓看起来比合租房规整很多，楼下有门禁和公告栏。",
	]
	if time_manager.money >= time_manager.rent_amount:
		lines.append("你算了算，如果有稳定工作和社保，也许未来可以申请。现在至少先把这个月房租稳住。")
	else:
		lines.append("申请条件写得很清楚，但你现在最现实的问题还是账户余额。")
	lines.append("它不是幻想中的免费住处，而是上海给年轻人的另一套排队规则。")
	hud.show_dialogue("人才公寓", lines)


func inspect_office(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"写字楼门口的风比城中村更硬一点，玻璃反光里每个人都像在赶路。",
	]
	if time_manager.stress >= 70:
		lines.append("你看着楼上的灯，胸口有点发紧。现在的压力已经很高了，最好找点能缓下来的事。")
	elif time_manager.stress >= 40:
		lines.append("你知道自己还撑得住，但这种撑住本身也很耗人。")
	else:
		lines.append("今天状态还算稳。至少现在，你还能把这栋楼当成一个普通目的地。")
	lines.append("如果要开始工作，进楼后选择运营、程序或销售工位。")
	office_return_position = player.global_position + Vector2(0, 20)
	enter_office(false)
	show_dialogue("写字楼入口", lines)


func inspect_media_company(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"传媒公司的招牌贴在老楼外墙上，粉色灯管亮得有点倔。",
	]
	if time_manager.get_segment_key() == "morning":
		lines.append("上午这里还算安静，直播间里有人在调设备和拆样品。")
	elif time_manager.get_segment_key() == "late_night":
		lines.append("这个点还开播的人，语气要比补光灯更亮一点。")
	else:
		lines.append("走廊里能听见运营复盘数据，也能听见主播练习开场白。")
	lines.append("进去后可以在直播间选择主播工作。")
	enter_media_company()
	show_dialogue("传媒公司", lines)


func inspect_metro_station(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"你顺着湿冷的楼梯往下走，地铁站里的白光和广告灯箱一起亮着。",
	]
	if time_manager.get_segment_key() == "morning":
		lines.append("早高峰还没完全爆开，但闸机口已经开始排队。")
	elif time_manager.get_segment_key() == "evening":
		lines.append("人流从站台方向涌上来，像城市把白天吐回地面。")
	elif time_manager.get_segment_key() == "late_night":
		lines.append("末班车提示音很轻，站里空得有点发冷。")
	else:
		lines.append("下午的站厅相对松一点，只有拖着电脑包的人在赶下一班车。")
	lines.append("要去写字楼，就到闸机处刷卡乘车。")
	enter_metro_station()
	show_dialogue("地铁站入口", lines)


func request_delivery_order() -> void:
	player.set_controls_enabled(false)
	if time_manager.get_segment_key() == "late_night":
		hud.show_dialogue("外卖配送站", [
			"站长看了眼时间，说这个点 DEMO 先不派夜宵单。",
			"真要跑夜单，得等以后把夜间风险和奖励一起做进去。",
		])
		return
	if delivery_state != "none":
		hud.show_dialogue("外卖配送站", [
			"你手机里已经有一单了。",
			_get_delivery_instruction(),
		])
		return
	if delivery_orders_completed_today >= 1:
		hud.show_dialogue("外卖配送站", [
			"站长拍拍你的车座：今天先到这吧。",
			"DEMO 里每天先限制一单，避免外卖把其他生活循环挤没。",
		])
		return
	if time_manager.energy < 32:
		hud.show_dialogue("外卖配送站", [
			"你拿起头盔，又放了回去。",
			"体力不足。外卖不是坐工位，腿会先替你抗议。",
		])
		return

	delivery_state = "accepted"
	time_manager.consume_energy(6)
	time_manager.add_stress(3)
	hud.show_dialogue("外卖配送站", [
		"站长给你派了一单：小饭馆取餐，送到出租楼。",
		"你扣上头盔，手机开始导航。先去小饭馆门口取餐。",
		"接单消耗体力 6，压力 +3。",
	])
	_on_status_changed(time_manager.get_status())


func request_delivery_pickup() -> void:
	player.set_controls_enabled(false)
	if delivery_state == "none":
		hud.show_dialogue("外卖取餐点", [
			"老板把打包袋扎得很紧。",
			"不过你还没在配送站接单，先去配送站拿任务。",
		])
		return
	if delivery_state == "picked":
		hud.show_dialogue("外卖取餐点", [
			"餐已经在你手上了。",
			"现在该送到出租楼门口。",
		])
		return

	delivery_state = "picked"
	time_manager.consume_energy(8)
	hud.show_dialogue("外卖取餐点", [
		"小饭馆老板把热汤和米饭递给你，袋子外面全是水汽。",
		"餐已取到。现在送去出租楼门口。",
		"体力 -8。",
	])
	_on_status_changed(time_manager.get_status())


func request_delivery_dropoff() -> void:
	player.set_controls_enabled(false)
	if delivery_state == "none":
		hud.show_dialogue("外卖送达点", [
			"楼道口有人在等外卖，但那不是你的单。",
			"先去配送站接单。",
		])
		return
	if delivery_state != "picked":
		hud.show_dialogue("外卖送达点", [
			"你到了楼下，才发现餐还没取。",
			"先回小饭馆取餐。",
		])
		return

	var reward := 58
	var energy_cost := 14
	var stress_gain := 8
	var performance := "准时"
	var line := "你一路穿过湿漉漉的街巷，把餐送到出租楼门口。"
	if time_manager.is_rainy():
		reward += 18
		stress_gain += 6
		line = "雨把导航声淹得断断续续。你护着餐袋送到楼下，雨水顺着袖口往里钻。"
	if time_manager.energy >= 70:
		reward += 12
		performance = "利落"
	elif time_manager.energy < 38:
		reward -= 10
		stress_gain += 4
		performance = "勉强"

	if not time_manager.consume_energy(energy_cost):
		hud.show_dialogue("外卖送达点", [
			"你扶着车把喘了一会儿，腿有点发软。",
			"体力不够完成这单。先吃点东西再送。",
		])
		return

	delivery_state = "none"
	delivery_orders_completed_today += 1
	time_manager.add_money(max(35, reward))
	time_manager.add_stress(stress_gain)
	time_manager.record_work_performance("外卖%s" % performance)
	time_manager.set_segment("evening")
	hud.show_dialogue("外卖送达点", [
		line,
		"外卖表现：%s。收入 ¥%d，体力 -%d，压力 +%d。" % [performance, max(35, reward), energy_cost, stress_gain],
		"天色已经转晚，手机还有新单在跳，但你知道今天至少有一笔钱进账了。",
	])


func request_sleep() -> void:
	player.set_controls_enabled(false)
	time_manager.sleep_to_next_day()
	if current_location == "street":
		enter_apartment()
	var lines := [
		"你洗了个很快的热水澡，窗外的空调外机还在嗡嗡响。",
		"睡醒时，上海又变成了上午。体力恢复了，生活也继续往前推了一格。",
	]
	lines.append_array(pending_morning_notice)
	pending_morning_notice.clear()
	hud.show_dialogue("合租出租屋", lines)


func _spawn_npcs() -> void:
	var npc_data := [
		{
			"id": "landlord",
			"name": "房东",
			"role": "landlord",
			"position": Vector2(204, 214),
			"palette": {"hair": Color("#3a3029"), "skin": Color("#c49167"), "shirt": Color("#8d7560")},
			"routes": {
				"morning": [Vector2(206, 214), Vector2(216, 258), Vector2(154, 258), Vector2(154, 214)],
				"afternoon": [Vector2(188, 198), Vector2(236, 226), Vector2(218, 276)],
				"evening": [Vector2(132, 204), Vector2(202, 204)],
				"late_night": [Vector2(118, 190)],
			},
			"dialogue": {
				"default": ["房租别忘了。刚来上海不容易，手头紧也提前说。"],
				"morning": ["早啊，楼道灯坏了我下午找人看。你上班别迟到。"],
				"evening": ["晚上回来记得轻点，隔壁阿姨睡得早。"],
				"late_night": ["这么晚才回来？年轻人拼是拼，也要留点命给明天。"],
			},
		},
		{
			"id": "shopkeeper",
			"name": "便利店老板",
			"role": "shopkeeper",
			"position": Vector2(612, 222),
			"palette": {"hair": Color("#25262b"), "skin": Color("#d6a373"), "shirt": Color("#3f806f")},
			"routes": {
				"morning": [Vector2(612, 222), Vector2(704, 222)],
				"afternoon": [Vector2(636, 212), Vector2(710, 212), Vector2(710, 248)],
				"evening": [Vector2(618, 228), Vector2(690, 228), Vector2(690, 252)],
				"late_night": [Vector2(646, 214)],
			},
			"dialogue": {
				"default": ["要点什么？饭团刚补货，咖啡机也还热着。"],
				"morning": ["早高峰买咖啡的人最多。你看，大家都靠一点热的东西启动。"],
				"evening": ["下雨天生意还行，伞卖得快，泡面也卖得快。"],
				"late_night": ["这个点还醒着的人，不是在加班，就是在等一个不太想回的家。"],
			},
		},
		{
			"id": "girl",
			"name": "同样沪漂的女孩",
			"role": "drifter",
			"position": Vector2(332, 260),
			"palette": {"hair": Color("#241b22"), "skin": Color("#d8a17b"), "shirt": Color("#c55b70")},
			"routes": {
				"morning": [Vector2(170, 248), Vector2(380, 296), Vector2(704, 382)],
				"afternoon": [Vector2(338, 286), Vector2(396, 332), Vector2(316, 360)],
				"evening": [Vector2(716, 386), Vector2(532, 302), Vector2(658, 218)],
				"late_night": [Vector2(656, 238), Vector2(520, 268), Vector2(340, 354)],
			},
			"dialogue": {
				"default": ["我也是刚来没多久。每天都很累，但偶尔会觉得，这座城市也不是完全冷的。"],
				"morning": ["今天要挤二号线。希望别在站台上被人潮推着走。"],
				"afternoon": ["午休出来透口气。工位的灯太白了，照得人像透明的。"],
				"evening": ["便利店的灯一亮，突然就有点想家。"],
				"late_night": ["凌晨的路安静很多，就是安静得让人容易想太多。"],
			},
		},
		{
			"id": "delivery_rider_npc",
			"name": "配送骑手",
			"role": "delivery_rider",
			"position": Vector2(860, 506),
			"palette": {"hair": Color("#26313d"), "skin": Color("#d6a373"), "shirt": Color("#e5bd3f")},
			"routes": {
				"morning": [Vector2(860, 506), Vector2(792, 500), Vector2(456, 440), Vector2(850, 506)],
				"afternoon": [Vector2(880, 510), Vector2(456, 440), Vector2(240, 226), Vector2(860, 506)],
				"evening": [Vector2(846, 512), Vector2(716, 386), Vector2(458, 440), Vector2(846, 512)],
				"late_night": [Vector2(838, 510), Vector2(902, 510)],
			},
			"dialogue": {
				"default": ["今天单子不算多，但每一单都像在跟时间赛跑。"],
				"morning": ["早高峰路口最堵，骑慢一点少赚，骑快一点心慌。"],
				"afternoon": ["午高峰刚过去，腿有点软。你要跑单的话记得先吃点东西。"],
				"evening": ["下班的人一多，外卖也多。城市亮起来的时候，骑手最忙。"],
				"late_night": ["凌晨还有夜宵单。路空了，风也冷了。"],
			},
		},
		{
			"id": "streamer_npc",
			"name": "新人主播",
			"role": "streamer",
			"position": Vector2(936, 220),
			"palette": {"hair": Color("#2b2527"), "skin": Color("#d8a17b"), "shirt": Color("#c26c74")},
			"routes": {
				"morning": [Vector2(936, 220), Vector2(902, 220), Vector2(930, 252)],
				"afternoon": [Vector2(934, 222), Vector2(1012, 316), Vector2(1188, 516)],
				"evening": [Vector2(936, 220), Vector2(960, 220), Vector2(936, 220)],
				"late_night": [Vector2(934, 224), Vector2(900, 224)],
			},
			"dialogue": {
				"default": ["镜头前要一直笑，但下播以后脸会有点僵。"],
				"morning": ["上午先写脚本。数据不好看，主管会让我们改标题。"],
				"afternoon": ["今天要补一个探店短视频，最好别下雨。"],
				"evening": ["黄金档要开播了。灯一亮，就像另一种上班打卡。"],
				"late_night": ["下播以后还要复盘。热闹是屏幕里的，安静是自己的。"],
			},
		},
		{
			"id": "office_worker_npc",
			"name": "写字楼白领",
			"role": "office_worker",
			"position": Vector2(1088, 330),
			"palette": {"hair": Color("#24292f"), "skin": Color("#d6a373"), "shirt": Color("#5d6870")},
			"routes": {
				"morning": [Vector2(716, 386), Vector2(1050, 330), Vector2(1138, 318)],
				"afternoon": [Vector2(1138, 318), Vector2(1188, 516), Vector2(1112, 318)],
				"evening": [Vector2(1112, 318), Vector2(1188, 516), Vector2(716, 386)],
				"late_night": [Vector2(1138, 318), Vector2(1038, 336)],
			},
			"dialogue": {
				"default": ["今天会很多，但能真正做完的只有一半。"],
				"morning": ["我刚从地铁出来。还没坐到工位，消息已经响了十几条。"],
				"afternoon": ["咖啡只是让人清醒，不会让事情变少。"],
				"evening": ["大家都说先走了，结果电梯口还是一堆人。"],
				"late_night": ["楼里只剩保洁和几个屏幕还亮着。"],
			},
		},
		{
			"id": "metro_commuter_npc",
			"name": "地铁通勤者",
			"role": "metro_commuter",
			"position": Vector2(706, 386),
			"palette": {"hair": Color("#3b302b"), "skin": Color("#c49167"), "shirt": Color("#6b7280")},
			"routes": {
				"morning": [Vector2(650, 398), Vector2(706, 386), Vector2(742, 390)],
				"afternoon": [Vector2(704, 382), Vector2(652, 402), Vector2(704, 382)],
				"evening": [Vector2(742, 390), Vector2(706, 386), Vector2(650, 398)],
				"late_night": [Vector2(704, 382), Vector2(718, 382)],
			},
			"dialogue": {
				"default": ["每天都在换乘，手机电量和耐心一起掉。"],
				"morning": ["早高峰进去以后，脚基本不是自己的。"],
				"afternoon": ["这个点地铁空一点，但人还是很多。上海很少真的空。"],
				"evening": ["回家那趟车最安静，大家都低头不说话。"],
				"late_night": ["末班车快到了，错过就只能打车，太贵了。"],
			},
		},
	]

	for data in npc_data:
		var npc := NpcScene.instantiate() as LifeNpc
		npc.configure(data)
		npc_relationships[npc.npc_id] = 0
		add_child(npc)
		npcs.append(npc)


func register_npc_talk(npc_id: String) -> String:
	var current_value := int(npc_relationships.get(npc_id, 0))
	if talked_today.has(npc_id):
		if npc_id == "landlord":
			return "今天已经聊过一会儿了。好感 %d。%s" % [current_value, _get_landlord_rent_line()]
		return "今天已经聊过一会儿了。好感 %d。" % current_value

	current_value += 1
	npc_relationships[npc_id] = current_value
	talked_today[npc_id] = true
	time_manager.relieve_stress(3)
	_update_npc_relationship_visual(npc_id)
	if npc_id == "landlord":
		return "你们多聊了一会儿。好感 +1（当前 %d），压力 -3。%s" % [current_value, _get_landlord_rent_line()]
	return "你们多聊了一会儿。好感 +1（当前 %d），压力 -3。" % current_value


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
		var display_status := status.duplicate()
		display_status["delivery_state"] = delivery_state
		display_status["delivery_orders_completed"] = delivery_orders_completed_today
		hud.update_status(display_status)


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
	_apply_world_light(time_manager.get_segment_key())
	_on_status_changed(time_manager.get_status())


func _on_day_started(_day: int) -> void:
	talked_today.clear()
	delivery_state = "none"
	delivery_orders_completed_today = 0
	pending_morning_notice.clear()
	if time_manager.get_rent_overdue_days() > 0:
		pending_morning_notice = [
			"你醒来时第一眼看到的是账单。",
			"房租已经逾期 %d 天，压力又往上压了一点。" % time_manager.get_rent_overdue_days(),
		]


func _on_shop_item_selected(item: Dictionary) -> void:
	var price := int(item.get("price", 0))
	var energy := int(item.get("energy", 0))
	if time_manager.spend(price):
		time_manager.recover_energy(energy)
		var stress_relief := int(item.get("stress_relief", 3))
		time_manager.relieve_stress(stress_relief)
		var stress_text := "压力 -%d" % stress_relief
		if stress_relief < 0:
			stress_text = "压力 +%d" % abs(stress_relief)
		hud.set_shop_message("买了%s。钱包轻了一点，身体暖了一点。%s。" % [item.get("name", "东西"), stress_text])
	else:
		hud.set_shop_message("钱不够。老板看了你一眼，又假装没看见。")


func _resume_player_after_ui() -> void:
	player.set_controls_enabled(true)
	var focus = player.focused_interactable
	if focus != null and focus.has_method("get_prompt"):
		hud.show_prompt(str(focus.call("get_prompt")))


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
			{"name": "青菜鸡蛋", "price": 14, "energy": 16, "stress_relief": 2},
			{"name": "打折水果", "price": 10, "energy": 10, "stress_relief": 3},
			{"name": "菜场熟食", "price": 18, "energy": 20, "stress_relief": 4},
			{"name": "便宜菜包", "price": 8, "energy": 8, "stress_relief": 1},
		]
	if source_id == "restaurant":
		return [
			{"name": "青菜面", "price": 16, "energy": 18, "stress_relief": 4},
			{"name": "蛋炒饭", "price": 18, "energy": 22, "stress_relief": 5},
			{"name": "红烧肉盖饭", "price": 32, "energy": 35, "stress_relief": 8},
		]
	if source_id == "office_coffee":
		return [
			{"name": "美式咖啡", "price": 18, "energy": 8, "stress_relief": -4},
			{"name": "拿铁", "price": 24, "energy": 10, "stress_relief": 2},
			{"name": "可颂", "price": 19, "energy": 14, "stress_relief": 3},
		]
	return [
		{"name": "饭团", "price": 12, "energy": 10, "stress_relief": 2},
		{"name": "热豆浆", "price": 7, "energy": 6, "stress_relief": 2},
		{"name": "关东煮", "price": 15, "energy": 14, "stress_relief": 4},
		{"name": "雨伞", "price": 35, "energy": 2, "stress_relief": 1},
	]


func _get_commute_line() -> String:
	if time_manager.is_rainy():
		return "你刷过闸机，站在黄色安全线后。雨水味、广告灯箱和早高峰一起挤进车厢，四十分钟后你到了公司。"
	return "你刷卡进站，跟着人流站到车门旁。四十分钟后，地铁把你送到写字楼附近。"


func _get_work_return_line(job_id: String) -> String:
	if job_id == "job_streamer":
		return "傍晚回到传媒公司门口，补光灯的白还留在眼睛里，街上的天色反而显得更真实。"
	return "傍晚回到写字楼门口，玻璃幕墙映出一张有点疲惫的脸。"


func _calculate_work_result(job_id: String = "job_operations") -> Dictionary:
	var job := _get_job_profile(job_id)
	var start_energy := time_manager.energy
	var energy_cost := int(job["energy_cost"])
	var wage := int(job["base_wage"])
	var stress_gain := int(job["stress_gain"])
	var performance := "普通"
	var work_line := str(job["work_line"])

	if start_energy >= 86:
		performance = "高效"
		wage += int(job["high_energy_bonus"])
		energy_cost += 6
		stress_gain += 3
	elif start_energy >= 58:
		performance = "稳定"
		wage += int(job["stable_bonus"])
	elif start_energy < 42:
		performance = "勉强"
		wage -= int(job["low_energy_penalty"])
		energy_cost -= 4
		stress_gain += 6

	if time_manager.is_rainy():
		work_line = str(job["rain_line"])
		wage -= 10
		stress_gain += 5
		if performance == "高效":
			performance = "稳定"
		elif performance == "稳定":
			performance = "普通"

	if job_id == "job_streamer" and time_manager.get_segment_key() == "afternoon":
		wage += 30
		stress_gain += 4
		work_line = "%s 下午流量更好，但运营盯数据也更紧。" % work_line

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
				"name": "程序岗",
				"base_wage": 260,
				"energy_cost": 42,
				"stress_gain": 18,
				"high_energy_bonus": 70,
				"stable_bonus": 25,
				"low_energy_penalty": 45,
				"work_line": "你戴上耳机，处理需求、修 Bug、等构建。屏幕亮到下午，世界缩成了一个个窗口。",
				"rain_line": "雨声贴着玻璃，需求消息一条接一条。你在潮湿的白噪音里把 Bug 一个个按下去。",
			}
		"job_sales":
			return {
				"name": "销售岗",
				"base_wage": 210,
				"energy_cost": 36,
				"stress_gain": 22,
				"high_energy_bonus": 95,
				"stable_bonus": 35,
				"low_energy_penalty": 55,
				"work_line": "你打电话、回客户消息、改报价单。每一次沉默都像在等一个不确定的结果。",
				"rain_line": "雨天客户更难约。你在电话和企业微信之间来回切，嗓子有点发干。",
			}
		"job_streamer":
			return {
				"name": "主播岗",
				"base_wage": 190,
				"energy_cost": 32,
				"stress_gain": 24,
				"high_energy_bonus": 110,
				"stable_bonus": 35,
				"low_energy_penalty": 65,
				"work_line": "你坐到补光灯前，念开场、讲卖点、回应弹幕。笑容要稳定，语速也要稳定。",
				"rain_line": "雨声拍在窗上，直播间却亮得像没有天气。你撑着精神把一场货播做完。",
			}
		_:
			return {
				"name": "运营岗",
				"base_wage": 220,
				"energy_cost": 34,
				"stress_gain": 14,
				"high_energy_bonus": 45,
				"stable_bonus": 15,
				"low_energy_penalty": 35,
				"work_line": "你排表、写文案、看数据、追进度。一天过去，表格像被填满的城市格子。",
				"rain_line": "雨天活动数据更乱，你在群消息和表格之间来回切，终于把日报发了出去。",
			}


func _update_npc_relationship_visual(npc_id: String) -> void:
	for npc in npcs:
		if npc.npc_id == npc_id:
			npc.set_relationship(int(npc_relationships.get(npc_id, 0)))
			return


func _get_landlord_rent_line() -> String:
	var due_in := time_manager.get_rent_due_in_days()
	if due_in > 0:
		return "房东提醒你：房租还有 %d 天到期。" % due_in
	if due_in == 0:
		return "房东提醒你：今天该交房租了。"
	return "房东语气沉了点：房租已经逾期 %d 天了。" % abs(due_in)


func _get_delivery_instruction() -> String:
	if delivery_state == "accepted":
		return "当前外卖单：去小饭馆取餐。"
	if delivery_state == "picked":
		return "当前外卖单：送到出租楼门口。"
	return "当前没有外卖单。"
