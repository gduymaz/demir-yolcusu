# Codex Agent Kuralları (Bu Proje)

Bu dosya, mevcut Claude kurulumunu bozmadan Codex ajanları için ek yönlendirme sağlar.

## Sınırlar
- `.claude/` içeriğini kullanıcı istemedikçe değiştirme.
- Mevcut mimariyi koru; yalnızca görev kapsamındaki dosyalara dokun.

## Geliştirme İlkeleri
- Test-first: RED -> GREEN -> REFACTOR
- Küçük ve geri alınabilir değişiklikler
- Net dosya referanslarıyla teknik özet

## Godot/Test
```bash
GODOT="/Users/splendour/Downloads/Godot.app/Contents/MacOS/Godot"
$GODOT --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ -c --ignoreHeadlessMode
```
