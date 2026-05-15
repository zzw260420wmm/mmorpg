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


func open_shop(source: Node) -> void:
	player.set_controls_enabled(false)
	time_manager.set_time_paused(true)
	var shop_title := "Corner Shop"
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


func request_commute_work() -> void:
	player.set_controls_enabled(false)
	var fare := 6
	var commute_speaker := "Metro Gate" if current_location == "metro_station" else "Metro Entrance"
	if time_manager.get_segment_key() in ["evening", "late_night"]:
		hud.show_dialogue(commute_speaker, [
			"Going to the office this late would just turn into overtime.",
			"Leave it for tomorrow morning.",
		])
		return
	if not time_manager.spend(fare):
		hud.show_dialogue(commute_speaker, [
			"Your transit balance is too low.",
			"You need 6 more to get through the gate.",
		])
		return

	_apply_commute_time_jump()
	office_return_position = Vector2(1112, 338)
	enter_office(true)
	hud.show_dialogue("Commute", [
		_get_commute_line(),
		"You made it to the office. Pick the job you want at the workstation.",
	])



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
				"It is too late to start this shift now.",
				"Come back tomorrow morning or choose a night-friendly route.",
			])
			return
	if time_manager.energy < energy_cost:
		hud.show_dialogue(job_name, [
			"You sit down at the workstation and realize you cannot focus.",
			"Energy is too low. Eat something from the bag or rest first.",
		])
		return

	var return_segment: String = "late_night" if job_id == "job_streamer" and time_manager.get_segment_key() == "evening" else "evening"
	var worked: bool = time_manager.complete_work_shift(wage, energy_cost, return_segment, performance)
	if not worked:
		hud.show_dialogue(job_name, ["You are too tired to finish this work today."])
		return
	time_manager.add_stress(stress_gain)
	if current_location == "media_company":
		media_return_position = Vector2(898, 242)
		exit_media_company()
	else:
		office_return_position = Vector2(1112, 338)
		exit_office()
	hud.show_dialogue(job_name, [
		str(work_result["work_line"]),
		"Result %s. Pay +%d, energy -%d, stress +%d." % [performance, wage, energy_cost, stress_gain],
		_get_work_return_line(job_id),
	])

func request_fridge_food() -> void:
	player.set_controls_enabled(false)
	time_manager.recover_energy(8)
	time_manager.relieve_stress(2)
	hud.show_dialogue("Shared Fridge", [
		"You dig out a simple leftover snack from the fridge.",
		"It is not great, but it helps. Energy +8, stress -2.",
	])




func request_pay_rent() -> void:
	player.set_controls_enabled(false)
	if time_manager.pay_rent():
		var timing_line := "Transfer complete. Rent -%d." % time_manager.rent_amount
		if time_manager.get_rent_due_in_days() > time_manager.rent_cycle_days:
			timing_line = "You paid early. Rent -%d." % time_manager.rent_amount
		hud.show_dialogue("Rent Bill", [
			timing_line,
			"At least for the next few days, the landlord will stop knocking. Stress -8.",
		])
	else:
		hud.show_dialogue("Rent Bill", [
			"You do not have enough money for the rent. Need %d." % time_manager.rent_amount,
			"That means tomorrow probably needs to be a work day.",
		])



func request_clinic_visit() -> void:
	player.set_controls_enabled(false)
	var fee := 48
	if time_manager.energy >= 82 and time_manager.stress < 35:
		hud.show_dialogue("Clinic", [
			"You pause at the self-service kiosk and realize you can still push through today.",
			"Better save the clinic fee for when you really need it.",
		])
		return
	if not time_manager.spend(fee):
		hud.show_dialogue("Clinic", [
			"Registration costs %d." % fee,
			"You do not have enough cash, so all you can do is sit down and breathe for a while.",
		])
		return
	time_manager.recover_energy(16)
	time_manager.relieve_stress(22)
	hud.show_dialogue("Clinic", [
		"The doctor says you are mostly exhausted and out of rhythm.",
		"Fee %d. Energy +16, stress -22." % fee,
	])




func inspect_rental_agency(_source: Node) -> void:
	player.set_controls_enabled(false)
	var due_in := time_manager.get_rent_due_in_days()
	var lines := [
		"The rental board is full of tradeoffs: better commute, higher price; cheaper room, longer ride.",
	]
	if due_in < 0:
		lines.append("Your current rent is already overdue, so moving is not realistic right now.")
	elif due_in <= 2:
		lines.append("With rent due soon, every extra expense feels heavier.")
	else:
		lines.append("You have a little time before the next rent deadline closes in.")
	lines.append("It is useful as a reminder: housing pressure shapes every other choice.")
	hud.show_dialogue("Rental Agency", lines)




