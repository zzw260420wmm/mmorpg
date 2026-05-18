extends Node2D

const TimeManagerScript := preload("res://scripts/core/time_manager.gd")
const CityMapScene := preload("res://scenes/world/city_map.tscn")
const ChangchunMapScene := preload("res://scenes/world/changchun_map.tscn")
const XianMapScene := preload("res://scenes/world/xian_map.tscn")
const ChengduMapScene := preload("res://scenes/world/chengdu_map.tscn")
const HangzhouMapScene := preload("res://scenes/world/hangzhou_map.tscn")
const QikaiDistrictMapScene := preload("res://scenes/world/qikai_district_map.tscn")
const FawFactoryMapScene := preload("res://scenes/world/faw_factory_map.tscn")
const TangChanganMapScene := preload("res://scenes/world/tang_changan_map.tscn")
const RepublicShanghaiMapScene := preload("res://scenes/world/republic_shanghai_map.tscn")
const ShanghaiMansionScene := preload("res://scenes/world/shanghai_mansion_interior.tscn")
const ApartmentInteriorScene := preload("res://scenes/world/apartment_interior.tscn")
const OfficeInteriorScene := preload("res://scenes/world/office_interior.tscn")
const MediaCompanyInteriorScene := preload("res://scenes/world/media_company_interior.tscn")
const MetroStationInteriorScene := preload("res://scenes/world/metro_station_interior.tscn")
const InternetCafeInteriorScene := preload("res://scenes/world/internet_cafe_interior.tscn")
const WetMarketInteriorScene := preload("res://scenes/world/wet_market_interior.tscn")
const ClinicInteriorScene := preload("res://scenes/world/clinic_interior.tscn")
const PlayerScene := preload("res://scenes/player/player.tscn")
const NpcScene := preload("res://scenes/npc/npc.tscn")
const HudScene := preload("res://scenes/ui/hud.tscn")

const STREET_HOME := Vector2(348, 382)
const STREET_STORE := Vector2(1238, 382)
const STREET_RESTAURANT := Vector2(858, 1018)
const STREET_METRO := Vector2(2138, 1218)
const STREET_OFFICE := Vector2(3540, 642)
const STREET_OFFICE_COFFEE := Vector2(3936, 1408)
const STREET_DELIVERY_STATION := Vector2(2976, 1408)
const STREET_DELIVERY_PICKUP := Vector2(858, 1018)
const STREET_DELIVERY_DROPOFF := Vector2(4700, 642)
const STREET_MEDIA := Vector2(2784, 386)
const STREET_INTERNET_CAFE := Vector2(1680, 1024)
const STREET_MARKET := Vector2(670, 2494)
const STREET_CLINIC := Vector2(1438, 2366)
const STREET_TALENT_APARTMENT := Vector2(4700, 642)
const STREET_RENTAL_AGENCY := Vector2(4512, 1664)
const STREET_PEOPLE_SQUARE := Vector2(2304, 960)
const STREET_BUND := Vector2(5150, 980)
const STREET_LUJIAZUI := Vector2(5570, 880)
const STREET_HIGH_SPEED_RAIL := Vector2(5880, 1740)
const STREET_REPUBLIC_SHANGHAI := Vector2(5340, 1300)

var time_manager: TimeManager
var city_map: CityMap
var apartment: ApartmentInterior
var office: OfficeInterior
var media_company: MediaCompanyInterior
var metro_station: MetroStationInterior
var internet_cafe: InternetCafeInterior
var wet_market: WetMarketInterior
var clinic: ClinicInterior
var qikai_district: QikaiDistrictMap
var faw_factory: FawFactoryMap
var tang_changan: HistoricalCityMap
var republic_shanghai: HistoricalCityMap
var shanghai_mansion: ShanghaiMansionInterior
var player: Player
var hud: GameHUD
var canvas_modulate: CanvasModulate
var npcs: Array[LifeNpc] = []
var current_location := "street"
var current_city_id := "shanghai"
var regional_city_maps: Dictionary = {}
var last_street_position := Vector2.ZERO
var office_return_position: Vector2 = STREET_OFFICE
var media_return_position: Vector2 = STREET_MEDIA
var metro_return_position: Vector2 = STREET_METRO
var internet_cafe_return_position: Vector2 = STREET_INTERNET_CAFE
var market_return_position: Vector2 = STREET_MARKET
var clinic_return_position: Vector2 = STREET_CLINIC
var qikai_district_return_position := Vector2(288, 352)
var faw_factory_return_position := Vector2(1120, 288)
var tang_changan_return_position := Vector2(1120, 352)
var republic_shanghai_return_position := STREET_REPUBLIC_SHANGHAI + Vector2(0, 84)
var shanghai_mansion_return_position := STREET_REPUBLIC_SHANGHAI + Vector2(-180, 120)
var active_housing_id := "urban_village"
var home_street_position: Vector2 = STREET_HOME
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
var reputation := 0
var city_reputations: Dictionary = {}
var has_chosen_start_city := false
var completed_city_tasks_today: Dictionary = {}
var claimed_city_reputation_rewards: Dictionary = {}
var invited_historical_companions: Array[String] = []
var talked_mansion_guests: Array[String] = []
var collected_artifacts: Array[String] = []
var active_archaeology_task := ""
var history_story_progress: Dictionary = {
	"republic_salon": 0,
	"tang_museum": 0,
}
var claimed_history_node_rewards: Dictionary = {}
var owned_land: Array[String] = []
var owned_companies: Array[String] = []
var owned_historical_assets: Array[String] = []
var owned_city_growth_assets: Array[String] = []
var company_daily_income: int = 0
var historical_asset_daily_income: int = 0
var city_growth_asset_daily_income: int = 0


func _ready() -> void:
	RenderingServer.set_default_clear_color(Color("#1b2430"))

	time_manager = TimeManagerScript.new()
	time_manager.name = "TimeManager"
	add_child(time_manager)

	canvas_modulate = CanvasModulate.new()
	canvas_modulate.name = "WorldLight"
	add_child(canvas_modulate)

	city_map = CityMapScene.instantiate() as CityMap
	city_map.name = "ShanghaiVillageMap"
	add_child(city_map)
	_spawn_regional_city_maps()

	apartment = ApartmentInteriorScene.instantiate() as ApartmentInterior
	apartment.name = "ApartmentInterior"
	apartment.visible = false
	apartment.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(apartment)
	apartment.set_housing_variant(active_housing_id, "城中村合租")

	office = OfficeInteriorScene.instantiate() as OfficeInterior
	office.name = "OfficeInterior"
	office.visible = false
	office.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(office)

	media_company = MediaCompanyInteriorScene.instantiate() as MediaCompanyInterior
	media_company.name = "MediaCompanyInterior"
	media_company.visible = false
	media_company.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(media_company)

	metro_station = MetroStationInteriorScene.instantiate() as MetroStationInterior
	metro_station.name = "MetroStationInterior"
	metro_station.visible = false
	metro_station.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(metro_station)

	internet_cafe = InternetCafeInteriorScene.instantiate() as InternetCafeInterior
	internet_cafe.name = "InternetCafeInterior"
	internet_cafe.visible = false
	internet_cafe.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(internet_cafe)

	wet_market = WetMarketInteriorScene.instantiate() as WetMarketInterior
	wet_market.name = "WetMarketInterior"
	wet_market.visible = false
	wet_market.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(wet_market)

	clinic = ClinicInteriorScene.instantiate() as ClinicInterior
	clinic.name = "ClinicInterior"
	clinic.visible = false
	clinic.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(clinic)

	qikai_district = QikaiDistrictMapScene.instantiate() as QikaiDistrictMap
	qikai_district.name = "QikaiDistrictMap"
	qikai_district.visible = false
	qikai_district.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(qikai_district)

	faw_factory = FawFactoryMapScene.instantiate() as FawFactoryMap
	faw_factory.name = "FawFactoryMap"
	faw_factory.visible = false
	faw_factory.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(faw_factory)

	tang_changan = TangChanganMapScene.instantiate() as HistoricalCityMap
	tang_changan.name = "TangChanganMap"
	tang_changan.visible = false
	tang_changan.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(tang_changan)

	republic_shanghai = RepublicShanghaiMapScene.instantiate() as HistoricalCityMap
	republic_shanghai.name = "RepublicShanghaiMap"
	republic_shanghai.visible = false
	republic_shanghai.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(republic_shanghai)

	shanghai_mansion = ShanghaiMansionScene.instantiate() as ShanghaiMansionInterior
	shanghai_mansion.name = "ShanghaiMansionInterior"
	shanghai_mansion.visible = false
	shanghai_mansion.process_mode = Node.PROCESS_MODE_DISABLED
	add_child(shanghai_mansion)

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
	_set_collision_tree_enabled(internet_cafe, false)
	_set_collision_tree_enabled(wet_market, false)
	_set_collision_tree_enabled(clinic, false)
	_set_collision_tree_enabled(qikai_district, false)
	_set_collision_tree_enabled(faw_factory, false)
	_set_collision_tree_enabled(tang_changan, false)
	_set_collision_tree_enabled(republic_shanghai, false)
	_set_collision_tree_enabled(shanghai_mansion, false)

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
	_show_start_city_choice()


func _process(_delta: float) -> void:
	_update_hud_navigation()


func _spawn_regional_city_maps() -> void:
	var configs: Array[Dictionary] = [
		{"id": "changchun", "scene": ChangchunMapScene},
		{"id": "xian", "scene": XianMapScene},
		{"id": "chengdu", "scene": ChengduMapScene},
		{"id": "hangzhou", "scene": HangzhouMapScene},
	]
	for config_index in range(configs.size()):
		var config: Dictionary = configs[config_index]
		var map_scene: PackedScene = config["scene"]
		var regional_map: Node2D = map_scene.instantiate() as Node2D
		regional_map.visible = false
		regional_map.process_mode = Node.PROCESS_MODE_DISABLED
		add_child(regional_map)
		regional_city_maps[str(config["id"])] = regional_map
		_set_collision_tree_enabled(regional_map, false)


func _get_active_street_map() -> Node2D:
	if current_city_id == "shanghai":
		return city_map
	return regional_city_maps.get(current_city_id, city_map) as Node2D


func _set_street_map_active(city_id: String) -> void:
	city_map.visible = city_id == "shanghai"
	city_map.process_mode = Node.PROCESS_MODE_INHERIT if city_id == "shanghai" else Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, city_id == "shanghai")
	var regional_keys: Array = regional_city_maps.keys()
	for regional_index in range(regional_keys.size()):
		var regional_id := str(regional_keys[regional_index])
		var regional_map: Node2D = regional_city_maps[regional_id] as Node2D
		var is_active := regional_id == city_id
		regional_map.visible = is_active
		regional_map.process_mode = Node.PROCESS_MODE_INHERIT if is_active else Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(regional_map, is_active)
	_set_npcs_enabled(city_id == "shanghai")


func _set_npcs_enabled(enabled: bool) -> void:
	for npc in npcs:
		npc.visible = enabled
		npc.process_mode = Node.PROCESS_MODE_INHERIT if enabled else Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(npc, enabled)


func _show_start_city_choice() -> void:
	if has_chosen_start_city:
		return
	player.set_controls_enabled(false)
	time_manager.set_time_paused(true)
	hud.show_shop("选择你的第一座发展城市", _get_start_city_options())
	hud.set_shop_message("先选一座城市落脚。每座城市都有临时住处、本地工作和城市委托，前期压力会更温和。")


func _get_start_city_options() -> Array[Dictionary]:
	var options: Array[Dictionary] = []
	for city_id in _get_city_ids():
		var config: Dictionary = _get_city_config(city_id)
		options.append({
			"id": "start_%s" % city_id,
			"name": "%s  %s" % [_get_city_name(city_id), str(config.get("start_tag", "稳步发展"))],
			"summary": str(config.get("summary", "适合稳步开局的城市。")),
			"rent": int(config.get("rent", 900)),
			"rent_cycle": int(config.get("rent_cycle", 10)),
			"work": str(config.get("work", "本地工作")),
			"unlock": str(config.get("unlock", "声望成长奖励")),
			"price": 0,
			"energy": 0,
			"start_city_id": city_id,
		})
	return options


func _choose_start_city(city_id: String) -> void:
	has_chosen_start_city = true
	_travel_to_city(city_id)
	_apply_city_landing_profile(city_id)
	_add_city_reputation(city_id, 3)
	hud.set_shop_message("已在%s落脚。关掉面板后，可以先找住处休息、接本地工作，或者去城市委托栏积累声望。" % _get_city_name(city_id))


