
CREATE TABLE olympics_new (
    id INT,
    name TEXT,
    sex CHAR(1),
    age INT,
    height NUMERIC,
    weight NUMERIC,
    year INT,
    sport TEXT,
    event TEXT,
    medal TEXT,
    noc CHAR(3),
    country TEXT
);

UPDATE olympics_new
SET 
    height = height / 10.0,
    weight = weight / 10.0
WHERE height IS NOT NULL
or weight is not NULL;

select * from olympics_new
;
-- in Dezimalzahlen transformieren
ALTER TABLE olympics_new
ALTER COLUMN height TYPE NUMERIC(5,1)
USING TRUNC(height, 1),
ALTER COLUMN weight TYPE NUMERIC(5,1)
USING TRUNC(weight, 1);

select * from olympics_new
where height is not null
;

CREATE TABLE dim_country (
    noc CHAR(3) UNIQUE PRIMARY KEY,
    country TEXT
);

INSERT INTO dim_country (noc, country)
SELECT DISTINCT noc, country
FROM olympics_new;

select * from dim_country;

CREATE TABLE dim_sport (
    sport_key SERIAL PRIMARY KEY,
    sport TEXT UNIQUE
);
-- stellst du Kursor auf "Tables" in Menu und dann "Refresh", siehst neue erstellte Tabelle
INSERT INTO dim_sport (sport)
SELECT DISTINCT sport
FROM olympics_new;

select * from dim_sport;

CREATE TABLE dim_event (
    event_key SERIAL PRIMARY KEY,
    event TEXT,
    sport_key INT REFERENCES dim_sport(sport_key),
    CONSTRAINT uq_event UNIQUE (event, sport_key)
);

INSERT INTO dim_event (event, sport_key)
SELECT DISTINCT
    o.event,
    s.sport_key
FROM olympics_new o
JOIN dim_sport s ON s.sport = o.sport;

select * from dim_event;

/* 
Kernproblem in deinen Daten
Ein Athlet:
nimmt in mehreren Jahren teil
hat unterschiedliches Alter
evtl. anderes Gewicht / Groesse
aber bleibt dieselbe Person
Alter, Gewicht usw sind zeitabhaengige Attribute
Warum problematisch?
age, height, weight gehoeren nicht stabil zur Person
dieselbe Person bekommt mehrere IDs
Identitaet und Zustand

Korrektes Denkmodell (sehr wichtig)
Athlet = Identitaet (zeitlos)
Name
Geschlecht
(optional: Geburtsjahr)

Athleten-Zustand = zeitabhaengig
Alter
Gewicht
Groesse
Jahr / Olympiade
*/
CREATE TABLE dim_athlete (
    athlete_key SERIAL PRIMARY KEY,
    name TEXT NOT NULL,
    sex CHAR(1)
);

INSERT INTO dim_athlete (name, sex)
SELECT DISTINCT name, sex
FROM olympics_new;

select * from dim_athlete
where name = 'Paavo Johannes Aaltonen';

CREATE TABLE dim_athlete_season (
    athlete_season_key SERIAL PRIMARY KEY,
    athlete_key INT REFERENCES dim_athlete(athlete_key),
    year INT,
    age INT,
    height NUMERIC(5,1),
    weight NUMERIC(5,1),
    CONSTRAINT uq_athlete_year UNIQUE (athlete_key, year)
);

INSERT INTO dim_athlete_season (athlete_key, year, age, height, weight)
SELECT
    a.athlete_key,
    o.year,
    MAX(o.age)        AS age,
    MAX(o.height)     AS height,
    AVG(o.weight)     AS weight
FROM olympics_new o
JOIN dim_athlete a
  ON a.name = o.name
 AND a.sex  = o.sex
GROUP BY
    a.athlete_key,
    o.year;

select * from dim_athlete_season
ORDER BY athlete_key DESC;

-- ein Sportler hat in einem Jahr in mehreren Sportsevents  teilgenommen
SELECT
    a.athlete_key,
    o.year,
    COUNT(*) AS rows_per_year
FROM olympics_new o
JOIN dim_athlete a
  ON a.name = o.name
 AND a.sex  = o.sex