func inspect_talent_apartment(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"The talent apartment listings look better than your current place, but also much pricier.",
	]
	if time_manager.money >= time_manager.rent_amount:
		lines.append("If your savings keep growing, upgrading later could make sense.")
	else:
		lines.append("Right now the cheaper room and survivable rent matter more.")
	lines.append("For this demo, it mostly reminds you what better housing would cost.")
	hud.show_dialogue("Talent Apartment", lines)




func inspect_office(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"The office tower lobby is clean, cold, and quietly demanding.",
	]
	if time_manager.stress >= 70:
		lines.append("Just seeing the building makes your shoulders tighten.")
	elif time_manager.stress >= 40:
		lines.append("You can handle a shift, but it will still cost something.")
	else:
		lines.append("You still have room to get useful work done today.")
	lines.append("You head upstairs and can pick your work at the desk.")
	office_return_position = player.global_position + Vector2(0, 20)
	enter_office(false)
	show_dialogue("Office Entrance", lines)




func inspect_media_company(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"The media company floor is bright, polished, and a little exhausting.",
	]
	if time_manager.get_segment_key() == "morning":
		lines.append("The studio is waking up. This is a good time to prepare for creator work.")
	elif time_manager.get_segment_key() == "late_night":
		lines.append("At this hour the lights feel harsher than the pay is worth.")
	else:
		lines.append("Streams and creator work trade money for energy and pressure.")
	lines.append("You step inside and can choose whether to keep pushing tonight.")
	enter_media_company()
	show_dialogue("Media Company", lines)




func inspect_metro_station(_source: Node) -> void:
	player.set_controls_enabled(false)
	var lines := [
		"The station hums with turnstiles, footsteps, and train noise.",
	]
	if time_manager.get_segment_key() == "morning":
		lines.append("Morning commuters are already packed in. It is the fastest way to reach work.")
	elif time_manager.get_segment_key() == "evening":
		lines.append("The evening rush makes every platform feel tighter.")
	elif time_manager.get_segment_key() == "late_night":
		lines.append("Service is thinning out. If you do not need to travel, going home is smarter.")
	else:
		lines.append("It is a reliable shortcut when you want to trade money for time.")
	enter_metro_station()
	show_dialogue("Metro Station", lines)




func request_delivery_order() -> void:
	player.set_controls_enabled(false)
	if time_manager.get_segment_key() == "late_night":
		hud.show_dialogue("Delivery Station", [
			"No more orders are being assigned this late.",
			"Come back earlier in the day.",
		])
		return
	if delivery_state != "none":
		hud.show_dialogue("Delivery Station", [
			"You already have delivery work in progress.",
			_get_delivery_instruction(),
		])
		return
	if delivery_orders_completed_today >= 1:
		hud.show_dialogue("Delivery Station", [
			"The demo currently limits delivery to one completed order per day.",
			"Try a different job or rest and come back tomorrow.",
		])
		return
	if time_manager.energy < 32:
		hud.show_dialogue("Delivery Station", [
			"You are too tired to take a new route.",
			"Eat something or rest first.",
		])
		return

	delivery_state = "accepted"
	time_manager.consume_energy(6)
	time_manager.add_stress(3)
	hud.show_dialogue("Delivery Station", [
		"You accepted a fresh order from the station board.",
		"Energy -6, stress +3. Go pick up the food now.",
	])
	_on_status_changed(time_manager.get_status())




func request_delivery_pickup() -> void:
	player.set_controls_enabled(false)
	if delivery_state == "none":
		hud.show_dialogue("Delivery Pickup", [
			"You do not have an assigned order yet.",
			"Accept one at the station first.",
		])
		return
	if delivery_state == "picked":
		hud.show_dialogue("Delivery Pickup", [
			"You already picked the order up.",
			"Head to the customer and finish the route.",
		])
		return

	delivery_state = "picked"
	time_manager.consume_energy(8)
	hud.show_dialogue("Delivery Pickup", [
		"The food is packed and ready to go.",
		"Energy -8. Now head to the customer.",
	])
	_on_status_changed(time_manager.get_status())



