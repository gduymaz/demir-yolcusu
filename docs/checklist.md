# Demir Yolcusu — Faz Checklist

**Son Güncelleme:** 2026-02-16  
**Aktif Faz:** 9 (devam ediyor)  
**Toplam Test:** 359 / 359 PASSED

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
| 7 | Görevler + Olaylar + Kargo | ✅ Tamamlandı | 24+ |
| 8 | Dükkan + Yükseltmeler | ✅ Tamamlandı | 20+ |
| 9 | Başarımlar + Zorluk + Tutorial | 🟨 Devam Ediyor | 22+ |
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

## Faz 7 — Görevler + Rastgele Olaylar + Kargo ✅

### 7.1 Görev Sistemi (QuestSystem)
- [x] QuestData veri modeli (id, title, type, conditions, rewards, status)
- [x] QuestSystem mantığı
    - [x] Durum geçişleri: LOCKED → AVAILABLE → ACTIVE → COMPLETED
    - [x] Zincir sistemi: Tamamla → sonraki açılsın
    - [x] Koşul kontrolü (TRANSPORT: yolcu say, EXPLORE: durak uğra, CARGO_DELIVERY: kargo teslim)
    - [x] Ödül dağıtımı (EconomySystem + ReputationSystem)
    - [x] EventBus sinyalleri (quest_started, quest_progress, quest_completed)
