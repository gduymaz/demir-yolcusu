---
name: pixel-art-gen
description: "Kod ile placeholder pixel art üretimi. Renkli dikdörtgen, geometrik sprite. Placeholder art gerektiğinde kullan."
---

# Placeholder Pixel Art

## Standartlar
| Entity | Şekil | Renk | Boyut |
|--------|-------|------|-------|
| Lokomotif | Dikdörtgen + ok | #C0392B | 64x48 |
| Vagon (ekonomi) | Dikdörtgen | #3498DB | 48x32 |
| Vagon (VIP) | Dikdörtgen | #F1C40F | 48x32 |
| Yolcu (normal) | Daire + "N" | Mavi | 16x24 |
| Yolcu (VIP) | Daire + "V" | Altın | 16x24 |
| Durak | Kutu + isim | #7F8C8D | Değişken |

## Godot ile Oluşturma
```gdscript
func create_placeholder(w: int, h: int, color: Color) -> Sprite2D:
    var image = Image.create(w, h, false, Image.FORMAT_RGBA8)
    image.fill(color)
    var texture = ImageTexture.create_from_image(image)
    var sprite = Sprite2D.new()
    sprite.texture = texture
    return sprite
```

## Referans: `assets/reference/` klasöründeki retro pixel art dosyaları
