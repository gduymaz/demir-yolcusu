---
name: game-tdd
description: "GdUnit4 ile test-driven game development. Test yazma, mock/stub, state machine testi, ekonomi testi."
---

# GdUnit4 ile Oyun TDD

## Test Şablonu
```gdscript
extends GdUnitTestSuite

func test_EconomySystem_Earn_ValidAmount_ShouldIncreaseBalance() -> void:
    # Arrange
    var economy = EconomySystem.new()
    economy.set_balance(100)
    # Act
    economy.earn(50, "ticket")
    # Assert
    assert_int(economy.get_balance()).is_equal(150)
```

## Test Stratejileri
- Ekonomi: Gelir/gider, yetersiz bakiye, bilet fiyat kademesi, indirimler
- Yolcu Bindirme: Doğru vagon, yanlış vagon engeli, kapasite aşımı
- Yakıt: Tüketim formülü, boş tank, otomatik ikmal
- İtibar: Asimetrik artış/azalış, yıldız hesaplama, kilit kontrolü
- İsometrik: Grid ↔ Screen dönüşüm doğruluğu
