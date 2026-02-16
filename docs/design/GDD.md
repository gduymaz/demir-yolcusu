# Demir Yolcusu — Game Design Document (GDD)

**Versiyon:** 1.0  
**Tarih:** Şubat 2026  
**Platform:** iOS / Android  
**Motor:** Godot 4.3+ / GDScript  

> *"Dedenin eski lokomotifini devral. Türkiye'nin demiryollarında yolculara hizmet et. Bir efsane ol."*

**Hedef Kitle:** 10+ yaş | **Tamamen Ücretsiz** | **Reklamsız** | **Offline**

---

## 1. Genel Bakış

| Parametre | Değer |
|-----------|-------|
| Oyun Adı | Demir Yolcusu |
| Tür | İsometrik Pixel Art Tren Yönetim Simülasyonu |
| Platform | Mobil (iOS / Android) |
| Ekran Yönelimi | Portrait (dikey) |
| Motor | Godot 4.3+ Stable |
| Dil | GDScript |
| Hedef FPS | 30 |
| Minimum Cihaz | iPhone 11+ / Android 10+ |
| Uygulama Boyutu | 300-500 MB (tüm içerik dahil, offline) |
| Monetizasyon | Tamamen ücretsiz, reklamsız, IAP yok |
| Dil Desteği | i18n altyapısı baştan, MVP'de Türkçe |
| Kaydetme | Otomatik (her durakta) + 3 kayıt slotu |
| Veri Formatı | SQLite (save + game data) + Godot Resource (runtime) |
| Oturum Hedefi | 15-20 dakika, esnek — her an bırakıp devam et |

### Elevator Pitch

Demir Yolcusu, Türkiye'nin gerçek demiryolu hatlarında geçen isometrik pixel art tren yönetim oyunudur. Oyuncu, dedesinden miras kalan eski bir kömürlü lokomotifle başlar; duraklarda bekleyen yolcuları sürükleyerek vagonlara bindirir, kargo taşır, Demir Altını kazanır ve lokomotif filosunu geliştirerek Türkiye'nin dört bir yanını keşfeder. Eğitici macera hikayesi, gerçekçi TCDD atmosferi ve bölgesel kültürel içeriklerle 10+ yaş grubuna yönelik, tamamen ücretsiz ve reklamsız bir deneyim sunar.

---

## 2. Vizyon

### Oyuncu Fantasisi
Oyuncu kendini bir makinist olarak hayal eder: eski bir lokomotifi devralır, Türkiye'nin güzel manzaraları arasında seyahat eder, yolculara hizmet verir ve zamanla güçlü bir tren filosu kurar.

### Hedef Duygular
- **Sahiplenme:** "Bu benim trenim, ben büyüttüm"
- **Keşif:** "Bir sonraki durakta ne var?"
- **Başarı:** "Bu seferde rekor kırdım!"
- **Öğrenme:** "Konya'da buğday yetişiyormuş!"

### 3 Tanımlayıcı Kelime
**Keşif — Strateji — Nostalji**

---

## 3. Core Loop (Oyun Döngüsü)

### Mikro Döngü (10-30 saniye)
Durakta bekleyen yolcuları incele → Hedef, ücret, sabır ve tipi değerlendir → Uygun vagona sürükle-bırak ile bindir → Zaman limiti dolmadan karar ver → Para ve itibar kazan.

### Makro Döngü (15-20 dakika / oturum)
Garajda tren hazırla (lokomotif seç, vagon diz) → Haritada rota seç (başlangıç/bitiş durağı) → Sefere çık → Her durakta yolcu yönet + kargo al → Seyir sırasında mini oyun oyna → Dönüş seferi → Sefer sonu özet ekranı.

### Meta Döngü (günler/haftalar)
Hat görevlerini tamamla → Yeni hat aç → Yeni lokomotifler ve vagonlar satın al/yükselt → Teknoloji ağacında ilerle → Dükkan aç → Başarım topla → Tüm Türkiye'yi keşfet.

---

## 4. Zaman & Tur Mekaniği