- [x] Ege görev zinciri (5 görev)
    - [x] ege_01: İlk Sefer (Torbalı'ya git) → 100 DA + 0.2 ★
    - [x] ege_02: Efes Yolcuları (10 yolcu Selçuk'a) → 150 DA + 0.3 ★
    - [x] ege_03: Aydın Zeytini (kargo teslim) → 200 DA + 0.3 ★
    - [x] ege_04: Nazilli Ekspresi (tek seferde 20 yolcu) → 250 DA + 0.5 ★
    - [x] ege_05: Denizli Yolu (tam sefer) → 500 DA + 1.0 ★
- [x] Görev UI
    - [x] Harita: aktif görev paneli (sol alt)
    - [x] Harita: hedef durağında "!" ikonu
    - [x] Durak: görev yolcusunda sarı vurgu
    - [x] Görev tamamlanma popup + kondüktör kutlama
    - [x] Özet: görev ödülü satırı
- [x] Görev save/load entegrasyonu
- [x] TDD testleri geçiyor

### 7.2 Rastgele Olay Sistemi (RandomEventSystem)
- [x] RandomEventData veri modeli (id, type, trigger, probability, effect)
- [x] RandomEventSystem mantığı
    - [x] Tetiklenme zamanları (ON_TRAVEL, ON_STATION_ARRIVE, ON_TRIP_START)
    - [x] Olasılık kontrolü (balance.gd'den)
    - [x] Max 2 olay per sefer
    - [x] Aynı tipten max 1 per sefer
    - [x] Geçici efektler (sadece mevcut durak/sefer)
    - [x] EventBus sinyali (random_event_triggered)
- [x] MVP olayları (6 adet)
    - [x] Motor Arızası → hız ×0.5
    - [x] Kapı Arızası → durak süresi -5 sn
    - [x] Sürpriz VIP → ekstra VIP yolcu
    - [x] Hasta Yolcu → indir = +0.5 ★
    - [x] Yakıt Zamı → yakıt fiyat ×1.5
    - [x] Festival → yolcu ×2
- [x] Olay UI
    - [x] Üst banner (3 sn, ikon + başlık)
    - [x] Kondüktör otomatik mesaj
    - [x] Aktif efekt ikonu HUD'da
- [x] Olay → sahne entegrasyonu
    - [x] Motor arızası → travel_scene hız değişimi
    - [x] Kapı arızası → station_scene timer azaltma
    - [x] Festival → station_scene yolcu çarpanı
    - [x] Sürpriz VIP → station_scene ekstra spawn
    - [x] Hasta yolcu → station_scene "İndir" butonu
    - [x] Yakıt zamı → fuel_system fiyat çarpanı
- [x] TDD testleri geçiyor

### 7.3 Kargo Sistemi (CargoSystem)
- [x] CargoData veri modeli (id, name, origin, destination, reward, weight, deadline)
- [x] CargoSystem mantığı
    - [x] Kargo vagonu kontrolü (yoksa yüklenemez)
    - [x] Kapasite kontrolü
    - [x] Durakta rastgele kargo teklifi (0-2)
    - [x] Yükleme / boşaltma
    - [x] Hedef durağa varınca otomatik teslim + para
    - [x] Deadline azaltma + expire (ceza yok)
    - [x] EventBus sinyalleri (cargo_loaded, cargo_delivered, cargo_expired)
- [x] Ege kargoları (7 ürün havuzu)
    - [x] İzmir→Denizli: Elektronik Parça (80 DA)
    - [x] Selçuk→İzmir: Zeytin Yağı (60 DA)
    - [x] Aydın→İzmir: İncir Kutusu (50 DA)
    - [x] Denizli→Aydın: Tekstil Balya (70 DA)
    - [x] Torbalı→Nazilli: Tarım Malzemesi (40 DA)
    - [x] Nazilli→Selçuk: Pamuk Balyası (45 DA)
    - [x] İzmir→Aydın: Makine Yedek Parça (55 DA)
- [x] Kargo UI
    - [x] Durak: kargo teklif paneli + "Yükle" butonu
    - [x] Tren: kargo vagonunda kutu ikonu + sayı
    - [x] Seyir: kargo durumu bilgisi
    - [x] Teslim popup
    - [x] Özet: kargo geliri satırı
- [x] Kargo save/load entegrasyonu
- [x] TDD testleri geçiyor

### 7.4 Entegrasyon
- [x] ege_03 görevi CargoSystem ile bağlı (Aydın Zeytini)
- [x] Sefer özeti genişletildi (kargo + görev + olay satırları)
- [x] Save/load genişletildi (görev + kargo + olay verileri)
- [x] Harita: durak ikonları ("!" görev, "📦" kargo)
- [x] Tüm eski testler hâlâ geçiyor
- [x] Tam akış testi: Garaj → Harita → Seyir (olay) → Durak (kargo+yolcu+görev) → Özet → Harita

---

## Faz 8 — Dükkan + Yükseltmeler ✅

### 8.1 Durak Dükkan Sistemi
- [x] ShopData veri modeli (station_id, shop_type, level, income_per_trip)
- [x] Dükkan tipleri
    - [x] Büfe/Kantin → yolcu memnuniyeti + pasif gelir
    - [x] Hediyelik Eşya → bölgesel pasif gelir
    - [x] Kargo Deposu → kargo teklifi artışı
- [x] Dükkan mantığı
    - [x] Aç (para + itibar koşulu)
    - [x] Yükselt (seviye 1-3)
    - [x] Pasif gelir (sefer sonunda otomatik)
    - [x] Sınırlı slot per durak
- [x] Dükkan UI
    - [x] Durak sahnesinde "Dükkan" butonu
    - [x] Dükkan paneli (mevcut + satın alınabilir)
    - [x] Seviye göstergesi
- [x] Dükkan geliri sefer özetine ekleme
- [x] Save/load: dükkan seviyeleri
- [x] TDD testleri

### 8.2 Lokomotif/Vagon Yükseltme
- [x] Upgrade veri modeli (entity_id, upgrade_type, level, cost)
- [x] Lokomotif upgrade'leri (4 eksen)
    - [x] Hız → daha hızlı seferler
    - [x] Kapasite → daha çok vagon çekme
    - [x] Yakıt Verimliliği → daha az tüketim
    - [x] Dayanıklılık → daha az arıza
- [x] Vagon upgrade'leri (3 eksen)
    - [x] Konfor → yolcu memnuniyeti bonusu
    - [x] Kapasite → daha çok koltuk/kutu
    - [x] Bakım Hızı → daha az temizlik
- [x] Upgrade UI (garaj sahnesinde)
    - [x] Lokomotif/vagon seçince upgrade paneli
    - [x] Seviye + maliyet + efekt gösterimi
    - [x] "Yükselt" butonu
- [x] Üçlü kilit: Para + İtibar + Hat tamamlama
- [x] Kısmi respec (son 1-2 upgrade geri alınabilir)
- [x] Save/load: upgrade seviyeleri
- [x] TDD testleri

### 8.3 Garaj Mağaza Genişletme
- [x] Lokomotif satışı ekleme
    - [x] "Demir Yürek" (kömür, yeni) → daha iyi Kara Duman
    - [x] "Boz Kaplan" (dizel, eski) → itibar kilidi ile
- [x] Vagon: VIP + Yemekli vagon satışı ekleme
- [x] Fiyatlar balance.gd'den
- [x] İtibar kilidi kontrolü

---

## Faz 9 — Başarımlar + Zorluk + Tutorial 🟨

### 9.1 Başarım Sistemi (AchievementSystem)
- [x] AchievementData veri modeli (id, category, title, description, condition, reward)
- [x] 4 kategori (Sefer/Yolcu/Koleksiyon/Keşif)
- [x] 16 başarım tanımı eklendi (i18n anahtarları ile)
- [x] Otomatik takip (EventBus dinleyicileri)
- [x] Kademeli görünürlük (visible_after zinciri)
- [x] Ödül: bonus para (EconomySystem.earn)
- [x] Başarım popup (kondüktör mesajı + üst banner)
- [x] Başarım vitrini ekranı (kategori sekmeleri + ilerleme)
- [x] HUD'da toplam başarım sayacı (🏆 x/y)
- [x] Save/load: başarım durumları + sayaçlar
- [x] TDD testleri

### 9.2 Dinamik Zorluk Sistemi (DifficultySystem)
- [x] Son 3 sefer performansını takip et
- [x] 4 parametre otomatik ayarla
    - [x] Durak zaman limiti çarpanı
    - [x] Yolcu sabır çarpanı
    - [x] Arıza sıklığı çarpanı
    - [x] Bilet geliri çarpanı
- [x] Görünmez (oyuncuya açık menü yok)
- [x] Clamp sınırları (0.7 - 1.5)
- [x] Save/load: son 3 skor
- [x] TDD testleri

### 9.3 Tutorial İyileştirme
- [x] Kondüktör rehberli adım bazlı tutorial akışı (MVP 6 adım)
    - [x] Garaj (vagon ekleme)
    - [x] Harita (durak seçimi)
    - [x] Durak (ilk bindirme + süre uyarısı)
    - [x] Seyir (hız kontrolü)
    - [x] Özet (sefer sonucu)
- [x] Akıllı atlama: 2. save slotunda tutorial otomatik atlanır
- [x] Tutorial durumu save'e yazılır
- [x] Balonda "Atla >" ve "Devam >" kontrolleri
- [x] Hedef alan vurgulama efekti (glow/pulse)

### 9.4 Erişilebilirlik
- [x] Font boyutu: 3 seviye (küçük/orta/büyük)
- [x] Yavaş mod: 2× zaman limitleri
- [x] Ayarlar ekranı (ses + oynanış + görünüm + kayıt sil)
- [x] Ayarları save/load ile kalıcılaştırma

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
Bu checklist'i kontrol et: docs/checklist.md
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
