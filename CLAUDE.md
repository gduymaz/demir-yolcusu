# Demir Yolcusu - Proje Calisma Rehberi

## Urun Ozeti
Demir Yolcusu, TCDD hatlari uzerinde gecen mobil tren yonetim oyunudur.
Hedef platform portrait iOS/Android, motor Godot 4.6, dil GDScript, test altyapisi GdUnit4.

## Gercek Durum (16 Subat 2026)
- Faz 1-5 tamamlandi.
- Garage -> Map -> Travel -> Station dongusu calisir durumda.
- Ekonomi, itibar, yakit, yolcu bindirme, sabir ve sefer planlama sistemleri aktif.
- Ege ana hatti rota verisi (Izmir - Denizli) entegre.
- Test durumu: 271/271 gecer.

## Kod Yapisi
```text
src/
  config/       # constants.gd, balance.gd
  entities/     # locomotive_data, wagon_data, train_config, route_data
  systems/      # economy, reputation, fuel, boarding, patience, trip_planner
  managers/     # game_manager, player_inventory
  scenes/       # garage, map, travel, station
  events/       # event_bus
  factories/    # passenger_factory
  data/         # tcdd_full_reference.json
tests/          # entities/systems/managers/events testleri
```

## Calisma Kurali
1. Once ilgili testleri yaz veya guncelle.
2. En kucuk kod degisikligiyle testi gecir.
3. Refactor yap, tekrar test et.
4. Degisiklikte davranis farkini net raporla.

## Teknik Oncelikler
1. Yakit kurallarinda oyun kurali tutarliligi (yetersiz yakitla ilerleme kontrolu).
2. Trip planner'da stale state risklerinin temizlenmesi.
3. Save/load katmaninin production seviyesinde tamamlanmasi.
4. Pixel art pipeline ile placeholder -> production gecisi.

## Hedef Sonraki Milestone
Faz 6:
- Save/load butunlugu + migration altyapisi
- Ekonomi denge iterasyonu
- Mobil performans olcum ve optimizasyon turu
