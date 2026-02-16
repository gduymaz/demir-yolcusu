# Demir Yolcusu — Technical Architecture Document

**Versiyon:** 1.0  
**Tarih:** Şubat 2026

---

## 1. Teknoloji Stack

| Bileşen | Seçim | Neden |
|---------|-------|-------|
| Motor | Godot 4.3+ Stable | 2D/isometric için ideal, açık kaynak, mobil export olgun |
| Dil | GDScript | Godot-native, hızlı prototipleme, Python benzeri |
| Test | GdUnit4 | GDScript için idiyomatik, TDD desteği, Godot 4 uyumlu |
| Veri (config) | SQLite + Godot Resource | SQLite sorgulama gücü + .tres runtime performans |
| Veri (save) | SQLite | Tek dosya, 3 slot, güçlü sorgulama |
| Versiyon | Git + GitHub | Standart, Godot .gitignore |
| CI/CD | GitHub Actions | Otomatik test + Godot export build |
| Platform | iOS / Android | Godot export templates |

---

## 2. Proje Yapısı

```
demir_yolcusu/
├── project.godot
├── CLAUDE.md
├── src/
│   ├── entities/              # Oyun nesneleri
│   │   ├── passenger.gd       # Yolcu entity
│   │   ├── locomotive.gd      # Lokomotif entity
│   │   ├── wagon.gd           # Vagon entity
│   │   ├── station.gd         # Durak entity
│   │   └── cargo.gd           # Kargo entity
│   ├── components/            # Yeniden kullanılabilir davranışlar
│   │   ├── patience.gd        # Sabır barı (yolcu)
│   │   ├── fuel_tank.gd       # Yakıt deposu (lokomotif)
│   │   ├── capacity.gd        # Kapasite (vagon)
│   │   ├── draggable.gd       # Sürüklenebilirlik (yolcu)
│   │   ├── cleanliness.gd     # Temizlik durumu (vagon)
│   │   └── upgradeable.gd     # Yükseltme durumu
│   ├── systems/               # Mantık işlemcileri
│   │   ├── passenger_system.gd    # Yolcu üretimi ve yönetimi
│   │   ├── boarding_system.gd     # Bindirme/indirme mantığı
│   │   ├── economy_system.gd      # Para kazanma/harcama
│   │   ├── fuel_system.gd         # Yakıt tüketim/ikmal
│   │   ├── reputation_system.gd   # İtibar hesaplama
│   │   ├── difficulty_system.gd   # Dinamik zorluk ayarı
│   │   ├── quest_system.gd        # Görev zinciri yönetimi
│   │   ├── event_system.gd        # Rastgele olay tetikleme
│   │   ├── cargo_system.gd        # Kargo mantığı
│   │   └── save_system.gd         # Kaydetme/yükleme
│   ├── scenes/                # Godot sahneleri
│   │   ├── main_menu/
│   │   ├── map/
│   │   ├── garage/
│   │   ├── station/
│   │   ├── travel/
│   │   └── summary/
│   ├── managers/              # Tekil yöneticiler (autoload)
│   │   ├── audio_manager.gd
│   │   ├── scene_manager.gd
│   │   ├── input_manager.gd
│   │   └── game_manager.gd
│   ├── ui/                    # HUD, menüler, diyaloglar
│   │   ├── hud/
│   │   ├── panels/
│   │   └── dialogs/
│   ├── data/                  # Veri tanımları
│   │   ├── game_data.db       # SQLite (durak, lokomotif, görev, eğitici)
│   │   ├── locomotives.tres   # Godot Resource
│   │   ├── wagons.tres
│   │   └── quests.tres
│   ├── events/                # Event bus + custom event tipleri
│   │   ├── event_bus.gd       # Merkezi sinyal sistemi (autoload)
│   │   └── game_events.gd     # Olay sabitleri
│   ├── factories/             # Entity oluşturma
│   │   ├── passenger_factory.gd
│   │   ├── locomotive_factory.gd
│   │   └── wagon_factory.gd
│   ├── utils/                 # Yardımcı fonksiyonlar
│   │   ├── math_utils.gd
│   │   └── iso_utils.gd      # İsometrik dönüşüm
│   └── config/                # Sabitler, ayarlar
│       ├── constants.gd       # Genel sabitler
│       ├── balance.gd         # Ekonomi denge değerleri
│       └── settings.gd        # Oyuncu ayarları
├── tests/                     # src/ yapısını aynalar
│   ├── entities/
│   │   ├── test_passenger.gd
│   │   ├── test_locomotive.gd
│   │   └── test_wagon.gd
│   ├── systems/
│   │   ├── test_economy_system.gd
│   │   ├── test_boarding_system.gd
│   │   ├── test_fuel_system.gd
│   │   ├── test_reputation_system.gd
│   │   └── test_difficulty_system.gd
│   └── utils/
│       └── test_iso_utils.gd
├── assets/
│   ├── sprites/
│   │   ├── placeholder/
│   │   ├── trains/
│   │   ├── passengers/
│   │   ├── stations/
│   │   └── ui/
│   ├── tilesets/
│   ├── audio/
│   │   ├── music/
│   │   └── sfx/
│   ├── fonts/
│   └── reference/             # Retro asset referansları
├── docs/
│   ├── design/GDD.md
│   ├── technical/ARCHITECTURE.md
│   └── art/STYLE_GUIDE.md
└── addons/
    └── gdUnit4/               # Test framework
```

