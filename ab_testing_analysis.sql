CREATE TABLE marketing_ab (
	row_index int,
    user_id int,
    test_group VARCHAR(10),
    converted BIT,
    total_ads INT,
    most_ads_day VARCHAR(10),
    most_ads_hour INT
);

--SELECT COLUMN_NAME
--FROM INFORMATION_SCHEMA.COLUMNS
--WHERE TABLE_NAME = 'marketing_ab';

-- Data preprocessing
--checking for missing values
SELECT
  SUM(CASE WHEN user_id IS NULL THEN 1 ELSE 0 END) AS missing_user_id,
  SUM(CASE WHEN test_group IS NULL THEN 1 ELSE 0 END) AS missing_test_group,
  SUM(CASE WHEN converted IS NULL THEN 1 ELSE 0 END) AS missing_converted,
  SUM(CASE WHEN total_ads IS NULL THEN 1 ELSE 0 END) AS missing_total_ads,
  SUM(CASE WHEN most_ads_day IS NULL THEN 1 ELSE 0 END) AS missing_most_ads_day,
  SUM(CASE WHEN most_ads_hour IS NULL THEN 1 ELSE 0 END) AS missing_most_ads_hour
FROM marketing_ab;

--validate and normalise values
SELECT DISTINCT test_group FROM marketing_ab;

--removing duplicates if any
WITH cte AS (
    SELECT *, ROW_NUMBER() OVER (PARTITION BY user_id ORDER BY user_id) AS rn
    FROM marketing_ab
)
DELETE FROM cte WHERE rn > 1;

--Analysis
--1. Conversion Rate by Group
SELECT 
    test_group AS group_name,
    COUNT(*) AS total_users,
    SUM(CASE WHEN converted = 1 THEN 1 ELSE 0 END) AS conversions,
    ROUND(1.0 * SUM(CASE WHEN converted = 1 THEN 1 ELSE 0 END) / COUNT(*), 4) AS conversion_rate
FROM marketing_ab
GROUP BY test_group;

--2. A/B test Uplift
WITH group_stats AS (
    SELECT 
        test_group AS group_name,
        COUNT(*) AS total_users,
        SUM(CASE WHEN converted = 1 THEN 1 ELSE 0 END) AS conversions,
        1.0 * SUM(CASE WHEN converted = 1 THEN 1 ELSE 0 END) / COUNT(*) AS conversion_rate
    FROM marketing_ab
    GROUP BY test_group
)
SELECT 
    MAX(CASE WHEN group_name = 'psa' THEN conversion_rate END) AS control_rate,
    MAX(CASE WHEN group_name = 'ad' THEN conversion_rate END) AS test_rate,
    MAX(CASE WHEN group_name = 'ad' THEN conversion_rate END) - 
    MAX(CASE WHEN group_name = 'psa' THEN conversion_rate END) AS uplift
FROM group_stats;

--3. Chi_sqaure test
WITH counts AS (
    SELECT 
        test_group AS group_name,
        SUM(CASE WHEN converted = 1 THEN 1 ELSE 0 END) AS converted,
        SUM(CASE WHEN converted = 0 THEN 1 ELSE 0 END) AS not_converted
    FROM marketing_ab
    GROUP BY test_group
),
totals AS (
    SELECT 
        SUM(converted) AS total_converted,
        SUM(not_converted) AS total_not_converted,
        SUM(converted + not_converted) AS grand_total
    FROM counts
),
chi_square AS (
    SELECT 
        c.group_name,
        c.converted, c.not_converted,
        t.total_converted, t.total_not_converted, t.grand_total,

        -- Expected values
        1.0 * t.total_converted * (c.converted + c.not_converted) / t.grand_total AS expected_converted,
        1.0 * t.total_not_converted * (c.converted + c.not_converted) / t.grand_total AS expected_not_converted

    FROM counts c
    CROSS JOIN totals t
)
SELECT 
    SUM(POWER(converted - expected_converted, 2) / expected_converted +
        POWER(not_converted - expected_not_converted, 2) / expected_not_converted) AS chi_square_statistic
FROM chi_square;

--4. Click through rate per user and by group
--by user
SELECT 
    user_id,
    total_ads,
    converted,
    ROUND(100.0 * converted / NULLIF(total_ads, 0), 2) AS estimated_ctr