func request_delivery_dropoff() -> void:
	player.set_controls_enabled(false)
	if delivery_state == "none":
		hud.show_dialogue("Delivery Dropoff", [
			"You do not have an active order right now.",
			"Go accept one first, then pick it up before trying to drop it off.",
		])
		return
	if delivery_state != "picked":
		hud.show_dialogue("Delivery Dropoff", [
			"The order is not ready to deliver yet.",
			"Pick up the food first, then head to the customer.",
		])
		return

	var reward := 58
	var energy_cost := 14
	var stress_gain := 8
	var performance := "Steady"
	var line := "You weave through the block and hand the order over before it goes cold."
	if time_manager.is_rainy():
		reward += 18
		stress_gain += 6
		line = "Rain slows everyone down, but the extra rush fee makes the route worth it."
	if time_manager.energy >= 70:
		reward += 12
		performance = "Focused"
	elif time_manager.energy < 38:
		reward -= 10
		stress_gain += 4
		performance = "Drained"

	if not time_manager.consume_energy(energy_cost):
		hud.show_dialogue("Delivery Dropoff", [
			"You are too tired to finish the route safely.",
			"Eat something or rest before taking the next order.",
		])
		return

	delivery_state = "none"
	delivery_orders_completed_today += 1
	time_manager.add_money(max(35, reward))
	time_manager.add_stress(stress_gain)
	time_manager.record_work_performance("Delivery %s" % performance)
	time_manager.set_segment("evening")
	hud.show_dialogue("Delivery Dropoff", [
		line,
		"Result %s. Pay +%d, energy -%d, stress +%d." % [performance, max(35, reward), energy_cost, stress_gain],
		"The shift is over. You can recover, buy supplies, or head home.",
	])



func request_sleep() -> void:
	player.set_controls_enabled(false)
	time_manager.sleep_to_next_day()
	if current_location == "street":
		enter_apartment()
	var lines := [
		"You finally get some sleep.",
		"A new day starts with a little more room to plan.",
	]
	lines.append_array(pending_morning_notice)
	pending_morning_notice.clear()
	hud.show_dialogue("Sleep", lines)




