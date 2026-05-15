extends Node
class_name TimeManager

signal status_changed(status: Dictionary)
signal time_segment_changed(segment_key: String, segment_label: String)
signal day_started(day: int)
signal weather_changed(weather_key: String, weather_label: String)

const SEGMENT_KEYS := ["morning", "afternoon", "evening", "late_night"]
const SEGMENT_LABELS := ["上午", "下午", "晚上", "深夜"]
const SEGMENT_START_MINUTES := [360, 720, 1080, 0]
const MINUTES_PER_SEGMENT := 360
const REAL_TIME_SPEED := 96.0
const WEATHER_SEQUENCE := ["overcast", "rain", "clear", "rain", "overcast"]
const WEATHER_LABELS := {
	"clear": "晴天",
	"overcast": "阴天",
	"rain": "下雨",
}

@export var seconds_per_segment := float(MINUTES_PER_SEGMENT * 60) / REAL_TIME_SPEED

var month := 6
var day := 1
var money := 2600
var max_energy := 100
var energy := 78
var max_stress := 100
var stress := 22
var rent_amount := 1200
var rent_cycle_days := 7
var next_rent_day := 7
var housing_id := "urban_village"
var housing_label := "城中村合租"
var commute_fare := 6
var commute_energy_cost := 4
var commute_stress_gain := 2
var segment_index := 0
var elapsed_in_segment := 0.0
var weather_index := 0
var weather_key: String = WEATHER_SEQUENCE[0]
var last_work_performance := "未工作"
var worked_this_day := false
var time_paused := false
var flow_multiplier := 1.0
var last_emitted_clock_minute := -1


func _ready() -> void:
	_emit_status()
	time_segment_changed.emit(get_segment_key(), get_segment_label())
	weather_changed.emit(weather_key, get_weather_label())


func _process(delta: float) -> void:
	if time_paused:
		return
	elapsed_in_segment += delta
	var clock_minute := get_clock_total_minutes()
	if clock_minute != last_emitted_clock_minute:
		last_emitted_clock_minute = clock_minute
		_emit_status()
	if elapsed_in_segment >= _get_segment_duration():
		elapsed_in_segment = 0.0
		_advance_segment()


func get_segment_key() -> String:
	return SEGMENT_KEYS[segment_index]


func get_segment_label() -> String:
	return SEGMENT_LABELS[segment_index]


func get_date_label() -> String:
	return "%02d/%02d" % [month, day]


func get_clock_total_minutes() -> int:
	var segment_duration := maxf(0.001, _get_segment_duration())
	var segment_progress := clampf(elapsed_in_segment / segment_duration, 0.0, 0.999)
	var minutes_into_segment := int(floor(segment_progress * float(MINUTES_PER_SEGMENT)))
	return (SEGMENT_START_MINUTES[segment_index] + minutes_into_segment) % 1440


func get_clock_label() -> String:
	var total_minutes := get_clock_total_minutes()
	return "%02d:%02d" % [total_minutes / 60, total_minutes % 60]


func get_weather_label() -> String:
	return WEATHER_LABELS.get(weather_key, "阴天")


func is_rainy() -> bool:
	return weather_key == "rain"


func get_status() -> Dictionary:
	return {
		"date": get_date_label(),
		"clock": get_clock_label(),
		"time_speed": int(REAL_TIME_SPEED),
		"segment": get_segment_label(),
		"segment_key": get_segment_key(),
		"weather": get_weather_label(),
		"weather_key": weather_key,
		"money": money,
		"energy": energy,
		"max_energy": max_energy,
		"stress": stress,
		"max_stress": max_stress,
		"rent_amount": rent_amount,
		"housing_id": housing_id,
		"housing_label": housing_label,
		"commute_fare": commute_fare,
		"commute_energy_cost": commute_energy_cost,
		"commute_stress_gain": commute_stress_gain,
		"rent_due_in": get_rent_due_in_days(),
		"rent_overdue_days": get_rent_overdue_days(),
		"rent_label": get_rent_label(),
		"work_performance": last_work_performance,
		"worked_this_day": worked_this_day,
	}


func spend(amount: int) -> bool:
	if amount <= 0:
		return true
	if money < amount:
		return false
	money -= amount
	_emit_status()
	return true


func add_money(amount: int) -> void:
	money += amount
	_emit_status()


