# Demir Yolcusu - Teknik Mimari (As-Built)

**Versiyon:** 2.0  
**Tarih:** 16 Subat 2026

## 1. Teknoloji Stack
- Motor: Godot 4.6 Stable
- Dil: GDScript
- Test: GdUnit4
- Hedef Platform: iOS/Android (portrait)
- Veri: Runtime config + JSON referans veri (`src/data/tcdd_full_reference.json`)

## 2. Kod Organizasyonu

```text
src/
  config/
    balance.gd
    constants.gd
  entities/
    locomotive_data.gd
    wagon_data.gd
    train_config.gd
    route_data.gd
  systems/
    economy_system.gd
    reputation_system.gd
    fuel_system.gd
    boarding_system.gd
    patience_system.gd
    trip_planner.gd
  managers/
    game_manager.gd
    player_inventory.gd
  events/
    event_bus.gd
  factories/
    passenger_factory.gd
  scenes/
    garage/
    map/
    travel/
    station/
  data/
    tcdd_full_reference.json

tests/
  entities/
  systems/
  managers/
  events/
```

## 3. Mimari Kararlar

### 3.1 Oyun Durumu
- `GameManager` autoload tum ana sistemleri baslatir ve sahneler arasi paylasilan state'i tutar.
- `EventBus` autoload gevsek bagli haberlesme saglar.

### 3.2 Is Kurali Katmani
- Is kurallari `systems/` altinda tutulur.
- `scenes/` sadece akis, girdi ve sunum tarafini yonetir.
- Bu ayrim testlerin UI bagimsiz yazilmasini saglar.

### 3.3 Veri Katmani
- Entity benzeri veri modelleri (`LocomotiveData`, `WagonData`, `RouteData`, `TrainConfig`) `entities/` altinda.
- Uretim islemleri `PassengerFactory` ile merkezilesir.

### 3.4 Sahne Akisi
- Mevcut ana akis:
  1. `garage_scene`
  2. `map_scene`
  3. `travel_scene`
  4. `station_scene`
  5. tekrar `map_scene`

## 4. Faz Durumu

### Tamamlanan
- Faz 1: Proje altyapisi + EventBus + ilk test duzeni
- Faz 2: Ekonomi / itibar / yakit temel sistemleri
- Faz 3: Yolcu-vagon-bindirme-sabir ve istasyon prototipi
- Faz 4: Garaj, envanter, tren konfigürasyonu
- Faz 5: Harita, rota secimi, sefer planlama, seyir akisi

### Test Durumu
- GdUnit toplam: 271 test
- Son calisma sonucu: 271/271 basarili

## 5. Bilinen Teknik Riskler
1. Yakit yetersizken sefer ilerleme kontrolu davranissal olarak sertlestirilmeli.
2. Trip planner gecersiz secimlerinde stale state temizleme guclendirilmeli.
3. Gercek vagon sayisinin yakit/preview hesaplarina tam yansitilmasi tamamlanmali.

## 6. Faz 6 Hedefi
- Save/load veri butunlugu ve migration
- Ekonomi denge iterasyonlari
- Mobil performans olcumu (fps/memory/load-time)
- Pixel art pipeline ve kalite kontrol standardi

## 7. Gelistirme Standardi
- Test-first zorunlu: RED -> GREEN -> REFACTOR
- Her degisiklikte ilgili testler calistirilir
- Buyuk degisiklikler kucuk, commitlenebilir adimlara bolunur
