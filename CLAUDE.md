# Demir Yolcusu — Proje Bağlamı

## Proje Nedir?
Türkiye'nin gerçek TCDD demiryolu hatlarında geçen, isometrik pixel art, mobil tren yönetim oyunu.
10+ yaş hedef kitle, tamamen ücretsiz, reklamsız. Eğitici macera hikayesi ile Türk coğrafyası/tarihi/kültürü öğretir.

## Teknoloji Stack
- **Motor:** Godot 4.3+ Stable
- **Dil:** GDScript
- **Test:** GdUnit4
- **Veri:** SQLite (save + game data) + Godot Resource (.tres, runtime)
- **Platform:** iOS / Android (portrait)
- **Tile:** 32x32 isometrik pixel art (2:1 oran)

## Proje Yapısı
```
src/
├── entities/        # Oyun nesneleri (Passenger, Locomotive, Wagon, Station, Cargo)
├── components/      # Yeniden kullanılabilir davranışlar (Patience, FuelTank, Draggable)
├── systems/         # Mantık işlemcileri (BoardingSystem, EconomySystem, FuelSystem)
├── scenes/          # Godot sahneleri (main_menu, map, garage, station, travel, summary)
├── managers/        # Tekil yöneticiler (AudioManager, SceneManager, InputManager)
├── ui/              # HUD, paneller, diyaloglar
├── data/            # SQLite DB + .tres config dosyaları
├── events/          # EventBus (Godot Signals) + custom event tipleri
├── utils/           # Yardımcı fonksiyonlar (iso_utils, math_utils)
└── config/          # Sabitler, denge değerleri, ayarlar
tests/               # src/ yapısını aynalar
assets/              # Sprite, tileset, ses, font
docs/                # GDD, mimari, stil rehberi
```

## Mimari Kurallar (ZORUNLU)
1. **TDD FIRST**: Her özellik için ÖNCE test yaz (RED), SONRA implement et (GREEN), SONRA temizle (REFACTOR)
2. **Kompozisyon > Kalıtım**: Godot Node/Scene sistemi ile component bazlı yapı
3. **Event Bus**: Sistemler arası iletişim Godot Signal + merkezi EventBus autoload ile
4. **Factory Pattern**: Entity oluşturma SADECE Factory üzerinden, asla direkt new()
5. **State Machine**: Entity davranışları ve sahne yönetimi FSM ile
6. **Repository Pattern**: Veri erişimi SQLite/Resource soyutlaması ile
7. **Tek Sorumluluk**: Bir script = bir iş
8. **Magic Number YOK**: Tüm sayılar config/balance.gd veya config/constants.gd içinde

## Test Kuralları
- Framework: GdUnit4
- Konum: `tests/` klasörü (`src/` yapısını aynalar)
- İsimlendirme: `test_[Entity]_[Method]_[Senaryo]_[BeklenenSonuç]`
- Yapı: Arrange → Act → Assert
- Test EDİLMEZ: Render çıktısı, motor iç işlevleri, ses çalma

## Godot Komutları
```bash
# Projeyi çalıştır
godot --path . --main-run

# Testleri çalıştır (GdUnit4 kurulduktan sonra)
godot --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --run-tests
```

## Geliştirme Akışı (HER ÖZELLİK İÇİN)
1. Özelliğin teknik spec'ini yaz (kısa, 5-10 satır)
2. Testleri yaz (RED — başarısız olmalı)
3. Minimum kodu yaz (GREEN — testler geçmeli)
4. Refactor et (testler hâlâ yeşil)
5. Çalıştır ve test et
6. git commit

## Para Birimi
Demir Altını (DA) — oyun içi tek para birimi

## Mevcut Durum
Proje YENİ başlıyor. Henüz kod yok. Sıfırdan kurulacak.

## Önemli Dokümanlar (MUTLAKA OKU)
- `docs/design/GDD.md` — Tam oyun tasarım belgesi
- `docs/technical/ARCHITECTURE.md` — Teknik mimari
- `docs/art/STYLE_GUIDE.md` — Görsel stil rehberi
- `assets/reference/` — Referans görseller

## Uyarılar
- Bu proje sahibi oyun geliştirme deneyimi YOKTUR — her adımı açıkla
- Godot bilgisi YOKTUR — Godot kavramlarını kısaca açıkla
- ASLA varsayım yapma — belirsiz bir şey varsa sor
- Küçük adımlarla ilerle — her seferinde tek bir sistem/özellik
- Her özellikten sonra çalışan demo göster
