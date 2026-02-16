---
name: economy-balance
description: Demir Altını ekonomisi için ödül/fiyat dengesini test destekli optimize eden workflow.
---

# Economy Balance

Ne zaman kullanılır:
- Bilet fiyatı, görev ödülü, maliyet güncellemeleri

Adımlar:
1. Mevcut gelir/gider akışını tabloya dök.
2. Erken-orta oyun hedef eğrilerini belirle.
3. Denge testleri ekle (min/max, exploit).
4. Parametreleri küçük adımlarla güncelle.

Çıktı:
- Denge varsayımları
- Değişen parametreler
- Regresyon testi sonucu
