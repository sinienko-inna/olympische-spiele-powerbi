# Wie der Bericht entstanden ist

Dokumentation der Fallstudie **Olympische Spiele** (SQL + Power BI) im Kurs Data Analytics.

Der Ablauf ist aus den SQL-Skripten, den exportierten Tabellen, dem ERD und den Seiten des Power-BI-Berichts rekonstruiert. Datenbank, Modell und `.pbix` sind vollständig von mir erstellt.

## 1. Aufgabenstellung

Die Kursfallstudie verlangt eine relationale Olympia-Datenbank und eine Auswertung des Medaillenerfolgs. Die Musterlösung der Kursleitung (`sql/reference/musterloesung.sql`) modelliert vier Tabellen (`Athletes`, `Events`, `Countries`, `Athlete_Event`).

Ich habe bewusst ein **Sternschema** gebaut, weil Alter, Größe und Gewicht nicht zur Person gehören, sondern zum Zustand in einem Olympiajahr.

Leitfragen:

1. Welche Länder sind langfristig am erfolgreichsten?
2. Wie zählt man Medaillen korrekt, wenn in Mannschaftssportarten viele Athletinnen/Athleten dieselbe Medaille teilen?
3. Welche Kennzahl ist fairer als die Rohzahl: Medaillen je Wettbewerb, 4-2-1-Punkte, Siegindex?
4. Welche Athletinnen/Athleten und Länder sind besonders effizient?

## 2. Daten beschaffen

| Bedarf | Vorgehen | Ergebnisdatei |
| --- | --- | --- |
| Athleten-Event-Rohdaten | Kursdatensatz laden (CSV) | `data/raw/olympics_rohDaten.csv` |
| Datenbank | Neue PostgreSQL-Datenbank in pgAdmin | Schema `public` + später `staging` |

Spalten der Rohdatei: `ID`, `Name`, `Sex`, `Age`, `Height`, `Weight`, `Year`, `Sport`, `Event`, `Medal`, `NOC`, `Country`.

`Height` und `Weight` lagen als Zehnerwerte vor (z. B. 1800 statt 180,0) und wurden in SQL durch 10 geteilt.

## 3. Laden und Bereinigen in PostgreSQL

Skript: [`sql/01_create_tables.sql`](../sql/01_create_tables.sql).

1. Staging-Tabelle `olympics_new` anlegen (gleiche Körnung wie die CSV).
2. CSV importieren (pgAdmin Import/Export bzw. `COPY`; eine Python-Skizze liegt unter [`scripts/import_olympics.py`](../scripts/import_olympics.py)).
3. `height` und `weight` durch 10 teilen, Datentyp `NUMERIC(5,1)`.
4. Leere Medaillen (`''`) auf `NULL` setzen, Spalte auf den ENUM-Typ `medal_enum` (`Gold`, `Silver`, `Bronze`) umstellen.
5. Roh-Tabelle nach `staging.olympics_new` verschieben, damit `public` nur das analytische Modell enthält.

## 4. Datenmodell (Normalisierung)

Zentrale Modellentscheidung: **Athlet = Identität**, **Athleten-Saison = zeitabhängiger Zustand**.

| Tabelle | Inhalt |
| --- | --- |
| `dim_athlete` | Name, Geschlecht (zeitlos) |
| `dim_athlete_season` | Alter, Größe, Gewicht je Athlet und Jahr |
| `dim_country` | NOC als Primärschlüssel, Land |
| `dim_sport` / `dim_event` | Sportart und Wettbewerb (Event hängt am Sport) |
| `dim_date` | Olympiajahr |
| `fact_results` | eine Leistung: Athlet-Saison × Event × Land × Jahr × Medaille |

`medal_points` in der Faktabelle: Gold = 3, Silber = 2, Bronze = 1.

Nach dem ersten Entwurf habe ich den künstlichen `country_key` entfernt und `noc` als natürlichen Schlüssel verwendet (besser für Joins und Power BI).

