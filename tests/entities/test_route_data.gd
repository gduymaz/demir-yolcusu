## Test suite: test_route_data.gd
## Restored English comments for maintainability and i18n coding standards.

class_name TestRouteData
extends GdUnitTestSuite

## Handles `test_Haversine_SamePoint_ShouldBeZero`.
func test_Haversine_SamePoint_ShouldBeZero() -> void:
	var dist := RouteData.haversine(38.4236, 27.1472, 38.4236, 27.1472)
	assert_float(dist).is_less(0.1)

## Handles `test_Haversine_IzmirTorbali_ShouldBeApprox33km`.
func test_Haversine_IzmirTorbali_ShouldBeApprox33km() -> void:

	var dist := RouteData.haversine(38.4236, 27.1472, 38.1706, 27.3481)

	assert_float(dist).is_greater(28.0)
	assert_float(dist).is_less(38.0)

## Handles `test_Haversine_IzmirDenizli_ShouldBeApprox212km`.
func test_Haversine_IzmirDenizli_ShouldBeApprox212km() -> void:

	var dist := RouteData.haversine(38.4236, 27.1472, 37.7892, 29.0897)
	assert_float(dist).is_greater(170.0)
	assert_float(dist).is_less(220.0)

## Handles `test_CreateStop_ShouldHaveCorrectProperties`.
func test_CreateStop_ShouldHaveCorrectProperties() -> void:
	var stop := RouteData.create_stop(312, "IZMIR (BASMANE)", "IZMIR", 38.4236, 27.1472, "large", 0.0)
	assert_int(stop["station_id"]).is_equal(312)
	assert_str(stop["name"]).is_equal("IZMIR (BASMANE)")
	assert_str(stop["city"]).is_equal("IZMIR")
	assert_float(stop["lat"]).is_equal(38.4236)
	assert_float(stop["lng"]).is_equal(27.1472)
	assert_str(stop["size"]).is_equal("large")
	assert_float(stop["km_from_start"]).is_equal(0.0)

## Handles `test_Create_ShouldStoreBasicProperties`.
func test_Create_ShouldStoreBasicProperties() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	assert_str(route.id).is_equal("ege_main")
	assert_str(route.route_name).is_equal("Ege Ana Hat")
	assert_str(route.region).is_equal("ege")

## Handles `test_Create_ShouldHaveCorrectStopCount`.
func test_Create_ShouldHaveCorrectStopCount() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	assert_int(route.get_stop_count()).is_equal(3)

## Handles `test_GetStop_ValidIndex_ShouldReturnStop`.
func test_GetStop_ValidIndex_ShouldReturnStop() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	var stop: Dictionary = route.get_stop(0)
	assert_str(stop["name"]).is_equal("IZMIR")

## Handles `test_GetStop_InvalidIndex_ShouldReturnEmpty`.
func test_GetStop_InvalidIndex_ShouldReturnEmpty() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	var stop: Dictionary = route.get_stop(99)
	assert_int(stop.size()).is_equal(0)

## Handles `test_GetTotalDistance_ShouldReturnLastStopKm`.
func test_GetTotalDistance_ShouldReturnLastStopKm() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	assert_float(route.get_total_distance()).is_greater(0.0)

## Handles `test_GetDistanceBetween_Adjacent_ShouldBePositive`.
func test_GetDistanceBetween_Adjacent_ShouldBePositive() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	var dist := route.get_distance_between(0, 1)
	assert_float(dist).is_greater(0.0)

## Handles `test_GetDistanceBetween_SameStop_ShouldBeZero`.
func test_GetDistanceBetween_SameStop_ShouldBeZero() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	assert_float(route.get_distance_between(0, 0)).is_equal(0.0)

## Handles `test_GetDistanceBetween_MultipleStops_ShouldSumSegments`.
func test_GetDistanceBetween_MultipleStops_ShouldSumSegments() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	var total := route.get_distance_between(0, 2)
	var seg1 := route.get_distance_between(0, 1)
	var seg2 := route.get_distance_between(1, 2)
	assert_float(total).is_equal_approx(seg1 + seg2, 0.1)

## Handles `test_GetSubRoute_ShouldReturnCorrectStops`.
func test_GetSubRoute_ShouldReturnCorrectStops() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	var sub := route.get_sub_route(0, 1)
	assert_int(sub.size()).is_equal(2)

