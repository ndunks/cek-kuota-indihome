# Cek Kuota Indihome

## Akun

Buat file baru bernama `indihome.cfg`. Isi dengan format sbb:

``` ini
EMAIL=email@contoh.com
PASSWORD=12345678
```

## Contoh Penggunaan & Output

``` bash
$ ./indihome.sh
Login..
Login OK
Mengambil daftar profile akun..
1 ------------------------
Getting data 0281XXXXXXXXX...
No Telp : 0281XXXXXXXXX
No Inet : 1433XXXXXXXXX
Speed   : 10 Mbps
Quota   : 91.57 GB/400.00 GB (Sisa 308.43 GB)
Telpon  : 0 Menit/0 Menit
Channel : 0 Channel
2 ------------------------
Getting data 0286XXXXXXXXX...
No Telp : 0286XXXXXXXXX
No Inet : 1413XXXXXXXXX
Speed   : 50 Mbps
Quota   : 484.44 GB/1,850.00 GB (Sisa 1,365.56 GB)
Telpon  : 0 Menit/0 Menit
Channel : 0 Channel
```

## Debug & Test with nodemon

`nodemon -d 0.2 -e .sh -x "./indihome.sh -d || exit 1"`

