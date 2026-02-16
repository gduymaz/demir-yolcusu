## Test suite: test_passenger_factory.gd
## Restored English comments for maintainability and i18n coding standards.

extends GdUnitTestSuite

## Handles `test_Create_Normal_ShouldReturnValidPassenger`.
func test_Create_Normal_ShouldReturnValidPassenger() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "denizli", 100)
	assert_str(p["destination"]).is_equal("denizli")
	assert_int(p["type"]).is_equal(Constants.PassengerType.NORMAL)
	assert_int(p["state"]).is_equal(Constants.PassengerState.WAITING)
	assert_str(p["id"]).is_not_empty()

## Handles `test_Create_VIP_ShouldSetVIPType`.
func test_Create_VIP_ShouldSetVIPType() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.VIP, "izmir", 50)
	assert_int(p["type"]).is_equal(Constants.PassengerType.VIP)

## Handles `test_Create_Student_ShouldSetStudentType`.
func test_Create_Student_ShouldSetStudentType() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.STUDENT, "afyon", 200)
	assert_int(p["type"]).is_equal(Constants.PassengerType.STUDENT)

## Handles `test_Create_Elderly_ShouldSetElderlyType`.
func test_Create_Elderly_ShouldSetElderlyType() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.ELDERLY, "selcuk", 80)
	assert_int(p["type"]).is_equal(Constants.PassengerType.ELDERLY)

## Handles `test_Create_ShouldGenerateUniqueIds`.
func test_Create_ShouldGenerateUniqueIds() -> void:
	var p1 := PassengerFactory.create(Constants.PassengerType.NORMAL, "a", 50)
	var p2 := PassengerFactory.create(Constants.PassengerType.NORMAL, "b", 50)
	assert_str(p1["id"]).is_not_equal(p2["id"])

## Handles `test_Create_Normal_FareShouldMatchDistance`.
func test_Create_Normal_FareShouldMatchDistance() -> void:

	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 100)
	assert_int(p["fare"]).is_equal(200)

## Handles `test_Create_VIP_FareShouldBeTriple`.
func test_Create_VIP_FareShouldBeTriple() -> void:

	var p := PassengerFactory.create(Constants.PassengerType.VIP, "test", 100)
	assert_int(p["fare"]).is_equal(600)

## Handles `test_Create_Student_FareShouldBeHalf`.
func test_Create_Student_FareShouldBeHalf() -> void:

	var p := PassengerFactory.create(Constants.PassengerType.STUDENT, "test", 100)
	assert_int(p["fare"]).is_equal(100)

## Handles `test_Create_Elderly_FareShouldBe70Percent`.
func test_Create_Elderly_FareShouldBe70Percent() -> void:

	var p := PassengerFactory.create(Constants.PassengerType.ELDERLY, "test", 100)
	assert_int(p["fare"]).is_equal(140)

## Handles `test_Create_MediumDistance_ShouldApplyMediumMultiplier`.
func test_Create_MediumDistance_ShouldApplyMediumMultiplier() -> void:

	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 200)
	assert_int(p["fare"]).is_equal(600)

## Handles `test_Create_Normal_PatienceShouldBeBase`.
func test_Create_Normal_PatienceShouldBeBase() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.NORMAL, "test", 50)
	var expected := Balance.PATIENCE_BASE * Balance.PATIENCE_MULTIPLIER_NORMAL
	assert_float(p["patience"]).is_equal(expected)

## Handles `test_Create_VIP_PatienceShouldBeLow`.
func test_Create_VIP_PatienceShouldBeLow() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.VIP, "test", 50)
	var expected := Balance.PATIENCE_BASE * Balance.PATIENCE_MULTIPLIER_VIP
	assert_float(p["patience"]).is_equal(expected)

## Handles `test_Create_Student_PatienceShouldBeHigh`.
func test_Create_Student_PatienceShouldBeHigh() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.STUDENT, "test", 50)
	var expected := Balance.PATIENCE_BASE * Balance.PATIENCE_MULTIPLIER_STUDENT
	assert_float(p["patience"]).is_equal(expected)

## Handles `test_Create_Elderly_PatienceShouldBeNormal`.
func test_Create_Elderly_PatienceShouldBeNormal() -> void:
	var p := PassengerFactory.create(Constants.PassengerType.ELDERLY, "test", 50)
	var expected := Balance.PATIENCE_BASE * Balance.PATIENCE_MULTIPLIER_ELDERLY
	assert_float(p["patience"]).is_equal(expected)

## Handles `test_CreateRandom_ShouldReturnValidPassenger`.
func test_CreateRandom_ShouldReturnValidPassenger() -> void:
	var destinations := ["izmir", "denizli", "afyon"]
	var p := PassengerFactory.create_random(destinations, 150)
	assert_that(p).is_not_null()
	assert_bool(p["destination"] in destinations).is_true()
	assert_int(p["fare"]).is_greater(0)
	assert_float(p["patience"]).is_greater(0.0)

## Handles `test_CreateBatch_ShouldReturnRequestedCount`.
func test_CreateBatch_ShouldReturnRequestedCount() -> void:
	var destinations := ["izmir", "denizli"]
	var batch := PassengerFactory.create_batch(3, destinations, 100)
	assert_int(batch.size()).is_equal(3)

## Handles `test_CreateBatch_AllShouldHaveUniqueIds`.
func test_CreateBatch_AllShouldHaveUniqueIds() -> void:
	var destinations := ["izmir", "denizli"]
	var batch := PassengerFactory.create_batch(5, destinations, 100)
	var ids: Array[String] = []
	for p in batch:
		assert_bool(p["id"] in ids).is_false()
		ids.append(p["id"])
