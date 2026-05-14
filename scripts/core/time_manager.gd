extends Node
class_name TimeManager

signal status_changed(status: Dictionary)
signal time_segment_changed(segment_key: String, segment_label: String)
signal day_started(day: int)
signal weather_changed(weather_key: String, weather_label: String)

const SEGMENT_KEYS := ["morning", "afternoon", "evening", "late_night"]
const SEGMENT_LABELS := ["上午", "下午", "晚上", "深夜"]
const WEATHER_SEQUENCE := ["overcast", "rain", "clear", "rain", "overcast"]
const WEATHER_LABELS := {
	"clear": "晴",
	"overcast": "阴",
	"rain": "雨",
}

@export var seconds_per_segment := 32.0

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
var segment_index := 0
var elapsed_in_segment := 0.0
var weather_index := 0
var weather_key := WEATHER_SEQUENCE[0]
var last_work_performance := "未上班"


func _ready() -> void:
	_emit_status()
	time_segment_changed.emit(get_segment_key(), get_segment_label())
	weather_changed.emit(weather_key, get_weather_label())


func _process(delta: float) -> void:
	elapsed_in_segment += delta
	if elapsed_in_segment >= seconds_per_segment:
		elapsed_in_segment = 0.0
		_advance_segment()


func get_segment_key() -> String:
	return SEGMENT_KEYS[segment_index]


func get_segment_label() -> String:
	return SEGMENT_LABELS[segment_index]


func get_date_label() -> String:
	return "%d月%d日" % [month, day]


func get_weather_label() -> String:
	return WEATHER_LABELS.get(weather_key, "阴")


func is_rainy() -> bool:
	return weather_key == "rain"


func get_status() -> Dictionary:
	return {
		"date": get_date_label(),
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
		"rent_due_in": get_rent_due_in_days(),
		"rent_overdue_days": get_rent_overdue_days(),
		"rent_label": get_rent_label(),
		"work_performance": last_work_performance,
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
	var due_in := get_rent_due_in_days()
	if due_in > 0:
		return "%d天后交租" % due_in
	if due_in == 0:
		return "今天交租"
	return "逾期%d天" % abs(due_in)


func pay_rent() -> bool:
	if money < rent_amount:
		return false
	money -= rent_amount
	next_rent_day = max(next_rent_day + rent_cycle_days, day + rent_cycle_days)
	relieve_stress(8)
	_emit_status()
	return true


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


func set_segment(segment_key: String) -> void:
	var next_index := SEGMENT_KEYS.find(segment_key)
	if next_index < 0:
		return
	segment_index = next_index
	elapsed_in_segment = 0.0
	_emit_status()
	time_segment_changed.emit(get_segment_key(), get_segment_label())


func complete_work_shift(wage: int, energy_cost: int, arrive_segment: String, performance_label: String = "普通") -> bool:
	if not consume_energy(energy_cost):
		return false
	last_work_performance = performance_label
	add_money(wage)
	set_segment(arrive_segment)
	return true


func record_work_performance(performance_label: String) -> void:
	last_work_performance = performance_label
	_emit_status()


func sleep_to_next_day() -> void:
	day += 1
	segment_index = 0
	elapsed_in_segment = 0.0
	energy = max_energy
	stress = max(0, stress - 28)
	last_work_performance = "未上班"
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


func _advance_weather() -> void:
	weather_index = (weather_index + 1) % WEATHER_SEQUENCE.size()
	weather_key = WEATHER_SEQUENCE[weather_index]


func _apply_daily_rent_pressure() -> void:
	var overdue_days := get_rent_overdue_days()
	if overdue_days > 0:
		stress = clampi(stress + min(16, 5 + overdue_days * 3), 0, max_stress)
	elif get_rent_due_in_days() == 0:
		stress = clampi(stress + 6, 0, max_stress)