func _spawn_npcs() -> void:
	var npc_data: Array[Dictionary] = [
		{
			"id": "landlord",
			"name": "Landlord Chen",
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
				"default": ["Rent is not just a number. It decides how much room you have to breathe."],
				"morning": ["Morning. Check your wallet before the week runs away from you."],
				"afternoon": ["The lane is loud today. Loud streets usually mean late rent."],
				"evening": ["Back late again? Shanghai does not slow down for tired people."],
				"late_night": ["Keep it quiet. The whole building is trying to sleep."],
			},
		},
		{
			"id": "shopkeeper",
			"name": "Auntie Lin",
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
				"default": ["Snacks go into your bag now. Use them when the day starts biting."],
				"morning": ["Soy milk is warm. Eggs are fresh. Your boss will not be either."],
				"afternoon": ["The lunch rush is gone. Best time to buy without being squeezed."],
				"evening": ["Convenience food is not romance, but it can save a night."],
				"late_night": ["Only quick items left. Even the shelves look tired."],
			},
		},
		{
			"id": "girl",
			"name": "Mia",
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
				"default": ["People here keep moving. If you stop too long, the city starts asking questions."],
				"morning": ["I like the first train noise. It makes everyone pretend today has a plan."],
				"afternoon": ["If your stress is high, walk a loop before buying more coffee."],
				"evening": ["Neon makes the street look richer than any of us."],
				"late_night": ["Late air is honest. It tells you exactly how tired you are."],
			},
		},
		{
			"id": "delivery_captain",
			"name": "Captain Zhao",
			"role": "delivery_rider",
			"position": Vector2(1044, 520),
			"palette": {"hair": Color("#1f2428"), "skin": Color("#c49167"), "shirt": Color("#d29b2e")},
			"routes": {
				"morning": [Vector2(1044, 520), Vector2(1118, 496), Vector2(1188, 516)],
				"afternoon": [Vector2(1038, 520), Vector2(1120, 548), Vector2(1210, 532)],
				"evening": [Vector2(1084, 518), Vector2(1188, 516), Vector2(1078, 552)],
				"late_night": [Vector2(1052, 520), Vector2(1070, 520)],
			},
			"dialogue": {
				"default": ["Orders pay fast, but the city charges energy first."],
				"morning": ["Breakfast orders are short. Good warm-up if you can move."],
				"afternoon": ["Rain turns every delivery into a negotiation with the road."],
				"evening": ["Dinner peak is money, stress, and traffic all at once."],
				"late_night": ["No heroic routes now. Take only what you can finish."],
			},
		},
		{
			"id": "streamer_npc",
			"name": "Luna",
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
				"default": ["The camera likes confidence. The algorithm likes exhaustion."],
				"morning": ["Morning streams are quiet, but quiet can be useful."],
				"afternoon": ["Afternoon viewers tip better when the weather is bad."],
				"evening": ["Prime time pays, then collects interest from your nerves."],
				"late_night": ["End the stream before the stream ends you."],
			},
		},
		{
			"id": "office_worker_npc",
			"name": "Colleague Xu",
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
				"default": ["Office work is mostly choosing which pressure becomes visible."],
				"morning": ["Arrive before the meeting and you look prepared. Arrive after and you become the agenda."],
				"afternoon": ["After lunch, every spreadsheet starts looking like a weather report."],
				"evening": ["Leaving on time is a skill. Not everyone survives learning it."],
				"late_night": ["If you are still here, at least pretend the lights are stars."],
			},
		},
		{
			"id": "metro_commuter_npc",
			"name": "Commuter Sun",
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
				"default": ["The metro does not care about your plan. It only cares whether you made it to the gate."],
				"morning": ["The first crowd is the most honest one. Everyone is half awake."],
				"afternoon": ["Off-peak rides feel like borrowing time from the city."],
				"evening": ["Evening trains carry every unfinished sentence home."],
				"late_night": ["Last trains make people calculate their lives very quickly."],
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
	var current_value: int = int(npc_relationships.get(npc_id, 0))
	if talked_today.has(npc_id):
		if npc_id == "landlord":
			return "We already talked today. Affinity %d. %s" % [current_value, _get_landlord_rent_line()]
		return "We already talked today. Affinity %d." % current_value

	current_value += 1
	npc_relationships[npc_id] = current_value
	talked_today[npc_id] = true
	time_manager.relieve_stress(3)
	_update_npc_relationship_visual(npc_id)
	if npc_id == "landlord":
		return "Talked with the landlord. Affinity +1, stress -3. Affinity %d. %s" % [current_value, _get_landlord_rent_line()]
	return "You shared a short street-side chat. Affinity +1, stress -3. Affinity %d." % current_value

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
		"name": str(item.get("name", "Item")),
		"price": int(item.get("price", 0)),
		"energy": int(item.get("energy", 0)),
		"stress_relief": int(item.get("stress_relief", 0)),
		"quantity": 1,
	}
	inventory_items.append(new_item)
	_on_status_changed(time_manager.get_status())


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
		_:
			return city_map.get_world_rect()


func _get_minimap_points() -> Array[Dictionary]:
	var points: Array[Dictionary] = []
	match current_location:
		"apartment":
			points.append({"position": Vector2(246, 240), "color": Color("#d98a8a"), "radius": 4.0})
			points.append({"position": Vector2(412, 300), "color": Color("#b8d8c4"), "radius": 3.0})
			points.append({"position": Vector2(322, 208), "color": Color("#efc36f"), "radius": 3.0})
			points.append({"position": Vector2(322, 304), "color": Color("#f0c77b"), "radius": 4.0})
		"office":
			points.append({"position": Vector2(590, 340), "color": Color("#b8d9e8"), "radius": 4.0})
			points.append({"position": Vector2(704, 340), "color": Color("#c4d8a8"), "radius": 4.0})
			points.append({"position": Vector2(818, 340), "color": Color("#e9b293"), "radius": 4.0})
			points.append({"position": Vector2(710, 444), "color": Color("#c7e7ff"), "radius": 4.0})
		"media_company":
			points.append({"position": Vector2(606, 316), "color": Color("#ffd0d5"), "radius": 5.0})
			points.append({"position": Vector2(710, 412), "color": Color("#e3c7f0"), "radius": 4.0})
		"metro_station":
			points.append({"position": Vector2(640, 344), "color": Color("#a9d7ff"), "radius": 5.0})
			points.append({"position": Vector2(454, 346), "color": Color("#b8d8c4"), "radius": 3.0})
			points.append({"position": Vector2(640, 426), "color": Color("#e8c879"), "radius": 4.0})
		_:
			points.append({"position": Vector2(152, 190), "color": Color("#efc36f"), "radius": 4.0})
			points.append({"position": Vector2(656, 202), "color": Color("#f5d37b"), "radius": 4.0})
			points.append({"position": Vector2(720, 390), "color": Color("#a9d7ff"), "radius": 5.0})
			points.append({"position": Vector2(1112, 318), "color": Color("#c7e7ff"), "radius": 5.0})
			points.append({"position": Vector2(878, 508), "color": Color("#f3cf6b"), "radius": 4.0})
			points.append({"position": Vector2(898, 222), "color": Color("#ffc4d6"), "radius": 4.0})
			points.append({"position": Vector2(278, 790), "color": Color("#d8c886"), "radius": 4.0})
			points.append({"position": Vector2(538, 750), "color": Color("#d8fff0"), "radius": 4.0})
			for npc in npcs:
				if npc.visible:
					points.append({"position": npc.global_position, "color": Color("#f4dcb1"), "radius": 2.6})
	return points


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
		_:
			if time_manager.get_rent_due_in_days() <= 1:
				return {"position": Vector2(152, 190)}
			if time_manager.energy < 45:
				return {"position": Vector2(656, 202)}
			if not time_manager.worked_this_day and time_manager.get_segment_key() in ["morning", "afternoon"]:
				return {"position": Vector2(720, 390)}
			if not time_manager.worked_this_day and time_manager.get_segment_key() == "evening":
				return {"position": Vector2(898, 222)}
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
			"Rent is overdue. The landlord will not ignore it forever.",
			"Overdue rent: %d day(s). Pay at the apartment door when you can." % time_manager.get_rent_overdue_days(),
		]

