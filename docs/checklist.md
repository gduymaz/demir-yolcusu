# Demir Yolcusu — Faz Checklist

**Son Güncelleme:** ___________  
**Aktif Faz:** ___  
**Toplam Test:** ___ / ___ PASSED

> Bu dosyayı her faz sonunda güncelle. Codex/Claude Code'a "bu checklist'i kontrol et" diyerek durumu doğrulat.

---

## 📊 Genel İlerleme

| Faz | Başlık | Durum | Test |
|-----|--------|-------|------|
| 1 | Proje Altyapısı | ✅ Tamamlandı | 7 |
| 2 | Temel Sistemler | ✅ Tamamlandı | 65 |
| 3 | Durak + Yolcu Bindirme | ✅ Tamamlandı | 56 |
| 4 | Garaj + Tren Yönetimi | ✅ Tamamlandı | — |
| 5 | Harita + Seyir | ✅ Tamamlandı | 49 |
| 6 | Yakıt + Özet + Kayıt + Kondüktör | ✅ Tamamlandı | 20+ |
| 7 | Görevler + Olaylar + Kargo | 🔄 Devam ediyor | — |
| 8 | Dükkan + Yükseltmeler | ⬜ Başlanmadı | — |
| 9 | Başarımlar + Zorluk + Tutorial | ⬜ Başlanmadı | — |
| 10 | Ses + Görsel + MVP Final | ⬜ Başlanmadı | — |
| 11 | Marmara Hattı (Post-MVP) | ⬜ Başlanmadı | — |
| 12 | İç Anadolu Hattı (Post-MVP) | ⬜ Başlanmadı | — |
| 13 | Ek İçerik + Yayın (Post-MVP) | ⬜ Başlanmadı | — |

---

## ═══════════════════════════════════════
## MVP FAZLARI (Faz 1-10) — Ege Hattı
## ═══════════════════════════════════════

---

## Faz 1 — Proje Altyapısı ✅

- [x] Godot 4.3+ projesi oluşturuldu (project.godot)
- [x] GdUnit4 test framework kuruldu
- [x] EventBus autoload oluşturuldu (sinyal sistemi)
- [x] Proje klasör yapısı oluşturuldu (src/, tests/, assets/, docs/)
- [x] .gitignore oluşturuldu
- [x] Git repository başlatıldı
- [x] İlk test yazıldı ve geçti
- [x] CLAUDE.md oluşturuldu

---

## Faz 2 — Temel Sistemler ✅

- [x] constants.gd — 7 enum + yapısal sabitler
- [x] balance.gd — Ekonomi denge değerleri
- [x] EconomySystem — Para yönetimi + bilet fiyatı + sefer özeti
    - [x] earn() / spend() / get_balance() / can_afford()
    - [x] Mesafe kademeli bilet fiyatlandırma (TCDD tarzı)
    - [x] 39 test geçiyor
- [x] ReputationSystem — Asimetrik itibar sistemi
    - [x] add() / remove() (×0.5 yavaş düşüş)
    - [x] get_stars() (0.0-5.0)
    - [x] meets_requirement()
    - [x] 26 test geçiyor

---

## Faz 3 — Durak + Yolcu Bindirme (Core Loop) ✅

### Faz 3a — Oyun Mantığı
- [x] PassengerData — Yolcu veri modeli (id, type, destination, fare, patience)
- [x] PassengerFactory — Tip + popülerlik bazlı yolcu üretimi
    - [x] Ücret hesaplama (öğrenci %50, yaşlı %30, VIP 3x)
    - [x] Sabır hesaplama (VIP düşük, öğrenci yüksek)
    - [x] Testler geçiyor
- [x] WagonData — Vagon veri modeli (id, type, capacity, current_passengers)
    - [x] add_passenger() / remove_passenger()
    - [x] Tip uyumu kontrolü (VIP sadece VIP/Business vagona)
    - [x] Testler geçiyor