Oyun **hibrit tur bazlıdır**. Tren duraklar arasında otomatik hareket eder (seyir ekranı). Durağa varınca zaman limiti başlar ve oyuncu karar verir. Her sefer = 1 oyun günü (soyut takvim).

### Durak Zaman Limiti

| Durak Büyüklüğü | Baz Süre | Kolay (×1.5) | Normal (×1) | Zor (×0.7) |
|------------------|----------|--------------|-------------|------------|
| Küçük (köy) | 10 sn | 15 sn | 10 sn | 7 sn |
| Orta (ilçe) | 15 sn | 22 sn | 15 sn | 10 sn |
| Büyük (şehir) | 20 sn | 30 sn | 20 sn | 14 sn |

### Gündüz/Gece Döngüsü
Kademeli: Başta sadece görsel renk değişimi (sabah/öğle/akşam/gece). İleriki hatlarda mekanik etki eklenir (gece seferlerinde yolcu azalır, yakıt artar).

### Mevsim Sistemi
Hat bazlı sabit mevsim: Ege = yaz hissi, İç Anadolu = kış ağırlıklı, Marmara = ilkbahar/sonbahar. Her bölgenin özel renk paleti var.

---

## 5. Yolcu Sistemi

### Yolcu Tipleri

| Tip | Ücret | Sabır | Özel Özellik | Görsel |
|-----|-------|-------|--------------|--------|
| Normal | Standart | Orta | Yok | Günlük kıyafet |
| VIP | Yüksek (3x) | Düşük | Sadece VIP/Business vagona biner | Takım elbise |
| Öğrenci | Düşük (%50 indirim) | Yüksek | Uzun bekler, gruplar halinde gelir | Sırt çantası |
| Yaşlı | Düşük (%30 indirim) | Orta | Öncelikli koltuk ister | Baston |

### Yolcu Bilgileri (Sprite Üzerinde Görünen)
- Hedef durak (renk koduyla)
- Ödeyeceği ücret (Demir Altını)
- Sabır barı (azalan çubuk — yeşil→sarı→kırmızı)
- Yolcu tipi (VIP rozeti, öğrenci ikonu vb.)

### Yolcu Etkileşimi
**Sürükle-bırak:** Oyuncu yolcuyu parmakla tutar ve uygun vagona sürükler. Yanlış vagon tipine bırakılırsa sistem engeller ve yolcu geri döner (kırmızı flash uyarısı).

### Yolcu İndirme
Animasyonlu: Durağa varınca önce hedefi bu durak olan yolcular görünür şekilde iner. İniş tamamlandıktan sonra yeni yolcu bindirme süresi başlar.

### Yolcu Kaybetme
Sabırsız yolcu beklemeyi bırakıp giderse: İtibar puanı düşer. İtibar düşüşü hat açma ve tren/vagon satın alma koşullarını etkiler.

### Yolcu Üretimi (Dinamik)
4 faktör birlikte etkiler:
- **Durak popülerliği:** Büyük şehir = çok yolcu
- **Zaman dilimi:** Sabah iş saati = yoğun, gece = az
- **Hava durumu etkisi:** Kötü hava = az yolcu (ileri hatlarda)
- **Olay etkisi:** Festival = yolcu patlaması

---

## 6. Tren Sistemi

### Lokomotif Sınıfları

| Yakıt Tipi | Hız | Vagon Limiti | Bakım Maliyeti | Örnek İsim |
|------------|-----|-------------|----------------|------------|
| Kömür (eski) | Yavaş | 2-3 vagon | Düşük | Kara Duman |
| Kömür (yeni) | Yavaş-Orta | 3-4 vagon | Düşük-Orta | Demir Yürek |
| Dizel (eski) | Orta | 4-5 vagon | Orta | Boz Kaplan |
| Dizel (yeni) | Orta-Hızlı | 5-6 vagon | Orta-Yüksek | Demir Rüzgarı |
| Elektrik (yeni) | Hızlı | 6-8 vagon | Yüksek | Anadolu Yıldızı |