---

## 3. Mimari Desenler

### 3.1 Entity-Component (Kompozisyon)

Godot'un Node/Scene sistemi doğal kompozisyon sağlar. Her entity bir Scene (tscn) olarak tanımlanır, alt-node'ları component olarak eklenir.

```
Passenger (Node2D)
  ├── Sprite2D               # Görsel
  ├── PatienceComponent       # Sabır barı
  ├── DraggableComponent      # Sürüklenebilirlik
  ├── Label                   # Hedef/ücret bilgisi
  └── AnimationPlayer         # Animasyonlar

Locomotive (Node2D)
  ├── AnimatedSprite2D        # 8 yönlü sprite
  ├── FuelTankComponent       # Yakıt deposu
  ├── UpgradeableComponent    # Yükseltme durumu
  └── CollisionShape2D        # Çarpışma

Wagon (Node2D)
  ├── Sprite2D                # Görsel
  ├── CapacityComponent       # Koltuk/kutu kapasitesi
  ├── CleanlinessComponent    # Temizlik durumu
  └── UpgradeableComponent    # Yükseltme durumu
```

### 3.2 State Machine (FSM)

Entity davranışları ve sahne yönetimi için:

| State Machine | Durumlar |
|--------------|----------|
| PassengerFSM | Waiting → Dragged → Boarding → Seated → Alighting → Gone |
| TrainFSM | InGarage → Departing → Traveling → Arriving → AtStation |
| GameFSM | MainMenu → MapView → GarageSetup → StationPlay → TravelView → Summary |
| QuestFSM | Locked → Available → Active → Completed |

```gdscript
# Basit FSM şablonu
class_name StateMachine
extends Node

var current_state: String = ""
var states: Dictionary = {}

func transition_to(new_state: String) -> void:
    if current_state != "":
        _exit_state(current_state)
    current_state = new_state
    _enter_state(new_state)

func _enter_state(state: String) -> void:
    pass  # Override

func _exit_state(state: String) -> void:
    pass  # Override
```

### 3.3 Event Bus (Observer)

Godot Signal'ları + merkezi EventBus autoload. Sistemler arası gevşek bağlantı:

