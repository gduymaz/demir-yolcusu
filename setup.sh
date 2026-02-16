#!/bin/bash
# ============================================
# 🚂 Demir Yolcusu — Otomatik Proje Kurulumu
# ============================================
# Bu scripti çalıştır: bash setup.sh
# Proje klasöründe tüm yapıyı oluşturur.

set -e

echo "🚂 Demir Yolcusu proje yapısı kuruluyor..."
echo ""

# ---- Temel klasörler ----
echo "📁 Klasör yapısı oluşturuluyor..."

# Claude Code yapısı
mkdir -p .claude/commands
mkdir -p .claude/skills/godot-basics
mkdir -p .claude/skills/game-tdd
mkdir -p .claude/skills/pixel-art-gen
mkdir -p .claude/agents

# Dokümanlar
mkdir -p docs/design
mkdir -p docs/technical
mkdir -p docs/art

# Asset'ler
mkdir -p assets/sprites/placeholder
mkdir -p assets/sprites/trains
mkdir -p assets/sprites/passengers
mkdir -p assets/sprites/stations
mkdir -p assets/sprites/ui
mkdir -p assets/tilesets
mkdir -p assets/audio/music
mkdir -p assets/audio/sfx
mkdir -p assets/fonts
mkdir -p assets/reference

# Kaynak kod
mkdir -p src/entities
mkdir -p src/components
mkdir -p src/systems
mkdir -p src/scenes/main_menu
mkdir -p src/scenes/map
mkdir -p src/scenes/garage
mkdir -p src/scenes/station
mkdir -p src/scenes/travel
mkdir -p src/scenes/summary
mkdir -p src/managers
mkdir -p src/ui/hud
mkdir -p src/ui/panels
mkdir -p src/ui/dialogs
mkdir -p src/data
mkdir -p src/events
mkdir -p src/utils
mkdir -p src/config

# Testler
mkdir -p tests/entities
mkdir -p tests/systems
mkdir -p tests/utils

echo "✅ Klasörler oluşturuldu"

# ---- .gitignore ----
echo "📄 .gitignore oluşturuluyor..."
cat > .gitignore << 'GITIGNORE'
# Godot
.godot/
*.import
export_presets.cfg

# Claude Code kişisel
.claude/settings.local.json

# OS
.DS_Store
Thumbs.db

# IDE
.vscode/
.idea/

# Build
build/
export/
GITIGNORE
echo "✅ .gitignore oluşturuldu"

# ---- CLAUDE.md ----
echo "📄 CLAUDE.md oluşturuluyor..."
cat > CLAUDE.md << 'CLAUDEMD'
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
CLAUDEMD
echo "✅ CLAUDE.md oluşturuldu"

# ---- SKILLS ----
echo "📄 Skills oluşturuluyor..."

cat > .claude/skills/godot-basics/SKILL.md << 'SKILL1'
---
name: godot-basics
description: "Godot 4 motor bilgisi. GDScript sözdizimi, Node/Scene sistemi, Signal kullanımı, TileMap, AnimatedSprite2D, isometrik kurulum."
---

# Godot 4 Temelleri — Demir Yolcusu İçin

## Godot Konseptleri
- **Node**: Her şeyin temel yapı taşı
- **Scene**: Node'ların bir araya geldiği dosya (.tscn)
- **Signal**: Node'lar arası mesajlaşma (observer pattern)
- **Autoload**: Oyun boyunca aktif tekil script (singleton)
- **GDScript**: Godot'un kendi dili, Python'a benzer

## project.godot Ayarları
```ini
[display]
window/size/viewport_width=540
window/size/viewport_height=960
window/handheld/orientation="portrait"
window/stretch/mode="canvas_items"
window/stretch/aspect="keep_width"

[rendering]
textures/canvas_textures/default_texture_filter=0

[autoload]
EventBus="*res://src/events/event_bus.gd"
```

## İsometrik TileMap
- Tile boyutu: 32x32
- Layout: Isometric, Cell size: Vector2i(32, 16)

## GDScript Temel Syntax
```gdscript
class_name MyClass
extends Node2D

@export var speed: float = 100.0
signal health_changed(new_value: int)

func _ready() -> void:
    pass
```

## Signal Kullanımı
```gdscript
signal passenger_boarded(passenger, wagon)
passenger_boarded.emit(passenger, wagon)
some_node.passenger_boarded.connect(_on_passenger_boarded)
```
SKILL1

cat > .claude/skills/game-tdd/SKILL.md << 'SKILL2'
---
name: game-tdd
description: "GdUnit4 ile test-driven game development. Test yazma, mock/stub, state machine testi, ekonomi testi."
---

# GdUnit4 ile Oyun TDD

## Test Şablonu
```gdscript
extends GdUnitTestSuite

func test_EconomySystem_Earn_ValidAmount_ShouldIncreaseBalance() -> void:
    # Arrange
    var economy = EconomySystem.new()
    economy.set_balance(100)
    # Act
    economy.earn(50, "ticket")
    # Assert
    assert_int(economy.get_balance()).is_equal(150)
```

## Test Stratejileri
- Ekonomi: Gelir/gider, yetersiz bakiye, bilet fiyat kademesi, indirimler
- Yolcu Bindirme: Doğru vagon, yanlış vagon engeli, kapasite aşımı
- Yakıt: Tüketim formülü, boş tank, otomatik ikmal
- İtibar: Asimetrik artış/azalış, yıldız hesaplama, kilit kontrolü
- İsometrik: Grid ↔ Screen dönüşüm doğruluğu
SKILL2

