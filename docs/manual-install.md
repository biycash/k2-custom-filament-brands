# Elle kurulum (Mac / Linux / betik kullanmadan)

🇬🇧 [English](manual-install.en.md) · [Ana sayfaya dön](../README.md)

Windows'ta en kolay yol [betikle kurulum](../README.md#kurulum-betikle-önerilen). Bu sayfa Mac/Linux kullananlar ve
ne yapıldığını adım adım görmek isteyenler için. Başlamadan önce ana sayfadaki
[riskleri](../README.md#önce-okuyun-riskler-ve-sınırlamalar) okuyun.

İki yol var:

| | Yol A: Liste + yazıcıdaki Python (önerilen) | Yol B: Dosyayı tamamen elle düzenlemek |
|---|---|---|
| Zorluk | Kolay–orta | Orta–zor |
| Hata riski | Düşük; Python kontrol eder | Yüksek; tek virgül hatası listeyi bozar |
| Tekrar kurulum ve kaldırma | Komutla | Elle |

## Ortak hazırlık

1. **Root erişimini açın:** Ekranda **Ayarlar → Root account information**. Kutuyu işaretleyin, 30 saniye bekleyin,
   **OK**'e basın ve parolayı not edin.
2. **IP adresini öğrenin:** Ekranda **Ayarlar → Ağ**.
3. **Bağlanma araçları:**
   - **Mac / Linux:** Hazır gelen **Terminal** yeterli (`ssh` ve `scp` komutları).
   - **Windows'ta elle yapmak isterseniz:** [WinSCP](https://winscp.net) (dosya kopyalama ve düzenleme) ve
     WinSCP'nin içindeki **"Open in PuTTY"** ya da Windows'un kendi `ssh` komutu.
4. **Baskı yapılmıyor olsun.**

Aşağıda `YAZICI_IP` yazan yerlere kendi IP adresinizi yazın. Parola sorulduğunda root parolasını girin; yazarken görünmez, bu normal.

---

## Yol A: Liste dosyası + yazıcıdaki Python (önerilen)

Bu yolda eklemek istediğiniz filamentleri küçük bir liste dosyasına yazarsınız. Yazıcının kendi Python'u bunu
güvenli şekilde ekler. Bu, betikli kurulumun kullandığı programın aynısıdır.

### A1. Liste dosyasını hazırlayın

Bu depodaki [`examples/custom_spec.example.json`](../examples/custom_spec.example.json) dosyasını kopyalayıp
`my_spec.json` adıyla kaydedin ve düzenleyin. Her filament bir bloktur:

```json
{
  "parent": "Generic ABS",
  "nozzles": ["0.2", "0.4", "0.6", "0.8"],
  "base": { "id": "90001", "brand": "Porima", "name": "Porima ABS Basic", "minTemp": 230, "maxTemp": 260, "density": 1.04 },
  "kv": { "filament_vendor": "Porima", "nozzle_temperature": "250", "hot_plate_temp": "100" }
}
```

| Alan | Ne yazılır |
|---|---|
| `parent` | Kopyalanacak Generic kayıt. Aynı türde olmalı: `Generic PLA`, `Generic ABS`, `Generic PETG`, `Generic ASA`, `Generic PA`, `Generic PA6-CF`, `Generic PC`, `Generic TPU`, `Generic ABS-CF`, `Generic PLA-CF`, `Generic PETG-CF`, `Generic PET`… |
| `nozzles` | Bu filamenti kullandığınız nozüller |
| `base.id` | **Benzersiz** 5 haneli kimlik. `90001`'den başlayıp sırayla artırın. Bir kez verdikten sonra değiştirmeyin. |
| `base.brand` | Ekranda görünecek marka |
| `base.name` | Ekranda görünecek ad. Ekrandaki mevcut adlarla aynı olmasın. |
| `base.minTemp` / `maxTemp` | Nozül sıcaklık aralığı (°C). Yükleme ve boşaltmada kullanılabilir. |
| `base.density` | Yoğunluk (g/cm³). İsteğe bağlı. |
| `base.meterialType` | **Yalnızca** yazıcıda Generic karşılığı olmayan türler için, örneğin HIPS: `"meterialType": "HIPS"` ve `"parent": "Generic ABS"` |
| `kv` | Değiştirmek istediğiniz ayarlar. Değerler **tırnak içinde** yazılır: `"250"`. Yalnızca Generic kayıtta zaten bulunan ayarlar değiştirilir. |

JSON yazım kuralları: Bloklar arasına virgül koyun, son bloktan sonra virgül koymayın, metinleri çift tırnakla yazın.
Kaydetmeden önce dosyayı [jsonlint.com](https://jsonlint.com) gibi bir sitede denetleyebilirsiniz.

### A2. Dosyaları yazıcıya kopyalayın

Deponun klasöründe bir Terminal açın:

```sh
scp tools/printer_material_install.py my_spec.json root@YAZICI_IP:/tmp/
```

### A3. Yazıcıya bağlanıp yedek alın

```sh
ssh root@YAZICI_IP
```

Bağlandıktan sonra (bundan sonraki komutlar yazıcıda çalışır):

```sh
B=/mnt/UDISK/creality/userdata/box
mkdir -p /mnt/UDISK/creality/userdata/box_backup_manual
cp -a $B/material_database.json $B/material_option.json /mnt/UDISK/creality/userdata/box_backup_manual/
```

### A4. Deneyin (hiçbir şey değişmez)

```sh
python3 /tmp/printer_material_install.py --spec /tmp/my_spec.json
```

Çıktıda her filament için `ADD …` satırı ve sonda `RESULT … skipped=0` görmelisiniz. `SKIP` satırları neyin neden
eklenmediğini söyler; örneğin `parent` yanlışsa veya ad zaten varsa. Bu komut yeni dosyaları yalnızca `/tmp` altına yazar.

### A5. Uygulayın

```sh
cp /tmp/new_material_database.json $B/material_database.json
cp /tmp/new_material_option.json $B/material_option.json
cp /tmp/new_k2_custom_filament_brands.json $B/k2_custom_filament_brands.json
sync
```

Ekranda markalarınızı kontrol edin; görünmezse yazıcıyı yeniden başlatın.

### Değişiklik, tekrar kurulum, kaldırma

- **Liste değişti veya firmware güncellendi:** A2–A5'i tekrarlayın. Araç önce kendi eklediklerini kaldırır, sonra yeniden ekler.
- **Kaldırma:** A4 yerine `python3 /tmp/printer_material_install.py --remove` çalıştırın, sonra A5'teki üç `cp` komutunu uygulayın.
- **Bir şey ters giderse yedeği geri koyun:**
  ```sh
  cp -a /mnt/UDISK/creality/userdata/box_backup_manual/material_database.json \
        /mnt/UDISK/creality/userdata/box_backup_manual/material_option.json $B/
  rm -f $B/k2_custom_filament_brands.json
  sync
  ```

---

## Yol B: Dosyayı tamamen elle düzenlemek (WinSCP ile)

Python kullanmadan, dosyaları bir metin düzenleyiciyle değiştirirsiniz. Dikkat gerektirir: Tek bir virgül hatası
ekrandaki malzeme listesini bozabilir. **Yedek almadan başlamayın.**

### B1. WinSCP ile bağlanın

- **Dosya protokolü:** SFTP · **Sunucu adı:** `YAZICI_IP` · **Kullanıcı adı:** `root` · **Parola:** ekrandaki root parolası
- `/mnt/UDISK/creality/userdata/box/` klasörüne gidin.

### B2. Yedek alın

`material_database.json` ve `material_option.json` dosyalarını bilgisayarınıza indirin ve **bir kopyasını saklayın**.

### B3. `material_database.json` dosyasına kayıt ekleyin

Dosyayı JSON'u renklendiren bir düzenleyiciyle açın (Notepad++ veya VS Code; Windows'un Not Defteri önerilmez).
Dosya tek satır olabilir; VS Code'da **Format Document** ile okunur hale getirebilirsiniz.

1. `"name":"Generic ABS"` geçen kaydı bulun. Kayıt `{"engineVersion":` ile başlar ve `"base":{…}}` ile biter.
2. Bu kaydın **tamamını** (süslü parantezleriyle birlikte) kopyalayın.
3. `"list":[` ifadesinden hemen sonra yapıştırın ve sonuna virgül koyun: `"list":[{…sizin kaydınız…},{…mevcut ilk kayıt…`
4. Yapıştırdığınız kopyada şunları değiştirin:
   - `"base"` içinde: `"id"` → `"90001"` (benzersiz), `"brand"` → `"Porima"`, `"name"` → `"Porima ABS Basic"`,
     `"minTemp"` / `"maxTemp"` → kendi aralığınız.
   - `"nozzleDiameter"` → kullandığınız nozüller, örneğin `["0.2","0.4","0.6","0.8"]`.
   - İsterseniz `"kvParam"` içindeki değerleri (örneğin `"nozzle_temperature":"250"`).
5. Dosyanın sonundaki `"count":` değerini eklediğiniz kayıt sayısı kadar artırın.

### B4. `material_option.json` dosyasına markayı ekleyin

Bu dosya ekrandaki **marka → tür → ad** listesidir. Son `}` işaretinden önce, önceki markadan sonra virgül koyarak ekleyin:

```json
  "Porima":{
    "ABS":"Porima ABS Basic\nPorima ABS Eco",
    "PLA":"Porima PLA Premium"
  }
```

Aynı türde birden fazla ad varsa aralarına `\n` yazılır. Tür (`"ABS"`), kaydın `"meterialType"` değeriyle aynı olmalıdır.

### B5. Denetleyin, yükleyin, kontrol edin

1. İki dosyayı da [jsonlint.com](https://jsonlint.com) gibi bir sitede denetleyin; **"Valid JSON"** görmelisiniz.
2. WinSCP ile dosyaları aynı yere geri yükleyin (üzerine yazın).
3. Ekranı kontrol edin; gerekirse yazıcıyı yeniden başlatın.
4. Bir sorun olursa B2'deki yedekleri geri yükleyin.

Not: Yol B ile eklenen kayıtlar bu aracın kayıt dosyasına (`k2_custom_filament_brands.json`) yazılmaz. Daha sonra
betikli kuruluma geçerseniz, kimliği **ve** adı betiğin ürettiğiyle aynı olan kayıtlar otomatik olarak devralınır;
diğerlerini elle silmeniz gerekebilir.
