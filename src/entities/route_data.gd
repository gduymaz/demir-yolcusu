## Güzergah veri modeli.
## Bir demiryolu güzergahı ve sıralı durakları tutar.
## GPS koordinatlarından mesafe hesaplar (Haversine).
class_name RouteData
extends RefCounted


var id: String
var route_name: String
var region: String
var _stops: Array = []  # Array[Dictionary]


## Güzergah oluşturur.
static func create(route_id: String, name: String, route_region: String, stops: Array) -> RouteData:
	var route := RouteData.new()
	route.id = route_id
	route.route_name = name
	route.region = route_region
	route._stops = stops
	return route


## Durak verisi oluşturur.
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


# ==========================================================
# SORGULAMA
# ==========================================================

func get_stop_count() -> int:
	return _stops.size()


func get_stop(index: int) -> Dictionary:
	if index < 0 or index >= _stops.size():
		return {}
	return _stops[index]


func get_stops() -> Array:
	return _stops


func get_total_distance() -> float:
	if _stops.is_empty():
		return 0.0
	var last: Dictionary = _stops[_stops.size() - 1]
	return last["km_from_start"]


## İki durak arasındaki mesafeyi döner (km).
func get_distance_between(from_index: int, to_index: int) -> float:
	if from_index < 0 or to_index < 0:
		return 0.0
	if from_index >= _stops.size() or to_index >= _stops.size():
		return 0.0
	var from_stop: Dictionary = _stops[from_index]
	var to_stop: Dictionary = _stops[to_index]
	return absf(to_stop["km_from_start"] - from_stop["km_from_start"])


## Alt rota döner (from_index → to_index arası duraklar).
## from > to ise ters sırada döner (dönüş yolculuğu).
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
		# Ters yön
		for i in range(from_index, to_index - 1, -1):
			result.append(_stops[i])
	return result


# ==========================================================
# HAVERSİNE FORMÜLÜ
# ==========================================================

## İki GPS koordinatı arasındaki mesafeyi km olarak hesaplar.
## Haversine formülü: Dünya'nın küresel şeklini dikkate alan mesafe hesabı.
static func haversine(lat1: float, lon1: float, lat2: float, lon2: float) -> float:
	var R := 6371.0  # Dünya yarıçapı (km)
	var d_lat := deg_to_rad(lat2 - lat1)
	var d_lon := deg_to_rad(lon2 - lon1)
	var a := sin(d_lat / 2.0) * sin(d_lat / 2.0) + \
		cos(deg_to_rad(lat1)) * cos(deg_to_rad(lat2)) * \
		sin(d_lon / 2.0) * sin(d_lon / 2.0)
	var c := 2.0 * atan2(sqrt(a), sqrt(1.0 - a))
	return R * c


# ==========================================================
# MVP EGE ROTASI
# ==========================================================

## Ege ana hattını TCDD verilerinden yükler.
## İzmir (Basmane) → Torbalı → Selçuk → Ortaklar → Aydın → Nazilli → Denizli
static func load_ege_route() -> RouteData:
	# Gerçek TCDD GPS verileri
	var station_data := [
		{"id": 312, "name": "IZMIR (BASMANE)", "city": "IZMIR", "lat": 38.4236, "lng": 27.1472, "size": "large"},
		{"id": 410, "name": "TORBALI", "city": "IZMIR", "lat": 38.1706, "lng": 27.3481, "size": "large"},
		{"id": 375, "name": "SELCUK", "city": "IZMIR", "lat": 37.9514, "lng": 27.3733, "size": "large"},
		{"id": 362, "name": "ORTAKLAR", "city": "AYDIN", "lat": 37.8872, "lng": 27.5056, "size": "large"},
		{"id": 288, "name": "AYDIN", "city": "AYDIN", "lat": 37.8486, "lng": 27.8367, "size": "large"},
		{"id": 358, "name": "NAZILLI", "city": "AYDIN", "lat": 37.9150, "lng": 28.3297, "size": "large"},
		{"id": 309, "name": "DENIZLI", "city": "DENIZLI", "lat": 37.7892, "lng": 29.0897, "size": "large"},
	]

	# Mesafeleri Haversine ile hesapla
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


## Kullanılabilir güzergahları döner.
static func get_available_routes() -> Dictionary:
	return {
		"ege_main": "Ege Ana Hat (Izmir - Denizli)",
	}
