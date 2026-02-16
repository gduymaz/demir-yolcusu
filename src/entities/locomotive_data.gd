## Module: locomotive_data.gd
## Restored English comments for maintainability and i18n coding standards.

class_name LocomotiveData
extends RefCounted

var id: String
var loco_name: String
var fuel_type: Constants.FuelType
var base_speed: float
var max_wagons: int
var fuel_consumption: float
var fuel_tank_capacity: float
var base_cost: int

static var _catalog := {
	"kara_duman": {
		"loco_name_key": "locomotive.kara_duman",
		"fuel_type": Constants.FuelType.COAL_OLD,
		"base_speed": Balance.LOCOMOTIVE_SPEED_COAL_OLD,
		"max_wagons": Constants.MAX_WAGONS_COAL_OLD,
		"fuel_consumption": Balance.FUEL_CONSUMPTION_COAL_OLD,
		"fuel_tank_capacity": Balance.FUEL_TANK_COAL_OLD,
		"base_cost": Balance.LOCOMOTIVE_COST_COAL_OLD,
	},
	"demir_yildizi": {
		"loco_name_key": "locomotive.demir_yildizi",
		"fuel_type": Constants.FuelType.DIESEL_OLD,
		"base_speed": Balance.LOCOMOTIVE_SPEED_DIESEL_OLD,
		"max_wagons": Constants.MAX_WAGONS_DIESEL_OLD,
		"fuel_consumption": Balance.FUEL_CONSUMPTION_DIESEL_OLD,
		"fuel_tank_capacity": Balance.FUEL_TANK_DIESEL_OLD,
		"base_cost": Balance.LOCOMOTIVE_COST_DIESEL_OLD,
	},
	"mavi_simsek": {
		"loco_name_key": "locomotive.mavi_simsek",
		"fuel_type": Constants.FuelType.ELECTRIC,
		"base_speed": Balance.LOCOMOTIVE_SPEED_ELECTRIC,
		"max_wagons": Constants.MAX_WAGONS_ELECTRIC,
		"fuel_consumption": Balance.FUEL_CONSUMPTION_ELECTRIC,
		"fuel_tank_capacity": Balance.FUEL_TANK_ELECTRIC,
		"base_cost": Balance.LOCOMOTIVE_COST_ELECTRIC,
	},
	"demir_yurek": {
		"loco_name_key": "locomotive.demir_yurek",
		"fuel_type": Constants.FuelType.COAL_NEW,
		"base_speed": Balance.LOCOMOTIVE_SPEED_COAL_NEW,
		"max_wagons": Constants.MAX_WAGONS_COAL_NEW,
		"fuel_consumption": Balance.FUEL_CONSUMPTION_COAL_NEW,
		"fuel_tank_capacity": Balance.FUEL_TANK_COAL_NEW,
		"base_cost": Balance.LOCOMOTIVE_COST_DEMIR_YUREK,
	},
	"boz_kaplan": {
		"loco_name_key": "locomotive.boz_kaplan",
		"fuel_type": Constants.FuelType.DIESEL_NEW,
		"base_speed": Balance.LOCOMOTIVE_SPEED_DIESEL_NEW,
		"max_wagons": Constants.MAX_WAGONS_DIESEL_OLD,
		"fuel_consumption": Balance.FUEL_CONSUMPTION_DIESEL_NEW,
		"fuel_tank_capacity": Balance.FUEL_TANK_DIESEL_NEW,
		"base_cost": Balance.LOCOMOTIVE_COST_BOZ_KAPLAN,
	},
}

static func create(loco_id: String) -> LocomotiveData:
	if not _catalog.has(loco_id):
		return null

	var data: Dictionary = _catalog[loco_id]
	var loco := LocomotiveData.new()
	loco.id = loco_id
	loco.loco_name = I18n.t(str(data["loco_name_key"]))
	loco.fuel_type = data["fuel_type"]
	loco.base_speed = data["base_speed"]
	loco.max_wagons = data["max_wagons"]
	loco.fuel_consumption = data["fuel_consumption"]
	loco.fuel_tank_capacity = data["fuel_tank_capacity"]
	loco.base_cost = data["base_cost"]
	return loco

static func get_catalog() -> Dictionary:
	var result := {}
	for loco_id in _catalog:
		result[loco_id] = I18n.t(str(_catalog[loco_id]["loco_name_key"]))
	return result