Lokomotif isimleri hayali gerçekçi: Türkçe, güç/hız çağrıştıran.

### Vagon Tipleri

| Vagon Tipi | Kapasite | Özel Etki | Yıpranma |
|------------|----------|-----------|----------|
| Ekonomi Yolcu | 20 koltuk | Standart | Kullanım bazlı |
| Business Yolcu | 12 koltuk | Yüksek konfor, itibar bonusu | Kullanım bazlı |
| VIP | 8 koltuk | VIP yolcular için, çok konforlu | Kullanım bazlı |
| Yemekli | Yok | Pasif memnuniyet + otomatik gelir | Kullanım bazlı |
| Kargo | X kutu | Kargo taşıma, basit kapasite | Kullanım bazlı |

### Vagon Dizilimi
Stratejik: Vagonların sıralaması ağırlık dağılımı üzerinden hız ve yakıt tüketimini etkiler. Ağır vagonlar arkaya = daha verimli.

### Fizik
Eklemli vagonlar virajda bağımsız açılanır, frende kayma efekti, sallantı animasyonu.

### Lokomotif Upgrade Kategorileri (4 Eksen)
- **Hız:** Daha hızlı seferler
- **Kapasite:** Daha çok vagon çekme
- **Yakıt Verimliliği:** Daha az tüketim
- **Dayanıklılık:** Daha az arıza, uzun ömür

### Vagon Upgrade Kategorileri (4 Eksen)
- **Konfor:** Yolcu memnuniyeti artar, itibar bonusu
- **Kapasite:** Daha çok koltuk
- **Görsel Özelleştirme:** Renk, desen, dış görünüm
- **Bakım Hızı:** Daha az sürede temizlenir

### Teknoloji Ağacı
Dallanmalı yapı: Her yakıt tipinde 2-3 farklı dal (hız vs kapasite vs verimlilik). Upgrade'ler para + itibar + hat tamamlama ile açılır (üçlü kilit). Son 1-2 upgrade geri alınabilir (kısmi respec).

### Paralel Garaj
Birden fazla lokomotif saklanabilir, sefere göre seçilir. Depo kapasitesi yükseltmeyle genişler.

---

## 7. Ekonomi Sistemi

### Para Birimi: Demir Altını (DA)
Tek para birimi. Tematik ve değerli hissi veren isim. Gösterim: "150 DA kazandın!"

### İtibar Sistemi
- 1-5 yıldız gösterimi (yarım yıldız dahil)
- Harcanan değil, kilitleri açan pasif değer
- **Asimetrik:** Artar hızlı, düşer yavaş (çocuk dostu, teşvik edici)
- Etkileyen 4 faktör: yolcu memnuniyeti, kaybedilen yolcu, görev tamamlama, kargo teslim performansı
- Rota ve satın alma kilitleri için kullanılır

### Gelir Kaynakları

| Kaynak | Açıklama | Tip |
|--------|----------|-----|
| Yolcu bileti | Mesafe kademeli TCDD tarzı fiyat | Aktif |
| Kargo teslimi | Bölgesel ürün teslimatı, zamana bağlı ödeme | Aktif |
| Dükkan geliri | Durak dükkanlarından pasif gelir (idle) | Pasif |
| Görev/sözleşme ödülleri | Zincir görev + süreli sözleşme bonus | Aktif |

### Gider Kalemleri

| Gider | Tetikleyici | Açıklama |
|-------|-------------|----------|
| Yakıt | Her sefer öncesi (otomatik minimum ikmal) | Mesafe + hız + ağırlık + arazi (kademeli formül) |
| Bakım/tamir | Düzenli bakım uyarısı + rastgele arıza | Anında para öde, hemen tamir |
| Temizlik | Kirlilik barı + yolcu sayısı + rastgele olay | Mini oyun (kirli noktaları tıkla) |

**ÖNEMLİ:** Periyodik gider YOK — sadece tetiklenen giderler var (çocuk dostu).

### Bilet Fiyatlandırması
Otomatik, mesafe kademeli TCDD tarzı:
- 0-100 km: Taban fiyat
- 100-300 km: Taban ×1.5
- 300+ km: Taban ×2