- [x] BoardingSystem — Yolcu bindirme/indirme mantığı
    - [x] Doğru vagon → kabul, yanlış vagon → red
    - [x] Kapasite kontrolü
    - [x] EventBus entegrasyonu
    - [x] Testler geçiyor
- [x] PatienceSystem — Sabır azalması + kaybolma
    - [x] Zaman bazlı sabır azalması
    - [x] Sabır bitince → itibar düşüşü
    - [x] Testler geçiyor

### Faz 3b — İstasyon Sahnesi
- [x] Placeholder sprite'lar (kod ile renkli dikdörtgenler)
    - [x] Yolcu: 16x24 renkli daire + tip harfi
    - [x] Vagon: 48x32 renkli dikdörtgen
    - [x] Lokomotif: 64x48 kırmızı dikdörtgen
- [x] Durak sahnesi (station_scene) — portrait 540x960
    - [x] HUD (para, itibar, süre)
    - [x] Ray + tren (lokomotif + vagonlar)
    - [x] Bekleme alanı (yolcular)
    - [x] Sürükle-bırak (touch + mouse)
    - [x] Doğru vagon → yeşil flash + para
    - [x] Yanlış vagon → kırmızı flash + geri dön
    - [x] Geri sayım timer (20 sn)
    - [x] Sefer sonu özet panel
    - [x] "Tekrar Oyna" butonu

---

## Faz 4 — Garaj + Tren Yönetimi ✅

- [x] LocomotiveData — Lokomotif veri modeli
    - [x] "Kara Duman" (kömür, eski, yavaş, 2-3 vagon)
    - [x] Testler geçiyor
- [x] FuelSystem — Yakıt deposu + tüketim hesaplama
    - [x] consume() / refuel()
    - [x] Otomatik minimum ikmal
    - [x] Testler geçiyor
- [x] TrainConfig — Lokomotif + vagon listesi yönetimi
    - [x] max_wagons kontrolü
    - [x] Vagon ekleme/çıkarma/sıra değiştirme
    - [x] Toplam kapasite hesaplama
    - [x] Testler geçiyor
- [x] PlayerInventory — Envanter sistemi
    - [x] Başlangıç: Kara Duman + 1 ekonomi + 1 kargo
    - [x] Satın alma (EconomySystem entegrasyonu)
    - [x] Testler geçiyor
- [x] Garaj Sahnesi (garage_scene)
    - [x] Lokomotif seçimi
    - [x] Vagon sürükle-bırak (envanter → tren)
    - [x] Vagon çıkarma
    - [x] Kapasite göstergesi
    - [x] "Sefere Çık" butonu → Durak sahnesine geçiş
    - [x] "Mağaza" butonu → Satın alma paneli
- [x] Basit Mağaza Paneli
    - [x] Vagon satışı (Ekonomi, Business, Kargo + fiyatlar)
    - [x] Yetersiz bakiye kontrolü
- [x] Sahne akışı: Garaj ↔ Durak geçişi
    - [x] TrainConfig verisi sahneler arası aktarım
    - [x] Durak sahnesi garajdan gelen vagonlarla çalışıyor

---

## Faz 5 — Harita + Seyir ✅

- [x] RouteData — Rota veri modeli (Haversine GPS mesafe)
    - [x] Ege rotası: 7 gerçek TCDD durağı (İzmir → Denizli)
    - [x] GPS koordinatları + mesafe hesaplama
    - [x] 23 test geçiyor
- [x] TripPlanner — Sefer planlama + yönetim
    - [x] Başlangıç/bitiş durak seçimi
    - [x] Rota ön izleme (tahmini gelir + yakıt)
    - [x] Çoklu durak akışı
    - [x] 26 test geçiyor
- [x] Harita Sahnesi (map_scene)
    - [x] Ege bölgesi haritası
    - [x] Durak seçimi (tıklama)
    - [x] Rota gösterimi
    - [x] "Sefere Başla" butonu
- [x] Seyir Sahnesi (travel_scene)
    - [x] Tren animasyonu
    - [x] İlerleme barı
    - [x] 1x/2x hız seçeneği
    - [x] "Durağa Gir" butonu