GROUP BY a.athlete_key, o.year
HAVING COUNT(*) > 1
ORDER BY athlete_key ASC
;
SELECT
    a.athlete_key,
    o.year,
	o.event
FROM olympics_new o
JOIN dim_athlete a
  ON a.name = o.name
 AND a.sex  = o.sex
GROUP BY a.athlete_key, o.year, o.event
ORDER BY athlete_key ASC
;


CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    year INT
);

INSERT INTO dim_date (date_key, year)
SELECT DISTINCT
    year AS date_key,
    year
FROM olympics_new;

CREATE TABLE fact_results (
    result_key SERIAL PRIMARY KEY,
    athlete_season_key INT REFERENCES dim_athlete_season(athlete_season_key),
    noc INT REFERENCES dim_country(noc),
    event_key INT REFERENCES dim_event(event_key),
	date_key INT REFERENCES dim_date(date_key),
    medal TEXT,
    medal_points INT
);


INSERT INTO fact_results (
    athlete_season_key, noc, event_key, date_key, medal, medal_points
)
SELECT
    ats.athlete_season_key,
    c.noc,
    e.event_key,
    d.date_key,
    o.medal,
    CASE o.medal
        WHEN 'Gold' THEN 1
        WHEN 'Silver' THEN 2
        WHEN 'Bronze' THEN 3
        ELSE 0
    END
FROM olympics_new o
JOIN dim_athlete a
    ON a.name = o.name
   AND a.sex = o.sex
JOIN dim_athlete_season ats
    ON ats.athlete_key = a.athlete_key
   AND ats.year = o.year
JOIN dim_country c
    ON c.noc = o.noc
JOIN dim_sport s
    ON s.sport = o.sport
JOIN dim_event e
    ON e.event = o.event
   AND e.sport_key = s.sport_key
JOIN dim_date d
    ON d.year = o.year;

UPDATE fact_results
SET medal_points = CASE medal
    WHEN 'Gold' THEN 3
    WHEN 'Silver' THEN 2
    WHEN 'Bronze' THEN 1
    ELSE 0
END
WHERE medal IN ('Gold', 'Silver', 'Bronze');

select *from fact_results
order by medal_points DESC;

ALTER TABLE dim_event
RENAME COLUMN events TO event;

CREATE SCHEMA staging;

ALTER TABLE olympics_new
SET SCHEMA staging;

SELECT schema_name
FROM information_schema.schemata
ORDER BY schema_name;

SELECT *
FROM staging.olympics_new
LIMIT 10;
/* Wichtig: ohne Schema-Prefix (staging.) 
findet PostgreSQL die Tabelle nicht, wenn dein search_path nur public enthaelt.*/


-- Ein ENUM Datentyp definieren:
CREATE TYPE medal_enum AS ENUM ('Gold', 'Silver', 'Bronze');
/*Vorteile vom Enum ist das Verhindern von ungültigen Eingaben. 
Es ist auch lesbarer als reine CHECK-Constraints und wird intern auch als effizienter Index gespeichert.*/

UPDATE fact_results
SET medal = NULL
WHERE medal = '';

ALTER TABLE fact_results
ALTER COLUMN medal
TYPE medal_enum
USING medal::medal_enum;


/* нужно удалить столбик персонального ключа country_key из табл fact_results, dim_country, 
из значения noc сделать РК - dim_country, FK - fact_results. */
ALTER TABLE fact_results
ADD COLUMN noc VARCHAR(3);

UPDATE fact_results f
SET noc = d.noc
FROM dim_country d
WHERE f.country_key = d.country_key;

ALTER TABLE fact_results
ALTER COLUMN noc SET NOT NULL;

SELECT conname
FROM pg_constraint
WHERE conrelid = 'dim_country'::regclass
AND contype = 'p';

ALTER TABLE fact_results
DROP CONSTRAINT fact_results_country_key_fkey;

ALTER TABLE dim_country
DROP CONSTRAINT dim_country_pkey;

ALTER TABLE dim_country
ADD PRIMARY KEY (noc);

ALTER TABLE fact_results
ADD CONSTRAINT fact_results_noc_fkey
FOREIGN KEY (noc)
REFERENCES dim_country(noc);

DROP VIEW country_year_results;

ALTER TABLE fact_results
DROP COLUMN country_key;