İndirimler: Öğrenci %50, Yaşlı %30, Normal tam fiyat, VIP tam + prim.

### Başlangıç Ekonomisi
- 500 DA ile başla (sadece ilk sefer yakıtına yeter)
- Eski kömürlü lokomotif + 1 ekonomi vagon (miras)

---

## 8. Hat & Durak Sistemi

### Hatlar

| Hat | Rota | Zorluk | Arazi | Özellik |
|-----|------|--------|-------|---------|
| Ege (MVP) | İzmir → Denizli / Afyon | Başlangıç (kolay) | Düz | Yaz hissi, deniz, zeytin |
| Marmara | İstanbul → Ankara | Orta | Karma | Yoğun trafik, modern |
| İç Anadolu | Ankara → Konya → Kayseri | İleri (zor) | Dağlık | Kış, rampa etkisi |

Hat açılma: Hikaye bazlı — her bölgenin görevi var, tamamlayınca yeni hat açılır.

### Durak Özellikleri
Her hat gerçek TCDD durak sayılarını kullanır. Duraklar:
- Gerçekçi + canlı çevre: Durak binası + şehir silueti + hava durumu efekti
- Canlı arka plan: Kuşlar uçar, bulutlar geçer, insanlar yürür
- Etkileşimli nesneler: Tıklayınca bilgi/easter egg çıkar
- Basit tabela: İsim + km bilgisi
- **Değişmez:** Duraklar zaman içinde gelişmez (sabit)

### Durak Dükkanları (Idle Tarzı)
Aç, yükselt, pasif gelir artar. Sınırlı slot + itibar kilidi.

| Dükkan Tipi | Etki |
|-------------|------|
| Büfe/Kantin | Yolcu memnuniyeti + gelir |
| Hediyelik Eşya | Bölgesel gelir (Ege seramik, Konya halı) |
| Kargo Deposu | Kargo kapasitesi artışı |

### Bekleme Kapasitesi
Değişken: Büyük durakta çok, küçük durakta az yolcu bekler. Kargo deposu dükkanı kapasiteyi artırır.

---

## 9. Sefer Mekaniği

### Sefer Planlama
- **Rota seçimi:** Harita üzerinde başlangıç/bitiş durağı tıkla
- **Kısmi sefer:** İstediğin duraklar arasında git
- **Ön izleme:** Tahmini gelir + yakıt maliyeti görünür
- **Rota kilidi:** Sefer başlayınca rota değişmez
- **Gidiş-dönüş:** A→D gidiş + D→A dönüş (iki ayrı sefer)
- **Dönüş:** Aynı duraklar ters sırada — farklı yolcu dağılımı doğal strateji farkı yaratır

### Ekspres Sefer
Kademeli: Başta her durakta zorunlu dur. İlerledikçe durak atlama seçeneği açılır (ekspres). Atlanan durak = zaman kazanır ama yolcu/kargo fırsatını kaçırırsın.

### Seyir Ekranı
Duraklar arası seyir: Kısa animasyon + manzara izleme + opsiyonel mini oyun. Otomatik hızlanma: Kısa mesafe normal, uzun mesafe otomatik hızlanır.

### Seyir Mini Oyunu
Karma: Bonus toplama, engel temizleme, sinyal yönetimi rastgele dönüşümlü. Sadece uzun mesafelerde (3+ durak) çıkar. Çeşitli ödüller: para, itibar, yakıt indirimi, arıza koruması.

### Karşı Tren Trafiği
Sadece görsel: Bazen karşı yönden tren geçer (atmosfer, mekanik etkisi yok).

---

## 10. Kargo Sistemi

Bölgesel özel ürünler: Ege'den zeytin/incir, Konya'dan un/buğday, Marmara'dan sanayi ürünleri.

- **Alma:** Duraklarda rastgele kargo kutusu + sözleşme bazlı özel teslimat
- **Kapasite:** Basit — X kutu sığar, tip farkı yok
- **Bozulma:** Basit zaman limiti — zamanında teslim = tam ödeme, geç kal = azalan ödeme

