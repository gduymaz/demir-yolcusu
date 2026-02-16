## Merkezi sinyal sistemi (Autoload).
## Tüm oyun olayları burada tanımlanır.
## Sistemler birbirini doğrudan bilmez — EventBus üzerinden haberleşir.
extends Node


# -- Yolcu olayları --
signal passenger_boarded(passenger_data: Dictionary, wagon_id: int)
signal passenger_lost(passenger_data: Dictionary, station_id: String)
signal passenger_arrived(passenger_data: Dictionary, station_id: String)

# -- Ekonomi olayları --
signal money_changed(old_value: int, new_value: int, reason: String)
signal money_earned(amount: int, source: String)
signal money_spent(amount: int, reason: String)

# -- İtibar olayları --
signal reputation_changed(old_value: float, new_value: float)

# -- Yakıt olayları --
signal fuel_changed(percentage: float)
signal fuel_low(locomotive_id: String, percentage: float)
signal fuel_empty(locomotive_id: String)

# -- Sefer olayları --
signal trip_started(route_data: Dictionary)
signal trip_completed(trip_summary: Dictionary)
signal station_arrived(station_id: String)

# -- Görev olayları --
signal quest_started(quest_id: String)
signal quest_completed(quest_id: String)

# -- Rastgele olaylar --
signal random_event_triggered(event_data: Dictionary)

# -- UI olayları --
signal hud_update_requested()
signal dialog_requested(dialog_data: Dictionary)
