---
name: release-gate
description: Sürüm öncesi teknik kalite kapısını test, risk ve stabilite üzerinden yöneten workflow.
---

# Release Gate

Ne zaman kullanılır:
- Internal build veya public release öncesi

Adımlar:
1. Kritik testleri çalıştır (oynanış, save/load, ekonomi).
2. Bilinen bug listesini severity ile sınıfla.
3. Mobil performans hedefleri karşılandı mı kontrol et.
4. Go/No-Go kararı üret ve gerekçelendir.

Çıktı:
- Gate checklist sonucu
- Bloklayıcı hatalar
- Go/No-Go önerisi