```gdscript
# src/events/event_bus.gd (Autoload)
extends Node

# Yolcu olayları
signal passenger_boarded(passenger_data: Dictionary, wagon_id: int)
signal passenger_lost(passenger_data: Dictionary, station_id: String)
signal passenger_arrived(passenger_data: Dictionary, station_id: String)

# Ekonomi olayları
signal money_changed(old_value: int, new_value: int, reason: String)
signal money_earned(amount: int, source: String)
signal money_spent(amount: int, reason: String)

# İtibar olayları
signal reputation_changed(old_value: float, new_value: float)

# Yakıt olayları
signal fuel_changed(percentage: float)
signal fuel_low(locomotive_id: String, percentage: float)
signal fuel_empty(locomotive_id: String)

# Sefer olayları
signal trip_started(route_data: Dictionary)
signal trip_completed(trip_summary: Dictionary)
signal station_arrived(station_id: String)

# Görev olayları
signal quest_completed(quest_id: String)
signal quest_started(quest_id: String)

# Rastgele olaylar
signal breakdown_occurred(train_id: String, breakdown_type: String)
signal random_event_triggered(event_data: Dictionary)

# UI olayları
signal hud_update_requested()
signal dialog_requested(dialog_data: Dictionary)
```

### 3.4 Factory Pattern

Entity oluşturma = Factory üzerinden, asla doğrudan new() ile değil:

```gdscript
# src/factories/passenger_factory.gd
class_name PassengerFactory

enum PassengerType { NORMAL, VIP, STUDENT, ELDERLY }

static func create(type: PassengerType, destination: String, station_popularity: float) -> Dictionary:
    var passenger = {
        "id": _generate_id(),
        "type": type,
        "destination": destination,
        "fare": _calculate_fare(type, destination),
        "patience": _calculate_patience(type),
        "state": "waiting"
    }
    return passenger

static func _calculate_fare(type: PassengerType, destination: String) -> int:
    var base_fare = _get_distance_fare(destination)
    match type:
        PassengerType.STUDENT:
            return int(base_fare * 0.5)
        PassengerType.ELDERLY:
            return int(base_fare * 0.7)
        PassengerType.VIP:
            return int(base_fare * 3.0)
        _:
            return base_fare

static func _calculate_patience(type: PassengerType) -> float:
    match type:
        PassengerType.VIP:
            return 0.5   # Düşük sabır
        PassengerType.STUDENT:
            return 1.5   # Yüksek sabır
        _:
            return 1.0   # Normal sabır
```

### 3.5 Repository Pattern

Veri erişimi soyutlaması:

```gdscript
# StationRepository → SQLite'tan durak verileri
# SaveRepository    → SQLite'a oyun kaydetme/yükleme
# ConfigRepository  → .tres'ten lokomotif/vagon config

# Örnek:
class_name StationRepository

var db: SQLite

func get_station(id: String) -> Dictionary:
    db.query("SELECT * FROM stations WHERE id = ?", [id])
    return db.query_result[0] if db.query_result.size() > 0 else {}

func get_stations_for_route(route_id: String) -> Array:
    db.query("SELECT * FROM stations WHERE route_id = ? ORDER BY km_position", [route_id])
    return db.query_result
```

### 3.6 Command Pattern

Giriş yönetimi için — dokunma olaylarını komutlara çevirir:

```gdscript
# DragPassengerCommand — yolcu sürükleme başla/bitir
# SelectWagonCommand — vagon seçimi
# StartTripCommand — sefer başlatma
# BoardPassengerCommand — yolcuyu vagona yerleştir
```

---

## 4. Veri Mimarisi

### 4.1 SQLite: game_data.db (Config — Read-Only)

Oyun config verileri + durak bilgileri:

| Tablo | İçerik | Örnek Alanlar |
|-------|--------|---------------|
| stations | Tüm durak bilgileri | id, name, region, km, size, popularity, lat, lng |
| routes | Hat tanımları | id, name, region, difficulty, station_ids |
| locomotives | Lokomotif modelleri | id, name, fuel_type, speed, capacity, cost |
| wagons | Vagon modelleri | id, type, capacity, comfort, cost |
| quests | Görev zincirleri | id, route_id, title, description, conditions, rewards |
| educational | Eğitici içerik | station_id, category, title, content_tr |
| events | Rastgele olay tanımları | id, type, probability, effects |