---

## 11. Yakıt & Bakım Sistemi

### Yakıt
- **Kademeli:** Başta otomatik kesilir, seviye ilerledikçe farklı duraklarda farklı fiyatlar (stratejik ikmal)
- **Tüketim:** Kademeli formül — başta basit bar, sonra hız+ağırlık+arazi
- **Yakıt biterse:** Hız kademeli düşer → tamamen biterse tren durur (çekici cezası)
- **İkmal güvenliği:** Sefere çıkınca minimum yakıt otomatik alınır
- **Yakıt geçişi:** Paralel — tüm lokomotifler garajda tutulabilir

### Bakım
Düzenli bakım uyarısı + rastgele arıza olayları. Tamir anında: Para öde, hemen tamir.

### Temizlik
Karma tetik: Kirlilik barı (manuel) + yolcu sayısına bağlı yıpranma + rastgele kirlenme olayları. Temizlik ekranı: Mini oyun — kirli noktaları tıklayarak temizle.

---

## 12. Görev & Hikaye Sistemi

### Başlangıç Hikayesi
Miras hikayesi: Kondüktör amca dedenin hikayesini anlatır, eski kömürlü lokomotifi sana devreder. İlk sefer 2-3 duraklık tutorial niteliğinde. 500 DA başlangıç parası.

### Görev Yapısı
- **Zincir görevler:** Her görev bir sonrakini açar, hikaye ilerler
- **3-5 görev per hat** (kısa, odaklı)
- **Görev tipleri:** Taşıma görevleri ("X yolcuyu Y durağına götür") + Keşif görevleri ("Tüm duraklara uğra")
- **Zaman baskısı/ekonomi hedefi YOK** — sadece taşıma ve keşif

### Hikaye Tonu
Eğitici + macera: Türkiye coğrafyası/tarihi/kültürü + gizem/keşif karışımı.

### Hikaye Anlatımı
Karma: Önemli anlar sinematik pixel art cutscene, normal görevler kondüktör diyaloğuyla.

### Sözleşme Sistemi
- Aktif slot: Kademeli — başta 1, itibar arttıkça 2→3
- Süre: Değişken — kolay=kısa, zor=uzun
- Erişim: Durak bazlı sözleşme panosu

---

## 13. Garaj Sistemi

İsometrik görsel garaj sahnesi + sürükle-diz vagon yönetimi. **Sadece sefer öncesi erişilebilir.**

- **Lokomotif depo:** Kısıtlı kapasite, yükseltmeyle genişler
- **Vagon dizimi:** Sürükle-bırak ile vagonları ekle/çıkar/sırala
- **Upgrade:** Başta basit (para öde, yükselt), sonra teknoloji ağacına geç
- **Mağaza:** Durak bazlı — bazı şeyler sadece belirli duraklarda satılır

---

## 14. Rastgele Olaylar

Hat zorluğuna göre artan sıklık: Ege'de nadir, İç Anadolu'da sık.

### Teknik Arızalar (4 tip)

| Arıza | Mekanik Etki |
|-------|-------------|
| Motor arızası | Hız %50 düşer, tamir gerekir |
| Fren arızası | Durakta durma süresi uzar |
| Ray sorunu | Belirli bölümde yavaşlama zorunlu |
| Kapı arızası | Yolcu bindirme süresi uzar |

### Yolcu Olayları (3 tip)

| Olay | Etki |
|------|------|
| Sürpriz VIP | Yüksek ödeme yapan özel yolcu belirir |
| Hasta yolcu | En yakın durağa acil iniş (bonus itibar) |
| Unutulan bavul | Sahibine ulaştır = ödül |

### Ekonomik Olaylar (2 tip)

| Olay | Etki |
|------|------|
| Yakıt fiyat artışı | Geçici süre yakıt pahalılaşır |
| Festival/bayram | Belirli duraklarda yolcu patlaması |

### Hava Durumu
Kademeli: Başta sadece görsel (yağmur/kar animasyonu). İleriki hatlarda mekanik etki (hız düşüşü, arıza riski artışı).

