# Screenshots

Ausschnitte des Power-BI-Berichts (ohne Menüband).  
Die Nummer am Dateinamen entspricht der Seite im Bericht. Wo dieselbe Seite zweimal vorkommt, ist ein Filterzustand festgehalten.

## Seite 1 — Langfristig erfolgreichste Länder

Goldanteil nach NOC, Wettbewerbe je Sportart, geteilte Goldmedaillen; Slicer Jahr.

| Datei | Inhalt |
| --- | --- |
| [`1_Langfristig_erfolgreichstene_Länder.png`](1_Langfristig_erfolgreichstene_L%C3%A4nder.png) | Alle Jahre: USA 19,7 % der Goldmedaillen, 5 020 Gold insgesamt; Athletics mit 941 Wettbewerben; 27 geteilte Goldmedaillen (u. a. Gymnastics 16) |
| [`1_Langfristig_erfolgreichstene_DEU_2016.png`](1_Langfristig_erfolgreichstene_DEU_2016.png) | Filter **GER**, Jahr **2016**, alle Sportarten: Deutschland **5,6 %** der Medaillen am Gesamtstand; 17 Gold, keine geteilten Goldmedaillen |

## Seite 2 — Gesamtzahl der Medaillen (Welt)

Weltkarte der Medaillen (Gold + Silber + Bronze) nach Land; Slicer Sport; Karten Gold / Silber / Bronze.

| Datei | Inhalt |
| --- | --- |
| [`2_Gesamtzahl_der_Medaillen_Welt.png`](2_Gesamtzahl_der_Medaillen_Welt.png) | Alle Sportarten: 5 020 Gold, 4 994 Silber, 5 397 Bronze; Tooltip Germany = 1 353 Medaillen |
| [`2_Gesamtzahl_der_Medaillen_DEU_Atletics.png`](2_Gesamtzahl_der_Medaillen_DEU_Atletics.png) | Filter **Athletics**: 943 / 947 / 945 Medaillen weltweit; Germany = 261 |

## Seite 3 — 4-2-1-NYT und Siegindex nach Sport

Balken: absolute Punkte nach dem 4-2-1-System der *New York Times*. Linie: Siegindex (Erfolg relativ zur Zahl der Wettbewerbe). Slicer Sport.

| Datei | Inhalt |
| --- | --- |
| [`3_421-NYT_und_Siegindex_nach_Sport.png`](3_421-NYT_und_Siegindex_nach_Sport.png) | Alle Sportarten: USA, Russia, Germany vorn bei den Punkten (6,2 / 3,9 / 3,1 Tsd.); kleinere Länder mit höherem Siegindex (z. B. Belarus 11,62, Azerbaijan 11,00) |
| [`3_421-NYT_und_Siegindex_nach_Football.png`](3_421-NYT_und_Siegindex_nach_Football.png) | Filter **Football**: USA 21 Punkte, Germany 18; Brazil mit Siegindex 16,00 bei 16 Punkten |

## Seite 4 — Athleteneffizienz

| Datei | Inhalt |
| --- | --- |
| [`4_Athleteneffizienz.png`](4_Athleteneffizienz.png) | Links: Streudiagramm Erfolgsquote vs. Athleteneffizienz nach Land (USA und Russia oben rechts). Rechts: Gold je Person und Teilnahmen; Michael Phelps 23 Gold bei 30 Teilnahmen |

## Seite 5 — Effizienz Land

Zwei Streudiagramme und Slicer Land.

| Datei | Inhalt |
| --- | --- |
| [`5_Effizienz_Land.png`](5_Effizienz_Land.png) | Alle Länder: links Teilnahmen vs. Erfolgsquote nach Jahr; rechts Siegindex vs. Gold-Events (USA, Russia, Germany als Ausreißer oben) |
| [`5_Effizienz_Land_DEU.png`](5_Effizienz_Land_DEU.png) | Filter **Germany**: Zeitpfad der Erfolgsquote (u. a. 1980 hoch, 1952 niedrig); rechts Germany bei Siegindex ≈ 7 und rund 420 Gold-Events |

## Datenmodell

| Datei | Inhalt |
| --- | --- |
| [`ERD.png`](ERD.png) | Sternschema in pgAdmin: Dimensionen um `fact_results` |

Die interaktive Datei bleibt [`powerbi/OlympSpiele_Sinienko.pbix`](../powerbi/OlympSpiele_Sinienko.pbix).
