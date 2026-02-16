## TripPlanner testleri.
## Sefer planlama: rota seçimi, ön izleme, yakıt kontrolü, sefer yönetimi.
class_name TestTripPlanner
extends GdUnitTestSuite


var _planner: TripPlanner
var _event_bus: Node
var _economy: EconomySystem
var _fuel: FuelSystem
var _route: RouteData


func before_test() -> void:
	_event_bus = auto_free(Node.new())
	_event_bus.set_script(load("res://src/events/event_bus.gd"))
	_economy = auto_free(EconomySystem.new())
	_economy.setup(_event_bus)
	var loco := LocomotiveData.create("kara_duman")
	_fuel = auto_free(FuelSystem.new())
	_fuel.setup(_event_bus, _economy, loco)
	_route = RouteData.load_ege_route()
	_planner = auto_free(TripPlanner.new())
	_planner.setup(_event_bus, _economy, _fuel, _route)


# ==========================================================
# ROTA SEÇİMİ
# ==========================================================

func test_SelectRoute_ShouldStoreStartAndEnd() -> void:
	_planner.select_stops(0, 6)  # İzmir → Denizli
	assert_int(_planner.get_start_index()).is_equal(0)
	assert_int(_planner.get_end_index()).is_equal(6)


func test_SelectRoute_ShouldCalculateStopCount() -> void:
	_planner.select_stops(0, 6)
	assert_int(_planner.get_trip_stop_count()).is_equal(7)


func test_SelectRoute_Partial_ShouldWork() -> void:
	_planner.select_stops(1, 4)  # Torbalı → Aydın
	assert_int(_planner.get_trip_stop_count()).is_equal(4)


func test_SelectRoute_Reversed_ShouldSwapIndices() -> void:
	_planner.select_stops(4, 1)  # Aydın → Torbalı (gidiş yönü ters)
	assert_int(_planner.get_start_index()).is_equal(4)
	assert_int(_planner.get_end_index()).is_equal(1)
	assert_int(_planner.get_trip_stop_count()).is_equal(4)


func test_SelectRoute_Invalid_ShouldReturnFalse() -> void:
	assert_bool(_planner.select_stops(-1, 6)).is_false()
	assert_bool(_planner.select_stops(0, 99)).is_false()


func test_SelectRoute_SameStop_ShouldReturnFalse() -> void:
	assert_bool(_planner.select_stops(2, 2)).is_false()


# ==========================================================
# ÖN İZLEME
# ==========================================================

func test_GetPreview_Distance_ShouldBePositive() -> void:
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_float(preview["distance_km"]).is_greater(0.0)


func test_GetPreview_FuelCost_ShouldBePositive() -> void:
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_float(preview["fuel_cost"]).is_greater(0.0)


func test_GetPreview_MoreWagons_ShouldIncreaseFuelCost() -> void:
	_planner.select_stops(0, 6)
	_planner.set_wagon_count(0)
	var low := _planner.get_preview()
	_planner.set_wagon_count(4)
	var high := _planner.get_preview()
	assert_float(high["fuel_cost"]).is_greater(low["fuel_cost"])


func test_GetPreview_StopCount_ShouldMatch() -> void:
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_int(preview["stop_count"]).is_equal(7)


func test_GetPreview_EstimatedRevenue_ShouldBePositive() -> void:
	_planner.select_stops(0, 6)
	var preview := _planner.get_preview()
	assert_int(preview["estimated_revenue"]).is_greater(0)


func test_GetPreview_CanAffordFuel_ShouldBeTrue() -> void:
	_planner.select_stops(0, 3)  # Kısa rota
	var preview := _planner.get_preview()
	assert_bool(preview["can_afford_fuel"]).is_true()


func test_GetPreview_TooExpensive_ShouldBeFalse() -> void:
	_economy.set_balance(0)
	_fuel.consume(280.0)  # Neredeyse boş tank
	_planner.select_stops(0, 6)  # Uzun rota
	var preview := _planner.get_preview()
	assert_bool(preview["can_afford_fuel"]).is_false()


