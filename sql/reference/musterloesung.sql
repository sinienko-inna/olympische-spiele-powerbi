--------------------------
-- TABELLEN ERSTELLEN
--------------------------

-- Athletes
CREATE TABLE Athletes (
    Athlete_ID SERIAL PRIMARY KEY,
    Name VARCHAR(255) NOT NULL,
    Sex CHAR(1) NOT NULL
);

-- Events
CREATE TABLE Events (
    Event_ID SERIAL PRIMARY KEY,
    Sport VARCHAR(255) NOT NULL,
    Event VARCHAR(255) NOT NULL
);

-- Countries
CREATE TABLE Countries (
    NOC CHAR(3) PRIMARY KEY,
    Country VARCHAR(255)
);

-- Athlete_Event
CREATE TYPE medal_enum AS ENUM ('Gold', 'Silver', 'Bronze', '');

CREATE TABLE Athlete_Event (
    Athlete_ID INT NOT NULL,
    Event_ID INT NOT NULL,
    Year INT NOT NULL,
    Medal medal_enum,
    Age INT,
    Height INT,
    Weight INT,
    NOC CHAR(3) NOT NULL,
    PRIMARY KEY (Event_ID, Athlete_ID, Year),
    FOREIGN KEY (Athlete_ID) REFERENCES Athletes(Athlete_ID),
    FOREIGN KEY (Event_ID) REFERENCES Events(Event_ID),
    FOREIGN KEY (NOC) REFERENCES Countries(NOC)
);


--------------------------
-- TABELLEN ERSTELLEN
--------------------------

-- Nur mit Superuser-Rechten oder durch Angabe von absoluten Pfaden
-- Pfad ggf. anpassen an dein System

-- Import athletes
COPY athletes
FROM 'C:\Program Files\PostgreSQL\17\data\import\athletes.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    QUOTE '"'
);

-- Test athletes
SELECT * FROM athletes;

-- Import countries
COPY countries
FROM 'C:\Program Files\PostgreSQL\17\data\import\countries.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    QUOTE '"'
);

-- Test countries
SELECT * FROM countries;

-- Import events
COPY events
FROM 'C:\Program Files\PostgreSQL\17\data\import\events.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';',
    QUOTE '"'
);

-- Test events
SELECT * FROM events;

-- Import athlete_event
COPY athlete_event
FROM 'C:\Program Files\PostgreSQL\17\data\import\athlete_event.csv'
WITH (
    FORMAT csv,
    HEADER true,
    DELIMITER ';'
);

-- Test athlete_event
SELECT * FROM athlete_event;

--------------------------
-- TABELLENÜBERSICHT
--------------------------
SELECT table_name
FROM information_schema.tables
WHERE table_schema = 'public'
  AND table_catalog = 'olympics';