---

## 15. Başarım & Zorluk Sistemi

### Başarım Kategorileri (4)
- **Sefer:** "İlk sefer", "100. sefer", "1000 km"
- **Yolcu:** "100 yolcu", "İlk VIP", "0 kayıp sefer"
- **Koleksiyon:** "Tüm lokomotifleri aç", "Tüm vagonları topla"
- **Keşif:** "Tüm Ege duraklarını ziyaret et", "Gece seferi yap"

Ödüller: Rozet + bonus para. Görünürlük: Kademeli — bir başarımı kazandıkça sonraki açığa çıkar.

### Dinamik Zorluk (Görünmez)
Son 3 sefer performansına göre ayarlanır:
- Durak zaman limiti uzar/kısalır
- Yolcu sabrı artar/azalır
- Arıza sıklığı azalır/artar
- Bilet geliri hafif artar/azalır

### Başarısızlık
**Soft game over:** İflas edersen başa dön ama lokomotif/vagon upgrade'lerin kalır.

---

## 16. Görsel & Ses Tasarımı

### Pixel Art Spesifikasyonları
- **Tile boyutu:** 32x32 pixel
- **İsometrik açı:** Klasik 2:1
- **Renk paleti:** Bölge × Mevsim matrisi
- **Art üretimi:** Tamamı AI ile üretilecek

### Tren Görselleri
- **8 yönlü sprite:** 4 ana + 4 çapraz yön
- **Animasyonlar:** Dönen tekerlekler, duman/kıvılcım, ışıklar, sallantı, pencereden yolcu siluetleri
- **Fizik:** Eklemli vagonlar virajda bağımsız açılanır, frende kayma efekti

### Kozmetik Özelleştirme
- **Renk değiştirme:** Lokomotif ve vagon rengi
- **Desen/çıkartma:** Şerit, yıldız, Türk bayrağı, TCDD, şehir armaları
- **Elde etme:** Karma — mağazadan satın al + başarım ödülü

### UI Tasarımı
- **Stil:** Karma — oyun pixel art, UI temiz/modern
- **HUD:** Detaylı — para + itibar + yakıt + hız + yolcu sayısı + sonraki durak
- **Font:** Pixel font (Türkçe karakter desteği zorunlu: ş,ğ,ü,ö,ç,ı)

### Ses & Müzik
- **Müzik:** Bölgeye özel — Ege=klarnet, İç Anadolu=bağlama, Marmara=modern orkestral
- **SFX:** Detaylı + Türkçe durak anonsu ("Sayın yolcular, Selçuk istasyonuna...")
- **Maskot sesi:** Basit tepki sesleri ("hm", "aha", "oh") + diyalog balonu
- **Ayarlar:** Ayrı müzik/SFX ses seviyesi

---

## 17. Kontroller & UX

### Dokunmatik
- **Tek parmak:** Tıklama + sürükleme yeterli (multi-touch yok)
- **Kamera:** Sabit — her durak ekrana sığar
- **Haptic:** Opsiyonel — ayarlardan açılır/kapatılır

### Kondüktör Maskot
- **Karakter:** Klasik bıyıklı TCDD kondüktör amca
- **Kıyafet:** Bölgeye göre değişir (Ege=yazlık, İç Anadolu=kışlık)
- **Konuşma tonu:** Değişken — duruma göre samimi/ciddi/espirili geçiş yapar
- **Mesaj gösterimi:** Pop-up konuşma balonu
- **Hitap:** Oyuncuya "Makinist" der

### Tutorial
- **Yoğunluk:** Tam rehberli — ilk 2-3 sefer kondüktör yönlendirmeli
- **Atlama:** Akıllı — ikinci kayıt slotunda tutorial otomatik atlanır
- **Sonrası:** Kondüktör önerileri — maskot uygun eylemleri önerir

### Eğitici İçerik (Duraklarda Tıklanabilir)
- **Şehir bilgisi:** Duraktaki şehrin kısa tarihi/özelliği
- **Kültürel bilgi:** Yerel yemek, festival, gelenek
- **Tren bilgisi:** TCDD tarihi, lokomotif bilgileri