### 4.2 SQLite: save_slot_N.db (Save — Read/Write)

Her save slotu ayrı SQLite dosyası (save_slot_1.db, save_slot_2.db, save_slot_3.db):

| Tablo | İçerik |
|-------|--------|
| player | Para (DA), itibar, toplam istatistikler (sefer, yolcu, km, kazanç) |
| inventory_locomotives | Sahip olunan lokomotifler + upgrade durumu |
| inventory_wagons | Sahip olunan vagonlar + upgrade durumu |
| active_train | Aktif tren konfigürasyonu (lokomotif + vagon sırası) |
| unlocked_routes | Açılmış hatlar |
| quest_progress | Görev ilerlemesi (quest_id, status, progress) |
| achievements | Başarım durumu (achievement_id, unlocked, date) |
| shops | Dükkan seviyeleri ve gelirleri (station_id, shop_type, level) |
| contracts | Aktif sözleşmeler (contract_id, status, deadline) |
| settings | Oyuncu tercihleri (volume, haptic, font_size, difficulty) |
| trip_history | Son sefer geçmişi (dinamik zorluk için son 3 sefer) |

### 4.3 Godot Resource (.tres)

Runtime nesneler için typed Resource'lar:

```gdscript
# src/data/locomotive_data.gd
class_name LocomotiveData
extends Resource

@export var id: String
@export var display_name: String
@export var fuel_type: int  # 0=coal, 1=diesel, 2=electric
@export var base_speed: float
@export var max_wagons: int
@export var fuel_efficiency: float
@export var base_cost: int
@export var sprite_path: String
@export var smoke_color: Color
```

---

## 5. Sistem Etkileşimleri

### 5.1 Sefer Yaşam Döngüsü

1. **GarageScene:** Oyuncu lokomotif + vagon seçer, dizilim yapar
2. **MapScene:** Oyuncu başlangıç/bitiş durağı seçer, ön izleme görür
3. **FuelSystem:** Minimum yakıt otomatik ikmal edilir
4. **StationScene:** Her durakta BoardingSystem aktif — yolcu indirme/bindirme
5. **TravelScene:** Duraklar arası animasyon + opsiyonel mini oyun
6. **EventSystem:** Rastgele olaylar kontrol edilir (arıza, hava, yolcu)
7. **SummaryScene:** Gelir/gider listesi + net kazanç gösterilir
8. **SaveSystem:** Otomatik kaydetme (her durakta + sefer sonunda)

### 5.2 Ekonomi Akışı

Tüm para işlemleri EconomySystem üzerinden geçer:

```gdscript
# Kullanım
EconomySystem.earn(amount, source)   # → EventBus.money_earned + money_changed
EconomySystem.spend(amount, reason)  # → return bool (yeterli mi?) + EventBus.money_spent
EconomySystem.get_balance() -> int
EconomySystem.can_afford(amount) -> bool
EconomySystem.get_trip_summary() -> Dictionary
```

### 5.3 İtibar Akışı

```gdscript
# Asimetrik: Artar hızlı, düşer yavaş
ReputationSystem.add(points, reason)     # Direkt ekleme
ReputationSystem.remove(points, reason)  # × 0.5 çarpanı ile (yavaş düşüş)
ReputationSystem.get_stars() -> float    # 0.0 - 5.0 (yarım yıldız)
ReputationSystem.meets_requirement(min_stars) -> bool
```

### 5.4 Dinamik Zorluk Akışı

```gdscript
# Son 3 seferin performansına göre 4 parametre ayarlanır:
DifficultySystem.get_time_multiplier() -> float      # Durak süre çarpanı
DifficultySystem.get_patience_multiplier() -> float   # Yolcu sabır çarpanı
DifficultySystem.get_breakdown_chance() -> float       # Arıza olasılığı
DifficultySystem.get_income_multiplier() -> float      # Gelir çarpanı
DifficultySystem.record_trip(trip_data: Dictionary)    # Sefer sonucu kaydet
```

