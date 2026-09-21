# Export des Sternschemas

CSV-Exporte aus PostgreSQL (`public`). **Ohne Kopfzeile**, Trenner `;`.

Diese Dateien sind das geladene Modell, nicht die Rohdaten. Zum Nachbauen der Datenbank das Skript [`sql/01_create_tables.sql`](../../sql/01_create_tables.sql) auf `olympics_rohDaten.csv` anwenden.

| Datei | Spalten (Reihenfolge) |
| --- | --- |
| `dim_athlete.csv` | `athlete_key`; `name`; `sex` |
| `dim_athlete_season.csv` | `athlete_season_key`; `athlete_key`; `year`; `age`; `height`; `weight` |
| `dim_country.csv` | `country_key`; `noc`; `country` *(Export vor dem Entfernen von `country_key`; fachlicher Schlüssel ist `noc`)* |
| `dim_date.csv` | `date_key`; `year` |
| `dim_event.csv` | `event_key`; `event`; `sport_key` |
| `dim_sport.csv` | `sport_key`; `sport` |
| `fact_results.csv` | `result_key`; `athlete_season_key`; `country_key`; `event_key`; `date_key`; `medal`; `medal_points` *(Export noch mit `country_key`; im späteren Modell ist der Schlüssel `noc`)* |

`ERD_Projekt Olympische Spiele.pgerd` ist die pgAdmin-Zeichnung; die PNG-Ansicht liegt unter [`screenshots/ERD.png`](../../screenshots/ERD.png).