# ==========================================================
# SEFER BAŞLATMA
# ==========================================================

func test_StartTrip_ShouldSetActive() -> void:
	_planner.select_stops(0, 3)
	assert_bool(_planner.start_trip()).is_true()
	assert_bool(_planner.is_trip_active()).is_true()


func test_StartTrip_ShouldSetCurrentStopToStart() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	assert_int(_planner.get_current_stop_index()).is_equal(0)


func test_StartTrip_NoRouteSelected_ShouldReturnFalse() -> void:
	assert_bool(_planner.start_trip()).is_false()


func test_StartTrip_ShouldConsumeFuelForRefuel() -> void:
	_planner.select_stops(0, 3)
	_fuel.consume(200.0)  # 100 kalan
	var balance_before := _economy.get_balance()
	_planner.start_trip()
	# Otomatik ikmal yapılmış olmalı
	assert_int(_economy.get_balance()).is_less_equal(balance_before)


# ==========================================================
# SEFER İLERLEME
# ==========================================================

func test_AdvanceToNextStop_ShouldIncrementIndex() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	_planner.advance_to_next_stop()
	assert_int(_planner.get_current_stop_index()).is_equal(1)


func test_AdvanceToNextStop_ShouldConsumeFuel() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	var fuel_before := _fuel.get_current_fuel()
	_planner.advance_to_next_stop()
	assert_float(_fuel.get_current_fuel()).is_less(fuel_before)


func test_AdvanceToNextStop_AtEnd_ShouldEndTrip() -> void:
	_planner.select_stops(0, 2)  # 3 durak: İzmir → Torbalı → Selçuk
	_planner.start_trip()
	_planner.advance_to_next_stop()  # → Torbalı
	_planner.advance_to_next_stop()  # → Selçuk (son durak)
	assert_bool(_planner.is_at_final_stop()).is_true()


func test_IsAtFinalStop_NotAtEnd_ShouldBeFalse() -> void:
	_planner.select_stops(0, 6)
	_planner.start_trip()
	assert_bool(_planner.is_at_final_stop()).is_false()


# ==========================================================
# SEFER BİTİRME
# ==========================================================

func test_EndTrip_ShouldDeactivate() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	_planner.end_trip()
	assert_bool(_planner.is_trip_active()).is_false()


func test_EndTrip_ShouldEmitSignal() -> void:
	_planner.select_stops(0, 3)
	_planner.start_trip()
	var result := {"emitted": false}
	_event_bus.trip_completed.connect(func(_summary: Dictionary) -> void: result["emitted"] = true)
	_planner.end_trip()
	assert_bool(result["emitted"]).is_true()


# ==========================================================
# MEVCUT DURAK BİLGİSİ
# ==========================================================

func test_GetCurrentStop_ShouldReturnStopData() -> void:
	_planner.select_stops(0, 6)
	_planner.start_trip()
	var stop := _planner.get_current_stop()
	assert_bool(stop["name"].begins_with("IZMIR")).is_true()


func test_GetNextStop_ShouldReturnNextStopData() -> void:
	_planner.select_stops(0, 6)
	_planner.start_trip()
	var next := _planner.get_next_stop()
	assert_str(next["name"]).is_equal("TORBALI")


func test_GetNextStop_AtEnd_ShouldReturnEmpty() -> void:
	_planner.select_stops(0, 1)  # 2 durak
	_planner.start_trip()
	_planner.advance_to_next_stop()  # Son durağa gel
	var next := _planner.get_next_stop()
	assert_int(next.size()).is_equal(0)


func test_GetDistanceToNextStop_ShouldBePositive() -> void:
	_planner.select_stops(0, 6)
	_planner.start_trip()
	assert_float(_planner.get_distance_to_next_stop()).is_greater(0.0)
