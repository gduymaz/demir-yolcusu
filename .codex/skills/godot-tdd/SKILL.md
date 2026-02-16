---
name: godot-tdd
description: Godot 4.6 ve GdUnit4 ile test-first geliştirme; yeni özellik veya refactor öncesi bu skill kullanılmalı.
---

# Godot TDD Workflow

Ne zaman kullanılır:
- Yeni gameplay/sistem geliştirmesi
- Mevcut davranışın güvenli refactor'u

Adımlar:
1. İlgili test dosyasını bul (`tests/` altında).
2. Davranışı anlatan test yaz/güncelle (RED).
3. Minimum kod ile testi geçir (GREEN).
4. Temizlik yap ve testi tekrar çalıştır.

Komutlar:
```bash
GODOT="/Users/splendour/Downloads/Godot.app/Contents/MacOS/Godot"
$GODOT --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ -c --ignoreHeadlessMode
```

Kurallar:
- Test adı davranışı açık etsin.
- Magic number yerine `src/config/` sabitleri kullan.
