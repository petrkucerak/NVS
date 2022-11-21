#! /bin/bash

mkdir out
cd out
echo "/*" > .gitignore

pandoc ../report.md -o Kucera_Petr_NVS_2022_UART.PDF

zip Kucera_Petr_NVS_2022_UART.zip ../*