## Handles `test_GetSubRoute_Reversed_ShouldReverseOrder`.
func test_GetSubRoute_Reversed_ShouldReverseOrder() -> void:
	var stops := _create_test_stops()
	var route := RouteData.create("ege_main", "Ege Ana Hat", "ege", stops)
	var sub := route.get_sub_route(2, 0)
	assert_int(sub.size()).is_equal(3)
	assert_str(sub[0]["name"]).is_equal("SELCUK")
	assert_str(sub[2]["name"]).is_equal("IZMIR")

## Handles `test_LoadEgeRoute_ShouldExist`.
func test_LoadEgeRoute_ShouldExist() -> void:
	var route := RouteData.load_ege_route()
	assert_object(route).is_not_null()

## Handles `test_LoadEgeRoute_ShouldHave7Stops`.
func test_LoadEgeRoute_ShouldHave7Stops() -> void:
	var route := RouteData.load_ege_route()
	assert_int(route.get_stop_count()).is_equal(7)

## Handles `test_LoadEgeRoute_FirstStop_ShouldBeIzmir`.
func test_LoadEgeRoute_FirstStop_ShouldBeIzmir() -> void:
	var route := RouteData.load_ege_route()
	var first: Dictionary = route.get_stop(0)
	assert_bool(first["name"].begins_with("IZMIR")).is_true()

## Handles `test_LoadEgeRoute_LastStop_ShouldBeDenizli`.
func test_LoadEgeRoute_LastStop_ShouldBeDenizli() -> void:
	var route := RouteData.load_ege_route()
	var last: Dictionary = route.get_stop(6)
	assert_str(last["name"]).is_equal("DENIZLI")

## Handles `test_LoadEgeRoute_TotalDistance_ShouldBeApprox212km`.
func test_LoadEgeRoute_TotalDistance_ShouldBeApprox212km() -> void:
	var route := RouteData.load_ege_route()
	var dist := route.get_total_distance()
	assert_float(dist).is_greater(180.0)
	assert_float(dist).is_less(250.0)

## Handles `test_LoadEgeRoute_StopOrder_ShouldBeCorrect`.
func test_LoadEgeRoute_StopOrder_ShouldBeCorrect() -> void:
	var route := RouteData.load_ege_route()
	var names: Array = []
	for i in route.get_stop_count():
		var stop: Dictionary = route.get_stop(i)
		names.append(stop["name"])
	assert_bool(names[1] == "TORBALI").is_true()
	assert_bool(names[2] == "SELCUK").is_true()
	assert_bool(names[3] == "ORTAKLAR").is_true()
	assert_bool(names[4] == "AYDIN").is_true()
	assert_bool(names[5] == "NAZILLI").is_true()

## Handles `test_LoadEgeRoute_KmFromStart_ShouldIncrease`.
func test_LoadEgeRoute_KmFromStart_ShouldIncrease() -> void:
	var route := RouteData.load_ege_route()
	var prev_km := 0.0
	for i in route.get_stop_count():
		var stop: Dictionary = route.get_stop(i)
		assert_float(stop["km_from_start"]).is_greater_equal(prev_km)
		prev_km = stop["km_from_start"]

## Handles `test_LoadEgeRoute_AllStops_ShouldHaveGPS`.
func test_LoadEgeRoute_AllStops_ShouldHaveGPS() -> void:
	var route := RouteData.load_ege_route()
	for i in route.get_stop_count():
		var stop: Dictionary = route.get_stop(i)
		assert_float(stop["lat"]).is_greater(36.0)
		assert_float(stop["lng"]).is_greater(26.0)

## Handles `test_GetAvailableRoutes_ShouldContainEge`.
func test_GetAvailableRoutes_ShouldContainEge() -> void:
	var routes := RouteData.get_available_routes()
	assert_bool(routes.has("ege_main")).is_true()

## Lifecycle/helper logic for `_create_test_stops`.
func _create_test_stops() -> Array:
	return [
		RouteData.create_stop(312, "IZMIR", "IZMIR", 38.4236, 27.1472, "large", 0.0),
		RouteData.create_stop(410, "TORBALI", "IZMIR", 38.1706, 27.3481, "large", 33.0),
		RouteData.create_stop(375, "SELCUK", "IZMIR", 37.9514, 27.3733, "large", 57.0),
	]
