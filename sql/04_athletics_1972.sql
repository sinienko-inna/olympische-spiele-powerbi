/* общее количество медалей Athletics в разрезе стран - 1972 */ 
WITH medals AS (
    SELECT DISTINCT
        r.event_key,
        r.noc,
        r.date_key,
        r.medal
    FROM fact_results r
    WHERE r.medal IS NOT NULL
)
SELECT
    c.country,
    m.date_key,
    s.sport,
    COUNT(DISTINCT m.event_key) AS events_count,
    SUM(CASE WHEN m.medal = 'Gold'   THEN 1 ELSE 0 END) AS gold,
    SUM(CASE WHEN m.medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
    SUM(CASE WHEN m.medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze,
    -- 👇 сумма всех медалей
    COUNT(*) AS total_medals
FROM medals m
JOIN dim_country c USING (noc)
JOIN dim_event e   USING (event_key)
JOIN dim_sport s   USING (sport_key)
WHERE s.sport = 'Athletics'
  AND m.date_key = 1972
GROUP BY
    c.country,
    m.date_key,
    s.sport
ORDER BY total_medals DESC, gold DESC;


/* Сколько событий в Athletics 1972 */
SELECT COUNT(DISTINCT e.event_key) AS total_athletics_1972
FROM fact_results r
JOIN dim_event e USING(event_key)
JOIN dim_sport s USING(sport_key)
WHERE s.sport = 'Athletics'
  AND r.date_key = 1972
  AND r.medal IS NOT NULL;

/* überprüfen «Сколько событий в Athletics 1972
дали Gold / Silver / Bronze» */
SELECT
    medal,
	COUNT(DISTINCT r.event_key) AS total_athletics_1972_medale
FROM fact_results r
JOIN dim_event e USING(event_key)
JOIN dim_sport s USING(sport_key)
WHERE s.sport = 'Athletics'
  AND r.date_key = 1972
  AND r.medal IS NOT NULL
GROUP BY medal;

/* überprüfen «Сколько medale в Athletics 1972
дали Gold / Silver / Bronze: 38*3= 114» */
SELECT SUM(total_events) AS total_medals_athletics_1972
FROM (
    SELECT
        medal,
        COUNT(DISTINCT r.event_key) AS total_events
    FROM fact_results r
    JOIN dim_event e USING(event_key)
    JOIN dim_sport s USING(sport_key)
    WHERE s.sport = 'Athletics'
      AND r.date_key = 1972
      AND r.medal IS NOT NULL
    GROUP BY medal
) t;

SELECT SUM(events_count) AS total_medals
FROM (
    SELECT COUNT(DISTINCT event_key) AS events_count
    FROM fact_results
    WHERE date_key = 1972  
      AND medal IS NOT NULL
    GROUP BY medal
) t;