func _on_shop_item_selected(item: Dictionary) -> void:
	var price: int = int(item.get("price", 0))
	if time_manager.spend(price):
		_store_inventory_item(item)
		hud.focus_inventory_tab()
		hud.set_function_bar_message("%s added to bag. Use it from the bottom inventory bar when you need it." % item.get("name", "Item"))
		hud.set_shop_message("%s bought. It now sits in your bag until you choose to use it." % item.get("name", "Item"))
	else:
		hud.set_shop_message("Not enough money.")





func _on_inventory_item_used(index: int) -> void:
	if index < 0 or index >= inventory_items.size():
		return
	var item: Dictionary = inventory_items[index]
	var item_name: String = str(item.get("name", "Item"))
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
	var stress_text := "Stress -%d" % stress_relief
	if stress_relief < 0:
		stress_text = "Stress +%d" % abs(stress_relief)
	hud.set_function_bar_message("Used %s. Energy +%d, %s." % [item_name, energy, stress_text])


func _resume_player_after_ui() -> void:
	time_manager.set_time_paused(false)
	player.set_controls_enabled(true)
	var focus = player.focused_interactable
	if focus != null and focus.has_method("get_prompt"):
		hud.show_prompt(str(focus.call("get_prompt")))


func _update_time_flow() -> void:
	if time_manager == null:
		return
	match current_location:
		"apartment":
			time_manager.set_flow_multiplier(1.65)
		"office", "media_company":
			time_manager.set_flow_multiplier(1.35)
		"metro_station":
			time_manager.set_flow_multiplier(1.20)
		_:
			time_manager.set_flow_multiplier(1.0)


func _apply_commute_time_jump() -> void:
	if time_manager.get_segment_key() == "morning":
		time_manager.set_segment("afternoon")
	elif time_manager.get_segment_key() == "afternoon":
		time_manager.consume_energy(4)
		time_manager.add_stress(2)


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
			{"id": "wet_market_veg_egg", "name": "Vegetable Egg Pack", "price": 14, "energy": 16, "stress_relief": 2},
			{"id": "wet_market_noodle_bowl", "name": "Noodle Bowl", "price": 18, "energy": 24, "stress_relief": 3},
			{"id": "wet_market_fruit_bag", "name": "Fruit Bag", "price": 16, "energy": 12, "stress_relief": 6},
		]
	if source_id == "convenience_store":
		return [
			{"id": "store_rice_ball", "name": "Rice Ball", "price": 10, "energy": 12, "stress_relief": 1},
			{"id": "store_coffee", "name": "Iced Coffee", "price": 12, "energy": 18, "stress_relief": -3},
			{"id": "store_late_snack", "name": "Late Snack", "price": 22, "energy": 28, "stress_relief": 4},
		]
	return [
		{"id": "canteen_set", "name": "Canteen Set", "price": 26, "energy": 34, "stress_relief": 4},
		{"id": "comfort_soup", "name": "Comfort Soup", "price": 32, "energy": 22, "stress_relief": 10},
		{"id": "quick_lunch", "name": "Quick Lunch", "price": 20, "energy": 26, "stress_relief": 2},
	]

