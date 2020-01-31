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
Getting data...
NAMA            : Xxxxxxxx Xxxxxxxx
STATUS_BAYAR    : Sudah Dibayar
JUMLAH_BAYAR    : Rp415.500,00
PENGGUNAAN      : 831 GB
FUP             : 800 GB
```

## Edit & Test with nodemon

`nodemon -d 0.1 -e .sh -x "./indihome.sh || return 0"`

