# Son Ziyaret — Terk Edilmiş Hastane

Godot 4 proje yöneticisinden `project.godot` dosyasını içe aktar ve **F5** ile başlat. Açık oyun varsa önce **F8** ile durdur. Harici paket gerektirmez; Compatibility renderer kullanır.

Terk edilmiş hastanede uyanıyorsun. Arkadaşların uzakta; ailene dönmek için çıkışı bulmalısın. Gözlem odasındaki aile resmine yaklaş ve ona bak (veya E'ye bas). İlk koridor karşılaşmasında yaratık görünür biçimde önünde belirir. Anahtarlar zemin kattaki hemşire istasyonunda, üst kattaki arşiv ve ameliyathanede bulunur. Doğu taraftaki merdivenden yukarı çık; üç anahtarla zemin katın girişindeki acil çıkışa dön.

- WASD: yürü; fare: bak; Shift: koş.
- F: el feneri; E: resme bak / anahtar al / çıkışı aç.
- Esc: duraklat; M: bütün sesleri aç/kapat.
- Resimden sonra koridora çıktığında yaratık aynı kattaki koridorda belirir. Görünmezken çarpışması kapalıdır. Feneri ona tutunca durur; duvar arkasındayken veya başka yöne bakınca yaklaşır. Merdiveni kullanarak üst kata kadar takip eder.
- Elektrik kesintileri kısa sürer; el fenerin çalışmaya devam eder.

İki kat ve 16 oda: gözlem, hasta odaları, hemşire istasyonu, radyoloji, arşiv, depo ve ameliyathane. Otuz basamaklı fiziksel merdiven, korkuluklar, duvar koruma şeritleri ve oda levhaları bulunur. İndirilen 3D hastane yatakları, serum askıları, monitörler, tekerlekli sandalyeler, dolaplar ve ameliyathane cihazları kullanılır. Duvar ve zeminde renk, normal ve pürüzlülük haritaları vardır. Kaynaklar ve lisanslar `assets/CREDITS.md` içindedir. Bazı eşyalar stilizedir; AAA fotogerçekçi bir asset paketi değildir.

Eşyalar sürekli sallanmaz: 28–48 saniyelik aralıklardan sonra yakındaki tek yatak kısa süre hareket edip durur. Loş ışıklar 32–50 saniyelik aralıklarla kısa süre kesilebilir. Diyaloglar harf harf yazılır ve yazı akarken düşük seviyeli “zvvzt” sesi çıkar; duraklatma ve M tuşu bu sesi de kontrol eder. Müzik ve ayak sesleri düşük seviyededir. Seslendirme yerine sentezlenmiş konuşma efekti kullanılır.

Doğrulama: Godot ile `--headless --path . --fixed-fps 60 --script res://tests/hospital_v2_test.gd`. Testler merdivenden fiziksel çıkış/iniş, düşmanın katlar arası takibi, diyalog sesi, nadir eşya hareketleri, anahtarlar, yakalanma ve yeniden başlamayı kapsar. Görsel kayıt: `--path . --script res://tests/capture_hospital.gd`.

Godot tarafından desteklenmeyen `KHR_mesh_quantization` içeren kaynak modeller `tests/dequantize-assets.cjs` ile standart glTF kayan noktalı verilere dönüştürüldü. Oyunda kullanılan `.scn` kaynakları `tests/prepare_models.gd` ile üretildi; hazır olarak projeye dahildir.

Gönderilen `source.zip`, `textures.zip` ve `ue5_textures.zip` hastane paketi oyuna eklendi. Yatak, tekerlekli sandalye, dolap, bank, serum askısı/torbası, çıkış kapısı ve levhası, aydınlatma, duvar, zemin ve tavan modelleri kendi dokularıyla kullanılır. Pakette yaratık modeli bulunmadığından mevcut yaratık kullanılır. `assets/user_hospital/ready/` içindeki 25 Godot sahnesi, 14 materyal ve 40 paylaşılan doku hazırdır; oyunu çalıştırmak için dönüştürme gerekmez. Dokular en fazla 1024 piksele küçültülüp sıkıştırıldı; kaynak kopyalar ve İndirilenler klasöründeki ZIP dosyaları korunur. Gerekirse `--headless --path . --script res://tests/prepare_user_assets.gd` ile tekrar hazırlanabilir. Paketin kaynak/lisans bilgisi `assets/CREDITS.md` dosyasında ayrı belirtilmiştir.
