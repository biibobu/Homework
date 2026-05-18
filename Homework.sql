WITH DeduplicatedData AS (
    -- Крок 1: Залишаємо лише один найсвіжіший запис для кожного оголошення за весь час
    SELECT 
        *,
        ROW_NUMBER() OVER (
            PARTITION BY ad_id 
            ORDER BY date DESC, timestamp DESC
        ) as row_num
    FROM `uplifted-cinema-496108-a4.homework.marketing_ads`
),
ChannelStats AS (
    -- Крок 2 & 3: Тепер SUM спрацює коректно, бо ad_id більше не дублюються між днями
    SELECT 
        source,
        SUM(spend) AS total_spend,
        SUM(impressions) AS total_impressions,
        SUM(clicks) AS total_clicks,
        SUM(installs) AS total_installs,
        SUM(registrations) AS total_registrations,
        CASE 
            WHEN source = 'google' THEN 12.40
            WHEN source = 'meta' THEN 6.20
            WHEN source = 'tiktok' THEN 8.50
        END AS ltv_per_user
    FROM DeduplicatedData
    WHERE row_num = 1
    GROUP BY source
)
-- Крок 4: Фінальний розрахунок (залишається без змін)
SELECT 
    source,
    ROUND(total_spend, 2) AS total_spend,
    ROUND(total_spend / NULLIF(total_impressions, 0) * 1000, 2) AS cpm,
    ROUND(total_clicks / NULLIF(total_impressions, 0) * 100, 2) AS ctr_pct,
    ROUND(total_installs / NULLIF(total_clicks, 0) * 100, 2) AS cr_click_install_pct,
    ROUND(total_registrations / NULLIF(total_installs, 0) * 100, 2) AS cr_install_reg_pct,
    ROUND(total_spend / NULLIF(total_registrations, 0), 2) AS cac,
    ltv_per_user AS ltv,
    ROUND(ltv_per_user / (total_spend / NULLIF(total_registrations, 0)), 2) AS ltv_cac
FROM ChannelStats
ORDER BY ltv_cac DESC;

SELECT 
    source, 
    FORMAT_DATE('%Y-%m', date) AS month,
    ROUND(SUM(spend) / NULLIF(SUM(registrations), 0), 2) AS monthly_cac
FROM (SELECT *, ROW_NUMBER() OVER (PARTITION BY ad_id, date ORDER BY timestamp DESC) as row_num FROM `uplifted-cinema-496108-a4.homework.marketing_ads`)
WHERE row_num = 1
GROUP BY 1, 2
ORDER BY 2 ASC, 3 ASC;