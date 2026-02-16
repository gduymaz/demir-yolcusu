# Demir Yolcusu Agent Kurallari

Bu dosya proje icinde calisacak ajanlar icin ortak yonlendirme sunar.

## Sinirlar
- Gorev kapsami disindaki dosyalari degistirme.
- Mimariyi koru, buyuk refactor oncesi etkiyi netlestir.
- Her degisiklikte test veya calistirma kaniti uret.

## Gelistirme Ilkeleri
- Test-first: RED -> GREEN -> REFACTOR.
- Kucuk ve geri alinabilir adimlarla ilerle.
- Dosya bazli teknik ozet ver.
- Belirsiz durumda varsayim yapma, kodu referans al.

## Proje Komutlari
```bash
GODOT="/Users/splendour/Downloads/Godot.app/Contents/MacOS/Godot"

# Tum testler
$GODOT --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ -c --ignoreHeadlessMode

# Tek test
$GODOT --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/systems/test_trip_planner.gd --ignoreHeadlessMode
```