- [x] Çoklu Durak Akışı
    - [x] Garaj → Harita → [Seyir ↔ Durak] × N → Harita

---

## Faz 6 — Yakıt + Özet + Kayıt + Kondüktör ✅

- [x] Yakıt entegrasyonu (seyir ile)
    - [x] Seyir sırasında yakıt tüketimi (mesafe × oran)
    - [x] Yakıt barı HUD'da (yeşil/sarı/kırmızı)
    - [x] Düşük/kritik yakıt uyarıları
    - [x] Yakıt bitince hız düşüşü
    - [x] Sefer başı otomatik minimum ikmal
- [x] Durakta yakıt ikmal
    - [x] "Yakıt Al" butonu
    - [x] Maliyet hesaplama + bakiye kontrolü
    - [x] İkmal progress animasyonu
- [x] Geliştirilmiş sefer özeti (summary_scene)
    - [x] Gelir bölümü (bilet + durak bazlı breakdown)
    - [x] Gider bölümü (yakıt)
    - [x] Net kazanç (yeşil/kırmızı renk)
    - [x] İtibar değişimi
    - [x] İstatistikler
    - [x] "Haritaya Dön" butonu
- [x] Save/Load sistemi
    - [x] user://save_slot_1.json
    - [x] Para, itibar, envanter, tren config, yakıt, istatistikler, tutorial durumu
    - [x] Sefer sonunda otomatik kayıt
    - [x] Oyun açılışında otomatik yükleme
- [x] Kondüktör maskot (conductor_manager)
    - [x] Sağ alt placeholder + konuşma balonu
    - [x] Sahneye göre ipuçları (Türkçe)
    - [x] Her ipucu tek sefer gösterim
    - [x] 5 sn auto-hide
- [x] Oyun başlangıç akışı
    - [x] Kayıt yoksa → 3 mesajlık intro
    - [x] Kayıt varsa → direkt garaj
    - [x] Başlangıç: 500 DA, 3.0 ★, Kara Duman + 1 ekonomi + 1 kargo
- [x] HUD tutarlılığı (global_hud)
    - [x] Para, itibar, yakıt, sahne başlığı tüm sahnelerde
    - [x] Local HUD çakışmaları temizlendi

### Faz 6 Ekstra (altyapı iyileştirmeleri)
- [x] i18n altyapısı (i18n.gd + tr/en JSON dosyaları)
- [x] Debug logger altyapısı (debug_logger.gd)
- [x] Yakıt matematik düzeltmesi (birim fiyat doğruluğu)
- [x] Kod temizliği ve standartlaştırma

---

## Faz 7 — Görevler + Rastgele Olaylar + Kargo 🔄

### 7.1 Görev Sistemi (QuestSystem)
- [ ] QuestData veri modeli (id, title, type, conditions, rewards, status)
- [ ] QuestSystem mantığı
    - [ ] Durum geçişleri: LOCKED → AVAILABLE → ACTIVE → COMPLETED
    - [ ] Zincir sistemi: Tamamla → sonraki açılsın
    - [ ] Koşul kontrolü (TRANSPORT: yolcu say, EXPLORE: durak uğra, CARGO_DELIVERY: kargo teslim)
    - [ ] Ödül dağıtımı (EconomySystem + ReputationSystem)
    - [ ] EventBus sinyalleri (quest_started, quest_progress, quest_completed)
