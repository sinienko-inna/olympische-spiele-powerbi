-- 1. Welche Länder sind bei Olympischen Spielen langfristig am erfolgreichsten?

-- Tabelle "medals" Gewonnene Medale des Lands in verschiedene Spiele !!! in Jahren - ohne Statistik
SELECT DISTINCT
        fr.event_key,
        fr.noc,
        fr.date_key,
        fr.medal
    FROM fact_results fr
    WHERE fr.medal IS NOT NULL
	ORDER BY event_key, date_key DESC;

-- Wie viele verschiedene Wettbewerbsarten gab es in Jahren der Olympiesche Spiele?
SELECT DISTINCT
        s.sport, fr.date_key, count(DISTINCT fr.event_key)
    FROM fact_results fr
JOIN dim_event e USING(event_key)
JOIN dim_sport s USING(sport_key)
GROUP BY  s.sport, fr.date_key
ORDER BY date_key DESC;

/*--metrics:
		medals_per_event, -- классическая нормализация Basis: Erfolgs-Metrik Medaillen pro Wettbewerb
        score_421, -- 🔥 метрика 4-2-1 (NYT- New York Times): 4*Gold+2*Silver+1*Bronze
        score_421_per_event -- 🔥 нормализованная версия 4-2-1 DURCH Anzahl_Teilnahme
*/
CREATE OR REPLACE VIEW view_olympic_medal_metrics AS
WITH medals AS (
    SELECT DISTINCT
        r.event_key,
        r.noc,
        r.date_key,
        r.medal
    FROM fact_results r
    WHERE r.medal IS NOT NULL
),
aggregated AS (
    SELECT
        c.country,
        m.date_key,
        s.sport,
        COUNT(DISTINCT m.event_key) AS events_count,
        SUM(CASE WHEN m.medal = 'Gold'   THEN 1 ELSE 0 END) AS gold,
        SUM(CASE WHEN m.medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
        SUM(CASE WHEN m.medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
    FROM medals m
    JOIN dim_country c USING (noc)
    JOIN dim_event e   USING (event_key)
    JOIN dim_sport s   USING (sport_key)
    GROUP BY
        c.country,
        m.date_key,
        s.sport
),
metrics AS (
    SELECT
        *,
        (gold + silver + bronze) AS total_medals,
        ROUND((gold + silver + bronze)::NUMERIC
            / NULLIF(events_count, 0),2) AS medals_per_event,
        (4 * gold + 2 * silver + 1 * bronze) AS score_421,
        ROUND((4 * gold + 2 * silver + bronze)::NUMERIC
            / NULLIF(events_count, 0),2) AS score_421_per_event
    FROM aggregated
)
SELECT *
FROM metrics;

WITH medals AS (
    SELECT DISTINCT
        r.event_key,
        r.noc,
        r.date_key,
        r.medal
    FROM fact_results r
    WHERE r.medal IS NOT NULL
),
aggregated AS (
    SELECT
        c.country,
        m.date_key,
        s.sport,
        COUNT(DISTINCT m.event_key) AS events_count,
        SUM(CASE WHEN m.medal = 'Gold'   THEN 1 ELSE 0 END) AS gold,
        SUM(CASE WHEN m.medal = 'Silver' THEN 1 ELSE 0 END) AS silver,
        SUM(CASE WHEN m.medal = 'Bronze' THEN 1 ELSE 0 END) AS bronze
    FROM medals m
    JOIN dim_country c USING (noc)
    JOIN dim_event e   USING (event_key)
    JOIN dim_sport s   USING (sport_key)
    GROUP BY
        c.country,
        m.date_key,
        s.sport
),
metrics AS (
    SELECT
        *,
        (gold + silver + bronze) AS total_medals,   -- Ganzer Anzahl der Medalien pro Land und pro Sportwettbewerbe
        ROUND((gold + silver + bronze)::NUMERIC
            / NULLIF(events_count, 0),2) AS medals_per_event, -- классическая нормализация
        (4 * gold + 2 * silver + 1 * bronze) AS score_421, -- 🔥 метрика 4-2-1 (NYT)
        ROUND((4 * gold + 2 * silver + bronze)::NUMERIC
            / NULLIF(events_count, 0),2) AS score_421_per_event -- 🔥 нормализованная версия 4-2-1
    FROM aggregated
)
SELECT *
FROM metrics
ORDER BY score_421_per_event  DESC;


/* Wie viele verschiedene Wettbewerbsarten gab es im Laufe der Geschichte der Olympiesche Spiele? * output 575*/
SELECT COUNT(DISTINCT e.event_key) AS total_wettbewerbe
FROM fact_results fr
JOIN dim_event e USING(event_key)
JOIN dim_sport s USING(sport_key)
; 

/*  
1- Индекс доминирования (Market Share): Процент медалей, выигранных страной в конкретном виде спорта,
от общего количества разыгранных медалей в этом виде за всю историю.*/


SELECT DISTINCT
        r.event_key,
        r.noc,
        r.date_key,
        r.medal
    FROM fact_results r
    WHERE r.medal IS NOT NULL

/* 
2-Коэффициент конверсии (Efficiency): Если у вас есть данные по количеству участников, 
рассчитайте отношение медалей к числу атлетов от страны в данном виде спорта.
*/

/*
Динамика успеха (Progress Index): Сравнение среднего количества баллов страны в виде спорта 
за последние 3-4 Олимпиады с её историческим средним показателем. */


/*Teilnahmeeffizienz-Indeх, Medaillendichte der Teilnahme 
Медальная плотность участий (Medal-to-Participation Ratio) 
Пояснение к запросу:
COUNT(fr.result_key) AS total_medals: Подсчитывает общее количество медалей 
для каждой пары «Страна — Вид спорта».
COUNT(DISTINCT dd.year) AS editions_participated: Это ключевая часть. 
Она использует DISTINCT year из таблицы dim_date, 
чтобы посчитать уникальное количество лет (Олимпиад), 
в которых страна выиграла хотя бы одну медаль в этом виде спорта. 
Это аппроксимация количества участий, основанная на ваших данных.
medal_to_participation_ratio: Рассчитывает итоговый показатель эффективности (отношение медалей к участиям), 
округленный до двух знаков после запятой.
WHERE fr.medal IN (...): Фильтрует только записи о медалях, исключая всех остальных участников.
*/
SELECT
    dc.country AS country_name,
    ds.sport AS sport_name,
    COUNT(fr.result_key) AS total_medals,
    COUNT(DISTINCT dd.year) AS editions_participated,
    CASE
        WHEN COUNT(DISTINCT dd.year) > 0 THEN ROUND(CAST(COUNT(fr.result_key) AS numeric) / COUNT(DISTINCT dd.year), 2)
        ELSE 0
    END AS medal_to_participation_ratio
FROM
    fact_results fr
JOIN
    dim_date dd ON fr.date_key = dd.date_key
JOIN
    dim_event de ON fr.event_key = de.event_key
JOIN
    dim_sport ds ON de.sport_key = ds.sport_key
JOIN
    dim_country dc ON fr.noc = dc.noc
WHERE
    fr.medal IN ('Gold', 'Silver', 'Bronze') -- Учитываем только призовые места
GROUP BY
    dc.country,
    ds.sport
HAVING
    COUNT(DISTINCT dd.year) > 0 -- Исключаем виды спорта/страны без участия
ORDER BY
    medal_to_participation_ratio DESC,
    total_medals DESC;

/*2. Коэффициент «Попадания в призы» (Podium Probability)
*/



-- 2. Top-N Länder pro Sport & Jahr (z. B. Top-3)
SELECT *
FROM (
    SELECT
        country,
        date_key,
        sport,
        events_count,
        total_medals,
        medals_per_event,
        RANK() OVER (
            PARTITION BY date_key, sport
            ORDER BY medals_per_event DESC
        ) AS rank_in_sport_year
    FROM metrics
) ranked
WHERE rank_in_sport_year <= 3
ORDER BY date_key, sport, rank_in_sport_year;


-- 3. Спортивные метрики по конкретным видам спорта


-- mit medale output 567, 575-567= 8 mal hatten Ergebnis ohne Medalien
SELECT COUNT(DISTINCT e.event_key) AS anzahl_wettbewerbe_spiel_jahr
FROM fact_results fr
JOIN dim_event e USING(event_key)
JOIN dim_sport s USING(sport_key)
WHERE  fr.medal IS NOT NULL;

/* überprüfen «Wie viele verschiedene Wettbewerbsarten gab Gold / Silver / Bronze» 
"Gold"	561
"Silver"	557
"Bronze"	546
*/
SELECT
    medal,
	COUNT(DISTINCT fr.event_key) AS total_wettbewerbe_medale
FROM fact_results fr
JOIN dim_event e USING(event_key)
JOIN dim_sport s USING(sport_key)
WHERE fr.medal IS NOT NULL
GROUP BY medal;

/* überprüfen «Wie viele verschiedene Wettbewerbsarten gab es im Laufe 
der Geschichte der ganzen Spiele  Gold / Silver / Bronze = 1664 */

SELECT SUM(event_count) AS total_medals
FROM (
    SELECT COUNT(DISTINCT event_key) AS event_count
    FROM fact_results
    WHERE medal IS NOT NULL
    GROUP BY medal
) t;

/* Anzahl der gewonnene Medalien pro Sport, TOP Sporte
*/
SELECT t.sport, SUM(total_events) AS total_medals
FROM (
    SELECT
        s.sport, fr.medal,
        COUNT(DISTINCT fr.event_key) AS total_events
    FROM fact_results fr
    JOIN dim_event e USING(event_key)
    JOIN dim_sport s USING(sport_key)
    WHERE fr.medal IS NOT NULL
	GROUP BY s.sport, fr.medal
) t
GROUP BY t.sport
ORDER BY total_medals DESC;


SELECT event_key, e.event, noc, date_key, COUNT(result_key) as count_athlete
FROM fact_results
join dim_athlete_season ats Using(athlete_season_key)
join dim_athlete a Using(athlete_key)
join dim_event e using(event_key)
GROUP BY event_key, e.event, noc, date_key
ORDER BY count_athlete DESC
;

/*SELECT event_key, medal, COUNT(*)
FROM fact_results
GROUP BY event_key, medal
HAVING COUNT(*) > 1;*/

-- Anzahl der Ärte/events in jedem Sport
select art.sport, sum(anzahl_events) as anzahl_arts 
from( 
	SELECT s.sport, e.event, count(*) as anzahl_events FROM dim_event e
	join dim_sport s using(sport_key)
	group by s.sport, e.event, e.sport_key
	order by e.sport_key DESC) as art
group by art.sport
order by anzahl_arts DESC
;

SELECT DISTINCT e.event
FROM dim_event e
JOIN dim_sport s USING (sport_key)
JOIN fact_results fr USING (event_key)
WHERE s.sport = 'Swimming'
  AND fr.date_key = 1968
  AND fr.noc = 'USA'
  AND medal_points >= 1
ORDER BY e.event DESC;


SELECT *
FROM (
    SELECT e.event,
           fr.medal_points,
           ROW_NUMBER() OVER (PARTITION BY e.event ORDER BY fr.medal_points DESC) rn
    FROM dim_event e
    JOIN dim_sport s USING (sport_key)
    JOIN fact_results fr USING (event_key)
    WHERE s.sport = 'Swimming'
      AND fr.date_key = 1968
      AND fr.noc = 'USA'
      AND medal_points >= 1
) t
WHERE rn = 1
ORDER BY event DESC;


-- Veränderung derAnzahlarts/events in jedem Sport in Jahren 
select art.sport, date_key, sum(anzahl_events) as anzahl_arts 
from( 
	SELECT DISTINCT s.sport, e.event, fr.date_key, count(*) as anzahl_events FROM dim_event e
	join dim_sport s using(sport_key)
	join fact_results fr using(event_key)
	group by s.sport, e.event,  fr.date_key
	order by s.sport DESC) as art
group by art.sport, date_key
order by art.sport DESC
;
-- Veränderung derAnzahl der Lands in jedem Sport in Jahren - сколько участников представили страну

	SELECT s.sport, e.event, fr.date_key, c.country,  count(c.country) as Anzahl_Mietglieder FROM dim_event e
	join dim_sport s using(sport_key)
	join fact_results fr using(event_key)
	join dim_country c using(noc)
	group by s.sport, e.event,  fr.date_key, c.country
	order by s.sport ASC;


-- какие виды спорта исчезли из ОР с 2000 года
SELECT DISTINCT
    s.sport,
    e.event
FROM dim_event e
JOIN dim_sport s USING (sport_key)
JOIN fact_results fr USING (event_key)
WHERE fr.date_key < 2000
AND NOT EXISTS (
    SELECT 1
    FROM fact_results fr2
    WHERE fr2.event_key = e.event_key
      AND fr2.date_key >= 2000
)
ORDER BY s.sport, e.event
;

SELECT
    s.sport,
    e.event
FROM dim_event e
JOIN dim_sport s USING (sport_key)
JOIN fact_results fr USING (event_key)
GROUP BY
    s.sport,
    e.event
HAVING
    MAX(fr.date_key) < 2000
ORDER BY s.sport, e.event;


CREATE OR REPLACE VIEW vw_discontinued_events_post_2000 AS
SELECT
    s.sport,
    e.event,
    MIN(fr.date_key) AS first_year,
    MAX(fr.date_key) AS last_year,
    COUNT(DISTINCT fr.date_key) AS editions_count
FROM dim_event e
JOIN dim_sport s USING (sport_key)
JOIN fact_results fr USING (event_key)
GROUP BY
    s.sport,
    e.event
HAVING
    MAX(fr.date_key) < 2000;


-- Ganzer Anzahl der Medale während OP
SELECT
    c.country,
    s.sport,
    SUM(
        CASE WHEN r.medal = 'Gold' THEN 1 ELSE 0 END
    ) AS total_gold,
    SUM(
        CASE WHEN r.medal = 'Silver' THEN 1 ELSE 0 END
    ) AS total_silver,
    SUM(
        CASE WHEN r.medal = 'Bronze' THEN 1 ELSE 0 END
    ) AS total_bronze
FROM (
    -- Сначала создаём уникальные медали для команд/индивидуалов
    SELECT DISTINCT
        r.date_key,
        r.event_key,
        r.noc,
        r.medal
    FROM fact_results r
) r
JOIN dim_country c USING(noc)
JOIN dim_event e   USING(event_key)
JOIN dim_sport s   USING(sport_key)
GROUP BY s.sport,
    c.country
ORDER BY total_gold DESC, total_silver DESC, s.sport ASC ;




/* falsche Medaillenzählung!!! 
Teamsspiele 12 Mietglieder -> jeder Mietglieder hat eine Gold gewonnen, aber es ist nicht 12 Medalen, 
sondern 1 Gold für Team
*/
SELECT
    r.date_key,
    r.medal,
	a.name,
	r.athlete_season_key,
    e.event,
	COUNT(*) rows_count
FROM fact_results r
JOIN dim_country c USING(noc)
JOIN dim_event e USING(event_key)
JOIN dim_athlete_season USING(athlete_season_key)
JOIN dim_athlete a USING(athlete_key)
WHERE c.country = 'Canada'
AND e.event = 'Lacrosse Men''s Lacrosse'
GROUP BY r.date_key, r.medal, a.name,
	e.event, r.athlete_season_key;


SELECT event
FROM dim_event
WHERE event LIKE '%Lacrosse%';

