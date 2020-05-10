#!/bin/bash

# Simple linux shell script untuk mengecek kuota Indihome anda
# by: klampok.child@gmail.com

set -e
CONFIG="indihome.cfg"
while [[ $# -gt 0 ]]; do
    case "$1" in
    -d | --debug)
        DEBUG=1
        ;;
    -n | --nomor)
        shift
        ACCOUNT="$1"
        ;;
    -h | --help)
        echo "Penggunaan:"
        echo "$0 [ -h | -d | -a nomor | -c config ]"
        echo "  -h | --help              Bantuan ini."
        echo "  -d | --debug             Debug mode, html saved in $PWD/indihome-debug.html"
        echo "                           jika sesi sebelumnya sudah tidak valid."
        echo "  -c file | --config file  Lokasi file konfigurasi."
        echo "                           Default './indihome.cfg' atau '$HOME/.indihome.cfg'"
        echo "  -n nomor | --nomor nomor Hanya tampilkan akun no urut tsbt. default all."
        echo "                           (hanya berlaku utk yg multi profile indihome)"
        exit
        ;;
    -c | --config)
        shift
        CONFIG="$1"
        ;;
    esac
    shift
done

HOME_URL="https://www.indihome.co.id"
CEK_URL="$HOME_URL/verifikasi-layanan/cek-email"
LOGIN_URL="$HOME_URL/verifikasi-layanan/login"
DATA_URL="$HOME_URL/profile/status-langganan/get-data"
FAST_URL="$HOME_URL/announcements"
COOKIE="/tmp/indihome-cookie.txt"
CURL="curl -A github.com/ndunks/cek-kuota-indihome -skb $COOKIE -c $COOKIE"

if [ -n "$DEBUG" ]; then
    echo "Options:" 1>&2
    echo "FORCELOGIN: $FORCELOGIN, DEBUG: $DEBUG, ACCOUNT: $ACCOUNT, CONFIG: $CONFIG" 1>&2
fi

if [ ! -f "$CONFIG" ]; then
    if [ -e "$HOME/.$CONFIG" ]; then
        CONFIG="$HOME/.$CONFIG"
        echo "Using config in $CONFIG" 1>&2
    else
        echo "Tidak ada file konfigurasi: $CONFIG atau $HOME/.$CONFIG" 1>&2
        exit 1
    fi
fi

source $CONFIG
if [ -z "$EMAIL" ]; then
    echo "Tidak ada EMAIL di $CONFIG" 1>&2
    exit 1
fi
if [ -z "$PASSWORD" ]; then
    echo "Tidak ada PASSWORD di $CONFIG" 1>&2
    exit 1
fi

indihome_curl() {
    if [ -n "$DEBUG" ]; then
        echo "CURL: $*" 1>&2
        $CURL $* >indihome-debug.html
        cat indihome-debug.html
    else
        $CURL $*
    fi
}

indihome_get_token() {
    TOKEN=$(indihome_curl $FAST_URL | grep "_token" | head -n 1 | cut -d '"' -f6)
}

indihome_login() {
    RESULT=$(indihome_curl -i $CEK_URL)
    CODE=$(echo "$RESULT" | head -n 1 | cut -d ' ' -f2)
    if [ $CODE = "302" ]; then
        echo "Masih login.." 1>&2
        return 0
    fi
    TOKEN=$(echo "$RESULT" | grep "_token" | head -n 1 | cut -d '"' -f6)
    if [ -z "$TOKEN" ]; then
        echo "Fail get token" 1>&2
        return 1
    fi
    echo "Login.." 1>&2

    # Do Login
    RESULT=$(
        indihome_curl -i \
            -F "_token=$TOKEN" \
            -F "email=$EMAIL" \
            -F "password=$PASSWORD" \
            $LOGIN_URL
    )
    CODE=$(echo "$RESULT" | head -n 1 | cut -d ' ' -f2)
    REDIRECT=$(echo "$RESULT" | grep Location | cut -d ' ' -f2)
    if [[ "$CODE" != "302" && "$CODE" != "100" ]]; then
        echo "Invalid code: $CODE" 1>&2
        return 1
    fi

    if $(echo "$REDIRECT" | grep $LOGIN_URL); then
        echo "Login gagal, cek username password." 1>&2
        return 1
    fi
    echo "Login OK" 1>&2
}

indihome_profiles() {
    echo "Mengambil daftar profile akun.."
    PROFILES=()
    LINES=$(indihome_curl $HOME_URL/profile/status-langganan |
        grep data-portfolio_id |
        tr -s ' ' |
        cut -d ' ' -f4-6 |
        sed 's/data-//g')
    IFS2="$IFS"
    IFS=$'\n'
    for LINE in $LINES; do
        PROFILES+=($LINE)
    done
    IFS=$IFS2
}

indihome_data() {
    echo "Getting data $3..." 1>&2
    [ -n "$TOKEN" ] || indihome_get_token

    RESULT=$(indihome_curl \
        -F "_token=$TOKEN" \
        -F "portfolio_id=$1" \
        -F "no_inet=$2" \
        -F "no_pots=$3" \
        $DATA_URL)
    eval $(echo $RESULT |
        cut -d '{' -f 3 |
        sed -e 's/,\"/\n\"/g' |
        sed -e 's/^"//' -e 's/":/=/g')
    #packageName quota usage usageBar remain menitQuota menitUsage speed channel
    echo "No Telp : $3"
    echo "No Inet : $2"
    echo "Speed   : $speed"
    echo "Quota   : $usage/$quota (Sisa $remain) GB"
    echo "Telpon  : $menitUsage/$menitQuota"
    echo "Channel : $channel"
}

indihome_login
indihome_profiles

for IDX in ${!PROFILES[@]}; do
    let "NO=$IDX+1"
    if [[ -z "$ACCOUNT" || "$ACCOUNT" = $NO ]]; then
        eval $(echo ${PROFILES[$IDX]} | xargs)
        echo "$NO ------------------------"
        indihome_data $portfolio_id $no_inet $no_pots
    fi
done
