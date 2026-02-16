---
name: bugfix-regression
description: Hata düzeltmede önce regresyon testi yazan ve minimum güvenli fix uygulayan workflow.
---

# Bugfix Regression Workflow

Ne zaman kullanılır:
- Tekrarlanabilir bir bug raporu geldiğinde
- Daha önce düzeltilip geri dönen hatalarda

Adımlar:
1. Hatanın yeniden üretim adımlarını yaz.
2. Regresyon testi ekle (başta kırmızı).
3. Kök nedene yönelik minimum fix uygula.
4. İlgili testleri tekrar çalıştır.
5. Yan etkileri kısa risk notu olarak yaz.

Çıktı formatı:
- Root cause
- Fix özeti
- Test kanıtı
- Kalan risk