func get_rent_due_in_days() -> int:
	return next_rent_day - day


func get_rent_overdue_days() -> int:
	return max(0, day - next_rent_day)


func get_rent_label() -> String:
	var due_in: int = get_rent_due_in_days()
	if due_in > 0:
		return "%d天后到期" % due_in
	if due_in == 0:
		return "今天到期"
	return "已逾期%d天" % abs(due_in)


func pay_rent() -> bool:
	if money < rent_amount:
		return false
	money -= rent_amount
	next_rent_day = max(next_rent_day + rent_cycle_days, day + rent_cycle_days)
	relieve_stress(8)
	_emit_status()
	return true


func apply_housing_contract(new_housing_id: String, label: String, new_rent_amount: int, new_commute_fare: int, new_commute_energy_cost: int, new_commute_stress_gain: int) -> void:
	housing_id = new_housing_id
	housing_label = label
	rent_amount = max(1, new_rent_amount)
	commute_fare = max(0, new_commute_fare)
	commute_energy_cost = max(0, new_commute_energy_cost)
	commute_stress_gain = max(0, new_commute_stress_gain)
	next_rent_day = max(next_rent_day, day + 1)
	_emit_status()


func add_stress(amount: int) -> void:
	stress = clampi(stress + amount, 0, max_stress)
	_emit_status()


func relieve_stress(amount: int) -> void:
	add_stress(-amount)


func consume_energy(amount: int) -> bool:
	if amount <= 0:
		return true
	if energy < amount:
		return false
	energy -= amount
	_emit_status()
	return true


func recover_energy(amount: int) -> void:
	energy = min(max_energy, energy + amount)
	_emit_status()


func set_time_paused(paused: bool) -> void:
	time_paused = paused


func set_flow_multiplier(multiplier: float) -> void:
	flow_multiplier = maxf(0.25, multiplier)


func advance_segments(count: int) -> void:
	for _i in range(max(count, 0)):
		_advance_segment()


func set_segment(segment_key: String) -> void:
	var next_index: int = SEGMENT_KEYS.find(segment_key)
	if next_index < 0:
		return
	segment_index = next_index
	elapsed_in_segment = 0.0
	_emit_status()
	time_segment_changed.emit(get_segment_key(), get_segment_label())


func complete_work_shift(wage: int, energy_cost: int, arrive_segment: String, performance_label: String = "稳定") -> bool:
	if not consume_energy(energy_cost):
		return false
	last_work_performance = performance_label
	worked_this_day = true
	add_money(wage)
	set_segment(arrive_segment)
	return true


func record_work_performance(performance_label: String) -> void:
	last_work_performance = performance_label
	worked_this_day = true
	_emit_status()


func sleep_to_next_day(target_energy: int = -1, stress_relief: int = 28) -> void:
	day += 1
	segment_index = 0
	elapsed_in_segment = 0.0
	last_emitted_clock_minute = -1
	if target_energy < 0:
		energy = max_energy
	else:
		energy = clampi(max(energy, target_energy), 0, max_energy)
	stress = max(0, stress - stress_relief)
	last_work_performance = "未工作"
	worked_this_day = false
	_advance_weather()
	_apply_daily_rent_pressure()
	day_started.emit(day)
	_emit_status()
	time_segment_changed.emit(get_segment_key(), get_segment_label())
	weather_changed.emit(weather_key, get_weather_label())


func _advance_segment() -> void:
	segment_index += 1
	if segment_index >= SEGMENT_KEYS.size():
		sleep_to_next_day()
		return

	energy = max(0, energy - 8)
	if get_segment_key() == "late_night":
		add_stress(4)
	_emit_status()
	time_segment_changed.emit(get_segment_key(), get_segment_label())


func _emit_status() -> void:
	status_changed.emit(get_status())


func _get_segment_duration() -> float:
	return seconds_per_segment * flow_multiplier


func _advance_weather() -> void:
	weather_index = (weather_index + 1) % WEATHER_SEQUENCE.size()
	weather_key = WEATHER_SEQUENCE[weather_index]


func _apply_daily_rent_pressure() -> void:
	var overdue_days: int = get_rent_overdue_days()
	if overdue_days > 0:
		stress = clampi(stress + min(16, 5 + overdue_days * 3), 0, max_stress)
	elif get_rent_due_in_days() == 0:
		stress = clampi(stress + 6, 0, max_stress)
