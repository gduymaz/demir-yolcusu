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

## Zorunlu Kod Kurallari
- TDD first zorunlu: Test yazmadan uygulama kodu yazma.
- OOP/architecture disiplini: sorumluluklari ayri tut, tek sinif/tek fonksiyon asiri yuklenmesin.
- Design pattern zorunlulugu: uygun yerde Factory, State, EventBus (Observer), Repository ve Strategy patternlerini tercih et; ad-hoc/cozum odakli daginik yaklasim kullanma.
- Yeni gelistirmelerde mevcut mimari desenlerini bozma; gerekirse once desen uyumlu refactor yap, sonra ozelligi ekle.
- i18n zorunlu: UI veya oyuncuya gorunen metinler kodda hardcode edilmez, locale anahtari ile kullanilir.
- Kod dili standardi: yorumlar, degisken adlari, fonksiyon adlari ve sinif adlari sadece English olur.
- Kod icinde Turkish comment kullanma.
- Turkish metin yalnizca locale dosyalarinda (or. `src/data/i18n_tr.json`) tutulur.
- Surekli uyum zorunlulugu: yeni kod yazarken dokunulan dosya/blokta bu kurallara aykiri bir yer gorulurse ayni kapsamda duzelt; "sonraya birakma" yaklasimi kullanma.
- PR/commit kapsami kurali: is kapsamini bozmadan, dokunulan alandaki kural ihlallerini temizleyip oyle commit et.

## Proje Komutlari
```bash
GODOT="/Users/splendour/Downloads/Godot.app/Contents/MacOS/Godot"

# Tum testler
$GODOT --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/ -c --ignoreHeadlessMode

# Tek test
$GODOT --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd -a tests/systems/test_trip_planner.gd --ignoreHeadlessMode
```
