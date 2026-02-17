# Demir Yolcusu — Art & Visual Style Guide

**Versiyon:** 1.0  
**Tarih:** Şubat 2026  

> *Tüm görseller AI ile üretilecektir.*

---

## 1. Genel Görsel Kimlik

| Parametre | Değer |
|-----------|-------|
| Stil | İsometrik Pixel Art |
| Tile Boyutu | 32×32 piksel |
| İsometrik Oran | Klasik 2:1 (genişlik:yükseklik) |
| Ekran | Portrait (dikey) mobil |
| Art Üretimi | Tamamı AI ile (placeholder + final art) |
| Referans Oyunlar | Stardew Valley, Pocket Trains, Railway Empire, Mini Metro |

### His & Atmosfer
Sıcak, davetkar, nostaljik ama modern. Gerçekçi TCDD hissi ile cartoon pixel artın buluşması. Canlı, detaylı dünya — her durak yaşayan bir yer hissi vermeli.

---

## 2. Renk Paleti

Bölge × Mevsim matrisi. Her hat kendi palet hissine sahip.

### 2.1 Ege Hattı (Yaz Hissi)

| Renk | Hex | Kullanım |
|------|-----|----------|
| Gökyüzü | `#87CEEB` | Arka plan, açık alan |
| Güneş | `#F4D03F` | Işık efekti, vurgu |
| Zeytin | `#27AE60` | Bitki örtüsü, ağaçlar |
| Kum | `#D4AC6E` | Zemin, yapılar |
| Deniz | `#3498DB` | Su, kıyı |
| Taş | `#F5F5DC` | Durak binaları |

Ege: Açık mavi gökyüzü, sıcak sarılar, zeytin yeşili, kumsal tonları. Akdeniz sıcaklığı.

### 2.2 Marmara Hattı (İlkbahar/Sonbahar)

| Renk | Hex | Kullanım |
|------|-----|----------|
| Bulut | `#95A5A6` | Gökyüzü, hava |
| Yeşil | `#2ECC71` | Park, ağaç |
| Kırmızı | `#E74C3C` | Vurgu, yapı detay |
| Beton | `#BDC3C7` | Modern binalar |
| Mor | `#8E44AD` | Akşam gökyüzü |
| Sonbahar | `#F39C12` | Yaprak, sıcak detay |

Marmara: Gri tonlar, endüstriyel renkler, sonbahar yaprak renkleri. Modern şehir hissi.

### 2.3 İç Anadolu Hattı (Kış Ağırlıklı)

| Renk | Hex | Kullanım |
|------|-----|----------|
| Kar | `#ECF0F1` | Zemin örtüsü |
| Buz | `#D5DBDB` | Yol, su |
| Gri | `#5D6D7E` | Gökyüzü, yapı |
| TCDD | `#C0392B` | Tren, vurgu |
| Buğday | `#F1C40F` | Tarla, sıcak detay |
| Toprak | `#8B4513` | Zemin, yapı |

İç Anadolu: Soğuk beyazlar, gri tonlar, buğday sarısı, toprak kahverengisi. Step sertliği.

### 2.4 UI Renkleri

| Kullanım | Hex | Açıklama |
|----------|-----|----------|
| Birincil | `#C0392B` | TCDD kırmızısı — logo, butonlar, vurgu |
| İkincil | `#2C3E50` | Koyu mavi — panel arka plan, metin |
| Başarı | `#27AE60` | Yeşil — kazanç, başarı, onay |
| Hata | `#E74C3C` | Kırmızı — kayıp, hata, uyarı |
| Uyarı | `#F39C12` | Turuncu — dikkat, yakıt düşük |
| Bilgi | `#3498DB` | Mavi — bilgi, eğitici içerik |

---

## 3. Tren Sprite Standartları

### 3.1 Lokomotif

| Özellik | Değer |
|---------|-------|
| Sprite boyutu | 64×48 piksel (2 tile genişliğinde) |
| Yön sayısı | 8 (N, NE, E, SE, S, SW, W, NW) |
| Animasyon kareleri | Tekerlek dönme: 4 kare, Duman/kıvılcım: 6 kare |
| Işık efekti | Far: gece aktif, gündüz pasif |
| Duman rengi | Kömür=koyu gri, Dizel=açık gri, Elektrik=yok |

### 3.2 Vagon