func _apply_city_landing_profile(city_id: String) -> void:
	var config: Dictionary = _get_city_config(city_id)
	active_housing_id = "starter_%s" % city_id
	housing_sleep_energy = 100
	housing_sleep_stress_relief = int(config.get("sleep_stress_relief", 30))
	housing_morning_line = "你在%s的早晨醒来，今天可以先从一件小事开始。" % _get_city_name(city_id)
	time_manager.apply_housing_contract(
		active_housing_id,
		str(config.get("home", "临时住处")),
		int(config.get("rent", 900)),
		0,
		2,
		1,
	)
	time_manager.rent_cycle_days = int(config.get("rent_cycle", 10))
	time_manager.next_rent_day = max(time_manager.next_rent_day, time_manager.day + time_manager.rent_cycle_days)
	if apartment != null:
		apartment.set_housing_variant(active_housing_id, str(config.get("home", "临时住处")))


func _get_city_ids() -> PackedStringArray:
	return PackedStringArray(["shanghai", "changchun", "xian", "chengdu", "hangzhou"])


func _get_city_config(city_id: String) -> Dictionary:
	var configs := {
		"shanghai": {
			"name": "上海",
			"station": "上海虹桥站",
			"start_tag": "机会密集",
			"summary": "机会最多、节奏最快，适合想快速积累资源和声望。",
			"unlock": "声望30：民国上海",
			"home": "城中村合租房",
			"work": "社区商务助理",
			"work_line": "你在商圈和社区之间跑资料、对接店家，开始认识这座城市的真实脉搏。",
			"base_wage": 260,
			"energy_cost": 26,
			"stress_gain": 6,
			"rent": 900,
			"rent_cycle": 10,
			"sleep_stress_relief": 30,
		},
		"changchun": {
			"name": "长春",
			"station": "长春西站",
			"start_tag": "工业稳扎",
			"summary": "租金低、工作稳定，是最稳的前期过渡城市。",
			"unlock": "声望15：汽配长期单",
			"home": "老小区短租房",
			"work": "汽配园区文员",
			"work_line": "你帮园区店铺整理订单和发货单，节奏稳定，收入不爆发但很踏实。",
			"base_wage": 230,
			"energy_cost": 24,
			"stress_gain": 4,
			"rent": 650,
			"rent_cycle": 10,
			"sleep_stress_relief": 32,
		},
		"xian": {
			"name": "西安",
			"station": "西安北站",
			"start_tag": "文旅起势",
			"summary": "任务回报均衡，适合从城市声望和文旅机会起步。",
			"unlock": "声望30：唐朝长安",
			"home": "城墙边合租屋",
			"work": "文旅项目助理",
			"work_line": "你在游客、店主和活动表之间来回协调，慢慢攒下本地口碑。",
			"base_wage": 240,
			"energy_cost": 25,
			"stress_gain": 5,
			"rent": 720,
			"rent_cycle": 10,
			"sleep_stress_relief": 31,
		},
		"chengdu": {
			"name": "成都",
			"station": "成都东站",
			"start_tag": "生活回血",
			"summary": "压力最低、恢复最好，适合轻松开局和养状态。",
			"unlock": "声望15：社区合伙机会",
			"home": "巷子短租房",
			"work": "社区运营助理",
			"work_line": "你帮小店做团购、排活动，也学会在忙里留一点松弛。",
			"base_wage": 235,
			"energy_cost": 23,
			"stress_gain": 3,
			"rent": 700,
			"rent_cycle": 10,
			"sleep_stress_relief": 34,
		},
		"hangzhou": {
			"name": "杭州",
			"station": "杭州东站",
			"start_tag": "互联网跳板",
			"summary": "收入成长快，适合走电商、直播和互联网跳板路线。",
			"unlock": "声望15：电商项目单",
			"home": "滨江合租间",
			"work": "电商运营助理",
			"work_line": "你盯数据、改标题、跟活动，忙得细碎，但每一天都更像职业起步。",
			"base_wage": 250,
			"energy_cost": 26,
			"stress_gain": 5,
			"rent": 820,
			"rent_cycle": 10,
			"sleep_stress_relief": 30,
		},
	}
	return configs.get(city_id, configs["shanghai"])


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


func open_high_speed_rail(source: Node) -> void:
	player.set_controls_enabled(false)
	time_manager.set_time_paused(true)
	var station_title := "高铁站"
	if source != null:
		var display_name: Variant = source.get("display_name")
		if display_name is String and not display_name.is_empty():
			station_title = display_name
	hud.show_shop(station_title, _get_high_speed_rail_tickets())


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


func enter_internet_cafe() -> void:
	internet_cafe_return_position = player.global_position + Vector2(0, 20)
	current_location = "internet_cafe"
	city_map.visible = false
	city_map.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, false)
	for npc in npcs:
		npc.visible = false
		npc.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(npc, false)
	internet_cafe.visible = true
	internet_cafe.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(internet_cafe, true)
	player.global_position = internet_cafe.get_player_spawn()
	player.set_camera_limits(internet_cafe.get_world_rect())
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


func exit_internet_cafe() -> void:
	current_location = "street"
	internet_cafe.visible = false
	internet_cafe.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(internet_cafe, false)
	city_map.visible = true
	city_map.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(city_map, true)
	for npc in npcs:
		npc.visible = true
		npc.process_mode = Node.PROCESS_MODE_INHERIT
		_set_collision_tree_enabled(npc, true)
	player.global_position = internet_cafe_return_position
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


