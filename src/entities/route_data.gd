## Module: route_data.gd
## Restored English comments for maintainability and i18n coding standards.

class_name RouteData
extends RefCounted

var id: String
var route_name: String
var region: String
var _stops: Array = []

static func create(route_id: String, name: String, route_region: String, stops: Array) -> RouteData:
	var route := RouteData.new()
	route.id = route_id
	route.route_name = name
	route.region = route_region
	route._stops = stops
	return route

static func create_stop(station_id: int, name: String, city: String,
		lat: float, lng: float, size: String, km_from_start: float) -> Dictionary:
	return {
		"station_id": station_id,
		"name": name,
		"city": city,
		"lat": lat,
		"lng": lng,
		"size": size,
		"km_from_start": km_from_start,
	}

## Handles `get_stop_count`.
func get_stop_count() -> int:
	return _stops.size()

## Handles `get_stop`.
func get_stop(index: int) -> Dictionary:
	if index < 0 or index >= _stops.size():
		return {}
	return _stops[index]

## Handles `get_stops`.
func get_stops() -> Array:
	return _stops

## Handles `get_total_distance`.
func get_total_distance() -> float:
	if _stops.is_empty():
		return 0.0
	var last: Dictionary = _stops[_stops.size() - 1]
	return last["km_from_start"]

## Handles `get_distance_between`.
func get_distance_between(from_index: int, to_index: int) -> float:
	if from_index < 0 or to_index < 0:
		return 0.0
	if from_index >= _stops.size() or to_index >= _stops.size():
		return 0.0
	var from_stop: Dictionary = _stops[from_index]
	var to_stop: Dictionary = _stops[to_index]
	return absf(to_stop["km_from_start"] - from_stop["km_from_start"])

## Handles `get_sub_route`.
func get_sub_route(from_index: int, to_index: int) -> Array:
	if from_index < 0 or to_index < 0:
		return []
	if from_index >= _stops.size() or to_index >= _stops.size():
		return []

	var result: Array = []
	if from_index <= to_index:
		for i in range(from_index, to_index + 1):
			result.append(_stops[i])
	else:

		for i in range(from_index, to_index - 1, -1):
			result.append(_stops[i])
	return result

static func haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var R := 6371.0
	var d_lat := deg_to_rad(lat2 - lat1)
	var d_lon := deg_to_rad(lon2 - lon1)
	var a := sin(d_lat / 2.0) * sin(d_lat / 2.0) + \
		cos(deg_to_rad(lat1)) * cos(deg_to_rad(lat2)) * \
		sin(d_lon / 2.0) * sin(d_lon / 2.0)
	var c := 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
	return R * c

static func load_ege_route() -> RouteData:

	var station_data := [
		{"id": 312, "name": "IZMIR (BASMANE)", "city": "IZMIR", "lat": 38.4236, "lng": 27.1472, "size": "large"},
		{"id": 410, "name": "TORBALI", "city": "IZMIR", "lat": 38.1706, "lng": 27.3481, "size": "large"},
		{"id": 375, "name": "SELCUK", "city": "IZMIR", "lat": 37.9514, "lng": 27.3733, "size": "large"},
		{"id": 362, "name": "ORTAKLAR", "city": "AYDIN", "lat": 37.8872, "lng": 27.5056, "size": "large"},
		{"id": 288, "name": "AYDIN", "city": "AYDIN", "lat": 37.8486, "lng": 27.8367, "size": "large"},
		{"id": 358, "name": "NAZILLI", "city": "AYDIN", "lat": 37.9150, "lng": 28.3297, "size": "large"},
		{"id": 309, "name": "DENIZLI", "city": "DENIZLI", "lat": 37.7892, "lng": 29.0897, "size": "large"},
	]

	var stops: Array = []
	var cumulative_km := 0.0

	for i in station_data.size():
		var s: Dictionary = station_data[i]
		if i > 0:
			var prev: Dictionary = station_data[i - 1]
			cumulative_km += haversine(prev["lat"], prev["lng"], s["lat"], s["lng"])

		stops.append(create_stop(
			s["id"], s["name"], s["city"],
			s["lat"], s["lng"], s["size"],
			snapped(cumulative_km, 0.01)
		))

	return create("ege_main", "Ege Ana Hat", "ege", stops)

static func load_manisa_alasehir_route() -> RouteData:
	var station_data := [
		{"id": 281, "name": "MANISA", "city": "MANISA", "lat": 38.6191, "lng": 27.4289, "size": "large"},
		{"id": 282, "name": "MURADIYE", "city": "MANISA", "lat": 38.6472, "lng": 27.3460, "size": "small"},
		{"id": 283, "name": "TURGUTLU", "city": "MANISA", "lat": 38.5050, "lng": 27.6990, "size": "large"},
		{"id": 284, "name": "AHMETLI", "city": "MANISA", "lat": 38.5172, "lng": 27.9374, "size": "small"},
		{"id": 285, "name": "SALIHLI", "city": "MANISA", "lat": 38.4929, "lng": 28.1396, "size": "large"},
		{"id": 286, "name": "KOPRUBASI", "city": "MANISA", "lat": 38.7467, "lng": 28.4007, "size": "small"},
		{"id": 287, "name": "ALASEHIR", "city": "MANISA", "lat": 38.3508, "lng": 28.5172, "size": "large"},
	]

	var stops: Array = []
	var cumulative_km := 0.0
	for i in station_data.size():
		var s: Dictionary = station_data[i]
		if i > 0:
			var prev: Dictionary = station_data[i - 1]
			cumulative_km += haversine(prev["lat"], prev["lng"], s["lat"], s["lng"])
		stops.append(create_stop(
			s["id"], s["name"], s["city"],
			s["lat"], s["lng"], s["size"],
			snapped(cumulative_km, 0.01)
		))
	return create("manisa_alasehir", "Manisa - Alasehir", "ege_regional", stops)

static func load_route_by_id(route_id: String) -> RouteData:
	match route_id:
		"manisa_alasehir":
			return load_manisa_alasehir_route()
		"ege_main":
			return load_ege_route()
		_:
			return load_ege_route()

static func get_available_routes() -> Dictionary:
	return {
		"ege_main": "Ege Ana Hat (Izmir - Denizli)",
		"manisa_alasehir": "Manisa - Alasehir",
	}

static func get_route_progression_catalog() -> Dictionary:
	return {
		"regional": [
			"manisa_alasehir",
			"basmane_denizli",
			"basmane_odemis",
			"basmane_tire",
			"basmane_usak",
			"basmane_alasehir",
			"basmane_nazilli",
			"soke_denizli",
			"soke_nazilli",
		],
		"mainline": [
			"izmir_mavi_treni",
			"konya_mavi_treni",
			"ege_ekspresi",
			"pamukkale_ekspresi",
			"ankara_ekspresi",
			"toros_ekspresi",
		],
		"yht": [
			"ankara_istanbul_yht",
			"ankara_eskisehir_yht",
			"ankara_konya_yht",
			"ankara_karaman_yht",
			"istanbul_konya_yht",
			"istanbul_karaman_yht",
			"ankara_sivas_yht",
			"sivas_istanbul_yht",
		],
		"starter_route_id": "manisa_alasehir",
	}
