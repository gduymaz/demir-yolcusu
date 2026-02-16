## Oyun sabitleri ve enum tanımları.
## Tüm magic number'lar burada. Kodda asla doğrudan sayı kullanma.
class_name Constants
extends RefCounted


# -- Yolcu Tipleri --
enum PassengerType {
	NORMAL,
	VIP,
	STUDENT,
	ELDERLY,
}

# -- Vagon Tipleri --
enum WagonType {
	ECONOMY,
	BUSINESS,
	VIP,
	DINING,
	CARGO,
}

# -- Yakıt Tipleri --
enum FuelType {
	COAL_OLD,
	COAL_NEW,
	DIESEL_OLD,
	DIESEL_NEW,
	ELECTRIC,
}

# -- Durak Boyutları --
enum StationSize {
	SMALL,   # Köy
	MEDIUM,  # İlçe
	LARGE,   # Şehir
}

# -- Yolcu Durumları (FSM) --
enum PassengerState {
	WAITING,
	DRAGGED,
	BOARDING,
	SEATED,
	ALIGHTING,
	GONE,
}

# -- Tren Durumları (FSM) --
enum TrainState {
	IN_GARAGE,
	DEPARTING,
	TRAVELING,
	ARRIVING,
	AT_STATION,
}

# -- Görev Durumları (FSM) --
enum QuestState {
	LOCKED,
	AVAILABLE,
	ACTIVE,
	COMPLETED,
}

# -- Bilet Mesafe Kademeleri (km) --
const TICKET_DISTANCE_SHORT := 100
const TICKET_DISTANCE_MEDIUM := 300

# -- Durak Zaman Limitleri (saniye) --
const STATION_TIME_SMALL := 10.0
const STATION_TIME_MEDIUM := 15.0
const STATION_TIME_LARGE := 20.0

# -- Zorluk Çarpanları --
const DIFFICULTY_EASY := 1.5
const DIFFICULTY_NORMAL := 1.0
const DIFFICULTY_HARD := 0.7

# -- Lokomotif Vagon Limitleri --
const MAX_WAGONS_COAL_OLD := 3
const MAX_WAGONS_COAL_NEW := 4
const MAX_WAGONS_DIESEL_OLD := 5
const MAX_WAGONS_DIESEL_NEW := 6
const MAX_WAGONS_ELECTRIC := 8

# -- Vagon Kapasiteleri --
const CAPACITY_ECONOMY := 20
const CAPACITY_BUSINESS := 12
const CAPACITY_VIP := 8
const CAPACITY_CARGO := 10  # Kutu

# -- Para Birimi Gösterimi --
const CURRENCY_NAME := "Demir Altını"
const CURRENCY_ABBR := "DA"