- [ ] Ege görev zinciri (5 görev)
    - [ ] ege_01: İlk Sefer (Torbalı'ya git) → 100 DA + 0.2 ★
    - [ ] ege_02: Efes Yolcuları (10 yolcu Selçuk'a) → 150 DA + 0.3 ★
    - [ ] ege_03: Aydın Zeytini (kargo teslim) → 200 DA + 0.3 ★
    - [ ] ege_04: Nazilli Ekspresi (tek seferde 20 yolcu) → 250 DA + 0.5 ★
    - [ ] ege_05: Denizli Yolu (tam sefer) → 500 DA + 1.0 ★
- [ ] Görev UI
    - [ ] Harita: aktif görev paneli (sol alt)
    - [ ] Harita: hedef durağında "!" ikonu
    - [ ] Durak: görev yolcusunda sarı vurgu
    - [ ] Görev tamamlanma popup + kondüktör kutlama
    - [ ] Özet: görev ödülü satırı
- [ ] Görev save/load entegrasyonu
- [ ] TDD testleri geçiyor

### 7.2 Rastgele Olay Sistemi (RandomEventSystem)
- [ ] RandomEventData veri modeli (id, type, trigger, probability, effect)
- [ ] RandomEventSystem mantığı
    - [ ] Tetiklenme zamanları (ON_TRAVEL, ON_STATION_ARRIVE, ON_TRIP_START)
    - [ ] Olasılık kontrolü (balance.gd'den)
    - [ ] Max 2 olay per sefer
    - [ ] Aynı tipten max 1 per sefer
    - [ ] Geçici efektler (sadece mevcut durak/sefer)
    - [ ] EventBus sinyali (random_event_triggered)
- [ ] MVP olayları (6 adet)
    - [ ] Motor Arızası → hız ×0.5
    - [ ] Kapı Arızası → durak süresi -5 sn
    - [ ] Sürpriz VIP → ekstra VIP yolcu
    - [ ] Hasta Yolcu → indir = +0.5 ★
    - [ ] Yakıt Zamı → yakıt fiyat ×1.5
    - [ ] Festival → yolcu ×2
- [ ] Olay UI
    - [ ] Üst banner (3 sn, ikon + başlık)
    - [ ] Kondüktör otomatik mesaj
    - [ ] Aktif efekt ikonu HUD'da
- [ ] Olay → sahne entegrasyonu
    - [ ] Motor arızası → travel_scene hız değişimi
    - [ ] Kapı arızası → station_scene timer azaltma
    - [ ] Festival → station_scene yolcu çarpanı
    - [ ] Sürpriz VIP → station_scene ekstra spawn
    - [ ] Hasta yolcu → station_scene "İndir" butonu
    - [ ] Yakıt zamı → fuel_system fiyat çarpanı
- [ ] TDD testleri geçiyor

### 7.3 Kargo Sistemi (CargoSystem)
- [ ] CargoData veri modeli (id, name, origin, destination, reward, weight, deadline)
- [ ] CargoSystem mantığı
    - [ ] Kargo vagonu kontrolü (yoksa yüklenemez)
    - [ ] Kapasite kontrolü
    - [ ] Durakta rastgele kargo teklifi (0-2)
    - [ ] Yükleme / boşaltma
    - [ ] Hedef durağa varınca otomatik teslim + para
    - [ ] Deadline azaltma + expire (ceza yok)
    - [ ] EventBus sinyalleri (cargo_loaded, cargo_delivered, cargo_expired)
- [ ] Ege kargoları (7 ürün havuzu)
    - [ ] İzmir→Denizli: Elektronik Parça (80 DA)
    - [ ] Selçuk→İzmir: Zeytin Yağı (60 DA)
    - [ ] Aydın→İzmir: İncir Kutusu (50 DA)
    - [ ] Denizli→Aydın: Tekstil Balya (70 DA)
    - [ ] Torbalı→Nazilli: Tarım Malzemesi (40 DA)
    - [ ] Nazilli→Selçuk: Pamuk Balyası (45 DA)
    - [ ] İzmir→Aydın: Makine Yedek Parça (55 DA)
- [ ] Kargo UI
    - [ ] Durak: kargo teklif paneli + "Yükle" butonu
    - [ ] Tren: kargo vagonunda kutu ikonu + sayı
    - [ ] Seyir: kargo durumu bilgisi
    - [ ] Teslim popup
    - [ ] Özet: kargo geliri satırı
- [ ] Kargo save/load entegrasyonu
- [ ] TDD testleri geçiyor

### 7.4 Entegrasyon
- [ ] ege_03 görevi CargoSystem ile bağlı (Aydın Zeytini)
- [ ] Sefer özeti genişletildi (kargo + görev + olay satırları)
- [ ] Save/load genişletildi (görev + kargo + olay verileri)
- [ ] Harita: durak ikonları ("!" görev, "📦" kargo)
- [ ] Tüm eski testler hâlâ geçiyor
- [ ] Tam akış testi: Garaj → Harita → Seyir (olay) → Durak (kargo+yolcu+görev) → Özet → Harita

---

## Faz 8 — Dükkan + Yükseltmeler ⬜

### 8.1 Durak Dükkan Sistemi
- [ ] ShopData veri modeli (station_id, shop_type, level, income_per_trip)
- [ ] Dükkan tipleri
    - [ ] Büfe/Kantin → yolcu memnuniyeti + pasif gelir
    - [ ] Hediyelik Eşya → bölgesel pasif gelir
    - [ ] Kargo Deposu → kargo kapasitesi artışı
- [ ] Dükkan mantığı
    - [ ] Aç (para + itibar koşulu)
    - [ ] Yükselt (seviye 1-3)
    - [ ] Pasif gelir (sefer sonunda otomatik)
    - [ ] Sınırlı slot per durak
- [ ] Dükkan UI
    - [ ] Durak sahnesinde "Dükkan" butonu
    - [ ] Dükkan paneli (mevcut + satın alınabilir)
    - [ ] Seviye göstergesi
- [ ] Dükkan geliri sefer özetine ekleme
- [ ] Save/load: dükkan seviyeleri
- [ ] TDD testleri

### 8.2 Lokomotif/Vagon Yükseltme
- [ ] Upgrade veri modeli (entity_id, upgrade_type, level, cost)
- [ ] Lokomotif upgrade'leri (4 eksen)
    - [ ] Hız → daha hızlı seferler
    - [ ] Kapasite → daha çok vagon çekme
    - [ ] Yakıt Verimliliği → daha az tüketim
    - [ ] Dayanıklılık → daha az arıza
- [ ] Vagon upgrade'leri (4 eksen)
    - [ ] Konfor → yolcu memnuniyeti bonusu
    - [ ] Kapasite → daha çok koltuk
    - [ ] Görsel → renk/desen seçimi
    - [ ] Bakım Hızı → daha az temizlik
- [ ] Upgrade UI (garaj sahnesinde)
    - [ ] Lokomotif/vagon seçince upgrade paneli
    - [ ] Seviye + maliyet + efekt gösterimi
    - [ ] "Yükselt" butonu
- [ ] Üçlü kilit: Para + İtibar + Hat tamamlama
- [ ] Kısmi respec (son 1-2 upgrade geri alınabilir)
- [ ] Save/load: upgrade seviyeleri
- [ ] TDD testleri

### 8.3 Garaj Mağaza Genişletme
- [ ] Lokomotif satışı ekleme
    - [ ] "Demir Yürek" (kömür, yeni) → daha iyi Kara Duman
    - [ ] "Boz Kaplan" (dizel, eski) → itibar kilidi ile
- [ ] Vagon: VIP + Yemekli vagon satışı ekleme
- [ ] Fiyatlar balance.gd'den
- [ ] İtibar kilidi kontrolü

---

## Faz 9 — Başarımlar + Zorluk + Tutorial ⬜

### 9.1 Başarım Sistemi (AchievementSystem)
- [ ] AchievementData veri modeli (id, category, title, description, condition, reward)
- [ ] 4 kategori
    - [ ] Sefer: "İlk Sefer", "10. Sefer", "100 km", "500 km", "1000 km"
    - [ ] Yolcu: "100 Yolcu", "İlk VIP", "0 Kayıp Sefer", "50 VIP"
    - [ ] Koleksiyon: "İlk Yükseltme", "2. Lokomotif", "Tüm Vagon Tipleri"
    - [ ] Keşif: "Tüm Ege Durakları", "Gece Seferi", "Festival Deneyimi"
- [ ] Otomatik takip (EventBus'tan dinle)
- [ ] Kademeli görünürlük (kazandıkça sonraki açığa çıkar)
- [ ] Ödül: Rozet + bonus para
- [ ] Başarım popup (kondüktör kutlama + rozet animasyonu)
- [ ] Başarım vitrini ekranı
- [ ] Save/load: başarım durumları
- [ ] TDD testleri

### 9.2 Dinamik Zorluk Sistemi (DifficultySystem)
- [ ] Son 3 sefer performansını takip et
- [ ] 4 parametre otomatik ayarla
    - [ ] Durak zaman limiti çarpanı
    - [ ] Yolcu sabır çarpanı
    - [ ] Arıza sıklığı çarpanı
    - [ ] Bilet geliri çarpanı
- [ ] Görünmez (oyuncu fark etmez)
- [ ] Sınırlar: Çok kolay/çok zor olmayacak şekilde clamp
- [ ] TDD testleri

### 9.3 Tutorial İyileştirme
- [ ] Kondüktör rehberli ilk 2-3 sefer (adım adım)
    - [ ] Garaj: "Şimdi vagonu buraya sürükle"
    - [ ] Harita: "Torbalı'yı seç, ilk seferimiz kısa olsun"
    - [ ] Durak: "Yolcuyu tut ve vagona bırak"
    - [ ] Seyir: "Trenimiz yolda, manzaranın keyfini çıkar"
- [ ] Akıllı atlama: 2. save slotunda tutorial otomatik atlanır
- [ ] Tutorial durumu save'e yazılır
- [ ] İpucu → butonu vurgulama efekti (glow/pulse)

### 9.4 Erişilebilirlik
- [ ] Font boyutu: 3 seviye (küçük/orta/büyük)
- [ ] Yavaş mod: 2× zaman limitleri
- [ ] Ayarlar ekranında toggle

---

## Faz 10 — Ses + Görsel + MVP Final ⬜

### 10.1 Ses Sistemi
- [ ] AudioManager genişletme
- [ ] Müzik: Ege bölgesi teması (klarnet esintili)
    - [ ] Garaj müziği
    - [ ] Harita müziği
    - [ ] Seyir müziği
    - [ ] Durak müziği
- [ ] SFX
    - [ ] Tren düdüğü (kalkış/varış)
    - [ ] Para kazanma sesi
    - [ ] Yolcu bindirme/indirme
    - [ ] Sürükle-bırak (tutma/bırakma)
    - [ ] Başarı/hata sesi
    - [ ] Timer uyarısı
    - [ ] Yakıt ikmal
    - [ ] Buton tıklama
- [ ] Türkçe durak anonsu ("Sayın yolcular, Selçuk istasyonuna...")
- [ ] Kondüktör tepki sesleri ("hm", "aha", "oh")
- [ ] Ayrı müzik/SFX ses seviyesi ayarı

### 10.2 Placeholder → Gerçek Görsel Geçişi
- [ ] Lokomotif sprite (8 yönlü + tekerlek animasyonu)
- [ ] Vagon sprite'ları (tip renkleriyle)
- [ ] Yolcu sprite'ları (4 tip — görsel ayrım)
- [ ] Durak arka planları (Ege stili — kıyı/zeytin/güneş)
- [ ] Harita görseli (stilize pixel art Türkiye)
- [ ] Kondüktör sprite
- [ ] UI ikonları (para, yıldız, yakıt, kargo)
- [ ] Ekran geçiş animasyonları
- [ ] Splash screen

### 10.3 Kozmetik Özelleştirme
- [ ] Lokomotif/vagon renk değiştirme
- [ ] Desen/çıkartma seçimi (bayrak, TCDD, şehir armaları)
- [ ] Satın alma + başarım ödülü olarak açılma

### 10.4 MVP Final Test & Polish
- [ ] Tüm testler geçiyor
- [ ] Tam oyun akışı baştan sona oynanabilir
- [ ] Save/load tam çalışıyor (3 slot)
- [ ] İlk açılış → tutorial → ilk sefer → para kazan → yükselt → tekrar oyna
- [ ] 15-20 dk oturum testi
- [ ] Performans: 30 FPS sabit
- [ ] Bellek: <200 MB
- [ ] APK boyut kontrolü
- [ ] Türkçe metin kontrolü (ş,ğ,ü,ö,ç,ı)
- [ ] Touch kontrol testi (gerçek cihaz)

---

## ═══════════════════════════════════════
## POST-MVP FAZLARI (Faz 11-13)
## ═══════════════════════════════════════

---

## Faz 11 — Marmara Hattı ⬜

- [ ] Marmara rotası verisi (İstanbul → Ankara, gerçek TCDD durakları)
- [ ] Bölgesel renk paleti (ilkbahar/sonbahar tonu)
- [ ] Bölgesel durak arka planları
- [ ] Bölgesel müzik (modern orkestral)
- [ ] Marmara görev zinciri (5 görev)
- [ ] Marmara kargoları (sanayi ürünleri)
- [ ] Marmara rastgele olayları (yoğun trafik teması)
- [ ] Yeni lokomotif: "Demir Rüzgarı" (dizel, yeni)
- [ ] Hat açılma koşulu: Ege tamamlanmış + itibar ≥ 3.5
- [ ] Kondüktör kıyafet değişimi (Marmara stili)
- [ ] Harita genişletme (Marmara bölgesi + sis kaldırma)

---

## Faz 12 — İç Anadolu Hattı ⬜

- [ ] İç Anadolu rotası (Ankara → Konya → Kayseri, gerçek TCDD)
- [ ] Bölgesel renk paleti (kış/step tonu)
- [ ] Bölgesel durak arka planları (kar, buğday tarlası)
- [ ] Bölgesel müzik (bağlama esintili)
- [ ] İç Anadolu görev zinciri (5 görev)
- [ ] İç Anadolu kargoları (buğday, un, halı)
- [ ] İç Anadolu olayları (kar fırtınası, rampa etkisi)
- [ ] Yeni lokomotif: "Anadolu Yıldızı" (elektrik)
- [ ] Hat açılma koşulu: Marmara tamamlanmış + itibar ≥ 4.0
- [ ] Arazi etkisi: Dağlık bölge = ekstra yakıt tüketimi
- [ ] Gündüz/gece mekanik etkisi aktif (gece = az yolcu, çok yakıt)

---

## Faz 13 — Ek İçerik + Yayın ⬜

- [ ] 3 slot save sistemi tam çalışıyor
- [ ] İstatistik ekranı (toplam sefer/yolcu/km/kazanç)
- [ ] Eğitici içerik: Duraklarda tıklanabilir bilgi (şehir/kültür/TCDD)
- [ ] Teknoloji ağacı tam dallanma
- [ ] Sandbox modu (tüm hatlar açık, hikaye bitti)
- [ ] Ek başarımlar (cross-hat başarımları)
- [ ] iOS App Store hazırlığı
- [ ] Google Play Store hazırlığı
- [ ] App Store görselleri + açıklama metni
- [ ] Final performans optimizasyonu
- [ ] Beta test (gerçek cihazlarda)
- [ ] Yayın!

---

## 🔍 Doğrulama Komutu

Her faz sonunda bu komutu Codex/Claude Code'a ver:

```
Bu checklist'i kontrol et: docs/CHECKLIST.md
1. Mevcut faz için tüm maddeler tamamlandı mı?
2. Tüm testler hâlâ geçiyor mu? (önceki fazlar dahil)
3. Save/load çalışıyor mu? (kaydet → kapat → aç → aynı durum mu?)
4. Sahne akışı kopuk mu? (her sahne geçişini test et)
5. Eksik veya kırık bir şey var mı?
Sonucu checklist formatında raporla.
```

---

## 📝 Notlar

- Her "[ ]" → "[x]" değiştirmesini ilgili faz tamamlandığında yap
- Test sayılarını her faz sonunda güncelle
- Yeni bug/teknik borç bulunursa bu dosyanın sonuna "Bilinen Sorunlar" bölümü ekle
- Post-MVP fazları tahmindir, GDD'ye göre değişebilir