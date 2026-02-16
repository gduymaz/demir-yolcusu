---
name: ui-flow-qa
description: Mobil UI akışlarında sahne geçişi, durum tutarlılığı ve input edge-case doğrulama workflow'u.
---

# UI Flow QA

Ne zaman kullanılır:
- Yeni menü/sahne eklendiğinde
- UI'da takılma veya yanlış state raporu olduğunda

Adımlar:
1. Kritik kullanıcı akışlarını çıkar.
2. Akış başına beklenen state'i tanımla.
3. Hızlı tıklama/back/iptal senaryolarını test et.
4. UI state regressions için test veya checklist ekle.

Çıktı:
- Akış bazlı bulgular
- Yeniden üretim adımları
- Önerilen düzeltme önceliği
