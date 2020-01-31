#!/bin/bash

# Simple linux shell script untuk mengecek kuota Indihome anda
# by: klampok.child@gmail.com

set -e
CONFIG="indihome.cfg"
if [ ! -f $CONFIG ]; then
    echo "Tidak ada file konfigurasi: $CONFIG" 1>&2
    exit 1
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

CURL="curl -s -b cookie.txt -c cookie.txt -k"
HOME_URL="https://www.indihome.co.id"
CEK_URL="$HOME_URL/verifikasi-layanan/cek-email"
LOGIN_URL="$HOME_URL/verifikasi-layanan/login"

indihome_login() {
    TOKEN=$(
        $CURL $CEK_URL |
            grep "_token" |
            head -n 1 |
            cut -d '"' -f6
    )
    if [ -z "$TOKEN" ]; then
        echo "Fail get token" 1>&2
        return 1
    fi

    ## Step cek email bisa dilewati aja, langsung login
    ## yg pnting udah dapet CSRF Token.

    # RESULT=$(
    #     $CURL -o /dev/null \
    #         -w "%{http_code} %{redirect_url}" \
    #         -F "_token=$TOKEN" \
    #         -F "email=$EMAIL" $CEK_URL
    # )
    # CODE=$(echo "$RESULT" | cut -d ' ' -f1)
    # REDIRECT=$(echo "$RESULT" | cut -d ' ' -f2)
    # if [ "$CODE" != "302" ]; then
    #     echo "Invalid code: $CODE" 1>&2
    #     return 1
    # fi
    # if [ "$REDIRECT" != "$LOGIN_URL" ]; then
    #     echo "Invalid Redirect: $REDIRECT" 1>&2
    #     return 1
    # fi

    # Do Login
    RESULT=$(
        $CURL \
            -w "%{http_code} %{redirect_url}" \
            -F "_token=$TOKEN" \
            -F "email=$EMAIL" \
            -F "password=$PASSWORD" \
            -o /dev/null \
            $LOGIN_URL
    )
    CODE=$(echo "$RESULT" | cut -d ' ' -f1)
    REDIRECT=$(echo "$RESULT" | cut -d ' ' -f2)
    if [ "$CODE" != "302" ]; then
        echo "Invalid code: $CODE" 1>&2
        return 1
    fi
    if [ "$REDIRECT" != "$HOME_URL" ]; then
        echo "Failed login: $REDIRECT" 1>&2
        return 1
    fi
}

indihome_data() {
    echo "Getting data..." 1>&2
    RESULT="$($CURL $HOME_URL)"
    NAMA=$(echo "$RESULT" | sed -n '/glyphicon-user/s/^.\+span> \(.*\)$/\1/p')
    if [ -z "$NAMA" ] || [ "$NAMA" == "myIndiHome" ]; then
        if [ -z "$RETRY" ]; then
            echo "Not logged in, Try to login.." 1>&2
            RETRY="1"
            indihome_login
            indihome_data
            return $?
        fi
        # Failed
        return 1
    fi
    STATUS_BAYAR=$(
        echo "$RESULT" |
            grep -m 1 -A 2 "/riwayat/tagihan" |
            tail -n2 |
            head -n1 |
            sed 's/.\+>\(.*\)<.\+/\1/'
    )
    JUMLAH_BAYAR=$(
        echo "$RESULT" |
            grep -m 1 -A 2 "/riwayat/tagihan" |
            tail -n1 |
            sed 's/.\+>\(.\+\)<\/b>.\+/\1/'
    )
    PENGGUNAAN=$(
        echo "$RESULT" |
            grep -A 2 "txtItemStatusLanggananHome" |
            sed -n '2s/.\+>\/\(.\+\)\s.\+/\1/p'
    )
    FUP=$(
        echo "$RESULT" |
            sed -n 's/^.\+"minipackPackage">\(.*\)<\/span> GB.\+$/\1/p'
    )
    if [ -z "$FUP" ]; then FUP='-'; fi
}

indihome_data

if [ "$?" != "0" ]; then
    echo "FAILED GET DATA" 1>&2
    exit 1
fi

echo -e "NAMA\t\t: $NAMA"
echo -e "STATUS_BAYAR\t: $STATUS_BAYAR"
echo -e "JUMLAH_BAYAR\t: $JUMLAH_BAYAR"
echo -e "PENGGUNAAN\t: $PENGGUNAAN GB"
echo -e "FUP\t\t: $FUP GB"
echo "---------------------"
