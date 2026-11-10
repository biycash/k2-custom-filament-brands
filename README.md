# K2 Custom Filament Brands

Creality K2 yazıcının dokunmatik ekranına **kendi filament markalarınızı** ekleyin.
Porima, Rhinolab, SAVA, Filamix… ne kullanıyorsanız, ekranda kendi adı ve markasıyla görünsün ve CFS yuvasına atanabilsin.

🇬🇧 [English version](README.en.md)

> **Gayriresmî bir araçtır, Creality ile bağlantısı yoktur.** Yazıcının içindeki bir sistem dosyasını değiştirir.
> Aşağıdaki [riskleri](#önce-okuyun-riskler-ve-sınırlamalar) okuyun. Tüm sorumluluk kullanıcıya aittir.

---

## Ne işe yarar?

| | Normalde | Bu araçla |
|---|---|---|
| Ekrandaki markalar | Sadece **Creality** ve **Generic** | Creality, Generic **ve sizin markalarınız** |
| Creality Print'te eklediğiniz özel filamentler | Ekranda **görünmez** | **Kendi markası ve adıyla** görünür |
| Örnek | Generic → ABS → Generic ABS | **Porima** → ABS → **Porima ABS Basic** |

Bir kez çalıştırırsınız. Creality Print'te özel filament ekledikçe veya firmware güncellemesinden sonra tekrar çalıştırırsınız.

## Neden ekranda görünmüyorlar?

Yazıcı, Creality hesabınızdaki bütün kişisel filament profillerini zaten indiriyor. Ama ekrana yalnızca
bir **sistem profilinden türetilmiş** olanları ekliyor. Creality Print'teki **"Özel filament ekle"** ile oluşturulan
profillerin "üst profili" (`inherits`) boş olduğu için yazıcı bunları sessizce atlıyor.

"Farklı kaydet" ile Generic bir profilden türetirseniz profil ekrana gelir, ama markası hep **Generic** görünür.
Bu araç, yazıcının kendi malzeme listesine sizin markanızla gerçek kayıtlar ekler.

---

## Önce okuyun: riskler ve sınırlamalar

- **Root erişimi gerekir.** Yazıcıda root (SSH) girişini açmanız gerekiyor. Bazı kaynaklar bunun garantiyi
  etkileyebileceğini söylüyor; yazıcı da açarken bir risk uyarısı gösteriyor.
- **Bir sistem dosyası değiştirilir.** Araç yazıcının malzeme listesini düzenler. Bir hata olursa ekrandaki malzeme
  seçimi bozulabilir. Bu yüzden araç her değişiklikten önce hem yazıcıda hem bilgisayarda **yedek alır**, önce
  **deneme** yapar ve tek tıkla **geri alma** sunar.
- **Firmware güncellemesi kayıtları büyük ihtimalle siler.** Güncellemeden sonra aracı yeniden çalıştırın.
- **Creality resmi malzeme listesini güncellerse** ne olacağı bilinmiyor. Markalarınız kaybolursa aracı yeniden çalıştırmanız yeterli.
- **Ekrandaki kayıt yalnızca yuvayı tanımlar.** Baskı sıcaklığı, hız ve diğer ayarlar Creality Print'teki profilinizden
  G-code ile gelir. Ancak filament yükleme ve boşaltma sırasında yazıcı ekrandaki kaydın sıcaklık aralığını kullanabilir;
  her yeni filamentin ilk kullanımında bunu izleyin.
- **Creality Print yuvayı profilinizle otomatik eşleştirmeyebilir.** Baskıyı gönderirken yuva ile profili elle seçin.
- **Otomatik yedekleme (auto refill):** Aynı tür ve aynı renkteki yuvalar "aynı malzeme" sayılır. Farklı markalarınız
  varsa yuvalara **farklı renkler** verin, yoksa biri bitince yazıcı diğerine geçebilir.
- **HIPS gibi yazıcının tanımadığı türler** ekranda kendi türüyle görünür. K2 Pro'da sorunsuz çalıştı; sizde sorun
  çıkarsa [Sorun giderme](#sorun-giderme-sss) bölümüne bakın.
- **Yalnızca K2 Pro'da test edildi.** K2 Plus, K2 ve K2 SE için test edilmedi. Bu modellerde önce deneme modunu
  çalıştırın (`-DryRun`, aşağıda). Sonucu bir [Issue](../../issues) açarak paylaşırsanız diğerlerine de yol gösterir.
- **Baskı sırasında çalıştırmayın.** Araç yazıcı baskıdaysa zaten durur.
- **Ekran nozül boyuna göre süzmüyor.** Her filament ailesi ekranda **tek kayıt** olarak görünür ve 0.2/0.4/0.6/0.8
  profillerini birlikte kapsar.
- **Creality Print'te çok sayıda profili kısa sürede oluşturmayın.** Bu aracın konusu değil, ama Creality bulutu toplu
  işlemlerde hesabı geçici olarak kısıtlayabiliyor (`1088 Please do not repeat the same operation`).

---

## Gereksinimler

- **Yazıcı:** Creality K2 Pro (test edildi). K2 Plus / K2 / K2 SE (test edilmedi).
- **Bilgisayar:** Windows 10 veya 11 (betikle kurulum için). Mac / Linux için: [Elle kurulum](docs/manual-install.md).
- **Creality Print 7.x**, filamentleriniz **"Özel filament ekle"** ile eklenmiş olmalı. Profilde **Marka (Vendor)** ve
  **Tür** doğru seçili olsun. Creality Print profil adını kendisi `Porima ABS Basic @Creality K2 Pro 0.4 nozzle` biçiminde verir.
- Yazıcı ve bilgisayar **aynı ağda** olmalı.
- İlk çalıştırmada internet gerekir (SSH için gereken PowerShell modülü otomatik indirilir).

---

## Kurulum (betikle, önerilen)

### 1. Yazıcıda root erişimini açın

1. Yazıcının ekranında **Ayarlar**'a girin ve aşağı kaydırıp **Root account information**'a dokunun.
2. Risk uyarısını okuyun, **"I have read and understood the risks of Root login"** kutusunu işaretleyin.
3. **30 saniye** bekleyin, sonra **OK**'e basın.
4. Ekranda görünen **root parolasını** bir yere not edin.

Fabrika ayarlarına dönerseniz bu adımı tekrarlamanız gerekir.
(Kaynaklar: [SimplyPrint K2 Pro kılavuzu](https://simplyprint.io/setup-guide/creality/k2-pro/on-printer),
[Helper Script Wiki – SSH](https://sw3defy.github.io/Creality-Helper-Script-Wiki-K2-Plus/firmwares/ssh-connection/))

### 2. Yazıcının IP adresini öğrenin

Ekranda **Ayarlar → Ağ**. Örnek: `192.168.1.25`.

### 3. Filamentlerinizi Creality Print'te hazırlayın

- Her filament için Creality Print'te **"Özel filament ekle"** ile profil oluşturun. **Marka** ve **Tür** alanlarını doldurun.
- Hangi nozüller için profil açtıysanız (0.2/0.4/0.6/0.8) hepsi tek ekran kaydında toplanır. Ayarlar 0.4 profilinden
  alınır; 0.4 yoksa 0.6, 0.8, 0.2 sırasıyla.
- Generic bir profilden **"Farklı kaydet"** ile oluşturduğunuz profiller zaten ekrana geliyor (marka Generic olarak); araç onlara dokunmaz.

### 4. Aracı indirin

1. Bu sayfanın üstündeki yeşil **Code** düğmesine, sonra **Download ZIP**'e tıklayın.
2. ZIP dosyasına sağ tıklayıp **Tümünü ayıkla** deyin. ZIP'in içinden çalıştırmayın, önce klasöre çıkarın.

### 5. Çalıştırın

Çıkardığınız klasörde **`Install-K2CustomFilamentBrands.cmd`** dosyasına çift tıklayın.

- Windows **"Windows bilgisayarınızı korudu"** derse: **Ek bilgi → Yine de çalıştır**.
- **Posh-SSH yüklensin mi?** sorusuna ilk seferde `E` yazın.
- **IP adresi** ve **root parolası** istenir. Parola yazarken ekranda görünmez, bu normal. Parola hiçbir yere kaydedilmez.
- Creality Print'te birden fazla yazıcı için özel profiliniz varsa hangisinin bu yazıcı olduğu sorulur.
- Araç eklenecek kayıtları listeler ve **önce yazıcıda dener**; bu aşamada hiçbir şey değişmez.
- **"Yukarıdaki kayıtlar yazıcıya yazılsın mı?"** sorusuna `E` yazın.

Örnek çıktı (kısaltılmış):

```text
[2] Creality Print profilleriniz okunuyor
   Creality Print: 7.0 | account folder: 1234567890 | printer: Creality K2 Pro | families: 21
   90001 | Porima ABS Basic         | Porima   | ABS  | nozzles 0.2,0.4,0.6,0.8
   90019 | SAVA TPU 60A             | SAVA     | TPU  | nozzles 0.2,0.4,0.6,0.8
[3] Yazicida deneniyor (canli dosyalar degismez)
   RESULT entries=77 count=77 custom=21 skipped=0 brands=Creality,Generic,Porima,SAVA,...
Yukaridaki kayitlar yaziciya yazilsin mi? (E/H, Y/N): E
[5] Kontrol
Yazicinin listesi: 77 malzeme, bu aracin kayitlari: 21
Tamam. Markalar ekranda hemen gorunmeli; gorunmezse yaziciyi yeniden baslatin.
```

### 6. Ekranda kontrol edin

Bir CFS yuvasında filament seçimini açın. Marka listesinde kendi markalarınız ve altlarında filamentleriniz görünmeli.
Görünmezse yazıcıyı yeniden başlatın.

**Önce sadece denemek isterseniz** (hiçbir şey yazmaz): klasörde adres çubuğuna `cmd` yazıp Enter'a basın, açılan pencerede:

```bat
Install-K2CustomFilamentBrands.cmd -DryRun
```

---

## Ne zaman tekrar çalıştırmalıyım?

- **Firmware güncellemesinden sonra** (markalar kaybolursa).
- Creality Print'te **yeni özel filament eklediğinizde** veya mevcut birinin değerlerini değiştirdiğinizde.

Tekrar çalıştırmak güvenlidir: araç önce kendi eklediği kayıtları kaldırır, sonra güncel listeyi ekler. Kimlikler
(`90001`, `90002`…) sabit kalır. Creality Print'te profil kaydetmek eklenen kayıtları silmez (test edildi).

## Kaldırma ve geri alma

| Dosya | Ne yapar |
|---|---|
| `Uninstall-K2CustomFilamentBrands.cmd` | **Yalnızca bu aracın eklediği** kayıtları kaldırır. Creality ve Generic kayıtlara dokunmaz. |
| `Restore-K2Backup.cmd` | Yazıcıdaki **en son yedeği** olduğu gibi geri koyar (bir şeyler ters giderse). |

Yedekler:
- **Yazıcıda:** `/mnt/UDISK/creality/userdata/box_backup_k2cfb_<tarih>/`
- **Bilgisayarda:** `Belgeler\K2CustomFilamentBrands\backups\<tarih>\`

---

## Sorun giderme (SSS)

**"running scripts is disabled on this system"**
`.ps1` dosyasını doğrudan çalıştırmayın; `.cmd` dosyalarını kullanın. Bunlar Windows ayarınızı değiştirmeden yalnızca o çalıştırma için izin verir.

**"Windows bilgisayarınızı korudu"**
**Ek bilgi → Yine de çalıştır**. İnternetten indirilen dosyalar için normal bir uyarıdır.

**Posh-SSH yüklenemedi**
İnternet bağlantınızı kontrol edin. Şirket ağındaysanız engellenmiş olabilir. Elle yüklemek için PowerShell'de:
`Install-Module Posh-SSH -Scope CurrentUser`

**"SSH baglantisi kurulamadi"**
Root erişimi açık mı, IP doğru mu, parolayı ekrandaki gibi mi girdiniz? Yazıcı ve bilgisayar aynı ağda mı?

**"SKIPPED … filament type 'XYZ' has no matching printer entry"**
Profilinizin türünü yazıcıdaki bir Generic türle eşleştiremedik. Creality Print'te profilin **Tür** alanını
desteklenen bir türe çevirin: PLA, PLA-CF, ABS, ABS-CF, ASA, PETG, PETG-CF, PET, PA, PA-CF, PC, PC-CF, TPU, PP, PVA, BVOH, HIPS.

**"SKIP … printer has no single 'Generic …' entry to copy"**
Yazıcınızın listesinde o Generic kayıt yok (diğer K2 modellerinde liste farklı olabilir). Profilin türünü değiştirin
ya da bir Issue açın.

**"SKIP … this name is already used by another entry"**
Filamentinizin adı ekranda zaten var olan bir adla aynı. Creality Print'te profil adını değiştirin.

**HIPS (veya başka özel tür) ekranda/CFS'de sorun çıkarıyor**
`tools\build_custom_spec.ps1` dosyasını Not Defteri ile açın, `$screenTypeOverride = @{ 'HIPS' = 'HIPS' }`
satırındaki ikinci `'HIPS'` değerini `'ABS'` yapın ve aracı tekrar çalıştırın.

**Markalar ekranda görünmüyor**
Yazıcıyı yeniden başlatın. Firmware güncellemesi olduysa aracı tekrar çalıştırın. Sonuç satırında `skipped=` sıfırdan büyükse yukarıdaki maddelere bakın.

**"Yazici bu sirada listeyi degistirdi"**
Yazıcı tam o sırada buluttan profil indirmiş. Bir dakika bekleyip tekrar çalıştırın.

**Birden fazla Creality hesabı**
Araç en çok özel profili olan hesabı seçer ve diğerlerini uyarıyla gösterir. Başka bir hesap için
`tools\K2CustomMaterials.ps1 -UserFolder <klasör adı>` kullanın.

---

## Nasıl çalışır? (teknik)

- `tools\build_custom_spec.ps1`: `%APPDATA%\Creality\Creality Print\<sürüm>\user\<hesap>\filament\` altındaki,
  üst profili boş özel filamentleri okur, filament ailesine göre gruplar ve `custom_spec.json` üretir.
- `tools\printer_material_install.py`: Yazıcının kendi `python3`'ü ile çalışır. Aynı türdeki Generic kaydı kopyalar;
  kimlik, marka, ad, sıcaklık aralığı, yoğunluk, nozül listesi ve eşleşen ayarları değiştirir. Yeni dosyaları yalnızca
  `/tmp` altına yazar.
- `tools\K2CustomMaterials.ps1`: Yedekler, yükler, dener, onay alır. Canlı dosyalar o arada değişmediyse yerine koyar
  ve yazıcıdan geri okuyarak doğrular.
- **Yazıcıdaki dosyalar:** `/mnt/UDISK/creality/userdata/box/material_database.json` (malzeme listesi),
  `material_option.json` (ekrandaki marka → tür → ad listesi), `k2_custom_filament_brands.json` (bu aracın eklediklerinin kaydı).
- **Bilgisayarda:** `Belgeler\K2CustomFilamentBrands\`: `custom_ids.json` (sabit kimlikler; silmeyin), `custom_spec.json`,
  `settings.json` (son IP), `backups\`.

## Elle kurulum (Mac / Linux / betik kullanmadan)

Adım adım rehber: **[docs/manual-install.md](docs/manual-install.md)**

## Katkı ve geri bildirim

Başka bir K2 modelinde denediyseniz sonucu bir [Issue](../../issues) ile paylaşın: yazıcı modeli, firmware sürümü,
`-DryRun` çıktısı. Ekran görüntüleri çok işe yarar.

## Lisans ve sorumluluk reddi

[MIT Lisansı](LICENSE). Bu yazılım "olduğu gibi" sunulur. Yazıcınıza, filamentinize veya garantinize gelebilecek
zararlardan geliştiriciler sorumlu tutulamaz. "Creality", "K2" ve diğer marka adları sahiplerine aittir; bu proje
onlarla bağlantılı değildir.
