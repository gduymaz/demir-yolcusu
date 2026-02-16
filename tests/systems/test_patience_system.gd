## PatienceSystem testleri.
## Sabır azalması, sabırsız yolcu kaybı, itibar etkisi.
extends GdUnitTestSuite


var _patience: PatienceSystem
var _reputation: ReputationSystem
var _event_bus: Node


func before_test() -> void:
	_event_bus = auto_free(load("res://src/events/event_bus.gd").new())
	_reputation = auto_free(ReputationSystem.new())
	_reputation.setup(_event_bus)
	_patience = auto_free(PatienceSystem.new())
	_patience.setup(_event_bus, _reputation)


# ==========================================================
# SABIR AZALMASI
# ==========================================================

func test_Update_ShouldDecreasePatience() -> void:
	var passengers: Array[Dictionary] = [
		PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	]
	_patience.update(passengers, 1.0)  # 1 saniye geçti
	assert_float(passengers[0]["patience"]).is_less(passengers[0]["patience_max"])


func test_Update_ShouldDecreaseByDelta() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	var passengers: Array[Dictionary] = [p]
	var initial: float = p["patience"]
	_patience.update(passengers, 2.0)  # 2 saniye geçti
	assert_float(p["patience"]).is_equal(initial - 2.0)


func test_Update_ShouldNotGoBelowZero() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	var passengers: Array[Dictionary] = [p]
	_patience.update(passengers, 9999.0)
	assert_float(p["patience"]).is_equal(0.0)


# ==========================================================
# YOLCU KAYBI
# ==========================================================

func test_Update_PatienceZero_ShouldReturnLostPassenger() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	p["patience"] = 0.5  # Çok düşük sabır
	var passengers: Array[Dictionary] = [p]
	var lost := _patience.update(passengers, 1.0)  # 1 sn geçti → sabır biter
	assert_int(lost.size()).is_equal(1)
	assert_str(lost[0]["id"]).is_equal(p["id"])


func test_Update_PatienceZero_ShouldRemoveFromList() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	p["patience"] = 0.1
	var passengers: Array[Dictionary] = [p]
	_patience.update(passengers, 1.0)
	assert_int(passengers.size()).is_equal(0)


func test_Update_PatienceZero_ShouldReduceReputation() -> void:
	var initial_rep := _reputation.get_reputation()
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	p["patience"] = 0.1
	var passengers: Array[Dictionary] = [p]
	_patience.update(passengers, 1.0)
	assert_float(_reputation.get_reputation()).is_less(initial_rep)


func test_Update_PatienceZero_ShouldEmitPassengerLostSignal() -> void:
	var result := {"lost": false}
	_event_bus.passenger_lost.connect(func(_p_data: Dictionary, _s_id: String) -> void:
		result["lost"] = true
	)
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	p["patience"] = 0.1
	var passengers: Array[Dictionary] = [p]
	_patience.update(passengers, 1.0)
	assert_bool(result["lost"]).is_true()


func test_Update_MultipleLost_ShouldReturnAll() -> void:
	var p1 := PassengerFactory.create(Constants.PassengerType.NORMAL, "a", 50)
	var p2 := PassengerFactory.create(Constants.PassengerType.NORMAL, "b", 50)
	p1["patience"] = 0.1
	p2["patience"] = 0.1
	var p3 := PassengerFactory.create(Constants.PassengerType.NORMAL, "c", 50)
	var passengers: Array[Dictionary] = [p1, p2, p3]
	var lost := _patience.update(passengers, 1.0)
	assert_int(lost.size()).is_equal(2)
	assert_int(passengers.size()).is_equal(1)


# ==========================================================
# SABIR YÜZDESI
# ==========================================================

func test_GetPatiencePercent_Full_ShouldBe100() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	assert_float(PatienceSystem.get_patience_percent(p)).is_equal(100.0)


func test_GetPatiencePercent_Half_ShouldBe50() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	p["patience"] = p["patience_max"] / 2.0
	assert_float(PatienceSystem.get_patience_percent(p)).is_equal(50.0)


func test_GetPatiencePercent_Zero_ShouldBeZero() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	p["patience"] = 0.0
	assert_float(PatienceSystem.get_patience_percent(p)).is_equal(0.0)