| Özellik | Değer |
|---------|-------|
| Sprite boyutu | 48×32 piksel (1.5 tile genişliğinde) |
| Yön sayısı | 8 (lokomotif ile aynı) |
| Pencere detayı | Yolcu siluetleri görünür (doluluk oranına göre) |
| Eklem animasyonu | Virajda bağımsız açılanma |
| Fren efekti | Kıvılcım sprite + sarsma |

### 3.3 Vagon Tip Renkleri

| Vagon | Ana Renk | Detay |
|-------|----------|-------|
| Ekonomi | `#3498DB` (Mavi) | Standart pencereler |
| Business | `#2C3E50` (Koyu mavi) | Geniş pencereler |
| VIP | `#F1C40F` (Altın) | Süslü detay, perde |
| Yemekli | `#27AE60` (Yeşil) | Masa siluetleri |
| Kargo | `#8B4513` (Kahve) | Penceresiz, kutu silueti |

### 3.4 Tren Hareket Animasyonları

| Durum | Animasyon |
|-------|-----------|
| Kalkış | Yavaş ivmelenme + duman artışı |
| Seyir | Sabit hız + hafif sallanım |
| Frenleme | Kademeli yavaşlama + kıvılcım |
| Durak | Tam durma + buhar/hava püskürtme |
| Viraj | Vagonlar gecikmeli açılanma (fizik sim) |

---

## 4. Durak Görsel Tasarımı

### 4.1 Durak Katmanları

| Katman | İçerik | Animasyon |
|--------|--------|-----------|
| Arka plan | Şehir silueti + gökyüzü + hava durumu | Bulut hareketi, gün batımı renk geçişi |
| Orta plan | Durak binası + peron + raylar | Statik (tıklanabilir nesneler) |
| Ön plan | Yolcular + tren + ağaçlar | Yolcu hareket, tren geliş/gidiş |
| UI katmanı | HUD + butonlar + bilgi paneli | Slide-in/fade animasyonlar |

### 4.2 Bölgesel Farklılıklar

| Bölge | Durak Stili | Bitki Örtüsü | Ek Detaylar |
|-------|-------------|--------------|-------------|
| Ege | Beyaz badanalı, kiremit çatı | Zeytin ağacı, begonvil | Deniz görüntüsü, martılar |
| Marmara | Modern beton/cam | Kavık, çınar | Fabrika bacası, trafik |
| İç Anadolu | Taş yapı, ahşap detay | Kavak, seyrek ot | Kar örtüsü, buğday tarlası |

### 4.3 Canlı Arka Plan Elemanları

- Kuşlar uçar (rastgele rota)
- Bulutlar geçer (paralaks)
- İnsanlar yürür (arka planda)
- Kediler/köpekler (easter egg)
- Bayrak dalgalanır (rüzgar efekti)
- Su yansıması (deniz kenarı duraklar)

### 4.4 Etkileşimli Nesneler

Tıklanınca bilgi popup'ı veya easter egg çıkar:
- Durak tabelası → şehir bilgisi
- Heykel/anıt → tarihi bilgi
- Yemek standı → yerel yemek bilgisi
- Tren afişi → TCDD bilgisi

---

## 5. Yolcu Sprite Standartları

### 5.1 Yolcu Tipleri

| Yolcu Tipi | Sprite Boyutu | Görsel İpucu | Renk Kodu |
|------------|--------------|--------------|-----------|
| Normal | 16×24 | Günlük kıyafet, çanta | Mavi etiket |
| VIP | 16×24 | Takım elbise, şapka | Sarı/altın etiket |
| Öğrenci | 16×24 | Sırt çantası, genç | Yeşil etiket |
| Yaşlı | 16×24 | Baston, yaşlı silüet | Mor etiket |

### 5.2 Yolcu Sprite Bileşenleri

Her yolcu sprite'ının üzerinde:

- **Hedef ikonu:** Renkli daire içinde durak harfi/ikonu
- **Sabır barı:** Başın üzerinde küçük yeşil→sarı→kırmızı bar
- **Ücret balonu:** Tıklayınca görünür (DA miktarı)
- **Tip rozeti:** VIP=yıldız, öğrenci=kitap, yaşlı=kalp

### 5.3 Yolcu Animasyonları

