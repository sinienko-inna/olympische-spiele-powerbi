CREATE VIEW country_year_results AS
SELECT
    c.country,
    r.date_key,
	e.event,
    SUM(CASE WHEN r.medal_points = '1' THEN 1 ELSE 0 END)   AS gold,
    SUM(CASE WHEN r.medal_points = '2' THEN 1 ELSE 0 END) AS silver,
    SUM(CASE WHEN r.medal_points = '3' THEN 1 ELSE 0 END) AS bronze,
    SUM(
        CASE
            WHEN r.medal_points = '1' THEN 3
            WHEN r.medal_points = '2' THEN 2
            WHEN r.medal_points = '3' THEN 1
            ELSE 0
        END
    ) AS score
FROM fact_results r
JOIN dim_country c USING(noc)
JOIN dim_event e   USING(event_key)
GROUP BY c.country, r.date_key, e.event

;



SELECT * FROM country_year_results
ORDER BY score DESC
;

SELECT * FROM country_year_results
ORDER BY silver DESC
;

-- Erfolg der Mannschaftsleistungen des Lands bei den Olympischen Spielen in verschiedenen Sportarten
CREATE VIEW AS
SELECT
    c.country,
    r.date_key,
    s.sport,
    COUNT(DISTINCT CASE
        WHEN r.medal = 'Gold'
        THEN r.date_key || '_' || r.event_key || '_' || r.noc
    END) AS gold,
    COUNT(DISTINCT CASE
        WHEN r.medal = 'Silver'
        THEN r.date_key || '_' || r.event_key || '_' || r.noc
    END) AS silver,
    COUNT(DISTINCT CASE
        WHEN r.medal = 'Bronze'
        THEN r.date_key || '_' || r.event_key || '_' || r.noc
    END) AS bronze
FROM fact_results r
JOIN dim_country c USING(noc)
JOIN dim_event e   USING(event_key)
JOIN dim_sport s USING(sport_key)
GROUP BY c.country, r.date_key,  s.sport
ORDER BY gold DESC;