func enter_qikai_district_from(source: Node) -> void:
	if current_city_id != "changchun":
		show_dialogue("汽开区班车", ["这条线路从长春市区发车。"])
		return
	if source is Node2D:
		var source_2d: Node2D = source as Node2D
		qikai_district_return_position = source_2d.global_position + Vector2(0, 84)
	current_location = "qikai_district"
	var active_map := _get_active_street_map()
	if active_map != null:
		active_map.visible = false
		active_map.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(active_map, false)
	_set_npcs_enabled(false)
	qikai_district.visible = true
	qikai_district.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(qikai_district, true)
	player.global_position = qikai_district.get_player_spawn()
	player.set_camera_limits(qikai_district.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_qikai_district() -> void:
	current_location = "street"
	current_city_id = "changchun"
	qikai_district.visible = false
	qikai_district.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(qikai_district, false)
	_set_street_map_active("changchun")
	player.global_position = qikai_district_return_position
	var active_map := _get_active_street_map()
	if active_map != null and active_map.has_method("get_world_rect"):
		var active_rect: Rect2 = active_map.call("get_world_rect")
		player.set_camera_limits(active_rect)
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_faw_factory_from(source: Node) -> void:
	if current_location != "qikai_district":
		show_dialogue("厂区入口", ["第一汽车制造厂入口在汽开区北侧。"])
		return
	if source is Node2D:
		var source_2d: Node2D = source as Node2D
		faw_factory_return_position = source_2d.global_position + Vector2(0, 84)
	current_location = "faw_factory"
	qikai_district.visible = false
	qikai_district.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(qikai_district, false)
	_set_npcs_enabled(false)
	faw_factory.visible = true
	faw_factory.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(faw_factory, true)
	player.global_position = faw_factory.get_player_spawn()
	player.set_camera_limits(faw_factory.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_faw_factory() -> void:
	current_location = "qikai_district"
	current_city_id = "changchun"
	faw_factory.visible = false
	faw_factory.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(faw_factory, false)
	qikai_district.visible = true
	qikai_district.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(qikai_district, true)
	player.global_position = faw_factory_return_position
	player.set_camera_limits(qikai_district.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_tang_changan_from(source: Node) -> void:
	if current_city_id == "xian":
		var required_reputation := _get_history_unlock_reputation("xian")
		var current_reputation := _get_city_reputation("xian")
		if current_reputation < required_reputation:
			show_dialogue("唐长安入口", [
				"这道入口还只是城市传闻。",
				"西安声望达到 %d 后，唐朝长安地图会开放。当前声望：%d。" % [required_reputation, current_reputation],
				"先去城市委托栏做几件本地任务，让城墙边的人开始记住你。",
			])
			return
	if current_city_id != "xian":
		show_dialogue("唐长安遗址入口", ["这处入口只在西安的城市记忆里显现。"])
		return
	if source is Node2D:
		var source_2d: Node2D = source as Node2D
		tang_changan_return_position = source_2d.global_position + Vector2(0, 84)
	_start_history_chain("tang_museum")
	current_location = "tang_changan"
	var active_map := _get_active_street_map()
	if active_map != null:
		active_map.visible = false
		active_map.process_mode = Node.PROCESS_MODE_DISABLED
		_set_collision_tree_enabled(active_map, false)
	tang_changan.visible = true
	tang_changan.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(tang_changan, true)
	player.global_position = tang_changan.get_player_spawn()
	player.set_camera_limits(tang_changan.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_tang_changan() -> void:
	current_location = "street"
	current_city_id = "xian"
	tang_changan.visible = false
	tang_changan.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(tang_changan, false)
	_set_street_map_active("xian")
	player.global_position = tang_changan_return_position
	var active_map := _get_active_street_map()
	if active_map != null and active_map.has_method("get_world_rect"):
		var active_rect: Rect2 = active_map.call("get_world_rect")
		player.set_camera_limits(active_rect)
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_republic_shanghai_from(source: Node) -> void:
	if current_city_id == "shanghai":
		var required_reputation := _get_history_unlock_reputation("shanghai")
		var current_reputation := _get_city_reputation("shanghai")
		if current_reputation < required_reputation:
			show_dialogue("民国上海旧影", [
				"这段旧影还没有真正向你打开。",
				"上海声望达到 %d 后，民国上海地图会开放。当前声望：%d。" % [required_reputation, current_reputation],
				"先在人民广场附近接城市委托，积累一点能被城市看见的名字。",
			])
			return
	if current_city_id != "shanghai":
		show_dialogue("民国上海旧影", ["这段城市旧影只在上海街头显现。"])
		return
	if source is Node2D:
		var source_2d: Node2D = source as Node2D
		republic_shanghai_return_position = source_2d.global_position + Vector2(0, 84)
	_start_history_chain("republic_salon")
	current_location = "republic_shanghai"
	city_map.visible = false
	city_map.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(city_map, false)
	_set_npcs_enabled(false)
	republic_shanghai.visible = true
	republic_shanghai.process_mode = Node.PROCESS_MODE_INHERIT
	_set_collision_tree_enabled(republic_shanghai, true)
	player.global_position = republic_shanghai.get_player_spawn()
	player.set_camera_limits(republic_shanghai.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_republic_shanghai() -> void:
	current_location = "street"
	current_city_id = "shanghai"
	republic_shanghai.visible = false
	republic_shanghai.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(republic_shanghai, false)
	_set_street_map_active("shanghai")
	player.global_position = republic_shanghai_return_position
	player.set_camera_limits(city_map.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func enter_shanghai_mansion_from(source: Node) -> void:
	if _get_city_reputation("shanghai") < _get_history_unlock_reputation("shanghai"):
		show_dialogue("海上公馆", [
			"公馆门口的灯亮着，但门房还不认识你。",
			"上海声望达到 %d 后，公馆会向你开放。当前声望：%d。" % [_get_history_unlock_reputation("shanghai"), _get_city_reputation("shanghai")],
		])
		return
	if source is Node2D:
		shanghai_mansion_return_position = (source as Node2D).global_position + Vector2(0, 64)
	current_location = "shanghai_mansion"
	_set_street_map_active("none")
	shanghai_mansion.visible = true
	shanghai_mansion.process_mode = Node.PROCESS_MODE_INHERIT
	shanghai_mansion.set_guests(invited_historical_companions)
	_set_collision_tree_enabled(shanghai_mansion, true)
	player.global_position = shanghai_mansion.get_player_spawn()
	player.set_camera_limits(shanghai_mansion.get_world_rect())
	player.clear_interaction_focus()
	hud.hide_prompt()
	_update_time_flow()


func exit_shanghai_mansion() -> void:
	current_location = "street"
	current_city_id = "shanghai"
	shanghai_mansion.visible = false
	shanghai_mansion.process_mode = Node.PROCESS_MODE_DISABLED
	_set_collision_tree_enabled(shanghai_mansion, false)
	_set_street_map_active("shanghai")
	player.global_position = shanghai_mansion_return_position
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
	office_return_position = STREET_OFFICE
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
	wage += _get_city_growth_wage_bonus()
	stress_gain = max(0, stress_gain - _get_city_growth_stress_relief())
	var event_lines: Array = work_event["lines"]
	var return_segment: String = "late_night" if job_id == "job_streamer" and time_manager.get_segment_key() == "evening" else "evening"
	var worked: bool = time_manager.complete_work_shift(wage, energy_cost, return_segment, performance)
	if not worked:
		var fail_lines := event_lines.duplicate()
		fail_lines.append("临时状况让这份工作比预想更耗体力，你今天撑不完。")
		hud.show_dialogue(job_name, fail_lines)
		return
	time_manager.add_stress(stress_gain)
	var reputation_gain: int = _get_work_reputation_gain(job_id, performance)
	_add_reputation(reputation_gain)
	if current_location == "media_company":
		media_return_position = STREET_MEDIA
		exit_media_company()
	else:
		office_return_position = STREET_OFFICE
		exit_office()
	var result_lines: Array = [str(work_result["work_line"])]
	result_lines.append_array(event_lines)
	result_lines.append("结果：%s。收入 +%d，体力 -%d，压力 +%d。" % [performance, wage, energy_cost, stress_gain])
	result_lines.append("%s声望 +%d。%s" % [_get_city_name(current_city_id), reputation_gain, _get_city_reputation_label(current_city_id)])
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




func rest_at_city_home(_source: Node = null) -> void:
	player.set_controls_enabled(false)
	var config: Dictionary = _get_city_config(current_city_id)
	_apply_city_landing_profile(current_city_id)
	var target_energy := housing_sleep_energy
	var stress_relief: int = int(config.get("sleep_stress_relief", housing_sleep_stress_relief))
	time_manager.sleep_to_next_day(target_energy, stress_relief)
	_add_city_reputation(current_city_id, 1)
	hud.show_dialogue(str(config.get("home", "临时住处")), [
		"你在%s暂时落脚。" % _get_city_name(current_city_id),
		"这一版把城市前期压力调轻：睡一觉会恢复体力，也会小幅增加本地熟悉度。",
		"体力恢复，压力 -%d。%s声望 +1。" % [stress_relief, _get_city_name(current_city_id)],
	])


func request_city_basic_work(_source: Node = null) -> void:
	player.set_controls_enabled(false)
	if time_manager.get_segment_key() in ["evening", "late_night"]:
		hud.show_dialogue("本地工作", [
			"今天开始上班太晚了。",
			"明天上午或下午再来，先去住处休息会更稳。",
		])
		return
	var config: Dictionary = _get_city_config(current_city_id)
	var wage: int = int(config.get("base_wage", 230)) + _get_city_growth_wage_bonus()
	var energy_cost: int = int(config.get("energy_cost", 24))
	var stress_gain: int = maxi(0, int(config.get("stress_gain", 5)) - _get_city_growth_stress_relief())
	if time_manager.energy < energy_cost:
		hud.show_dialogue(str(config.get("work", "本地工作")), [
			"你现在体力不够，硬撑只会把一天赔进去。",
			"先吃点东西，或者回临时住处睡一觉。",
		])
		return
	var worked: bool = time_manager.complete_work_shift(wage, energy_cost, "evening", "稳步")
	if not worked:
		hud.show_dialogue(str(config.get("work", "本地工作")), ["今天状态不太适合完成这份工作。"])
		return
	time_manager.add_stress(stress_gain)
	var reputation_gain: int = 2
	if _get_city_reputation(current_city_id) >= 20:
		reputation_gain += 1
	_add_reputation(reputation_gain)
	hud.show_dialogue(str(config.get("work", "本地工作")), [
		str(config.get("work_line", "你完成了一份稳定的本地工作。")),
		"收入 +%d，体力 -%d，压力 +%d。" % [wage, energy_cost, stress_gain],
		"%s声望 +%d。%s" % [_get_city_name(current_city_id), reputation_gain, _get_city_reputation_label(current_city_id)],
	])


func request_city_task(_source: Node = null) -> void:
	player.set_controls_enabled(false)
	var task_key: String = "%s_%d" % [current_city_id, time_manager.day]
	if completed_city_tasks_today.has(task_key):
		hud.show_dialogue("城市委托栏", [
			"今天这个城市的轻委托已经处理过了。",
			"明天再来，会刷新新的本地机会。",
		])
		return
	var task: Dictionary = _get_city_task_for_today(current_city_id)
	var event: Dictionary = _get_city_random_event(current_city_id)
	if not event.is_empty():
		task = _merge_city_task_event(task, event)
	var energy_cost: int = int(task.get("energy_cost", 14))
	if time_manager.energy < energy_cost:
		hud.show_dialogue("城市委托栏", [
			"你看完委托内容，知道现在体力不够。",
			"先吃饭或休息，再来接会更划算。",
		])
		return
	completed_city_tasks_today[task_key] = true
	var reward: int = int(task.get("reward", 120)) + int(floor(float(_get_city_reputation(current_city_id)) * 1.2))
	var stress_delta: int = int(task.get("stress_gain", 0))
	var rep_gain: int = int(task.get("reputation", 3))
	time_manager.add_money(reward)
	time_manager.consume_energy(energy_cost)
	if stress_delta >= 0:
		time_manager.add_stress(stress_delta)
	else:
		time_manager.relieve_stress(abs(stress_delta))
	_add_reputation(rep_gain)
	hud.show_dialogue(str(task.get("title", "城市委托")), [
		str(task.get("line", "你完成了一件小事，城市也稍微向你打开了一点。")),
		"奖励 +%d，体力 -%d，压力 %+d，%s声望 +%d。" % [reward, energy_cost, stress_delta, _get_city_name(current_city_id), rep_gain],
		_get_history_hint_line(current_city_id),
	])


func request_archaeology_task(_source: Node = null) -> void:
	player.set_controls_enabled(false)
	if current_city_id != "xian":
		hud.show_dialogue("考古委托栏", ["这些委托只在西安开放。"])
		return
	if _get_city_reputation("xian") < 15:
		hud.show_dialogue("考古委托栏", [
			"博物馆的人还不太放心把线索交给你。",
			"西安声望达到15后，可以接取考古委托。当前：%d。" % _get_city_reputation("xian"),
		])
		return
	active_archaeology_task = "tang_artifact_route"
	_advance_history_chain("tang_museum", 1)
	hud.show_dialogue("考古委托栏", [
		"你接下了私人博物馆的线索整理任务。",
		"去唐朝长安寻找可疑文物点，采集后回私人博物馆编目展示。",
		"任务链：唐长安文物展 1/6。下一步：进入唐长安采集第一件文物线索。",
		"节点奖励：+180，西安声望 +2。",
		"这不是盗墓玩法，而是城市记忆里的文物线索复原。",
	])


func inspect_private_museum(_source: Node = null) -> void:
	player.set_controls_enabled(false)
	var lines: Array[String] = [
		"这是一间私人博物馆，灯光很低，玻璃柜还空着几格。",
		"已展示文物：%d 件。" % collected_artifacts.size(),
	]
	if collected_artifacts.is_empty():
		lines.append("先在考古委托栏接任务，再进入唐朝长安采集线索。")
	else:
		for artifact_id in collected_artifacts:
			lines.append("展品：%s。" % _get_artifact_name(str(artifact_id)))
		lines.append("文物展示让西安声望继续变得扎实。")
	_progress_tang_museum_at_museum(lines)
	lines.append(_get_history_chain_hint("tang_museum"))
	hud.show_dialogue("私人博物馆", lines)


func collect_historical_item(source: Node) -> void:
	player.set_controls_enabled(false)
	if current_location != "tang_changan":
		hud.show_dialogue("文物线索", ["这条线索只在唐朝长安的城市记忆里显现。"])
		return
	if active_archaeology_task.is_empty():
		hud.show_dialogue("文物线索", [
			"你看见了可疑的旧物痕迹，但还没有正式委托。",
			"先回西安私人博物馆旁边的考古委托栏接任务。",
		])
		return
	var artifact_id: String = _get_source_interactable_id(source)
	if collected_artifacts.has(artifact_id):
		hud.show_dialogue("文物线索", ["这件文物线索已经复原并入馆展示。"])
		return
	collected_artifacts.append(artifact_id)
	_progress_tang_museum_after_collect()
	_add_city_reputation("xian", 3)
	time_manager.add_money(180)
	hud.show_dialogue(_get_artifact_name(artifact_id), [
		"你复原了一条来自唐长安的文物线索。",
		"回到西安私人博物馆后，它会出现在展示柜里。",
		"节点奖励 +180，西安声望 +3。",
		_get_history_chain_hint("tang_museum"),
	])


func meet_historical_companion(source: Node) -> void:
	player.set_controls_enabled(false)
	var companion_id: String = _get_source_interactable_id(source)
	if invited_historical_companions.has(companion_id):
		hud.show_dialogue(_get_companion_name(companion_id), [
			"你们已经约好，之后可以在海上公馆继续交谈。",
		])
		return
	invited_historical_companions.append(companion_id)
	var target_city: String = "shanghai" if current_location == "republic_shanghai" else "xian"
	_add_city_reputation(target_city, 4)
	if target_city == "shanghai":
		_progress_republic_salon_after_invite()
	hud.show_dialogue(_get_companion_name(companion_id), [
		_get_companion_intro_line(companion_id),
		"你递出海上公馆的邀请。之后她会出现在公馆里，成为可以互动的历史来客。",
		"城市声望 +4。",
		_get_history_chain_hint("republic_salon" if target_city == "shanghai" else "tang_museum"),
	])
	if shanghai_mansion != null:
		shanghai_mansion.set_guests(invited_historical_companions)


func interact_mansion_guest(source: Node) -> void:
	player.set_controls_enabled(false)
	var companion_id: String = _get_source_interactable_id(source)
	time_manager.relieve_stress(4)
	_add_city_reputation("shanghai", 1)
	if not talked_mansion_guests.has(companion_id):
		talked_mansion_guests.append(companion_id)
	_progress_republic_salon_after_mansion_talk()
	if _get_history_chain_progress("republic_salon") >= 6:
		_complete_republic_salon_chain()
		return
	hud.show_dialogue(_get_companion_name(companion_id), [
		_get_companion_mansion_line(companion_id),
		"这次交谈让你压力 -4，上海声望 +1。",
		_get_history_chain_hint("republic_salon"),
	])


func _get_source_interactable_id(source: Node) -> String:
	if source != null:
		var interactable_id: Variant = source.get("interactable_id")
		if interactable_id is String:
			return str(interactable_id)
	return ""


func _start_history_chain(chain_id: String) -> void:
	if _get_history_chain_progress(chain_id) <= 0:
		_advance_history_chain(chain_id, 1)


func _get_history_chain_progress(chain_id: String) -> int:
	return int(history_story_progress.get(chain_id, 0))


func _set_history_chain_progress(chain_id: String, value: int) -> void:
	history_story_progress[chain_id] = clampi(value, 0, 6)


func _advance_history_chain(chain_id: String, target_progress: int) -> void:
	var old_progress: int = _get_history_chain_progress(chain_id)
	var next_progress: int = clampi(maxi(old_progress, target_progress), 0, 6)
	_set_history_chain_progress(chain_id, next_progress)
	if next_progress > old_progress:
		_grant_history_node_reward(chain_id, next_progress)


func _grant_history_node_reward(chain_id: String, node: int) -> void:
	var reward_key: String = "%s_%d" % [chain_id, node]
	if claimed_history_node_rewards.has(reward_key):
		return
	claimed_history_node_rewards[reward_key] = true
	var reward: Dictionary = _get_history_node_reward(chain_id, node)
	var money: int = int(reward.get("money", 0))
	var reputation_gain: int = int(reward.get("reputation", 0))
	var stress_relief: int = int(reward.get("stress_relief", 0))
	var max_energy_gain: int = int(reward.get("max_energy", 0))
	var city_id: String = str(reward.get("city", "shanghai"))
	if money > 0:
		time_manager.add_money(money)
	if stress_relief > 0:
		time_manager.relieve_stress(stress_relief)
	if max_energy_gain > 0:
		time_manager.max_energy = mini(140, time_manager.max_energy + max_energy_gain)
	if reputation_gain > 0:
		_add_city_reputation(city_id, reputation_gain)
	var line: String = str(reward.get("line", "历史任务节点完成。"))
	if not line.is_empty():
		pending_morning_notice.append(line)


func _get_history_node_reward(chain_id: String, node: int) -> Dictionary:
	if chain_id == "republic_salon":
		match node:
			1:
				return {"city": "shanghai", "money": 220, "reputation": 2, "stress_relief": 0, "line": "旧商会沙龙 1/6：你踏入民国上海旧影，获得线索费 +220，上海声望 +2。"}
			2:
				return {"city": "shanghai", "money": 360, "reputation": 3, "stress_relief": 2, "line": "旧商会沙龙 2/6：第一位历史来客接受邀请，+360，压力 -2。"}
			3:
				return {"city": "shanghai", "money": 520, "reputation": 4, "stress_relief": 3, "line": "旧商会沙龙 3/6：两位来客到位，公馆沙龙可以筹备，+520。"}
			4:
				return {"city": "shanghai", "money": 680, "reputation": 5, "stress_relief": 5, "line": "旧商会沙龙 4/6：第一次公馆深谈完成，上海人脉开始发酵，+680。"}
			5:
				return {"city": "shanghai", "money": 900, "reputation": 6, "stress_relief": 7, "line": "旧商会沙龙 5/6：沙龙名单成型，媒体与商会线索打开，+900。"}
			_:
				return {"city": "shanghai", "money": 1500, "reputation": 10, "stress_relief": 12, "line": "旧商会沙龙 6/6：长线完成，公馆成为上海高级人脉资产，+1500。"}
	match node:
		1:
			return {"city": "xian", "money": 180, "reputation": 2, "stress_relief": 0, "line": "唐长安文物展 1/6：考古委托启动，西安声望 +2。"}
		2:
			return {"city": "xian", "money": 260, "reputation": 3, "stress_relief": 1, "line": "唐长安文物展 2/6：第一件文物线索复原，+260。"}
		3:
			return {"city": "xian", "money": 360, "reputation": 4, "stress_relief": 2, "line": "唐长安文物展 3/6：第二件文物线索复原，展柜有了主题，+360。"}
		4:
			return {"city": "xian", "money": 560, "reputation": 5, "stress_relief": 3, "line": "唐长安文物展 4/6：第三件文物入馆，馆方愿意给你更多权限，+560。"}
		5:
			return {"city": "xian", "money": 760, "reputation": 6, "stress_relief": 4, "max_energy": 2, "line": "唐长安文物展 5/6：四件文物成组，体力上限 +2，+760。"}
		_:
			return {"city": "xian", "money": 1300, "reputation": 10, "stress_relief": 8, "max_energy": 3, "line": "唐长安文物展 6/6：长线完成，私人博物馆成为西安声望资产，+1300。"}


func _get_republic_invited_count() -> int:
	var count: int = 0
	for companion_id in invited_historical_companions:
		if str(companion_id).begins_with("republic_"):
			count += 1
	return count


func _progress_republic_salon_after_invite() -> void:
	var invited_count: int = _get_republic_invited_count()
	if invited_count >= 1:
		_advance_history_chain("republic_salon", 2)
	if invited_count >= 2:
		_advance_history_chain("republic_salon", 3)


func _progress_republic_salon_after_mansion_talk() -> void:
	if _get_history_chain_progress("republic_salon") < 3:
		return
	var talked_count: int = _get_republic_mansion_talk_count()
	if talked_count >= 1:
		_advance_history_chain("republic_salon", 4)
	if talked_count >= 2:
		_advance_history_chain("republic_salon", 5)
	if talked_count >= 2 and _get_republic_invited_count() >= 2:
		_advance_history_chain("republic_salon", 6)


func _get_republic_mansion_talk_count() -> int:
	var count: int = 0
	for companion_id in talked_mansion_guests:
		if str(companion_id).begins_with("republic_"):
			count += 1
	return count


func _can_complete_republic_salon_chain() -> bool:
	return _get_history_chain_progress("republic_salon") >= 6 and _get_republic_invited_count() >= 2


func _complete_republic_salon_chain() -> void:
	_unlock_historical_asset("shanghai_mansion_network")
	hud.show_dialogue("海上公馆沙龙", [
		"报馆女作者和爵士歌者在公馆里聊起旧上海的人脉、商会和报纸版面。",
		"你把这些线索整理成现代上海可用的资源：媒体曝光、投资介绍和城市名片。",
		"任务链完成：旧商会沙龙 6/6。已解锁现代资产：海上公馆人脉。",
	])


func _can_complete_tang_museum_chain() -> bool:
	return _get_history_chain_progress("tang_museum") >= 5 and collected_artifacts.size() >= 4


func _complete_tang_museum_chain(lines: Array[String]) -> void:
	_advance_history_chain("tang_museum", 6)
	active_archaeology_task = ""
	_unlock_historical_asset("xian_private_museum_exhibit")
	lines.append("你完成了第一组唐长安文物复原展。")
	lines.append("任务链完成：唐长安文物展 6/6。已解锁现代资产：私人博物馆展陈。")


func _progress_tang_museum_after_collect() -> void:
	var artifact_count: int = collected_artifacts.size()
	if artifact_count >= 1:
		_advance_history_chain("tang_museum", 2)
	if artifact_count >= 2:
		_advance_history_chain("tang_museum", 3)
	if artifact_count >= 3:
		_advance_history_chain("tang_museum", 4)
	if artifact_count >= 4:
		_advance_history_chain("tang_museum", 5)


func _progress_tang_museum_at_museum(lines: Array[String]) -> void:
	if _can_complete_tang_museum_chain():
		_complete_tang_museum_chain(lines)
	elif collected_artifacts.size() >= 1:
		lines.append("你把已复原的线索做了临时编目。每多一件展品，博物馆的价值都会更明确。")


func _get_history_chain_hint(chain_id: String) -> String:
	var progress: int = _get_history_chain_progress(chain_id)
	var next_reward_line: String = _get_next_history_reward_preview(chain_id)
	if chain_id == "republic_salon":
		if progress <= 0:
			return "任务链：旧商会沙龙未开启。进入民国上海后开始。%s" % next_reward_line
		if progress == 1:
			return "任务链：旧商会沙龙 1/6。下一步：在民国上海结识第一位历史来客。%s" % next_reward_line
		if progress == 2:
			return "任务链：旧商会沙龙 2/6。下一步：继续结识第二位历史来客。%s" % next_reward_line
		if progress == 3:
			return "任务链：旧商会沙龙 3/6。下一步：回海上公馆与第一位来客深谈。%s" % next_reward_line
		if progress == 4:
			return "任务链：旧商会沙龙 4/6。下一步：与第二位来客深谈。%s" % next_reward_line
		if progress == 5:
			return "任务链：旧商会沙龙 5/6。下一步：完成公馆沙龙总结。%s" % next_reward_line
		return "任务链：旧商会沙龙 6/6 已完成。公馆人脉会持续反哺上海发展。"
	if progress <= 0:
		return "任务链：唐长安文物展未开启。先在西安接考古委托。%s" % next_reward_line
	if progress == 1:
		return "任务链：唐长安文物展 1/6。下一步：进入唐长安采集第一件文物。%s" % next_reward_line
	if progress == 2:
		return "任务链：唐长安文物展 2/6。下一步：采集第二件文物。%s" % next_reward_line
	if progress == 3:
		return "任务链：唐长安文物展 3/6。下一步：采集第三件文物。%s" % next_reward_line
	if progress == 4:
		return "任务链：唐长安文物展 4/6。下一步：采集第四件文物。%s" % next_reward_line
	if progress == 5:
		return "任务链：唐长安文物展 5/6。下一步：回私人博物馆完成成展。%s" % next_reward_line
	return "任务链：唐长安文物展 6/6 已完成。博物馆开始成为西安声望资产。"


func _get_next_history_reward_preview(chain_id: String) -> String:
	var next_node: int = mini(_get_history_chain_progress(chain_id) + 1, 6)
	if next_node >= 6 and _get_history_chain_progress(chain_id) >= 6:
		return ""
	var reward: Dictionary = _get_history_node_reward(chain_id, next_node)
	var money: int = int(reward.get("money", 0))
	var reputation_gain: int = int(reward.get("reputation", 0))
	var stress_relief: int = int(reward.get("stress_relief", 0))
	var extra: String = ""
	if stress_relief > 0:
		extra = "，压力 -%d" % stress_relief
	return " 下一节点奖励：+%d，声望 +%d%s。" % [money, reputation_gain, extra]


func _get_history_chain_objective() -> Dictionary:
	var republic_progress: int = _get_history_chain_progress("republic_salon")
	if republic_progress in [1, 2] and current_location == "republic_shanghai":
		return {"position": Vector2(448, 832)}
	if republic_progress in [3, 4, 5] and current_location == "street" and current_city_id == "shanghai":
		return {"position": shanghai_mansion_return_position}
	if republic_progress in [3, 4, 5] and current_location == "shanghai_mansion":
		return {"position": Vector2(480, 388)}
	var tang_progress: int = _get_history_chain_progress("tang_museum")
	if tang_progress == 1 and current_location == "street" and current_city_id == "xian":
		return {"position": _get_regional_tile_world_position(Vector2i(17, 5))}
	if tang_progress in [1, 2, 3, 4] and current_location == "tang_changan":
		return {"position": Vector2(416, 800)}
	if tang_progress == 5 and current_location == "street" and current_city_id == "xian":
		return {"position": _get_regional_tile_world_position(Vector2i(22, 8))}
	return {}


func _unlock_historical_asset(asset_id: String) -> void:
	if owned_historical_assets.has(asset_id):
		return
	owned_historical_assets.append(asset_id)
	var profile: Dictionary = _get_historical_asset_profile(asset_id)
	var city_id: String = str(profile.get("city", current_city_id))
	_add_city_reputation(city_id, int(profile.get("unlock_reputation", 0)))
	time_manager.add_money(int(profile.get("unlock_money", 0)))
	pending_morning_notice.append("历史资产解锁：%s。之后每天会结算现代收益。" % str(profile.get("name", "历史资产")))
	_on_status_changed(time_manager.get_status())


func _get_historical_asset_profile(asset_id: String) -> Dictionary:
	match asset_id:
		"shanghai_mansion_network":
			return {
				"name": "海上公馆人脉",
				"city": "shanghai",
				"daily_income": 360,
				"daily_reputation": 1,
				"stress_relief": 2,
				"unlock_money": 800,
				"unlock_reputation": 3,
				"desc": "旧商会与报馆线索转化成现代上海的人脉、曝光和投资介绍。",
			}
		"xian_private_museum_exhibit":
			return {
				"name": "私人博物馆展陈",
				"city": "xian",
				"daily_income": 300,
				"daily_reputation": 1,
				"stress_relief": 1,
				"unlock_money": 700,
				"unlock_reputation": 3,
				"desc": "唐长安文物展变成稳定展陈，带来门票、文旅项目和本地口碑。",
			}
		_:
			return {
				"name": "历史资产",
				"city": current_city_id,
				"daily_income": 120,
				"daily_reputation": 0,
				"stress_relief": 0,
				"unlock_money": 0,
				"unlock_reputation": 0,
				"desc": "历史线索转化成现代城市资源。",
			}


func _get_owned_historical_asset_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for asset_id in owned_historical_assets:
		var profile: Dictionary = _get_historical_asset_profile(str(asset_id))
		snapshot.append({
			"id": str(asset_id),
			"name": str(profile.get("name", asset_id)),
			"daily_income": int(profile.get("daily_income", 0)),
			"daily_reputation": int(profile.get("daily_reputation", 0)),
			"desc": str(profile.get("desc", "")),
		})
	return snapshot


func _collect_historical_asset_daily_income() -> int:
	var total_income: int = 0
	var total_stress_relief: int = 0
	for asset_id in owned_historical_assets:
		var profile: Dictionary = _get_historical_asset_profile(str(asset_id))
		total_income += int(profile.get("daily_income", 0))
		total_stress_relief += int(profile.get("stress_relief", 0))
		var city_id: String = str(profile.get("city", current_city_id))
		_add_city_reputation(city_id, int(profile.get("daily_reputation", 0)), false)
	if total_income > 0:
		time_manager.add_money(total_income)
	if total_stress_relief > 0:
		time_manager.relieve_stress(total_stress_relief)
	historical_asset_daily_income = total_income
	if total_income > 0:
		_on_status_changed(time_manager.get_status())
	return total_income


func _get_regional_tile_world_position(tile: Vector2i) -> Vector2:
	return Vector2(tile.x * 64.0 + 32.0, tile.y * 64.0 + 32.0)


func _merge_city_task_event(task: Dictionary, event: Dictionary) -> Dictionary:
	var merged: Dictionary = task.duplicate()
	merged["title"] = "%s｜%s" % [str(event.get("title", "随机事件")), str(task.get("title", "城市委托"))]
	merged["line"] = "%s %s" % [str(event.get("line", "")), str(task.get("line", ""))]
	merged["reward"] = int(task.get("reward", 0)) + int(event.get("reward", 0))
	merged["energy_cost"] = maxi(1, int(task.get("energy_cost", 0)) + int(event.get("energy_cost", 0)))
	merged["stress_gain"] = int(task.get("stress_gain", 0)) + int(event.get("stress_gain", 0))
	merged["reputation"] = int(task.get("reputation", 0)) + int(event.get("reputation", 0))
	return merged


func request_pay_rent() -> void:
	player.set_controls_enabled(false)
	if time_manager.pay_rent():
		var timing_line: String = "转账完成。房租 -%d。" % time_manager.rent_amount
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
	var reputation_gain := 1
	if performance == "专注":
		reputation_gain = 2
	_add_reputation(reputation_gain)
	time_manager.record_work_performance("外卖%s" % performance)
	time_manager.set_segment("evening")
	var result_lines := [
		line,
		"结果：%s。收入 +%d，体力 -%d，压力 +%d。" % [performance, max(35, reward), energy_cost, stress_gain],
		"%s声望 +%d。稳定完成城市里的小任务，也会慢慢被看见。" % [_get_city_name(current_city_id), reputation_gain],
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
			"position": STREET_HOME + Vector2(48, 24),
			"palette": {"hair": Color("#3a3029"), "skin": Color("#c49167"), "shirt": Color("#8d7560")},
			"routes": {
				"morning": [STREET_HOME + Vector2(48, 24), STREET_HOME + Vector2(64, 86), STREET_HOME + Vector2(-36, 86), STREET_HOME],
				"afternoon": [STREET_HOME + Vector2(36, 20), STREET_RENTAL_AGENCY, STREET_TALENT_APARTMENT, STREET_HOME + Vector2(78, 96)],
				"evening": [STREET_HOME + Vector2(-42, 14), STREET_HOME + Vector2(52, 18)],
				"late_night": [STREET_HOME + Vector2(-30, 0)],
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
			"position": STREET_STORE + Vector2(-32, 40),
			"palette": {"hair": Color("#25262b"), "skin": Color("#d6a373"), "shirt": Color("#3f806f")},
			"routes": {
				"morning": [STREET_STORE + Vector2(-32, 40), STREET_STORE + Vector2(90, 40), STREET_MARKET],
				"afternoon": [STREET_STORE + Vector2(10, 28), STREET_STORE + Vector2(96, 30), STREET_STORE + Vector2(96, 72)],
				"evening": [STREET_STORE + Vector2(-20, 52), STREET_STORE + Vector2(76, 52), STREET_STORE + Vector2(76, 84)],
				"late_night": [STREET_STORE + Vector2(20, 36)],
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
			"position": Vector2(760, 960),
			"palette": {"hair": Color("#241b22"), "skin": Color("#d8a17b"), "shirt": Color("#c55b70")},
			"routes": {
				"morning": [STREET_HOME + Vector2(-20, 128), Vector2(960, 960), STREET_METRO + Vector2(-60, -40)],
				"afternoon": [Vector2(820, 1120), STREET_CLINIC, Vector2(1160, 1160)],
				"evening": [STREET_METRO + Vector2(-80, -30), STREET_TALENT_APARTMENT, STREET_STORE + Vector2(40, 40)],
				"late_night": [STREET_STORE + Vector2(10, 66), Vector2(1500, 880), Vector2(940, 1120)],
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
			"position": STREET_DELIVERY_STATION + Vector2(64, 18),
			"palette": {"hair": Color("#1f2428"), "skin": Color("#c49167"), "shirt": Color("#d29b2e")},
			"routes": {
				"morning": [STREET_DELIVERY_STATION + Vector2(64, 18), STREET_OFFICE_COFFEE + Vector2(-20, 22), STREET_RESTAURANT],
				"afternoon": [STREET_DELIVERY_STATION + Vector2(56, 22), STREET_OFFICE_COFFEE + Vector2(20, 46), STREET_RENTAL_AGENCY],
				"evening": [STREET_DELIVERY_STATION + Vector2(110, 18), STREET_OFFICE_COFFEE, STREET_DELIVERY_STATION + Vector2(100, 54)],
				"late_night": [STREET_DELIVERY_STATION + Vector2(72, 20), STREET_DELIVERY_STATION + Vector2(92, 20)],
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
			"position": STREET_MEDIA + Vector2(48, 28),
			"palette": {"hair": Color("#2b2527"), "skin": Color("#d8a17b"), "shirt": Color("#c26c74")},
			"routes": {
				"morning": [STREET_MEDIA + Vector2(48, 28), STREET_MEDIA + Vector2(-20, 28), STREET_MEDIA + Vector2(32, 72)],
				"afternoon": [STREET_MEDIA + Vector2(44, 30), STREET_PEOPLE_SQUARE, STREET_OFFICE_COFFEE],
				"evening": [STREET_MEDIA + Vector2(48, 28), STREET_MEDIA + Vector2(90, 28), STREET_MEDIA + Vector2(48, 28)],
				"late_night": [STREET_MEDIA + Vector2(46, 32), STREET_MEDIA + Vector2(-24, 32)],
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
			"position": STREET_OFFICE + Vector2(0, 88),
			"palette": {"hair": Color("#24292f"), "skin": Color("#d6a373"), "shirt": Color("#5d6870")},
			"routes": {
				"morning": [STREET_METRO + Vector2(-60, -40), STREET_OFFICE + Vector2(-54, 88), STREET_OFFICE + Vector2(88, 76)],
				"afternoon": [STREET_OFFICE, STREET_OFFICE_COFFEE, STREET_RENTAL_AGENCY, STREET_OFFICE],
				"evening": [STREET_OFFICE, STREET_TALENT_APARTMENT, STREET_METRO + Vector2(-70, -34)],
				"late_night": [STREET_OFFICE + Vector2(88, 76), STREET_OFFICE + Vector2(-82, 94)],
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
			"position": STREET_METRO + Vector2(-16, -36),
			"palette": {"hair": Color("#3b302b"), "skin": Color("#c49167"), "shirt": Color("#6b7280")},
			"routes": {
				"morning": [STREET_METRO + Vector2(-76, -20), STREET_METRO + Vector2(-16, -36), STREET_METRO + Vector2(42, -28)],
				"afternoon": [STREET_METRO + Vector2(-18, -40), STREET_CLINIC, STREET_METRO + Vector2(-18, -40)],
				"evening": [STREET_METRO + Vector2(42, -28), STREET_METRO + Vector2(-16, -36), STREET_METRO + Vector2(-76, -20)],
				"late_night": [STREET_METRO + Vector2(-18, -40), STREET_METRO + Vector2(8, -40)],
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
		var landlord_line: String = "和房东聊了几句。关系 +%d，压力 -%d。%s。%s" % [relationship_gain, stress_relief, _get_relationship_summary_line(npc_id), _get_landlord_rent_line()]
		if not event_line.is_empty():
			return "%s %s" % [landlord_line, event_line]
		return landlord_line
	var profile: Dictionary = npc_social_profiles.get(npc_id, {})
	var npc_name: String = str(profile.get("name", "对方"))
	var talk_line: String = "你和%s在街边短短聊了一会儿。关系 +%d，压力 -%d。%s。" % [npc_name, relationship_gain, stress_relief, _get_relationship_summary_line(npc_id)]
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
		reputation = _get_total_reputation()
		display_status["reputation"] = reputation
		display_status["reputation_label"] = _get_reputation_label()
		display_status["city_name"] = _get_city_name(current_city_id)
		display_status["city_reputation"] = _get_city_reputation(current_city_id)
		display_status["city_reputation_label"] = _get_city_reputation_label(current_city_id)
		display_status["city_reputations"] = _get_city_reputation_snapshot()
		display_status["task_tracker"] = _get_task_tracker_snapshot()
		display_status["owned_land"] = _get_owned_land_snapshot()
		display_status["owned_companies"] = _get_owned_company_snapshot()
		display_status["owned_city_growth_assets"] = _get_owned_city_growth_asset_snapshot()
		display_status["owned_historical_assets"] = _get_owned_historical_asset_snapshot()
		display_status["company_daily_income"] = company_daily_income
		display_status["city_growth_asset_daily_income"] = city_growth_asset_daily_income
		display_status["historical_asset_daily_income"] = historical_asset_daily_income
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


func _add_reputation(amount: int) -> void:
	if amount <= 0:
		return
	_add_city_reputation(current_city_id, amount, false)
	reputation = _get_total_reputation()
	if time_manager != null:
		_on_status_changed(time_manager.get_status())


func _add_city_reputation(city_id: String, amount: int, refresh_status: bool = true) -> void:
	if amount <= 0:
		return
	var key := city_id
	if key.is_empty():
		key = "shanghai"
	var current_value: int = int(city_reputations.get(key, 0))
	city_reputations[key] = clampi(current_value + amount, 0, 100)
	reputation = _get_total_reputation()
	_apply_city_reputation_rewards(key, current_value, int(city_reputations[key]))
	if refresh_status and time_manager != null:
		_on_status_changed(time_manager.get_status())


func _get_city_reputation(city_id: String) -> int:
	return int(city_reputations.get(city_id, 0))


func _apply_city_reputation_rewards(city_id: String, old_value: int, new_value: int) -> void:
	for threshold in [15, 30, 60]:
		if old_value < threshold and new_value >= threshold:
			var reward_id: String = "%s_%d" % [city_id, threshold]
			if claimed_city_reputation_rewards.has(reward_id):
				continue
			claimed_city_reputation_rewards[reward_id] = true
			var reward: Dictionary = _get_city_reputation_reward(city_id, threshold)
			time_manager.add_money(int(reward.get("money", 0)))
			time_manager.max_energy = min(140, time_manager.max_energy + int(reward.get("max_energy", 0)))
			time_manager.relieve_stress(int(reward.get("stress_relief", 0)))
			_unlock_city_growth_asset(city_id, threshold)
			pending_morning_notice.append(str(reward.get("line", "%s声望提升，新的机会出现了。" % _get_city_name(city_id))))


func _get_city_reputation_reward(city_id: String, threshold: int) -> Dictionary:
	var city_name: String = _get_city_name(city_id)
	if threshold == 15:
		return {"money": 300, "max_energy": 2, "stress_relief": 3, "line": "%s声望达到15：本地人开始给你介绍稳定小单。奖励 +300，体力上限 +2。" % city_name}
	if threshold == 30:
		if city_id == "shanghai":
			return {"money": 600, "max_energy": 3, "stress_relief": 6, "line": "上海声望达到30：民国上海旧影入口开放。奖励 +600，体力上限 +3。"}
		if city_id == "xian":
			return {"money": 600, "max_energy": 3, "stress_relief": 6, "line": "西安声望达到30：唐朝长安入口开放。奖励 +600，体力上限 +3。"}
		return {"money": 600, "max_energy": 3, "stress_relief": 5, "line": "%s声望达到30：你有了本地口碑，工作收益会继续抬升。奖励 +600。" % city_name}
	return {"money": 1200, "max_energy": 5, "stress_relief": 10, "line": "%s声望达到60：你不再只是过客，城市开始反过来推你一把。奖励 +1200，体力上限 +5。" % city_name}


func _unlock_city_growth_asset(city_id: String, threshold: int) -> void:
	var asset_id: String = "%s_stage_%d" % [city_id, threshold]
	if owned_city_growth_assets.has(asset_id):
		return
	owned_city_growth_assets.append(asset_id)
	var profile: Dictionary = _get_city_growth_asset_profile(asset_id)
	pending_morning_notice.append("城市阶段资产解锁：%s。%s" % [
		str(profile.get("name", "本地机会")),
		str(profile.get("desc", "之后每天会带来更稳定的发展收益。")),
	])


func _get_city_growth_asset_profile(asset_id: String) -> Dictionary:
	var parts: PackedStringArray = asset_id.split("_stage_")
	var city_id: String = parts[0] if parts.size() > 0 else current_city_id
	var threshold: int = int(parts[1]) if parts.size() > 1 else 15
	var city_name: String = _get_city_name(city_id)
	if threshold >= 60:
		return {
			"name": "%s城市名片" % city_name,
			"city": city_id,
			"daily_income": 180,
			"daily_reputation": 1,
			"wage_bonus": 35,
			"stress_relief": 2,
			"desc": "本地口碑开始主动带来合作、介绍和更高工作报价。",
		}
	if threshold >= 30:
		return {
			"name": "%s熟人网络" % city_name,
			"city": city_id,
			"daily_income": 90,
			"daily_reputation": 1,
			"wage_bonus": 20,
			"stress_relief": 1,
			"desc": "你在这座城市有了稳定联系人，工作和委托更容易谈成。",
		}
	return {
		"name": "%s本地小单" % city_name,
		"city": city_id,
		"daily_income": 45,
		"daily_reputation": 0,
		"wage_bonus": 10,
		"stress_relief": 0,
		"desc": "附近的人开始记住你，偶尔会把轻量机会介绍过来。",
	}


func _get_owned_city_growth_asset_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for asset_id in owned_city_growth_assets:
		var profile: Dictionary = _get_city_growth_asset_profile(str(asset_id))
		snapshot.append({
			"id": str(asset_id),
			"name": str(profile.get("name", asset_id)),
			"city": str(profile.get("city", current_city_id)),
			"daily_income": int(profile.get("daily_income", 0)),
			"daily_reputation": int(profile.get("daily_reputation", 0)),
			"wage_bonus": int(profile.get("wage_bonus", 0)),
			"stress_relief": int(profile.get("stress_relief", 0)),
			"desc": str(profile.get("desc", "")),
		})
	return snapshot


func _collect_city_growth_asset_daily_income() -> int:
	var total_income: int = 0
	var total_stress_relief: int = 0
	for asset_id in owned_city_growth_assets:
		var profile: Dictionary = _get_city_growth_asset_profile(str(asset_id))
		total_income += int(profile.get("daily_income", 0))
		total_stress_relief += int(profile.get("stress_relief", 0))
		var city_id: String = str(profile.get("city", current_city_id))
		_add_city_reputation(city_id, int(profile.get("daily_reputation", 0)), false)
	if total_income > 0:
		time_manager.add_money(total_income)
	if total_stress_relief > 0:
		time_manager.relieve_stress(total_stress_relief)
	city_growth_asset_daily_income = total_income
	if total_income > 0:
		_on_status_changed(time_manager.get_status())
	return total_income


func _get_current_city_asset_wage_bonus() -> int:
	var bonus: int = 0
	for asset_id in owned_city_growth_assets:
		var profile: Dictionary = _get_city_growth_asset_profile(str(asset_id))
		if str(profile.get("city", current_city_id)) == current_city_id:
			bonus += int(profile.get("wage_bonus", 0))
	return bonus


func _get_current_city_asset_stress_relief() -> int:
	var relief: int = 0
	for asset_id in owned_city_growth_assets:
		var profile: Dictionary = _get_city_growth_asset_profile(str(asset_id))
		if str(profile.get("city", current_city_id)) == current_city_id:
			relief += int(profile.get("stress_relief", 0))
	return relief


func _get_history_unlock_reputation(city_id: String) -> int:
	if city_id == "shanghai" or city_id == "xian":
		return 30
	return 999


func _get_total_reputation() -> int:
	var total: int = 0
	var values: Array = city_reputations.values()
	for value_index in range(values.size()):
		total += int(values[value_index])
	return clampi(total, 0, 500)


func _get_city_reputation_label(city_id: String) -> String:
	var value: int = _get_city_reputation(city_id)
	if value >= 70:
		return "城市名片"
	if value >= 40:
		return "地方熟人"
	if value >= 15:
		return "被人记住"
	return "初来乍到"


func _get_city_growth_wage_bonus() -> int:
	var city_rep: int = _get_city_reputation(current_city_id)
	var total_rep: int = _get_total_reputation()
	return int(floor(float(city_rep) * 1.5)) + int(floor(float(total_rep) * 0.2)) + _get_current_city_asset_wage_bonus()


func _get_city_growth_stress_relief() -> int:
	var city_rep: int = _get_city_reputation(current_city_id)
	var asset_relief: int = _get_current_city_asset_stress_relief()
	if city_rep >= 70:
		return 5 + asset_relief
	if city_rep >= 40:
		return 3 + asset_relief
	if city_rep >= 20:
		return 2 + asset_relief
	return asset_relief


func _get_city_task_for_today(city_id: String) -> Dictionary:
	var tasks: Array[Dictionary] = _get_city_task_pool(city_id)
	if tasks.is_empty():
		return {"title": "城市小委托", "line": "你帮附近店家处理了一件小事。", "reward": 100, "energy_cost": 12, "stress_gain": 0, "reputation": 2}
	var index: int = absi((time_manager.day * 17 + city_id.hash()) % tasks.size())
	return tasks[index]


func _get_city_random_event(city_id: String) -> Dictionary:
	if city_id != "shanghai" and city_id != "xian":
		return {}
	var events: Array[Dictionary] = _get_city_random_event_pool(city_id)
	if events.is_empty():
		return {}
	var roll: int = absi((time_manager.day * 31 + time_manager.get_clock_total_minutes() + city_id.hash()) % 100)
	if roll >= 65:
		return {}
	var index: int = absi((time_manager.day * 7 + roll) % events.size())
	return events[index]


func _get_city_random_event_pool(city_id: String) -> Array[Dictionary]:
	if city_id == "shanghai":
		return [
			{"title": "雨突然大了", "line": "刚接下委托，雨点砸得像一整条街都在催你快点。", "reward": 45, "energy_cost": 2, "stress_gain": 1, "reputation": 1},
			{"title": "遇到熟面孔", "line": "便利店老板认出了你，顺手告诉你一条更近的小路。", "reward": 30, "energy_cost": -2, "stress_gain": -1, "reputation": 1},
			{"title": "末班车广播", "line": "地铁口的末班车广播响起，所有人的脚步都快了半拍。", "reward": 55, "energy_cost": 1, "stress_gain": 2, "reputation": 1},
			{"title": "写字楼临时需求", "line": "附近写字楼临时缺人对接资料，机会来得有点急。", "reward": 80, "energy_cost": 3, "stress_gain": 2, "reputation": 2},
		]
	if city_id == "xian":
		return [
			{"title": "城墙风起", "line": "城墙边风突然大了，游客慢下来，你反而有时间把事情讲清楚。", "reward": 35, "energy_cost": 0, "stress_gain": -1, "reputation": 1},
			{"title": "小吃摊加单", "line": "小吃摊老板临时多拜托你跑一趟，说完又塞给你热乎的吃食。", "reward": 55, "energy_cost": 2, "stress_gain": -1, "reputation": 1},
			{"title": "游客问路", "line": "几个游客在巷口迷路，你顺手把他们带到正确入口。", "reward": 40, "energy_cost": 1, "stress_gain": 0, "reputation": 2},
			{"title": "旧碑拓片", "line": "有人请你帮忙把资料送到碑林附近，纸袋里有旧墨味。", "reward": 75, "energy_cost": 3, "stress_gain": 1, "reputation": 2},
		]
	return []


func _get_city_task_pool(city_id: String) -> Array[Dictionary]:
	match city_id:
		"shanghai":
			return [
				{"title": "雨夜便利店补货", "line": "你帮便利店老板把雨夜到货的箱子搬进仓库，门口霓虹在积水里晃。", "reward": 160, "energy_cost": 16, "stress_gain": -2, "reputation": 4},
				{"title": "凌晨地铁指路", "line": "你在换乘口帮几个赶末班车的人指路，城市的陌生感少了一点。", "reward": 120, "energy_cost": 12, "stress_gain": 0, "reputation": 4},
				{"title": "合租楼维修登记", "line": "你把楼里的漏水、灯泡和门禁问题整理成表，房东终于愿意认真看一眼。", "reward": 140, "energy_cost": 14, "stress_gain": 1, "reputation": 5},
			]
		"xian":
			return [
				{"title": "城墙夜游协助", "line": "你帮小摊主和游客协调路线，晚风从城墙上吹下来。", "reward": 145, "energy_cost": 14, "stress_gain": -1, "reputation": 4},
				{"title": "碑林资料整理", "line": "你给文旅项目整理旧资料，纸页和手机备忘录混在一起。", "reward": 135, "energy_cost": 13, "stress_gain": 0, "reputation": 5},
				{"title": "小吃街排队引导", "line": "你帮店家维持排队秩序，老板多塞给你一份热乎的吃食。", "reward": 130, "energy_cost": 15, "stress_gain": -2, "reputation": 4},
			]
		"changchun":
			return [
				{"title": "汽配订单核对", "line": "你帮园区店铺核对发货单，东北风从卷帘门缝里钻进来。", "reward": 125, "energy_cost": 12, "stress_gain": 0, "reputation": 3},
				{"title": "社区公告张贴", "line": "你沿着老小区贴公告，也顺便记住了几条近路。", "reward": 110, "energy_cost": 11, "stress_gain": -1, "reputation": 3},
			]
		"chengdu":
			return [
				{"title": "巷子团购对接", "line": "你帮几家小店对齐团购信息，茶馆门口的人声慢慢热起来。", "reward": 120, "energy_cost": 11, "stress_gain": -2, "reputation": 3},
				{"title": "夜市摊位帮忙", "line": "你帮摊主整理桌椅，忙完后整条街都像亮了一点。", "reward": 125, "energy_cost": 13, "stress_gain": -1, "reputation": 3},
			]
		"hangzhou":
			return [
				{"title": "电商活动校对", "line": "你帮创业团队校对活动页，湖边风和工位灯同时亮着。", "reward": 140, "energy_cost": 14, "stress_gain": 1, "reputation": 3},
				{"title": "社区直播助理", "line": "你帮小店调试直播灯和商品卡片，第一次感觉流量离自己不远。", "reward": 150, "energy_cost": 15, "stress_gain": 1, "reputation": 4},
			]
	return []


func _get_companion_name(companion_id: String) -> String:
	match companion_id:
		"republic_companion_writer":
			return "报馆女作者"
		"republic_companion_singer":
			return "爵士歌者"
		"tang_companion_scholar":
			return "女史学者"
		_:
			return "历史来客"


func _get_companion_intro_line(companion_id: String) -> String:
	match companion_id:
		"republic_companion_writer":
			return "她在报馆写城市专栏，关心新女性、租界边界和普通人的命运。"
		"republic_companion_singer":
			return "她在舞厅唱爵士，也知道每一盏灯背后都有账单和故事。"
		"tang_companion_scholar":
			return "她熟悉坊市、文书和旧物来历，愿意帮你辨认唐长安的线索。"
		_:
			return "她像从城市记忆里走出来的人，带着另一个时代的气息。"


func _get_companion_mansion_line(companion_id: String) -> String:
	match companion_id:
		"republic_companion_writer":
			return "她把一篇未完成的专栏读给你听，里面写着城市如何吞下又托起年轻人。"
		"republic_companion_singer":
			return "她轻轻哼了一段旋律，公馆里的旧灯像雨夜便利店一样温暖。"
		"tang_companion_scholar":
			return "她把唐长安的坊市格局画在便笺上，提醒你文物背后先是人的生活。"
		_:
			return "你们聊了一会儿旧时代和今天，城市的压力短暂退后。"


func _get_artifact_name(artifact_id: String) -> String:
	match artifact_id:
		"artifact_tang_sancai":
			return "唐三彩碎片"
		"artifact_bronze_mirror":
			return "铜镜残片"
		_:
			return "未定名文物"


func _get_history_hint_line(city_id: String) -> String:
	if city_id == "shanghai":
		var need: int = _get_history_unlock_reputation("shanghai")
		return "上海声望达到 %d 后，可进入民国上海旧影。当前：%d。" % [need, _get_city_reputation("shanghai")]
	if city_id == "xian":
		var need: int = _get_history_unlock_reputation("xian")
		return "西安声望达到 %d 后，可进入唐朝长安。当前：%d。" % [need, _get_city_reputation("xian")]
	return "声望越高，本地工作收益越好，压力增长也会更低。"


func _get_city_reputation_snapshot() -> Array[Dictionary]:
	var city_ids: PackedStringArray = PackedStringArray(["shanghai", "changchun", "xian", "chengdu", "hangzhou"])
	var snapshot: Array[Dictionary] = []
	for city_id in city_ids:
		snapshot.append({
			"id": city_id,
			"name": _get_city_name(city_id),
			"value": _get_city_reputation(city_id),
			"label": _get_city_reputation_label(city_id),
		})
	return snapshot


func _get_task_tracker_snapshot() -> Dictionary:
	return {
		"main": _get_primary_task_objective(),
		"history": _get_history_task_entries(),
		"city": _get_city_development_task_entries(),
		"survival": _get_survival_task_entries(),
	}


func _task_entry(title: String, objective: String, reward: String = "", tag: String = "目标") -> Dictionary:
	return {
		"title": title,
		"objective": objective,
		"reward": reward,
		"tag": tag,
	}


func _get_primary_task_objective() -> Dictionary:
	if delivery_state == "accepted":
		return _task_entry("外卖配送", "去小饭馆取餐，再送到订单目的地。", "完成后获得配送收入和城市声望。", "进行中")
	if delivery_state == "picked":
		return _task_entry("外卖配送", "把已经取到的外卖送到目的地。", "尽快送达会让今天的现金流更稳。", "进行中")
	var rent_overdue_days: int = time_manager.get_rent_overdue_days()
	if rent_overdue_days > 0:
		return _task_entry("房租逾期", "回出租屋，在房租单处补交房租。", "解除逾期压力，避免继续恶化。", "紧急")
	if not time_manager.worked_this_day and time_manager.get_segment_key() in ["morning", "afternoon"]:
		return _task_entry("今日收入", "去本地工作点、写字楼、配送站或传媒公司安排一份工作。", "工资会受到城市声望和阶段资产加成。", "今日")
	var history_entry: Dictionary = _get_active_history_task_entry()
	if not history_entry.is_empty():
		return history_entry
	if time_manager.energy < 45:
		return _task_entry("恢复体力", "吃点东西、用背包物品，或者回住处休息。", "保持体力才能继续工作和跑任务。", "生存")
	return _task_entry("城市发展", "接城市委托、聊天或探索关键地点，继续积累本地声望。", "声望会解锁阶段资产、历史入口和更高收益。", "推荐")


func _get_active_history_task_entry() -> Dictionary:
	var republic_progress: int = _get_history_chain_progress("republic_salon")
	if republic_progress > 0 and republic_progress < 6:
		return _task_entry("旧商会沙龙", _get_history_chain_hint("republic_salon"), "完成后解锁海上公馆人脉资产。", "历史")
	var tang_progress: int = _get_history_chain_progress("tang_museum")
	if tang_progress > 0 and tang_progress < 6:
		return _task_entry("唐长安文物展", _get_history_chain_hint("tang_museum"), "完成后解锁私人博物馆展陈资产。", "历史")
	if _get_city_reputation("shanghai") >= _get_history_unlock_reputation("shanghai") and republic_progress <= 0:
		return _task_entry("民国上海入口", "去上海地图的民国上海旧影入口，开启旧商会沙龙。", "开启后每个节点都有现金、声望和减压奖励。", "历史")
	if _get_city_reputation("xian") >= _get_history_unlock_reputation("xian") and tang_progress <= 0:
		return _task_entry("唐朝长安入口", "去西安地图的唐朝长安入口，开启文物展长线。", "开启后可采集文物线索并解锁博物馆收益。", "历史")
	return {}


func _get_history_task_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var republic_progress: int = _get_history_chain_progress("republic_salon")
	if republic_progress > 0:
		entries.append(_task_entry("旧商会沙龙 %d/6" % republic_progress, _get_history_chain_hint("republic_salon"), "终点：海上公馆人脉每日收益。", "上海"))
	elif _get_city_reputation("shanghai") >= _get_history_unlock_reputation("shanghai"):
		entries.append(_task_entry("民国上海可进入", "前往上海旧影入口，开启旧商会沙龙。", "节点奖励：现金、上海声望、压力降低。", "上海"))
	else:
		entries.append(_task_entry("民国上海未解锁", "上海声望达到30后开放。当前：%d。" % _get_city_reputation("shanghai"), "先做上海城市委托。", "上海"))
	var tang_progress: int = _get_history_chain_progress("tang_museum")
	if tang_progress > 0:
		entries.append(_task_entry("唐长安文物展 %d/6" % tang_progress, _get_history_chain_hint("tang_museum"), "终点：私人博物馆展陈每日收益。", "西安"))
	elif _get_city_reputation("xian") >= _get_history_unlock_reputation("xian"):
		entries.append(_task_entry("唐朝长安可进入", "前往西安唐长安入口，或先接考古委托。", "节点奖励：现金、西安声望、体力上限。", "西安"))
	else:
		entries.append(_task_entry("唐朝长安未解锁", "西安声望达到30后开放。当前：%d。" % _get_city_reputation("xian"), "先做西安城市委托。", "西安"))
	return entries


func _get_city_development_task_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var city_name: String = _get_city_name(current_city_id)
	var city_rep: int = _get_city_reputation(current_city_id)
	var next_threshold: int = 15
	if city_rep >= 60:
		entries.append(_task_entry("%s后期发展" % city_name, "继续做城市委托或经营资产，把本地声望推向城市名片。", "阶段资产已进入稳定收益期。", "城市"))
		return entries
	if city_rep >= 30:
		next_threshold = 60
	elif city_rep >= 15:
		next_threshold = 30
	entries.append(_task_entry("%s声望成长" % city_name, "当前 %d / 下一阶段 %d。做本地工作、城市委托和聊天都能推进。" % [city_rep, next_threshold], "下一阶段会解锁新的城市阶段资产。", "城市"))
	if completed_city_tasks_today.has("%s_%d" % [current_city_id, time_manager.day]):
		entries.append(_task_entry("今日城市委托", "今天的城市委托已完成，明天刷新。", "已获得今日委托奖励。", "完成"))
	else:
		entries.append(_task_entry("今日城市委托", "去当前城市的委托栏接一个轻任务。", "奖励会随城市声望提高。", "可做"))
	return entries


func _get_survival_task_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var rent_due_in: int = time_manager.get_rent_due_in_days()
	var rent_overdue_days: int = time_manager.get_rent_overdue_days()
	if rent_overdue_days > 0:
		entries.append(_task_entry("房租逾期", "已逾期 %d 天。回家处理房租。" % rent_overdue_days, "处理后压力会下降。", "紧急"))
	elif rent_due_in <= 2:
		entries.append(_task_entry("房租提醒", "距离下次房租还有 %d 天，注意留现金。" % rent_due_in, "提前准备能减少被动压力。", "生活"))
	if time_manager.energy < 45:
		entries.append(_task_entry("体力偏低", "吃饭、使用背包物品或睡觉恢复。", "体力太低会挡住工作和任务。", "生活"))
	if time_manager.stress >= 60:
		entries.append(_task_entry("压力偏高", "聊天、休息、诊所或睡觉都能缓解。", "压力越低，日常循环越顺。", "生活"))
	if entries.is_empty():
		entries.append(_task_entry("生活状态稳定", "今天可以优先赚钱、做委托或推进历史线。", "保持节奏，收益会持续变高。", "生活"))
	return entries


func _get_reputation_label() -> String:
	var total: int = _get_total_reputation()
	if total >= 180:
		return "跨城名片"
	if total >= 90:
		return "多城口碑"
	if total >= 30:
		return "被城市记住"
	return "无人认识"


func _get_work_reputation_gain(job_id: String, performance: String) -> int:
	var gain := 1
	if performance == "专注":
		gain = 3
	elif performance == "稳定":
		gain = 2
	if job_id == "job_sales":
		gain += 1
	if job_id == "job_streamer":
		gain += 1
	return gain


func _get_land_profile(land_id: String) -> Dictionary:
	match land_id:
		"night_market_booth":
			return {"name": "夜市摊位", "required_reputation": 10, "price": 1800}
		"community_shopfront":
			return {"name": "社区小门面", "required_reputation": 25, "price": 4200}
		_:
			return {"name": "共享办公工位", "required_reputation": 5, "price": 900}


func _get_company_profile(company_id: String) -> Dictionary:
	match company_id:
		"errand_studio":
			return {
				"name": "跑腿小队",
				"land_id": "night_market_booth",
				"required_reputation": 18,
				"price": 2600,
				"daily_income": 130,
				"stress_relief": 0,
			}
		"media_studio":
			return {
				"name": "内容工作室",
				"land_id": "community_shopfront",
				"required_reputation": 35,
				"price": 6200,
				"daily_income": 260,
				"stress_relief": -3,
			}
		_:
			return {
				"name": "代运营小公司",
				"land_id": "shared_office_desk",
				"required_reputation": 12,
				"price": 1600,
				"daily_income": 80,
				"stress_relief": 0,
			}


func _get_owned_land_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for land_id in owned_land:
		var profile: Dictionary = _get_land_profile(land_id)
		snapshot.append({"id": land_id, "name": str(profile.get("name", land_id))})
	return snapshot


func _get_owned_company_snapshot() -> Array[Dictionary]:
	var snapshot: Array[Dictionary] = []
	for company_id in owned_companies:
		var profile: Dictionary = _get_company_profile(company_id)
		snapshot.append({
			"id": company_id,
			"name": str(profile.get("name", company_id)),
			"daily_income": int(profile.get("daily_income", 0)),
		})
	return snapshot


func _collect_company_daily_income() -> int:
	var total: int = 0
	var stress_delta: int = 0
	for company_id in owned_companies:
		var profile: Dictionary = _get_company_profile(company_id)
		total += int(profile.get("daily_income", 0))
		stress_delta += int(profile.get("stress_relief", 0))
	if total <= 0:
		company_daily_income = 0
		return 0
	time_manager.add_money(total)
	if stress_delta > 0:
		time_manager.relieve_stress(stress_delta)
	elif stress_delta < 0:
		time_manager.add_stress(abs(stress_delta))
	company_daily_income = total
	return total


func _apply_land_purchase(item: Dictionary) -> void:
	var land_id: String = str(item.get("land_id", ""))
	var profile: Dictionary = _get_land_profile(land_id)
	var land_name: String = str(item.get("name", profile.get("name", "地皮")))
	if owned_land.has(land_id):
		hud.set_shop_message("已经买下：%s。" % land_name)
		return
	var required_reputation: int = int(item.get("required_reputation", profile.get("required_reputation", 0)))
	var city_reputation: int = _get_city_reputation(current_city_id)
	if city_reputation < required_reputation:
		hud.set_shop_message("%s声望不足。需要 %d，当前 %d。" % [_get_city_name(current_city_id), required_reputation, city_reputation])
		return
	var price: int = int(item.get("price", profile.get("price", 0)))
	if not time_manager.spend(price):
		hud.set_shop_message("现金不足。买下 %s 需要 %d 元。" % [land_name, price])
		return
	owned_land.append(land_id)
	_add_reputation(3)
	_on_status_changed(time_manager.get_status())
	hud.set_shop_message("已买下：%s。你可以用它开办公司。" % land_name)
	hud.set_function_bar_message("新增资产：%s。城市信息里可以查看地皮和公司。" % land_name)


func _apply_company_opening(item: Dictionary) -> void:
	var company_id: String = str(item.get("company_id", ""))
	var profile: Dictionary = _get_company_profile(company_id)
	var company_name: String = str(item.get("name", profile.get("name", "公司")))
	if owned_companies.has(company_id):
		hud.set_shop_message("已经开办：%s。" % company_name)
		return
	var required_reputation: int = int(item.get("required_reputation", profile.get("required_reputation", 0)))
	var city_reputation: int = _get_city_reputation(current_city_id)
	if city_reputation < required_reputation:
		hud.set_shop_message("%s声望不足。需要 %d，当前 %d。" % [_get_city_name(current_city_id), required_reputation, city_reputation])
		return
	var required_land: String = str(item.get("required_land", profile.get("land_id", "")))
	if not owned_land.has(required_land):
		var land_profile: Dictionary = _get_land_profile(required_land)
		hud.set_shop_message("还缺少地皮：%s。" % str(land_profile.get("name", "地皮")))
		return
	var price: int = int(item.get("price", profile.get("price", 0)))
	if not time_manager.spend(price):
		hud.set_shop_message("现金不足。开办 %s 需要 %d 元。" % [company_name, price])
		return
	owned_companies.append(company_id)
	_add_reputation(6)
	_on_status_changed(time_manager.get_status())
	hud.set_shop_message("已开办：%s。每日预计收入 +%d。" % [company_name, int(profile.get("daily_income", 0))])
	hud.set_function_bar_message("公司成立：%s。从明天开始会产生经营收入。" % company_name)


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
		var item_name: String = str(item.get("name", "食物"))
		var profile: Dictionary = npc_social_profiles.get(npc_id, {})
		var npc_name: String = str(profile.get("name", "对方"))
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
		var gift_line: String = "你把%s分给了%s。关系 +%d。%s。" % [item_name, npc_name, new_value - old_value, _get_relationship_summary_line(npc_id)]
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
		"internet_cafe":
			return internet_cafe.get_world_rect()
		"wet_market":
			return wet_market.get_world_rect()
		"clinic":
			return clinic.get_world_rect()
		"qikai_district":
			return qikai_district.get_world_rect()
		"faw_factory":
			return faw_factory.get_world_rect()
		"tang_changan":
			return tang_changan.get_world_rect()
		"republic_shanghai":
			return republic_shanghai.get_world_rect()
		"shanghai_mansion":
			return shanghai_mansion.get_world_rect()
		_:
			var active_map := _get_active_street_map()
			if active_map != null and active_map.has_method("get_world_rect"):
				var active_rect: Rect2 = active_map.call("get_world_rect")
				return active_rect
			return city_map.get_world_rect()


func _get_minimap_points() -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	if current_location == "street" and current_city_id != "shanghai":
		var active_map := _get_active_street_map()
		if active_map != null and active_map.has_method("get_station_position"):
			var station_position: Vector2 = active_map.call("get_station_position")
			points.append(_minimap_point(station_position, "metro", "高铁", Color("#a9d7ff"), 5.0))
		if active_map != null and active_map.has_method("get_landmark_minimap_points"):
			var landmark_points: Array = active_map.call("get_landmark_minimap_points")
			for landmark_index in range(landmark_points.size()):
				var landmark_point: Dictionary = landmark_points[landmark_index]
				points.append(landmark_point)
		return points
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
		"qikai_district":
			if qikai_district != null:
				var qikai_points: Array[Dictionary] = qikai_district.get_minimap_points()
				points.append_array(qikai_points)
		"faw_factory":
			if faw_factory != null:
				var factory_points: Array[Dictionary] = faw_factory.get_minimap_points()
				points.append_array(factory_points)
		"tang_changan":
			if tang_changan != null:
				var tang_points: Array[Dictionary] = tang_changan.get_minimap_points()
				points.append_array(tang_points)
		"republic_shanghai":
			if republic_shanghai != null:
				var republic_points: Array[Dictionary] = republic_shanghai.get_minimap_points()
				points.append_array(republic_points)
		"shanghai_mansion":
			points.append(_minimap_point(Vector2(480, 590), "exit", "出口", Color("#e8c879"), 4.0))
			points.append(_minimap_point(Vector2(480, 388), "npc", "来客", Color("#ffc4d6"), 4.0))
		_:
			points.append(_minimap_point(home_street_position, "home", "家", Color("#efc36f"), 4.0))
			points.append(_minimap_point(STREET_STORE, "food", "便利", Color("#f5d37b"), 4.0))
			points.append(_minimap_point(STREET_METRO, "metro", "地铁", Color("#a9d7ff"), 5.0))
			points.append(_minimap_point(STREET_OFFICE, "work", "公司", Color("#c7e7ff"), 5.0))
			points.append(_minimap_point(STREET_DELIVERY_STATION, "delivery", "配送", Color("#f3cf6b"), 4.0))
			points.append(_minimap_point(STREET_MEDIA, "media", "传媒", Color("#ffc4d6"), 4.0))
			points.append(_minimap_point(STREET_MARKET, "food", "菜场", Color("#d8c886"), 4.0))
			points.append(_minimap_point(STREET_CLINIC, "clinic", "诊所", Color("#d8fff0"), 4.0))
			points.append(_minimap_point(STREET_TALENT_APARTMENT, "home", "公寓", Color("#c7e7ff"), 4.0))
			points.append(_minimap_point(STREET_RENTAL_AGENCY, "rent", "中介", Color("#e8c879"), 4.0))
			points.append(_minimap_point(STREET_PEOPLE_SQUARE, "landmark", "人广", Color("#c4d8a8"), 3.6))
			points.append(_minimap_point(STREET_BUND, "landmark", "外滩", Color("#a9d7ff"), 3.6))
			points.append(_minimap_point(STREET_LUJIAZUI, "landmark", "陆家嘴", Color("#8fc4d4"), 3.8))
			points.append(_minimap_point(STREET_HIGH_SPEED_RAIL, "metro", "高铁", Color("#a9d7ff"), 4.2))
			points.append(_minimap_point(STREET_REPUBLIC_SHANGHAI, "history", "民国", Color("#a9d7ff"), 4.0))
			points.append(_minimap_point(shanghai_mansion_return_position, "home", "公馆", Color("#e8c879"), 4.0))
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
	if current_location == "street" and current_city_id != "shanghai":
		var active_map := _get_active_street_map()
		if active_map != null and active_map.has_method("get_station_position"):
			var station_position: Vector2 = active_map.call("get_station_position")
			return {"position": station_position}
		return {}
	if delivery_state == "accepted":
		return {"position": STREET_DELIVERY_PICKUP}
	if delivery_state == "picked":
		return {"position": STREET_DELIVERY_DROPOFF}
	var history_objective: Dictionary = _get_history_chain_objective()
	if not history_objective.is_empty():
		return history_objective
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
		"qikai_district":
			return {"position": qikai_district.get_factory_gate_position()}
		"faw_factory":
			return {"position": faw_factory.get_exit_spawn()}
		"tang_changan":
			return {"position": tang_changan.get_exit_spawn()}
		"republic_shanghai":
			return {"position": republic_shanghai.get_exit_spawn()}
		"shanghai_mansion":
			return {"position": shanghai_mansion.get_exit_spawn()}
		_:
			if time_manager.get_rent_due_in_days() <= 1:
				return {"position": home_street_position}
			if time_manager.energy < 45:
				return {"position": STREET_MARKET}
			if time_manager.stress >= 60:
				return {"position": STREET_CLINIC}
			if not time_manager.worked_this_day and time_manager.get_segment_key() in ["morning", "afternoon"]:
				return {"position": STREET_METRO}
			if not time_manager.worked_this_day and time_manager.get_segment_key() == "evening":
				return {"position": STREET_MEDIA}
	return {}

func _on_time_segment_changed(segment_key: String, _segment_label: String) -> void:
	if city_map != null:
		city_map.set_time_segment(segment_key)
	var regional_time_keys: Array = regional_city_maps.keys()
	for regional_time_index in range(regional_time_keys.size()):
		var regional_time_id := str(regional_time_keys[regional_time_index])
		var regional_map: Node = regional_city_maps[regional_time_id] as Node
		if regional_map != null and regional_map.has_method("set_time_segment"):
			regional_map.call("set_time_segment", segment_key)
	if apartment != null:
		apartment.set_time_segment(segment_key)
	if office != null:
		office.set_time_segment(segment_key)
	if media_company != null:
		media_company.set_time_segment(segment_key)
	if metro_station != null:
		metro_station.set_time_segment(segment_key)
	if internet_cafe != null:
		internet_cafe.set_time_segment(segment_key)
	if wet_market != null:
		wet_market.set_time_segment(segment_key)
	if clinic != null:
		clinic.set_time_segment(segment_key)
	if qikai_district != null:
		qikai_district.set_time_segment(segment_key)
	if faw_factory != null:
		faw_factory.set_time_segment(segment_key)
	if tang_changan != null:
		tang_changan.set_time_segment(segment_key)
	if republic_shanghai != null:
		republic_shanghai.set_time_segment(segment_key)
	for npc in npcs:
		npc.set_time_segment(segment_key)
	_apply_world_light(segment_key)


func _on_weather_changed(weather_key: String, _weather_label: String) -> void:
	if city_map != null:
		city_map.set_weather(weather_key)
	var regional_weather_keys: Array = regional_city_maps.keys()
	for regional_weather_index in range(regional_weather_keys.size()):
		var regional_weather_id := str(regional_weather_keys[regional_weather_index])
		var regional_map: Node = regional_city_maps[regional_weather_id] as Node
		if regional_map != null and regional_map.has_method("set_weather"):
			regional_map.call("set_weather", weather_key)
	if apartment != null:
		apartment.set_weather(weather_key)
	if office != null:
		office.set_weather(weather_key)
	if media_company != null:
		media_company.set_weather(weather_key)
	if metro_station != null:
		metro_station.set_weather(weather_key)
	if internet_cafe != null:
		internet_cafe.set_weather(weather_key)
	if wet_market != null:
		wet_market.set_weather(weather_key)
	if clinic != null:
		clinic.set_weather(weather_key)
	if qikai_district != null:
		qikai_district.set_weather(weather_key)
	if faw_factory != null:
		faw_factory.set_weather(weather_key)
	if tang_changan != null:
		tang_changan.set_weather(weather_key)
	if republic_shanghai != null:
		republic_shanghai.set_weather(weather_key)
	_apply_world_light(time_manager.get_segment_key())
	_on_status_changed(time_manager.get_status())


func _on_day_started(_day: int) -> void:
	talked_today.clear()
	completed_city_tasks_today.clear()
	delivery_state = "none"
	delivery_orders_completed_today = 0
	pending_morning_notice.clear()
	pending_morning_notice.append(housing_morning_line)
	var passive_income: int = _collect_company_daily_income()
	if passive_income > 0:
		pending_morning_notice.append("公司账户结算了一笔经营收入：+%d 元。城市声望越高，当地机会越多。" % passive_income)
	var city_growth_income: int = _collect_city_growth_asset_daily_income()
	if city_growth_income > 0:
		pending_morning_notice.append("城市阶段资产结算：+%d 元。本地小单、熟人网络和城市名片正在把前期努力变成稳定回报。" % city_growth_income)
	var historical_income: int = _collect_historical_asset_daily_income()
	if historical_income > 0:
		pending_morning_notice.append("历史资产结算：+%d 元。公馆、展陈和城市记忆正在反哺现实发展。" % historical_income)
	if time_manager.get_rent_overdue_days() > 0:
		pending_morning_notice.append_array([
			"房租已经逾期了，房东不会一直当没看见。",
			"逾期 %d 天。能交的时候，回家在房租单那里处理。" % time_manager.get_rent_overdue_days(),
		])

func _on_shop_item_selected(item: Dictionary) -> void:
	if item.has("start_city_id"):
		_choose_start_city(str(item.get("start_city_id", "shanghai")))
		return
	if item.has("travel_city_id"):
		_travel_to_city(str(item.get("travel_city_id", "shanghai")))
		return
	if item.has("land_id"):
		_apply_land_purchase(item)
		return
	if item.has("company_id"):
		_apply_company_opening(item)
		return
	if item.has("contract_id"):
		_apply_housing_choice(item)
		return
	var price: int = int(item.get("price", 0))
	if time_manager.spend(price):
		_store_inventory_item(item)
		hud.focus_inventory_tab()
		hud.set_function_bar_message("%s 已放进包里，需要时点底部“包”使用。" % item.get("name", "物品"))
		var buy_line: String = "已购买 %s。效果会在你使用时生效。" % str(item.get("name", "物品"))
		if int(item.get("relationship_discount", 0)) > 0:
			buy_line = "熟人价已生效。%s" % buy_line
		hud.set_shop_message(buy_line)
	else:
		hud.set_shop_message("钱不够。")


func _get_high_speed_rail_tickets() -> Array[Dictionary]:
	var tickets: Array[Dictionary] = []
	for city_id in _get_city_ids():
		if city_id == current_city_id:
			continue
		var option: Dictionary = _get_city_config(city_id)
		tickets.append({
			"id": "ticket_%s" % city_id,
			"name": "前往%s" % _get_city_name(city_id),
			"price": 0,
			"energy": 0,
			"travel_city_id": city_id,
			"station": option.get("station", ""),
		})
	return tickets


func _travel_to_city(city_id: String) -> void:
	if city_id != "shanghai" and not regional_city_maps.has(city_id):
		hud.set_shop_message("这条线路还没有开通。")
		return
	current_city_id = city_id
	current_location = "street"
	_set_street_map_active(city_id)
	var active_map := _get_active_street_map()
	var spawn_position := STREET_HIGH_SPEED_RAIL + Vector2(0, 54)
	if active_map != null and active_map.has_method("get_station_spawn"):
		var station_spawn: Vector2 = active_map.call("get_station_spawn")
		spawn_position = station_spawn
	elif city_id == "shanghai":
		spawn_position = STREET_HIGH_SPEED_RAIL + Vector2(0, 54)
	player.global_position = spawn_position
	if active_map != null and active_map.has_method("get_world_rect"):
		var active_rect: Rect2 = active_map.call("get_world_rect")
		player.set_camera_limits(active_rect)
	player.clear_interaction_focus()
	hud.hide_prompt()
	hud.set_shop_message("已抵达%s。关闭面板后可以继续移动。" % _get_city_name(city_id))
	hud.set_function_bar_message("高铁抵达%s，当前城市已切换。" % _get_city_name(city_id))
	_update_hud_navigation()


func _get_city_name(city_id: String) -> String:
	return str(_get_city_config(city_id).get("name", "未知城市"))

func _apply_housing_choice(item: Dictionary) -> void:
	var deposit: int = int(item.get("price", 0))
	if not time_manager.spend(deposit):
		hud.set_shop_message("押金和中介费不够。")
		return
	var contract_id: String = str(item.get("contract_id", "urban_village"))
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
			home_street_position = STREET_METRO
			housing_sleep_energy = 88
			housing_sleep_stress_relief = 20
			housing_fridge_energy = 6
			housing_fridge_stress_relief = 1
			housing_rent_stress_relief = 4
			housing_morning_line = "远郊房租低一点，但醒来时通勤已经在心里排队。"
		"talent_apartment":
			home_street_position = STREET_TALENT_APARTMENT
			housing_sleep_energy = 100
			housing_sleep_stress_relief = 36
			housing_fridge_energy = 14
			housing_fridge_stress_relief = 5
			housing_rent_stress_relief = 12
			housing_morning_line = "人才公寓的早晨更安静，但高房租会提醒你继续往前跑。"
		_:
			home_street_position = STREET_HOME
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
	var stress_text: String = "压力 -%d" % stress_relief
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
			{"id": "land_shared_office_desk", "land_id": "shared_office_desk", "name": "共享办公工位", "price": 900, "required_reputation": 5},
			{"id": "company_agency_studio", "company_id": "agency_studio", "name": "代运营小公司", "price": 1600, "required_reputation": 12, "required_land": "shared_office_desk"},
			{"id": "land_night_market_booth", "land_id": "night_market_booth", "name": "夜市摊位", "price": 1800, "required_reputation": 10},
			{"id": "company_errand_studio", "company_id": "errand_studio", "name": "跑腿小队", "price": 2600, "required_reputation": 18, "required_land": "night_market_booth"},
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
	var pressure: String = " 车费 %d，体力 -%d，压力 +%d。" % [time_manager.commute_fare, time_manager.commute_energy_cost, time_manager.commute_stress_gain]
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
		"stress_gain": max(2, stress_gain),
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
			"stress_gain": 9,
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
			"stress_gain": 11,
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
			"stress_gain": 13,
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
