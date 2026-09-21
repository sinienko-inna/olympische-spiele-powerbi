# SQL-Kennzahlen (Export)

Ergebnisse der View `view_olympic_medal_metrics` bzw. verwandter Abfragen aus [`sql/03_analyse.sql`](../../sql/03_analyse.sql). Medaillen sind **pro Land, Jahr und Sport** eindeutig (Mannschaft = eine Medaille).

| Datei | Inhalt |
| --- | --- |
| `medal_metrics_421.csv` | Gold/Silber/Bronze, `total_medals`, `medals_per_event`, `score_421`, `score_421_per_event` |
| `medals_per_event.csv` | dieselbe Aggregation ohne 4-2-1-Spalten |

Kopfzeile vorhanden, Felder in Anführungszeichen.