| Durum | Animasyon | Kare |
|-------|-----------|------|
| Bekleme | Hafif bounce (idle) | 2 kare, 2 FPS |
| Sürükleme | Sallanma + büyüme efekti | - |
| Biniş | Vagona doğru yürüme | 4 kare, 6 FPS |
| İniş | Vagondan çıkıp uzaklaşma | 4 kare, 6 FPS |
| Kaybolma | Kızgın ifade + fade out | 3 kare |

---

## 6. Kondüktör Maskot

| Özellik | Değer |
|---------|-------|
| Sprite boyutu | 32×48 (ayakta) |
| Karakter | Orta yaşlı, bıyıklı, güler yüzlü TCDD kondüktörü |
| Kıyafet | Bölgeye göre değişir (Ege=yazlık, İç Anadolu=kışlık) |
| Animasyonlar | Konuşma, işaret etme, kutlama, üşüme, baş sallama |
| İfade | Değişken — mutlu/kaygılı/heyecanlı (duruma göre) |
| Konum | Sahnede sabit (peron kenarı) + konuşma balonu |

### Konuşma Balonu
- Pixel art çerçeveli baloncuk
- İçinde Türkçe metin (pixel font)
- Maskot ifadesi metne göre değişir
- Fade-in/out animasyonu

---

## 7. Harita Görsel Tasarımı

- **Stil:** Stilize pixel art Türkiye haritası
- **Hatlar:** Şematik ray çizgileri (TCDD tarzı — düz çizgi + durak noktaları)
- **Duraklar:** Küçük ikon + isim etiketi
- **Kilitli bölgeler:** Sis/pus efekti (fog of war)
- **Aktif hat:** Parlak + animasyonlu nokta (tren konumu)
- **Etkileşim:** Başlangıç/bitiş durağı tıklama ile seç
- **Bölge renkleri:** Her bölge kendi paleti ile boyalı

---

## 8. UI Görsel Standartları

### 8.1 Genel Yaklaşım
Karma stil: Oyun dünyası pixel art, UI elemanları temiz/modern. Ama butonlar ve paneller de pixel art estetikten kopmaz.

### 8.2 HUD Elemanları

| Eleman | Konum | Görsel |
|--------|-------|--------|
| Para (DA) | Sol üst | Altın sikke ikonu + rakam |
| İtibar | Sol üst (paranın altı) | Yıldız ikonu + 0.0-5.0 |
| Yakıt | Sağ üst | Yakıt pompası ikonu + doluluk barı |
| Hız | Sağ üst (yakıtın altı) | Hız göstergesi ikonu |
| Yolcu sayısı | Alt orta | Kişi ikonu + mevcut/kapasite |
| Sonraki durak | Alt | İsim + km + tahmini varış |
| Süre | Orta üst | Geri sayım (durakta aktif) |

### 8.3 Buton Stilleri

| Tip | Renk | Detay |
|-----|------|-------|
| Birincil | `#C0392B` (kırmızı) | Beyaz metin, 3px pixel border |
| İkincil | `#2C3E50` (koyu mavi) | Beyaz metin |
| Deaktif | `#95A5A6` (gri) | Soluk metin |
| Tehlike | `#E74C3C` (parlak kırmızı) | Titreme animasyonu |

### 8.4 Panel Stilleri

- **Arka plan:** Yarı saydam koyu (`#2C3E50`, %85 opak)
- **Kenarlık:** 2px pixel border, hafif ışıltı
- **Köşe:** Yuvarlak değil, pixel art keskin köşe
- **Animasyon:** Slide-in (alttan) veya fade-in

### 8.5 Font

---

## 9. MCP Prompt Contract (Final Asset Generation)

Bu bölüm, MCP ile üretimde prompt varyansını düşürmek için zorunlu prompt şablonlarını tanımlar.

### 9.1 Global Prompt Suffix

Her prompt sonuna şu kalite koşulu eklenir:

`pixel art game asset, clean silhouette, 1px controlled outline, 3-tone shading, no photorealism, no blur, no text, no watermark, consistent anatolian railway game style`

### 9.2 Background Prompt Template

`[scene purpose], side-view pixel art background, layered composition (foreground rails, midground station/terrain, background sky), reserved calm area for UI readability, regional palette locked, medium detail`

### 9.3 Vehicle Prompt Template

`single [vehicle type] sprite, side profile, transparent background, readable silhouette, mechanical details but low noise, consistent tcdd-inspired color accents`

