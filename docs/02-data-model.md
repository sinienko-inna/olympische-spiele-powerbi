# Datenmodell

Sternschema der Olympia-Fallstudie in PostgreSQL, so in Power BI geladen.

Screenshot: [screenshots/ERD.png](../screenshots/ERD.png).  
Prozess: [01-process.md](01-process.md).

## Prinzip

- **Fakt** = messbare Leistung (eine Zeile je Athlet in einem Event eines Jahres).
- **Dimensionen** = Land, Sport, Event, Jahr, Athlet, Athletenzustand.
- **Measures** stehen in Power BI in `metrics` und `kontrol`, nicht als Spalten in den Fakten.
- Zeitabhängige Körpermaße liegen **nicht** in `dim_athlete`, sondern in `dim_athlete_season`.

Die Kurs-Musterlösung speichert Age/Height/Weight direkt an `Athlete_Event`. Das Sternschema trennt Identität und Zustand, damit dieselbe Person über Jahre eine ID behält.

## Dimensionen

| Tabelle | Schlüssel | Wichtige Felder | Rolle |
| --- | --- | --- | --- |
| `dim_athlete` | `athlete_key` | `name`, `sex` | Person, zeitlos |
| `dim_athlete_season` | `athlete_season_key`; unique (`athlete_key`, `year`) | `age`, `height`, `weight` | Zustand in einem Olympiajahr |
| `dim_country` | `noc` (CHAR 3) | `country` | Nationales Olympisches Komitee |
| `dim_sport` | `sport_key` | `sport` | Sportart |
| `dim_event` | `event_key`; unique (`event`, `sport_key`) | `event` | Wettbewerb, gehört zu einer Sportart |
| `dim_date` | `date_key` (= Jahr) | `year` | Zeitachse |

In einem frühen Entwurf hatte `dim_country` noch `country_key`. Der Schlüssel wurde auf `noc` umgestellt; `fact_results.country_key` entfiel.

## Fakt

| Tabelle | Körnung | Felder | Quelle |
| --- | --- | --- | --- |
| `fact_results` | Athlet-Saison × Event × NOC × Jahr | `athlete_season_key`, `event_key`, `date_key`, `noc`, `medal` (`medal_enum`), `medal_points` | `staging.olympics_new` |

`medal_points`: Gold 3, Silber 2, Bronze 1, sonst 0. Für **Länderbilanzen** darf man diese Zeilen nicht einfach summieren — Mannschaften würden vervielfacht. Dafür existiert die View (unten).

## View und Measure-Tabellen

| Objekt | Schicht | Inhalt |
| --- | --- | --- |
| `view_olympic_medal_metrics` | PostgreSQL | Land × Jahr × Sport: Gold/Silber/Bronze ohne Mannschaftsverdopplung, `medals_per_event`, `score_421`, `score_421_per_event` |
| `metrics` | Power BI | DAX: `Total_Points_421`, `Siegindex`, `Athleteneffizienz` |
| `kontrol` | Power BI | DAX: `Total_Medals`, `Gold_Event`, `geteilte Gold` |

## Beziehungen

```text
dim_athlete          1 ──< dim_athlete_season
dim_athlete_season   1 ──< fact_results
dim_country          1 ──< fact_results          (über noc)
dim_event            1 ──< fact_results
dim_date             1 ──< fact_results
dim_sport            1 ──< dim_event
```

Filterrichtung in Power BI: von der Dimension zum Fakt (1:\*).  
Exportierte CSV ohne Kopfzeile: [data/star-schema](../data/star-schema/README.md).

## Körnung (Zahlen)

| Objekt | Zeilen |
| --- | --- |
| Rohdaten `olympics_rohDaten.csv` | 216 784 (plus Kopfzeile) |
| `fact_results` | 216 784 |
| `dim_athlete` | 114 109 |
| `dim_athlete_season` | 156 272 |
| `dim_country` | 228 |
| `dim_event` | 575 |
| `dim_sport` | 49 |
| `dim_date` | 26 (1904–2016, nur Sommer) |

Mehr Saison-Zeilen als Athletinnen/Athleten: dieselbe Person startet in mehreren Olympiajahren. Mehr Fakt-Zeilen als Saisons: dieselbe Person startet in einem Jahr in mehreren Events.

## Warum diese Form

- **NOC statt Landestext** als Schlüssel, weil Ländernamen in der Historie wechseln, der Code aber joinbar bleibt.
- **Event hängt am Sport**, damit Filter auf „Swimming 1968“ nicht Athletics-Events mitziehen.
- **View mit DISTINCT** für die Länderseite, Fakt unverändert für Athletenanalysen (Seite 4 des Berichts braucht die Personenzeile).
- **Zwei Measure-Tabellen** in Power BI, damit Kontrollgrößen (`Gold_Event`, geteilte Goldmedaillen) von den Erfolgsmetriken (4-2-1, Siegindex) getrennt bleiben.
