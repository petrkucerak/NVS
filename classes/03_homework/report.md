# Řídící jednotka s dvoumístným 7segmentovým zobrazovačem

Cílem úkolu bylo navrhnout, sestavit a naprogramovat jednoduchý automat, který bude rozsvěcet a zhasínat světlo.

## Ovládání

Automat má dva základní módy:

1. konfiguraci,
2. normální provoz.

Mezi módy lze plyně přecházet pomocí stisku potvrzovacího tlačítka.

### Mód konfigurace

Automat lze konfigurovat pomocí 3 tlačítek a 2 ciferního 7segmentového zobrazovače. Zobrazovač určuje nastavený čas. Pomocí tlačítek je možné čas upravovat a následně potvrdit. Po stisku potvrzovacího tlačítka přejde automat do módu *normální provozu*. 

Při konfiguračním módu svítí zelená LED dioda na mikrokontroleru. 

### Mód normálního provozu

V tomto režimu reaguje automat na zabudované tlačítko na desce mikrokontroleru. Po stisku se začne odpočítávat čas a rozsvítí se světlo. Před ukončením času se přerušovaným blikáním signalizuje konec. 

## Schéma projektu

Schéma zapojení projektu je dostupné [v repozitáři projektu](https://github.com/petrkucerak/NVS/blob/main/classes/03_homework/schema/schema.pdf). 

## Kód a reference

Veškerý kód se všemi materiály je dostupný v tomto repositáři ve složce [03_homework](https://github.com/petrkucerak/NVS/tree/main/classes/03_homework). 