### 9.4 Character Prompt Template

`single full-body [character role], side pose, transparent background, expressive but simple face, clear clothing blocks, game-ready sprite readability`

### 9.5 UI Prompt Template

`single [ui element] icon/panel, transparent background, high contrast, center-weighted composition, clean edges, no tiny noisy details`

### 9.6 Negative Rules (Always Avoid)

- Aşırı gradient ve painterly görünüm
- Micro-detail karmaşası ve texture noise
- Çift ışık yönü ve hacim karmaşası
- Arka planda istemsiz obje/karakter kalabalığı
- Okunurluğu bozan düşük kontrast

| Parametre | Değer |
|-----------|-------|
| Tip | Pixel font |
| Zorunlu Karakter Seti | a-z, A-Z, 0-9 + şğüöçıİŞĞÜÖÇ |
| Boyut Seviyeleri | Küçük (8px), Orta (12px), Büyük (16px) |
| Öneri | Press Start 2P benzeri + Türkçe glyph eklentisi |

---

## 9. Animasyon Standartları

| Animasyon | Kare Sayısı | FPS | Döngü |
|-----------|------------|-----|-------|
| Tekerlek dönme | 4 | 8 | Sürekli (seyirde) |
| Duman püskürtme | 6 | 6 | Sürekli (kömür/dizel) |
| Yolcu yürüme | 4 | 6 | Hareket sırasında |
| Yolcu bekleme | 2 | 2 | Sürekli (idle bounce) |
| Kondüktör konuşma | 3 | 4 | Diyalog sırasında |
| Kuş uçuşu | 4 | 8 | Rastgele arka plan |
| Bulut hareketi | Paralaks | Sürekli | Sürekli scroll |
| Su yansıması | 3 | 4 | Sürekli (deniz kenarı) |
| Yaprak dökümü | Particle | Değişken | Sonbahar/rüzgar |
| Kar yağışı | Particle | Değişken | İç Anadolu kış |

---

## 10. Ekran Geçiş Animasyonları

| Geçiş | Animasyon | Süre |
|--------|-----------|------|
| Menü → Harita | Fade to black → fade in | 0.5 sn |
| Harita → Garaj | Tren istasyona girer | 0.8 sn |
| Garaj → Durak | Tren kalkış efekti + düdük sesi | 1.0 sn |
| Durak → Seyir | Tren hızlanma + manzara geçişi | 0.8 sn |
| Seyir → Durak | Tren yavaşlama + durak görünür | 0.8 sn |
| Durak → Özet | Slide-up panel | 0.3 sn |

---

## 11. Placeholder Art Stratejisi

Prototipleme sırasında kod ile üretilecek placeholder'lar:

| Eleman | Placeholder Yöntemi | Renk |
|--------|-------------------|------|
| Lokomotif | Renkli dikdörtgen + yön oku | `#C0392B` |
| Vagon | Küçük renkli dikdörtgen (tip rengine göre) | Tipe göre |
| Yolcu | Renkli daire + tip harfi (N/V/Ö/Y) | Tipe göre |
| Durak | Gri dikdörtgen + isim etiketi | `#7F8C8D` |
| Harita | Basit çizgi + nokta (duraklar) | Hat rengine göre |
| HUD | Godot Label + ColorRect | UI renklerine göre |

### Placeholder → Final Art Geçiş Önceliği
1. Tren (lokomotif + vagonlar) — en çok görünen
2. Yolcular — core loop'un merkezi
3. Duraklar — oyun dünyası hissi
4. Harita — stratejik ekran
5. UI elementleri — polish aşaması

### Referans Görseller
`assets/reference/` klasöründeki retro pixel art dosyaları stil referansı olarak kullanılır. Bu görseller kopyalanmaz, sadece renk paleti ve detay seviyesi referans alınır.

---

## 12. Splash & Yükleme Ekranı

### Splash Screen
- İsometrik mini istasyon sahnesi
- Uzaktan tren yaklaşır
- Logo fade-in ile belirir
- TCDD tarzı kırmızı-beyaz logo
- Süre: 2-3 saniye

### Yükleme Ekranı
- Tematik pixel art tren animasyonu
- Tren ekranın solundan sağına ilerler
- İlerleme barı tren altında
- Opsiyonel: Eğitici bilgi kartı (durak/tren bilgisi)
