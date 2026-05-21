#!/bin/bash

JAM=$(date +%H)
NAMA_PANEL=$(hostname)

if [ $JAM -ge 0 ] && [ $JAM -lt 10 ]; then
    UCAPAN="Pagi"
elif [ $JAM -ge 10 ] && [ $JAM -lt 15 ]; then
    UCAPAN="Siang"
elif [ $JAM -ge 15 ] && [ $JAM -lt 18 ]; then
    UCAPAN="Sore"
else
    UCAPAN="Malam"
fi

echo -e "✨ \e[1;32mSelamat $UCAPAN Dan Selamat Datang Di $NAMA_PANEL 🚀\e[0m"
