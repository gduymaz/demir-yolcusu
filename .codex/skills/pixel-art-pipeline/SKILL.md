---
name: pixel-art-pipeline
description: Isometrik 32x32 stile uygun pixel art üretim hattı, adlandırma ve atlas düzen standardı.
---

# Pixel Art Pipeline

Ne zaman kullanılır:
- Yeni sprite/tileset üretimi
- Placeholder'dan production art'a geçiş

Adımlar:
1. Asset listesi ve boyut sözleşmesini çıkar.
2. Palet sınırını tanımla (ana + vurgu renkleri).
3. Dosya adlandırma standardı uygula (`*_placeholder`, `*_v1`).
4. Atlas gruplaması yap (entity/ui/tiles).
5. Godot import ayarlarını doğrula (filter off, mipmap off).

Çıktı:
- Üretim backlog'u
- Dosya/atlas planı
- Teknik import checklist