FROM marketing_ab
WHERE total_ads > 0;
--by group
SELECT 
    test_group,
    ROUND(100.0 * SUM(CAST(converted AS INT)) / NULLIF(SUM(total_ads), 0), 2) AS avg_ctr_percent
FROM marketing_ab
WHERE total_ads > 0
GROUP BY test_group;

--5. Pre/Post Analysis
--checking distribution of total_ads
--min,max and average
SELECT 
    MIN(total_ads) AS min_ads,
    MAX(total_ads) AS max_ads,
    AVG(CAST(total_ads AS FLOAT)) AS avg_ads
FROM marketing_ab;
--median
SELECT DISTINCT
    PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY total_ads) OVER () AS median_ads
FROM marketing_ab;
--grouping into low, mid and high ad exposure
SELECT 
    CASE
        WHEN total_ads BETWEEN 1 AND 10 THEN 'Pre - Low Exposure'
        WHEN total_ads BETWEEN 11 AND 25 THEN 'Mid Exposure'
        ELSE 'Post - High Exposure'
    END AS exposure_stage,
    COUNT(*) AS user_count,
    SUM(CAST(converted AS INT)) AS conversions,
    ROUND(1.0 * SUM(CAST(converted AS INT)) / COUNT(*), 4) AS conversion_rate
FROM marketing_ab
GROUP BY 
    CASE
        WHEN total_ads BETWEEN 1 AND 10 THEN 'Pre - Low Exposure'
        WHEN total_ads BETWEEN 11 AND 25 THEN 'Mid Exposure'
        ELSE 'Post - High Exposure'
    END;

--6. User Segmentation by Behavior
SELECT 
    CASE 
        WHEN total_ads BETWEEN 1 AND 5 THEN 'Low Activity'
        WHEN total_ads BETWEEN 6 AND 15 THEN 'Moderate Activity'
        WHEN total_ads > 15 THEN 'High Activity'
    END AS activity_segment,
    COUNT(*) AS user_count,
    SUM(CAST(converted AS INT)) AS conversions,
    ROUND(1.0 * SUM(CAST(converted AS INT)) / COUNT(*), 4) AS conversion_rate
FROM marketing_ab
GROUP BY 
    CASE 
        WHEN total_ads BETWEEN 1 AND 5 THEN 'Low Activity'
        WHEN total_ads BETWEEN 6 AND 15 THEN 'Moderate Activity'
        WHEN total_ads > 15 THEN 'High Activity'
    END;

--7. Peak Engagement Time 
-- Identifying engagement windows by day
SELECT 
    most_ads_day,
    COUNT(*) AS user_count,
    SUM(CAST(converted AS INT)) AS conversions,
    ROUND(1.0 * SUM(CAST(converted AS INT)) / COUNT(*), 4) AS conversion_rate
FROM marketing_ab
GROUP BY most_ads_day
ORDER BY conversion_rate DESC;
-- Identifying engagement windows by hour
SELECT 
    most_ads_hour,
    COUNT(*) AS user_count,
    SUM(CAST(converted AS INT)) AS conversions,
    ROUND(1.0 * SUM(CAST(converted AS INT)) / COUNT(*), 4) AS conversion_rate
FROM marketing_ab
GROUP BY most_ads_hour
ORDER BY conversion_rate DESC;

--8. Interaction between exposure and test group
SELECT 
    test_group,
    CASE 
        WHEN total_ads BETWEEN 1 AND 10 THEN 'Pre'
        WHEN total_ads BETWEEN 11 AND 25 THEN 'Mid'
        ELSE 'Post'
    END AS exposure_stage,
    COUNT(*) AS users,
    SUM(CAST(converted AS INT)) AS conversions,
    ROUND(1.0 * SUM(CAST(converted AS INT)) / COUNT(*), 4) AS conversion_rate
FROM marketing_ab
GROUP BY test_group,
         CASE 
            WHEN total_ads BETWEEN 1 AND 10 THEN 'Pre'
            WHEN total_ads BETWEEN 11 AND 25 THEN 'Mid'
            ELSE 'Post'
         END;

--9. Power Users
SELECT TOP 10 *
FROM marketing_ab
ORDER BY total_ads DESC;
