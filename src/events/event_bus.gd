## Module: event_bus.gd
## Restored English comments for maintainability and i18n coding standards.

extends Node

@warning_ignore("unused_signal")
signal passenger_boarded(passenger_data: Dictionary, wagon_id: int)
@warning_ignore("unused_signal")
signal passenger_lost(passenger_data: Dictionary, station_id: String)
@warning_ignore("unused_signal")
signal passenger_arrived(passenger_data: Dictionary, station_id: String)

@warning_ignore("unused_signal")
signal money_changed(old_value: int, new_value: int, reason: String)
@warning_ignore("unused_signal")
signal money_earned(amount: int, source: String)
@warning_ignore("unused_signal")
signal money_spent(amount: int, reason: String)

@warning_ignore("unused_signal")
signal reputation_changed(old_value: float, new_value: float)

@warning_ignore("unused_signal")
signal fuel_changed(percentage: float)
@warning_ignore("unused_signal")
signal fuel_low(locomotive_id: String, percentage: float)
@warning_ignore("unused_signal")
signal fuel_empty(locomotive_id: String)

@warning_ignore("unused_signal")
signal trip_started(route_data: Dictionary)
@warning_ignore("unused_signal")
signal trip_completed(trip_summary: Dictionary)
@warning_ignore("unused_signal")
signal station_arrived(station_id: String)

@warning_ignore("unused_signal")
signal quest_started(quest_id: String)
@warning_ignore("unused_signal")
signal quest_progress(quest_id: String, current: int, target: int)
@warning_ignore("unused_signal")
signal quest_completed(quest_id: String)

@warning_ignore("unused_signal")
signal random_event_triggered(event_data: Dictionary)

@warning_ignore("unused_signal")
signal cargo_loaded(cargo_data: Dictionary)
@warning_ignore("unused_signal")
signal cargo_delivered(cargo_data: Dictionary, station_id: String)
@warning_ignore("unused_signal")
signal cargo_expired(cargo_data: Dictionary)

@warning_ignore("unused_signal")
signal hud_update_requested()
@warning_ignore("unused_signal")
signal dialog_requested(dialog_data: Dictionary)
