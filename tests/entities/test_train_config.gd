## TrainConfig testleri.
## Tren konfigürasyonu: lokomotif + vagon listesi yönetimi.
class_name TestTrainConfig
extends GdUnitTestSuite


# ==========================================================
# OLUŞTURMA
# ==========================================================

func test_Create_WithLocomotive_ShouldStoreIt() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_str(config.get_locomotive().id).is_equal("kara_duman")


func test_Create_ShouldStartWithNoWagons() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_int(config.get_wagon_count()).is_equal(0)


# ==========================================================
# VAGON EKLEME
# ==========================================================

func test_AddWagon_SingleWagon_ShouldIncreaseCount() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	var wagon := WagonData.new(Constants.WagonType.ECONOMY)
	var result := config.add_wagon(wagon)
	assert_bool(result).is_true()
	assert_int(config.get_wagon_count()).is_equal(1)


func test_AddWagon_UpToMax_ShouldSucceed() -> void:
	var loco := LocomotiveData.create("kara_duman")  # max 3
	var config := TrainConfig.new(loco)
	for i in range(3):
		var wagon := WagonData.new(Constants.WagonType.ECONOMY)
		assert_bool(config.add_wagon(wagon)).is_true()
	assert_int(config.get_wagon_count()).is_equal(3)


func test_AddWagon_ExceedMax_ShouldReturnFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")  # max 3
	var config := TrainConfig.new(loco)
	for i in range(3):
		config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	var extra := WagonData.new(Constants.WagonType.BUSINESS)
	assert_bool(config.add_wagon(extra)).is_false()
	assert_int(config.get_wagon_count()).is_equal(3)


func test_AddWagon_ShouldAppendToEnd() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	var w1 := WagonData.new(Constants.WagonType.ECONOMY)
	var w2 := WagonData.new(Constants.WagonType.BUSINESS)
	config.add_wagon(w1)
	config.add_wagon(w2)
	var wagons := config.get_wagons()
	assert_int(wagons[0].type).is_equal(Constants.WagonType.ECONOMY)
	assert_int(wagons[1].type).is_equal(Constants.WagonType.BUSINESS)


# ==========================================================
# VAGON ÇIKARMA
# ==========================================================

func test_RemoveWagonAt_ValidIndex_ShouldRemove() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	config.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))
	var removed := config.remove_wagon_at(0)
	assert_object(removed).is_not_null()
	assert_int(removed.type).is_equal(Constants.WagonType.ECONOMY)
	assert_int(config.get_wagon_count()).is_equal(1)


func test_RemoveWagonAt_InvalidIndex_ShouldReturnNull() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	var removed := config.remove_wagon_at(0)
	assert_object(removed).is_null()


func test_RemoveWagonAt_NegativeIndex_ShouldReturnNull() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	var removed := config.remove_wagon_at(-1)
	assert_object(removed).is_null()


# ==========================================================
# SIRA DEĞİŞTİRME
# ==========================================================

func test_SwapWagons_ValidIndices_ShouldSwap() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	config.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))
	config.add_wagon(WagonData.new(Constants.WagonType.CARGO))
	var result := config.swap_wagons(0, 2)
	assert_bool(result).is_true()
	var wagons := config.get_wagons()
	assert_int(wagons[0].type).is_equal(Constants.WagonType.CARGO)
	assert_int(wagons[2].type).is_equal(Constants.WagonType.ECONOMY)


func test_SwapWagons_InvalidIndex_ShouldReturnFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_bool(config.swap_wagons(0, 5)).is_false()


func test_SwapWagons_SameIndex_ShouldReturnTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_bool(config.swap_wagons(0, 0)).is_true()


# ==========================================================
# KAPASİTE HESAPLAMA
# ==========================================================

func test_GetTotalPassengerCapacity_NoWagons_ShouldBeZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_int(config.get_total_passenger_capacity()).is_equal(0)


func test_GetTotalPassengerCapacity_WithWagons_ShouldSumAll() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))   # 20
	config.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))  # 12
	assert_int(config.get_total_passenger_capacity()).is_equal(32)


func test_GetTotalPassengerCapacity_CargoShouldNotCount() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))   # 20
	config.add_wagon(WagonData.new(Constants.WagonType.CARGO))     # Yolcu taşımaz
	# Cargo vagonu yolcu taşıyamaz ama kapasitesi 10 (kutu)
	# Toplam yolcu kapasitesi sadece 20 olmalı
	assert_int(config.get_total_passenger_capacity()).is_equal(20)


# ==========================================================
# AĞIRLIK HESAPLAMA
# ==========================================================

func test_GetTotalWeight_NoWagons_ShouldBeZero() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_float(config.get_total_weight()).is_equal(0.0)


func test_GetTotalWeight_WithWagons_ShouldMultiplyByConstant() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	config.add_wagon(WagonData.new(Constants.WagonType.BUSINESS))
	# 2 vagon × 15.0 ton = 30.0
	assert_float(config.get_total_weight()).is_equal(2 * Balance.WAGON_WEIGHT)


# ==========================================================
# MAX VAGON
# ==========================================================

func test_GetMaxWagons_ShouldMatchLocomotive() -> void:
	var loco := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco)
	assert_int(config.get_max_wagons()).is_equal(Constants.MAX_WAGONS_COAL_OLD)


func test_IsFull_NotFull_ShouldBeFalse() -> void:
	var loco := LocomotiveData.create("kara_duman")  # max 3
	var config := TrainConfig.new(loco)
	config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_bool(config.is_full()).is_false()


func test_IsFull_AtMax_ShouldBeTrue() -> void:
	var loco := LocomotiveData.create("kara_duman")  # max 3
	var config := TrainConfig.new(loco)
	for i in range(3):
		config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_bool(config.is_full()).is_true()


# ==========================================================
# LOKOMOTİF DEĞİŞTİRME
# ==========================================================

func test_SetLocomotive_ShouldChangeLocomotive() -> void:
	var loco1 := LocomotiveData.create("kara_duman")
	var config := TrainConfig.new(loco1)
	var loco2 := LocomotiveData.create("mavi_simsek")
	config.set_locomotive(loco2)
	assert_str(config.get_locomotive().id).is_equal("mavi_simsek")


func test_SetLocomotive_WithTooManyWagons_ShouldTrimExcess() -> void:
	var loco_big := LocomotiveData.create("mavi_simsek")  # max 8
	var config := TrainConfig.new(loco_big)
	for i in range(5):
		config.add_wagon(WagonData.new(Constants.WagonType.ECONOMY))
	assert_int(config.get_wagon_count()).is_equal(5)
	var loco_small := LocomotiveData.create("kara_duman")  # max 3
	config.set_locomotive(loco_small)
	assert_int(config.get_wagon_count()).is_equal(3)