cat > .claude/skills/pixel-art-gen/SKILL.md << 'SKILL3'
---
name: pixel-art-gen
description: "Kod ile placeholder pixel art üretimi. Renkli dikdörtgen, geometrik sprite. Placeholder art gerektiğinde kullan."
---

# Placeholder Pixel Art

## Standartlar
| Entity | Şekil | Renk | Boyut |
|--------|-------|------|-------|
| Lokomotif | Dikdörtgen + ok | #C0392B | 64x48 |
| Vagon (ekonomi) | Dikdörtgen | #3498DB | 48x32 |
| Vagon (VIP) | Dikdörtgen | #F1C40F | 48x32 |
| Yolcu (normal) | Daire + "N" | Mavi | 16x24 |
| Yolcu (VIP) | Daire + "V" | Altın | 16x24 |
| Durak | Kutu + isim | #7F8C8D | Değişken |

## Godot ile Oluşturma
```gdscript
func create_placeholder(w: int, h: int, color: Color) -> Sprite2D:
    var image = Image.create(w, h, false, Image.FORMAT_RGBA8)
    image.fill(color)
    var texture = ImageTexture.create_from_image(image)
    var sprite = Sprite2D.new()
    sprite.texture = texture
    return sprite
```

## Referans: `assets/reference/` klasöründeki retro pixel art dosyaları
SKILL3

echo "✅ Skills oluşturuldu"

# ---- AGENTS ----
echo "📄 Agents oluşturuluyor..."

cat > .claude/agents/architect.md << 'AGENT1'
---
name: architect
description: "Oyun mimarisi tasarla, class yapısı oluştur, pattern kararları ver."
---

Sen Demir Yolcusu projesinin teknik mimarısın.

Görevlerin:
1. Yeni özellikler için class/component/system yapısını tasarla
2. Dosya ve klasör organizasyonunu belirle
3. Sistemler arası bağımlılıkları yönet
4. Event bus üzerinden iletişim planla

Kuralların:
- docs/technical/ARCHITECTURE.md dosyasını HER ZAMAN referans al
- Kompozisyon > Kalıtım
- Her sistem tek sorumluluk
- Factory pattern ile entity oluşturma
- Karmaşık yapıları basit açıkla — proje sahibi Godot bilmiyor
AGENT1

cat > .claude/agents/tester.md << 'AGENT2'
---
name: tester
description: "GdUnit4 ile test yaz. TDD workflow'unu yönet."
---

Sen Demir Yolcusu projesinin test mühendisisin.

Görevlerin:
1. Her yeni özellik için ÖNCE testleri yaz (RED aşaması)
2. Edge case'leri belirle ve test et
3. Test coverage'ı takip et

Kuralların:
- İsimlendirme: test_[Entity]_[Method]_[Senaryo]_[BeklenenSonuç]
- Yapı: Arrange → Act → Assert
- Her test tek bir davranışı test eder
- ASLA test atlanmaz
AGENT2

echo "✅ Agents oluşturuldu"

# ---- COMMANDS ----
echo "📄 Commands oluşturuluyor..."

cat > .claude/commands/new-feature.md << 'CMD1'
Yeni bir oyun özelliği ekle: $ARGUMENTS

Adımlar:
1. docs/design/GDD.md dosyasından bu özelliğin tasarımını oku
2. docs/technical/ARCHITECTURE.md dosyasından mimari pattern'leri kontrol et
3. Kısa teknik spec yaz (hangi dosyalar, class'lar, veri akışı)
4. GdUnit4 ile testleri YAZ (RED — başarısız olmalı)
5. Minimum kodu yaz (GREEN — testler geçmeli)
6. Refactor et
7. Çalıştığını doğrula
8. Ne yapıldığını özetle

NOT: Her adımda ne yaptığını açıkla — proje sahibi Godot bilmiyor.
CMD1

cat > .claude/commands/test.md << 'CMD2'
Testleri çalıştır: $ARGUMENTS

Eğer argüman boşsa tüm testleri çalıştır.
Eğer belirli bir sistem belirtildiyse sadece o testleri çalıştır.
Başarısız testleri analiz et ve düzeltme öner.
CMD2

cat > .claude/commands/status.md << 'CMD3'
Projenin mevcut durumunu raporla:

1. Hangi sistemler implement edilmiş?
2. Test coverage ne durumda?
3. docs/design/GDD.md'deki MVP özelliklerinden hangilerini tamamladık?
4. Sıradaki en mantıklı adım ne?
CMD3

cat > .claude/commands/save.md << 'CMD4'
Mevcut çalışmayı kaydet:

1. Değişen dosyaları listele
2. Testlerin geçtiğini doğrula
3. Anlamlı git commit mesajı yaz (Türkçe)
4. git add ve commit yap
5. Ne değiştiğini özetle
CMD4

echo "✅ Commands oluşturuldu"

# ---- GIT INIT ----
if [ ! -d ".git" ]; then
    echo "📦 Git başlatılıyor..."
    git init
    echo "✅ Git başlatıldı"
fi

# ---- ÖZET ----
echo ""
echo "=========================================="
echo "🚂 Demir Yolcusu proje yapısı hazır!"
echo "=========================================="
echo ""
echo "Sonraki adımlar:"
echo "  1. Retro asset'lerini kopyala:"
echo "     cp ~/Downloads/retro-assets/* assets/reference/"
echo ""
echo "  2. Claude Code başlat:"
echo "     claude"
echo ""
echo "  3. İlk prompt'u yapıştır (REHBER.md'deki Adım 10.2)"
echo ""
echo "İyi geliştirmeler! 🚂"