---

## 6. İsometrik Sistem

### 6.1 Koordinat Dönüşümü

32x32 tile, 2:1 isometrik oran:

```gdscript
# src/utils/iso_utils.gd
class_name IsoUtils

const TILE_WIDTH: int = 32
const TILE_HEIGHT: int = 16  # TILE_WIDTH / 2

static func grid_to_screen(grid_pos: Vector2i) -> Vector2:
    var x = (grid_pos.x - grid_pos.y) * TILE_WIDTH / 2
    var y = (grid_pos.x + grid_pos.y) * TILE_HEIGHT / 2
    return Vector2(x, y)

static func screen_to_grid(screen_pos: Vector2) -> Vector2i:
    var x = (screen_pos.x / (TILE_WIDTH / 2.0) + screen_pos.y / (TILE_HEIGHT / 2.0)) / 2.0
    var y = (screen_pos.y / (TILE_HEIGHT / 2.0) - screen_pos.x / (TILE_WIDTH / 2.0)) / 2.0
    return Vector2i(roundi(x), roundi(y))
```

### 6.2 Tren Sprite Sistemi

8 yönlü sprite: N, NE, E, SE, S, SW, W, NW. AnimatedSprite2D ile yöne göre frame seçimi. Vagonlar fizik bazlı eklemle bağlı — virajda bağımsız açılanır.

### 6.3 Render Sıralama

Y-sort: Godot'un yerleşik y-sort özelliği ile isometrik derinlik. CanvasItem.z_index = y pozisyonuna bağlı dinamik.

---

## 7. Kaydetme Sistemi

### 7.1 Otomatik Kaydetme
- **Tetikleyici:** Her durağa varış + sefer sonu + tur bitimi
- **Format:** SQLite (save_slot_1.db, save_slot_2.db, save_slot_3.db)
- **Performans:** Background thread'de yazım, oyun duraklatmaz

### 7.2 Save Data Yapısı
- **Player state:** Para, itibar, toplam istatistikler
- **Inventory:** Lokomotif listesi + upgrade seviyeleri, vagon listesi + upgrade seviyeleri
- **Progress:** Açık hatlar, görev ilerlemesi, başarım durumları
- **World state:** Dükkan seviyeleri, sözleşme durumları
- **Settings:** Ses, haptic, font boyutu, zorluk tercihleri
- **Trip history:** Son 3 sefer (dinamik zorluk için)

### 7.3 Veri Bütünlüğü
SQLite transaction'lar ile atomik yazım. Bozulma durumunda son geçerli save'e geri dönüş.

---

## 8. Test Stratejisi

### 8.1 TDD Workflow

Her özellik için katı RED → GREEN → REFACTOR döngüsü:

1. **RED:** Beklenen davranışı tanımlayan başarısız testler yaz
2. **GREEN:** Testleri geçirecek minimum kodu yaz
3. **REFACTOR:** Testler yeşilken kodu temizle

### 8.2 Test Framework: GdUnit4

```gdscript
# tests/systems/test_economy_system.gd
extends GdUnitTestSuite

var economy: EconomySystem

func before_test() -> void:
    economy = EconomySystem.new()

func after_test() -> void:
    economy.free()

func test_EconomySystem_Earn_ValidAmount_ShouldIncreaseBalance() -> void:
    economy.set_balance(100)
    economy.earn(50, "ticket")
    assert_int(economy.get_balance()).is_equal(150)

func test_EconomySystem_Spend_InsufficientFunds_ShouldReturnFalse() -> void:
    economy.set_balance(30)
    var result = economy.spend(50, "fuel")
    assert_bool(result).is_false()
    assert_int(economy.get_balance()).is_equal(30)

func test_EconomySystem_Spend_SufficientFunds_ShouldDecrease() -> void:
    economy.set_balance(100)
    var result = economy.spend(40, "fuel")
    assert_bool(result).is_true()
    assert_int(economy.get_balance()).is_equal(60)
```

