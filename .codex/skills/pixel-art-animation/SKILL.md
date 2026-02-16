---
name: pixel-art-animation
description: Pixel art animasyonlarında frame bütçesi, okunabilirlik ve Godot playback ayarları workflow'u.
---

# Pixel Art Animation

Ne zaman kullanılır:
- Lokomotif, yolcu veya UI animasyonları hazırlanırken

Adımlar:
1. Her animasyon için frame bütçesi tanımla (idle/move/action).
2. Anahtar pozları önce blokla, sonra in-between ekle.
3. Silhouette okunabilirliğini zoom-out test et.
4. Godot Animation/SpriteFrames hızlarını normalize et.

Öneri bütçesi:
- Idle: 4-6 frame
- Move: 6-8 frame
- Action: 8-12 frame

Çıktı:
- Animasyon listesi
- Frame ve playback ayarları
- Revizyon notları
