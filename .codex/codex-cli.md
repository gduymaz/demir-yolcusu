# Codex CLI Çalışma Rehberi

## Amaç
Godot 4.6 + GdUnit4 ile küçük, doğrulanabilir adımlarla geliştirme.

## Standart Akış
1. İlgili kodu oku (`src/`, `tests/`, `docs/`).
2. Önce test yaz/güncelle (RED).
3. Minimum implementasyon yap (GREEN).
4. Refactor et ve tekrar test çalıştır.
5. Kısa teknik özet çıkar.

## Hızlı Komutlar
```bash
GODOT="/Users/splendour/Downloads/Godot.app/Contents/MacOS/Godot"

# Tüm testler
$GODOT --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ -c --ignoreHeadlessMode

# Tek test dosyası
$GODOT --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/events/test_event_bus.gd --ignoreHeadlessMode
```

## Kurallar
- Magic number kullanma; `src/config/` altında sabit tanımla.
- Sistemler arası iletişimde signal/EventBus tercih et.
- Büyük değişiklikleri küçük commit parçalara böl.
