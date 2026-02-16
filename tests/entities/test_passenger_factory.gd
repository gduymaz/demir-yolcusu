## PassengerFactory testleri.
## Yolcu üretimi, ücret hesaplama, sabır hesaplama.
extends GdUnitTestSuite


# ==========================================================
# YOLCU ÜRETİMİ
# ==========================================================

func test_Create_Normal_ShouldReturnValidPassenger() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "denizli", 100)
	assert_str(p["destination"]).is_equal("denizli")
	assert_int(p["type"]).is_equal(Constants.PassengerType.NORMAL)
	assert_int(p["state"]).is_equal(Constants.PassengerState.WAITING)
	assert_str(p["id"]).is_not_empty()


func test_Create_VIP_ShouldSetVIPType() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.VIP, "izmir", 50)
	assert_int(p["type"]).is_equal(Constants.PassengerType.VIP)


func test_Create_Student_ShouldSetStudentType() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.STUDENT, "afyon", 200)
	assert_int(p["type"]).is_equal(Constants.PassengerType.STUDENT)


func test_Create_Elderly_ShouldSetElderlyType() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.ELDERLY, "selcuk", 80)
	assert_int(p["type"]).is_equal(Constants.PassengerType.ELDERLY)


func test_Create_ShouldGenerateUniqueIds() -> void:
	var p1 := PassengerFactory.create(Constants.PassengerType.NORMAL, "a", 50)
	var p2 := PassengerFactory.create(Constants.PassengerType.NORMAL, "b", 50)
	assert_str(p1["id"]).is_not_equal(p2["id"])


# ==========================================================
# ÜCRET HESAPLAMA
# ==========================================================

func test_Create_Normal_FareShouldMatchDistance() -> void:
	# 100 km, Normal → 100 × 2 × 1.0 × 1.0 = 200
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 100)
	assert_int(p["fare"]).is_equal(200)


func test_Create_VIP_FareShouldBeTriple() -> void:
	# 100 km, VIP → 100 × 2 × 1.0 × 3.0 = 600
	var p := PassengerFactory.create(Constants.PassengerType.VIP, "test", 100)
	assert_int(p["fare"]).is_equal(600)


func test_Create_Student_FareShouldBeHalf() -> void:
	# 100 km, Student → 100 × 2 × 1.0 × 0.5 = 100
	var p := PassengerFactory.create(Constants.PassengerType.STUDENT, "test", 100)
	assert_int(p["fare"]).is_equal(100)


func test_Create_Elderly_FareShouldBe70Percent() -> void:
	# 100 km, Elderly → 100 × 2 × 1.0 × 0.7 = 140
	var p := PassengerFactory.create(Constants.PassengerType.ELDERLY, "test", 100)
	assert_int(p["fare"]).is_equal(140)


func test_Create_MediumDistance_ShouldApplyMediumMultiplier() -> void:
	# 200 km, Normal → 200 × 2 × 1.5 × 1.0 = 600
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 200)
	assert_int(p["fare"]).is_equal(600)


# ==========================================================
# SABIR HESAPLAMA
# ==========================================================

func test_Create_Normal_PatienceShouldBeBase() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	var expected := Balance.PATIENCE_BASE * Balance.PATIENCE_MULTIPLIER_NORMAL
	assert_float(p["patience"]).is_equal(expected)


func test_Create_VIP_PatienceShouldBeLow() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.VIP, "test", 50)
	var expected := Balance.PATIENCE_BASE * Balance.PATIENCE_MULTIPLIER_VIP
	assert_float(p["patience"]).is_equal(expected)


func test_Create_Student_PatienceShouldBeHigh() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.STUDENT, "test", 50)
	var expected := Balance.PATIENCE_BASE * Balance.PATIENCE_MULTIPLIER_STUDENT
	assert_float(p["patience"]).is_equal(expected)


func test_Create_Elderly_PatienceShouldBeNormal() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.ELDERLY, "test", 50)
	var expected := Balance.PATIENCE_BASE * Balance.PATIENCE_MULTIPLIER_ELDERLY
	assert_float(p["patience"]).is_equal(expected)


# ==========================================================
# RASTGELE YOLCU ÜRETİMİ
# ==========================================================

func test_CreateRandom_ShouldReturnValidPassenger() -> void:
	var destinations := ["izmir", "denizli", "afyon"]
	var p := PassengerFactory.create_random(destinations, 150)
	assert_that(p).is_not_null()
	assert_bool(p["destination"] in destinations).is_true()
	assert_int(p["fare"]).is_greater(0)
	assert_float(p["patience"]).is_greater(0.0)


func test_CreateBatch_ShouldReturnRequestedCount() -> void:
	var destinations := ["izmir", "denizli"]
	var batch := PassengerFactory.create_batch(3, destinations, 100)
	assert_int(batch.size()).is_equal(3)


func test_CreateBatch_AllShouldHaveUniqueIds() -> void:
	var destinations := ["izmir", "denizli"]
	var batch := PassengerFactory.create_batch(5, destinations, 100)
	var ids: Array[String] = []
	for p in batch:
		assert_bool(p["id"] in ids).is_false()
		ids.append(p["id"])