### 8.3 Test Kapsamı

| Sistem | Örnek Testler |
|--------|---------------|
| EconomySystem | Earn/Spend, yetersiz bakiye, bilet fiyatlandırma, indirimler (öğrenci %50, yaşlı %30) |
| BoardingSystem | Doğru vagon, yanlış vagon engeli, kapasite aşımı, indirme sırası |
| FuelSystem | Tüketim hesaplama (hız+ağırlık+arazi), boş tank davranışı, otomatik ikmal |
| ReputationSystem | Artış/azalış asimetrisi (×0.5 düşüş), yıldız hesaplama, kilit kontrolü |
| PassengerFactory | Tip üretimi, durak bazı dağılım, sabır parametreleri, ücret hesaplama |
| DifficultySystem | Son 3 sefer bazlı ayarlama, parametre sınırları, edge case'ler |
| CargoSystem | Zaman limiti, geç teslim azalan ödeme, kapasite kontrolü |
| IsoUtils | Grid ↔ Screen dönüşüm doğruluğu, edge case koordinatlar |
| SaveSystem | Kaydet/yükle bütünlüğü, slot yönetimi, bozulma kurtarma |

### 8.4 Test DIŞI Bırakılanlar
- Render çıktısı (piksel renkleri, shader, draw call)
- Godot motoru iç işlevleri
- Platform-özel API'ler
- Ses çalma

---

## 9. Yerelleştirme (i18n)

Baştan altyapı kurulur, MVP'de yalnızca Türkçe.

- Godot'un yerleşik TranslationServer + CSV translation dosyaları
- Tüm UI metinleri `tr()` fonksiyonu ile sarılır
- Durak isimleri ve eğitici içerik SQLite'ta dile göre tablo
- Font: Türkçe karakter desteği zorunlu (ş, ğ, ü, ö, ç, ı, İ, Ş, Ğ, Ü, Ö, Ç)

---

## 10. Performans Hedefleri

| Metrik | Hedef | Strateji |
|--------|-------|----------|
| FPS | 30 sabit | Tur bazlı = düşük GPU yükü, 30 yeterli |
| Bellek | <200 MB RAM | Object pooling, lazy asset yükleme |
| Başlatma | <3 saniye | Splash + hafif initial load |
| Save süresi | <500ms | Background thread SQLite write |
| Pil ömrü | 3+ saat sürekli oyun | 30 FPS + minimal particle, düşük GPU |
| APK/IPA | 300-500 MB | Tüm asset'ler dahil, sıkıştırma |

### Optimizasyon Stratejileri
- **Object pooling:** Sık oluşturulan/yok edilen nesneler (yolcu sprite, efekt)
- **Lazy loading:** Sadece aktif hat/durak asset'leri bellekte
- **Sprite atlas:** Tüm 32x32 tile'lar tek atlas'ta
- **Occlusion:** Ekran dışı entity'ler deaktif

---

## 11. project.godot Yapılandırması

```ini
[application]
config/name="Demir Yolcusu"
run/main_scene="res://src/scenes/main_menu/main_menu.tscn"
config/features=PackedStringArray("4.3")

[display]
window/size/viewport_width=540
window/size/viewport_height=960
window/handheld/orientation="portrait"
window/stretch/mode="canvas_items"
window/stretch/aspect="keep_width"

[rendering]
textures/canvas_textures/default_texture_filter=0
renderer/rendering_method="mobile"

[autoload]
EventBus="*res://src/events/event_bus.gd"
GameManager="*res://src/managers/game_manager.gd"
AudioManager="*res://src/managers/audio_manager.gd"

[input]
touch_tap={
"deadzone": 0.5,
"events": [Object(InputEventScreenTouch,"position":Vector2(0,0),"pressed":true)]
}

[internationalization]
locale/fallback="tr"
```