func _get_commute_line() -> String:
	if time_manager.is_rainy():
		return "You squeeze into the metro with damp sleeves and arrive near the office forty minutes later."
	return "You tap through the gate and ride the metro to the office district."

func _get_work_return_line(job_id: String) -> String:
	if job_id == "job_streamer":
		return "You step out of the studio with the ring lights still floating in your eyes."
	return "You walk back out of the office tower with the city lights already turning on."

func _calculate_work_result(job_id: String = "job_operations") -> Dictionary:
	var job: Dictionary = _get_job_profile(job_id)
	var start_energy: int = time_manager.energy
	var energy_cost: int = int(job["energy_cost"])
	var wage: int = int(job["base_wage"])
	var stress_gain: int = int(job["stress_gain"])
	var performance: String = "Steady"
	var work_line: String = str(job["work_line"])

	if start_energy >= 86:
		performance = "Focused"
		wage += int(job["high_energy_bonus"])
		energy_cost += 6
		stress_gain += 3
	elif start_energy >= 58:
		performance = "Steady"
		wage += int(job["stable_bonus"])
	elif start_energy < 42:
		performance = "Drained"
		wage -= int(job["low_energy_penalty"])
		energy_cost -= 4
		stress_gain += 6

	if time_manager.is_rainy():
		work_line = str(job["rain_line"])
		wage -= 10
		stress_gain += 5
		if performance == "Focused":
			performance = "Steady"
		elif performance == "Steady":
			performance = "Drained"

	if job_id == "job_streamer" and time_manager.get_segment_key() == "afternoon":
		wage += 30
		stress_gain += 4
		work_line = "%s The afternoon stream pulled in extra attention." % work_line

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
				"name": "Software Developer",
				"base_wage": 240,
				"energy_cost": 38,
				"stress_gain": 16,
				"high_energy_bonus": 80,
				"stable_bonus": 30,
				"low_energy_penalty": 50,
				"work_line": "You spend the shift fixing a stubborn production bug and reviewing merge requests.",
				"rain_line": "Rain drums against the office windows while you chase a production bug through old logs.",
			}
		"job_sales":
			return {
				"name": "Sales Specialist",
				"base_wage": 210,
				"energy_cost": 36,
				"stress_gain": 22,
				"high_energy_bonus": 95,
				"stable_bonus": 35,
				"low_energy_penalty": 55,
				"work_line": "You juggle client calls, demo notes, and a manager who keeps asking for one more follow-up.",
				"rain_line": "The rain slows every client visit, and each late reply makes the sales board feel heavier.",
			}
		"job_streamer":
			return {
				"name": "Livestream Shift",
				"base_wage": 190,
				"energy_cost": 32,
				"stress_gain": 24,
				"high_energy_bonus": 110,
				"stable_bonus": 35,
				"low_energy_penalty": 65,
				"work_line": "You keep smiling under hot lights while chat demands energy you do not really have.",
				"rain_line": "Rain traps more viewers indoors, but keeping them engaged takes everything you have left.",
			}
		_:
			return {
				"name": "Operations Assistant",
				"base_wage": 220,
				"energy_cost": 34,
				"stress_gain": 14,
				"high_energy_bonus": 45,
				"stable_bonus": 15,
				"low_energy_penalty": 35,
				"work_line": "You process vendor messages, reconcile forms, and keep the office machine from rattling apart.",
				"rain_line": "Rain delays deliveries, so the operations inbox becomes a little weather system of its own.",
			}

func _update_npc_relationship_visual(npc_id: String) -> void:
	for npc in npcs:
		if npc.npc_id == npc_id:
			npc.set_relationship(int(npc_relationships.get(npc_id, 0)))
			return


func _get_landlord_rent_line() -> String:
	var due_in: int = time_manager.get_rent_due_in_days()
	if due_in > 0:
		return "Rent is due in %d day(s). Keep enough cash ready." % due_in
	if due_in == 0:
		return "Rent is due today. Pay before sleep if you can."
	return "Rent is overdue by %d day(s). The pressure will keep growing." % abs(due_in)

func _get_delivery_instruction() -> String:
	if delivery_state == "accepted":
		return "Order accepted. Go to the pickup counter at the delivery station."
	if delivery_state == "picked":
		return "Food picked up. Ride to the drop-off marker before the city eats your bonus."
	return "Talk to Captain Zhao at the delivery station to accept a route."
