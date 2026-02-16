---
name: pixel-art-qa
description: Pixel art varlıklarında palet, pivot, hizalama ve teknik import kalite kontrol workflow'u.
---

# Pixel Art QA

Ne zaman kullanılır:
- Yeni art set teslimlerinde
- Build öncesi görsel kalite kontrolünde

Kontrol listesi:
1. Palet uyumu ve banding kontrolü
2. Sprite pivot/origin doğruluğu
3. Isometrik hizalama (32x32, 2:1)
4. Tile seam/jitter kontrolü
5. Godot import ayarları (filter/mipmap/compression)

Çıktı:
- Bulgu listesi (kritik/orta/düşük)
- Düzeltme önerisi
- Onay/red kararı
