## Ekonomi denge değerleri.
## Playtest sırasında sık değişebilir. Tüm oynanış ayarları burada.
class_name Balance
extends RefCounted


# ==========================================================
# EKONOMI
# ==========================================================

## Oyun başlangıç bakiyesi (DA)
const STARTING_MONEY := 500

## Bilet taban fiyatı (1 km için DA)
const TICKET_BASE_PRICE := 2

## Mesafe kademeli fiyat çarpanları
const TICKET_MULTIPLIER_SHORT := 1.0   # 0-100 km
const TICKET_MULTIPLIER_MEDIUM := 1.5  # 100-300 km
const TICKET_MULTIPLIER_LONG := 2.0    # 300+ km

## Yolcu tipi ücret çarpanları
const FARE_MULTIPLIER_NORMAL := 1.0
const FARE_MULTIPLIER_VIP := 3.0
const FARE_MULTIPLIER_STUDENT := 0.5   # %50 indirim
const FARE_MULTIPLIER_ELDERLY := 0.7   # %30 indirim


# ==========================================================
# İTİBAR
# ==========================================================

## İtibar puan sınırları
const REPUTATION_MIN := 0.0
const REPUTATION_MAX := 5.0

## Başlangıç itibarı
const REPUTATION_STARTING := 2.5

## İtibar düşüş çarpanı (asimetrik: artar hızlı, düşer yavaş)
const REPUTATION_LOSS_MULTIPLIER := 0.5

## Yolcu başına itibar puanları
const REPUTATION_PER_PASSENGER_DELIVERED := 0.1
const REPUTATION_PER_PASSENGER_LOST := -0.2  # ×0.5 uygulanmadan önceki değer

## İtibar → yıldız dönüşümü (direkt: 5.0 puan = 5 yıldız)
## Yarım yıldız dahil: 2.5 = 2.5 yıldız


# ==========================================================
# SABIR (Patience)
# ==========================================================

## Baz sabır süresi (saniye)
const PATIENCE_BASE := 30.0

## Yolcu tipi sabır çarpanları
const PATIENCE_MULTIPLIER_NORMAL := 1.0
const PATIENCE_MULTIPLIER_VIP := 0.5     # Düşük sabır
const PATIENCE_MULTIPLIER_STUDENT := 1.5  # Yüksek sabır
const PATIENCE_MULTIPLIER_ELDERLY := 1.0  # Normal sabır


# ==========================================================
# YAKIT
# ==========================================================

## Baz yakıt tüketimi (birim/km)
const FUEL_CONSUMPTION_COAL_OLD := 3.0
const FUEL_CONSUMPTION_COAL_NEW := 2.5
const FUEL_CONSUMPTION_DIESEL_OLD := 2.0
const FUEL_CONSUMPTION_DIESEL_NEW := 1.5
const FUEL_CONSUMPTION_ELECTRIC := 1.0

## Yakıt deposu kapasitesi
const FUEL_TANK_COAL_OLD := 300.0
const FUEL_TANK_COAL_NEW := 400.0
const FUEL_TANK_DIESEL_OLD := 500.0
const FUEL_TANK_DIESEL_NEW := 600.0
const FUEL_TANK_ELECTRIC := 800.0

## Düşük yakıt uyarı eşiği (yüzde)
const FUEL_LOW_THRESHOLD := 25.0
const FUEL_CRITICAL_THRESHOLD := 10.0

## Yakıt birim fiyatı (DA / birim)
const FUEL_UNIT_PRICE := 1.0

## Vagon başına ek yakıt çarpanı
const FUEL_PER_WAGON_MULTIPLIER := 0.1


# ==========================================================
# LOKOMOTİF
# ==========================================================

## Lokomotif baz hızları (km/saat)
const LOCOMOTIVE_SPEED_COAL_OLD := 60.0
const LOCOMOTIVE_SPEED_COAL_NEW := 75.0
const LOCOMOTIVE_SPEED_DIESEL_OLD := 80.0
const LOCOMOTIVE_SPEED_DIESEL_NEW := 100.0
const LOCOMOTIVE_SPEED_ELECTRIC := 120.0

## Lokomotif fiyatları (DA)
const LOCOMOTIVE_COST_COAL_OLD := 200
const LOCOMOTIVE_COST_COAL_NEW := 500
const LOCOMOTIVE_COST_DIESEL_OLD := 1000
const LOCOMOTIVE_COST_DIESEL_NEW := 2000
const LOCOMOTIVE_COST_ELECTRIC := 5000


# ==========================================================
# VAGON FİYATLARI
# ==========================================================

## Vagon satın alma fiyatları (DA)
const WAGON_COST_ECONOMY := 100
const WAGON_COST_BUSINESS := 200
const WAGON_COST_VIP := 350
const WAGON_COST_DINING := 150
const WAGON_COST_CARGO := 80

## Vagon ağırlığı (basitleştirilmiş, ton)
const WAGON_WEIGHT := 15.0


# ==========================================================
# DURAK ZAMANLAMA
# ==========================================================

## Baz durak süreleri constants.gd'de tanımlı
## Burada sadece zorluk çarpanları

## Yolcu indirme animasyon süresi (saniye)
const PASSENGER_ALIGHT_DURATION := 1.5

## Yolcu bindirme animasyon süresi (saniye)
const PASSENGER_BOARD_DURATION := 1.0
