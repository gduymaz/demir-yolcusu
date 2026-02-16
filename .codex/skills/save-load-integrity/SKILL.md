---
name: save-load-integrity
description: Save/load veri bütünlüğü, sürüm geçişi ve bozuk kayıt senaryolarını güvenli yöneten workflow.
---

# Save/Load Integrity

Ne zaman kullanılır:
- Save schema değişikliği
- Yükleme sırasında veri kaybı/çökme riski

Adımlar:
1. Kayıt şemasını ve versiyon alanını tanımla.
2. Backward compatibility testi ekle.
3. Bozuk/eksik kayıt için fallback davranışı uygula.
4. Yükle-kaydet-yeniden yükle döngüsünü test et.

Çıktı:
- Schema değişikliği
- Migration/fallback kuralı
- Test kanıtı
