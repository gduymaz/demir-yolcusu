## Module: constants.gd
## Restored English comments for maintainability and i18n coding standards.

class_name Constants
extends RefCounted

enum PassengerType {
	NORMAL,
	VIP,
	STUDENT,
	ELDERLY,
}

enum WagonType {
	ECONOMY,
	BUSINESS,
	VIP,
	DINING,
	CARGO,
}

enum FuelType {
	COAL_OLD,
	COAL_NEW,
	DIESEL_OLD,
	DIESEL_NEW,
	ELECTRIC,
}

enum StationSize {
	SMALL,
	MEDIUM,
	LARGE,
}

enum PassengerState {
	WAITING,
	DRAGGED,
	BOARDING,
	SEATED,
	ALIGHTING,
	GONE,
}

enum TrainState {
	IN_GARAGE,
	DEPARTING,
	TRAVELING,
	ARRIVING,
	AT_STATION,
}

enum QuestState {
	LOCKED,
	AVAILABLE,
	ACTIVE,
	COMPLETED,
}

enum QuestType {
	TRANSPORT,
	EXPLORE,
	CARGO_DELIVERY,
}

enum RandomEventType {
	TECHNICAL,
	PASSENGER,
	ECONOMIC,
}

enum RandomEventTrigger {
	ON_TRAVEL,
	ON_STATION_ARRIVE,
	ON_TRIP_START,
}

enum CargoStatus {
	AVAILABLE,
	LOADED,
	DELIVERED,
	EXPIRED,
}

const TICKET_DISTANCE_SHORT := 100
const TICKET_DISTANCE_MEDIUM := 300

const STATION_TIME_SMALL := 10.0
const STATION_TIME_MEDIUM := 15.0
const STATION_TIME_LARGE := 20.0

const DIFFICULTY_EASY := 1.5
const DIFFICULTY_NORMAL := 1.0
const DIFFICULTY_HARD := 0.7

const MAX_WAGONS_COAL_OLD := 3
const MAX_WAGONS_COAL_NEW := 4
const MAX_WAGONS_DIESEL_OLD := 5
const MAX_WAGONS_DIESEL_NEW := 6
const MAX_WAGONS_ELECTRIC := 8

const CAPACITY_ECONOMY := 20
const CAPACITY_BUSINESS := 12
const CAPACITY_VIP := 8
const CAPACITY_CARGO := 10

const CURRENCY_NAME := "IRON_CURRENCY"
const CURRENCY_ABBR := "DA"
