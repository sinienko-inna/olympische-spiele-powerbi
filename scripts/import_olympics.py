"""CSV-Rohdaten nach PostgreSQL laden (staging.olympics_new).

Zugangsdaten nicht im Skript speichern — Umgebungsvariable DATABASE_URL nutzen, z. B.
postgresql+psycopg2://USER:PASS@localhost:5432/olympics
"""

import os
from pathlib import Path

import pandas as pd
from sqlalchemy import create_engine

RAW_CSV = Path(__file__).resolve().parents[1] / "data" / "raw" / "olympics_rohDaten.csv"
DATABASE_URL = os.environ["DATABASE_URL"]


def main() -> None:
    df = pd.read_csv(RAW_CSV, sep="\t")
    engine = create_engine(DATABASE_URL)
    df.to_sql(
        "olympics_new",
        engine,
        schema="staging",
        if_exists="replace",
        index=False,
    )


if __name__ == "__main__":
    main()
