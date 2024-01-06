 -- Query to obtain DAU and count the number of analytical events per day.
 SELECT 
        log_date,
        COUNT(DISTINCT user_id) as dau,
        count(name) as events
   FROM events_log
        GROUP BY log_date
        ORDER BY log_date

-- A request to obtain a calculation of the number of unique users who visited the service from different acquisition sources.

SELECT 
        utm_source,
        COUNT(DISTINCT user_id) as users
FROM events_log
GROUP BY utm_source
ORDER BY users DESC

--The volume of new users attracted to the application on each day.

WITH new AS (
    
    SELECT user_id,       
           MIN(utm_source) AS utm_source, 
           MIN(install_date) AS install_date
    FROM events_log 
    WHERE log_date =install_date 
    GROUP BY user_id

),
new_by_source AS (
    
    SELECT utm_source,
           install_date,
           COUNT(DISTINCT user_id) AS uniques
    FROM new
    GROUP BY utm_source, install_date   

)
SELECT utm_source,
       install_date,
       uniques,
       CAST(uniques as FLOAT)/SUM(uniques) OVER (PARTITION BY install_date) AS perc_dau
FROM new_by_source
ORDER BY install_date, uniques DESC

--Conversion to purchase for each source of attraction for the entire observation period.

WITH new AS (

    SELECT user_id,
           MIN(utm_source) AS utm_source,
           MIN(install_date) AS install_date
    FROM events_log
    WHERE log_date = install_date
    GROUP BY user_id

),
purchase AS (
   SELECT 
          DISTINCT user_id
   FROM events_log
   WHERE name='purchase'
)
SELECT utm_source,
       COUNT(DISTINCT n.user_id) AS new_users,
       COUNT(DISTINCT p.user_id) AS buyers,
       CAST(COUNT(DISTINCT p.user_id) AS FLOAT)/CAST(COUNT(DISTINCT n.user_id) AS FLOAT) AS conversion
FROM new n
LEFT OUTER JOIN purchase p ON n.user_id=p.user_id
GROUP BY utm_source
ORDER BY buyers DESC

--Average movie viewing time

SELECT
    log_date,
    app_id,
    utm_source,
    SUM(CAST(REPLACE(object_value, ',', '.') AS FLOAT)) AS sum_duration,
    COUNT(DISTINCT user_id) AS users,
    (SUM(CAST(REPLACE(object_value, ',', '.') AS FLOAT)) / 3600.0) / CAST(COUNT(DISTINCT user_id) AS FLOAT) AS avg_duration
FROM events_log
WHERE name IN ('endMovie')
GROUP BY log_date, app_id, utm_source;