Details und Beziehungen: [02-data-model.md](02-data-model.md), Screenshot: [screenshots/ERD.png](../screenshots/ERD.png).

## 5. SQL-Analysen

Skripte: [`sql/03_analyse.sql`](../sql/03_analyse.sql), [`sql/02_create_views.sql`](../sql/02_create_views.sql), [`sql/04_athletics_1972.sql`](../sql/04_athletics_1972.sql).

**Problem:** In `fact_results` hat jedes Mannschaftsmitglied eine eigene Zeile. Zwölf kanadische Lacrosse-Spieler mit Gold wären sonst zwölf Goldmedaillen.

**Lösung:** zuerst `SELECT DISTINCT event_key, noc, date_key, medal` — eine Medaille je Land, Wettbewerb und Jahr.

Darauf aufbauend die View `view_olympic_medal_metrics`:

| Kennzahl | Bedeutung |
| --- | --- |
| `total_medals` | Gold + Silber + Bronze (landes-/sport-/jahresscharf, ohne Mannschaftsverdopplung) |
| `medals_per_event` | Medaillen geteilt durch die Zahl der Wettbewerbe |
| `score_421` | 4×Gold + 2×Silber + 1×Bronze (Punktesystem der *New York Times*) |
| `score_421_per_event` | dieselbe Punktzahl, normalisiert auf die Zahl der Wettbewerbe |

Weitere Abfragen: Medaillendichte je Teilnahme, Top-N-Länder pro Sport und Jahr, Events, die nach 2000 nicht mehr stattfanden, Kontrolle Athletics 1972.

Die View-Ergebnisse sind als CSV unter [`data/metrics/`](../data/metrics/) gespeichert.

## 6. Power BI

Die PostgreSQL-Tabellen (Schema `public`) wurden in Power BI als Import geladen. Zusätzlich zwei Measure-Tabellen `metrics` und `kontrol`.

| Seite | Rolle |
| --- | --- |
| 1 Langfristig erfolgreichste Länder | Goldanteil nach NOC, Wettbewerbe je Sportart, geteilte Goldmedaillen; Filter Jahr |
| 2 Gesamtzahl der Medaillen (Welt) | Karte der Medaillen nach Land; Filter Sport; Karten Gold / Silber / Bronze |
| 3 4-2-1-NYT und Siegindex nach Sport | Absolute Punkte vs. relativer Erfolg; Filter Sport |
| 4 Athleteneffizienz | Gold je Person; Streudiagramm Erfolgsquote vs. Effizienz |
| 5 Effizienz Land | Streudiagramme Siegindex / Gold-Events und Teilnahmen / Erfolgsquote; Slicer Land (Standard: Germany) |

Screenshots (inkl. Filter GER 2016 mit 5,6 % am Gesamtstand, Athletics, Football, Germany): [screenshots/README.md](../screenshots/README.md).

DAX-Namen (Formeln stehen in der `.pbix`): `Gold`, `Silber`, `Bronze`, `Total_Medals`, `Gold_Event`, `geteilte Gold`, `Total_Points_421`, `Siegindex`, `Athleteneffizienz`, `Erfolgsquote des Athleten`, `Anzahlteilnahmen_Athleten`, `FilterAnyMedal`.

## 7. Grenzen

- Nur Sommerspiele, 1904–2016 (1896/1900 und Winterspiele fehlen im Kursdatensatz).
- Athletinnen/Athleten sind über Name + Geschlecht identifiziert, nicht über eine stabile Personen-ID der Rohdatei — Namensgleichheit kann theoretisch zwei Personen zusammenführen.
- Die 4-2-1-Gewichtung ist eine publizistische Konvention, kein IOC-Ranking.
- Der Bericht ist interaktiv; GitHub zeigt statische Screenshots. Die `.pbix` bleibt die Arbeitsdatei.