### Erişilebilirlik
- Font boyutu: 3 seviye (küçük/orta/büyük)
- Yavaş mod: 2× zaman limitleri

---

## 18. Ekran Yapısı

### Ana Ekranlar
- **Ana Menü:** Oyuna başla, devam et, ayarlar
- **Harita:** Stilize pixel art Türkiye + şematik hatlar (sisli keşfedilmemiş bölgeler)
- **Garaj:** İsometrik görsel + sürükle-diz vagon yönetimi
- **Durak:** Ana oynanış ekranı (yolcu bindirme)
- **Seyir:** Tren manzarada ilerler + mini oyun

### Alt Paneller
- Görev paneli: Aktif/tamamlanmış görevler
- Sözleşme paneli: Mevcut kargo/yolcu sözleşmeleri

### Diğer Ekranlar
- **Splash:** İsometrik istasyon, tren yaklaşır, logo belirir
- **Yükleme:** Tematik pixel art tren animasyonu
- **Pause:** Devam / Ayarlar / Ana menü (3 buton)
- **Sefer özeti:** Gelir/gider listesi + net kazanç
- **Başarım vitrini:** Kazanılan rozetler
- **İstatistik:** Toplam sefer, yolcu, km, kazanç

### Ekran Geçişleri
- Menü→Harita: Fade
- Harita→Garaj: Tren istasyona girer
- Garaj→Durak: Kalkış efekti + düdük
- Durak→Seyir: Hızlanma + manzara geçişi
- Seyir→Durak: Yavaşlama + durak görünür

---

## 19. Teknik Gereksinimler

| Parametre | Değer |
|-----------|-------|
| Motor | Godot 4.3+ Stable |
| Dil | GDScript |
| Platform | iOS / Android |
| Ekran | Portrait, mobil öncelikli |
| Hedef FPS | 30 |
| Min Cihaz | iPhone 11+ / Android 10+ |
| Boyut | 300-500 MB |
| Save Format | SQLite (3 slot) |
| Veri Format | SQLite + Godot Resource |
| Kaydetme | Otomatik (her durakta) |
| i18n | Baştan kurulur, MVP Türkçe |
| Online | Yok — tamamen offline |

### Ayarlar
- Müzik ses seviyesi
- Efekt ses seviyesi
- Bildirimler aç/kapa
- Haptic aç/kapa
- Font boyutu (küçük/orta/büyük)
- Dil seçimi

---

## 20. MVP vs Tam Kapsam

### MVP (Ege Hattı) — Öncelik Sırası
1. Durak ekranı + yolcu bindirme (core loop)
2. Garaj + lokomotif/vagon yönetimi
3. Harita + hat seçimi + seyir ekranı
4. Görev zinciri + hikaye sistemi

### Tam Kapsam (Güncelleme ile)
- Marmara hattı (güncelleme 1)
- İç Anadolu hattı (güncelleme 2)
- Karadeniz, Akdeniz ve diğer hatlar
- Teknoloji ağacı genişlemesi
- Ek lokomotif/vagon modelleri
- Yeni dil destekleri

### Hedef Süre
Kalite öncelikli — deadline baskısı yok. İlk oynanabilir prototip sonrası iteratif geliştirme.

### Endgame
Soft ending: Hikaye pixel art sinematik ile biter, sonra sandbox açılır (ayrı mod DEĞİL — aynı oyun, tüm hatlar açık, sözleşme ve başarımlar sonsuz devam).

---

## 21. Marka & Kimlik

| Parametre | Değer |
|-----------|-------|
| Oyun İsmi | Demir Yolcusu |
| Para Birimi | Demir Altını (DA) |
| Oyuncu Hitabı | "Makinist" |
| Logo Stili | TCDD tarzı kırmızı-beyaz, resmi his |
| Lokomotif İsimleri | Hayali gerçekçi — Demir Rüzgarı, Boz Kaplan, Anadolu Yıldızı |
