-- NYC FOR-HIRE VEHICLE ANALYTICS - COMPLETE PROJECT
-- Author: Ofobutu Abiodun Emmanuel
-- Course: Principles of Business Analytics
-- Date: December 2025
-- Database: nyc_fhv_analytics
-- Dataset: NYC TLC HVFHV Trip Data (March 2025)
-- Records: 20,536,879 trips

-- SECTION 1: DATABASE CREATION
CREATE DATABASE nyc_fhv_analytics;




-- SECTION 2: TABLES CREATION
CREATE TABLE companies (
    company_id SERIAL PRIMARY KEY,
    hvfhs_license_num VARCHAR(10) UNIQUE NOT NULL,
    company_name VARCHAR(100) NOT NULL,
    service_type VARCHAR(50)
);

CREATE TABLE dispatch_bases (
    base_id SERIAL PRIMARY KEY,
    base_num VARCHAR(10) UNIQUE NOT NULL,
    base_name VARCHAR(100),
    company_id INTEGER REFERENCES companies(company_id),
    active_status BOOLEAN DEFAULT TRUE
);

CREATE TABLE locations (
    location_id INTEGER PRIMARY KEY,
    location_name VARCHAR(100) NOT NULL,
    borough VARCHAR(50),
    service_zone VARCHAR(50)
);

CREATE TABLE trips (
    trip_id BIGSERIAL PRIMARY KEY,
    company_id INTEGER REFERENCES companies(company_id),
    dispatching_base_id INTEGER REFERENCES dispatch_bases(base_id),
    originating_base_id INTEGER REFERENCES dispatch_bases(base_id),
    request_datetime TIMESTAMP,
    on_scene_datetime TIMESTAMP,
    pickup_datetime TIMESTAMP NOT NULL,
    dropoff_datetime TIMESTAMP NOT NULL,
    pickup_location_id INTEGER REFERENCES locations(location_id),
    dropoff_location_id INTEGER REFERENCES locations(location_id),
    trip_miles DECIMAL(8,2),
    is_shared_request BOOLEAN DEFAULT FALSE,
    is_shared_match BOOLEAN DEFAULT FALSE,
    is_access_a_ride BOOLEAN DEFAULT FALSE,
    is_wav_request BOOLEAN DEFAULT FALSE,
    is_wav_match BOOLEAN DEFAULT FALSE,
    trip_duration_minutes INTEGER,
    wait_time_minutes INTEGER
);

CREATE TABLE trip_financials (
    financial_id BIGSERIAL PRIMARY KEY,
    trip_id BIGINT REFERENCES trips(trip_id),
    base_passenger_fare DECIMAL(10,2),
    tolls DECIMAL(10,2),
    black_car_fund DECIMAL(10,2),
    sales_tax DECIMAL(10,2),
    congestion_surcharge DECIMAL(10,2),
    airport_fee DECIMAL(10,2),
    tips DECIMAL(10,2),
    driver_pay DECIMAL(10,2),
    cbd_congestion_fee DECIMAL(10,2),
    total_amount DECIMAL(10,2)
);

CREATE INDEX idx_trips_pickup_datetime ON trips(pickup_datetime);
CREATE INDEX idx_trips_company ON trips(company_id);
CREATE INDEX idx_trips_pickup_location ON trips(pickup_location_id);
CREATE INDEX idx_trips_dropoff_location ON trips(dropoff_location_id);
CREATE INDEX idx_trip_financials_trip ON trip_financials(trip_id);

-- Create staging table for trip data import
CREATE TABLE trips_staging (
    hvfhs_license_num VARCHAR(10),
    dispatching_base_num VARCHAR(10),
    originating_base_num VARCHAR(10),
    request_datetime TEXT,
    on_scene_datetime TEXT,
    pickup_datetime TEXT,
    dropoff_datetime TEXT,
    PULocationID TEXT,
    DOLocationID TEXT,
    trip_miles TEXT,
    trip_time TEXT,
    base_passenger_fare TEXT,
    tolls TEXT,
    black_car_fund TEXT,
    sales_tax TEXT,
    congestion_surcharge TEXT,
    airport_fee TEXT,
    tips TEXT,
    driver_pay TEXT,
    shared_request_flag VARCHAR(1),
    shared_match_flag VARCHAR(1),
    access_a_ride_flag VARCHAR(1),
    wav_request_flag VARCHAR(1),
    wav_match_flag VARCHAR(1),
    cbd_congestion_fee TEXT
);




-- SECTION 3: DATA IMPORT NOTES
-- Data imported via pgAdmin Import Tool:
-- 1. locations table: taxi_zone_lookup.csv (265 records)
-- 2. trips_staging table: fhvhv_tripdata_2025-03.csv (20.5M records)
-- 3. Transformation queries executed to populate trips and trip_financials






-- SECTION 4: ANALYTICAL PROCEDURES (13 ANALYSES)

-- ANALYSIS 1: PEAK HOUR DEMAND PATTERN
-- Business Question: When should we deploy most drivers?
SELECT 
    EXTRACT(HOUR FROM pickup_datetime) AS hour_of_day,
    COUNT(*) AS total_trips,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_daily_trips,
    ROUND(AVG(trip_miles), 2) AS avg_trip_miles,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration_min,
    ROUND(AVG(tf.driver_pay), 2) AS avg_driver_pay,
    ROUND(SUM(tf.driver_pay), 2) AS total_driver_earnings,
    ROUND(AVG(tf.driver_pay / NULLIF(trip_duration_minutes, 0)), 2) AS earnings_per_minute
FROM trips t
JOIN trip_financials tf ON t.trip_id = tf.trip_id
WHERE trip_duration_minutes > 0 AND trip_duration_minutes < 300
GROUP BY hour_of_day
ORDER BY hour_of_day;


-- ANALYSIS 2: COMPANY MARKET SHARE & PERFORMANCE
-- Business Question: How do Uber and Lyft compare?
SELECT 
    COALESCE(c.company_name, 'Unknown') AS company_name,
    COUNT(t.trip_id) AS total_trips,
    ROUND(100.0 * COUNT(t.trip_id) / SUM(COUNT(t.trip_id)) OVER (), 2) AS market_share_pct,
    ROUND(AVG(t.trip_miles), 2) AS avg_trip_miles,
    ROUND(AVG(t.trip_duration_minutes), 2) AS avg_duration_min,
    ROUND(AVG(tf.driver_pay), 2) AS avg_driver_earnings,
    ROUND(SUM(tf.driver_pay), 2) AS total_driver_earnings,
    ROUND(AVG(tf.tips), 2) AS avg_tips,
    ROUND(AVG(tf.tips / NULLIF(tf.driver_pay, 0) * 100), 2) AS avg_tip_pct
FROM trips t
LEFT JOIN companies c ON t.company_id = c.company_id
LEFT JOIN trip_financials tf ON t.trip_id = tf.trip_id
GROUP BY c.company_name
ORDER BY total_trips DESC;


-- ANALYSIS 3: TOP 25 PICKUP LOCATIONS BY REVENUE
-- Business Question: Where should drivers wait for passengers?
SELECT 
    l.location_name,
    l.borough,
    COUNT(t.trip_id) AS total_pickups,
    ROUND(AVG(t.trip_miles), 2) AS avg_trip_distance,
    ROUND(AVG(t.trip_duration_minutes), 2) AS avg_trip_duration,
    ROUND(AVG(tf.driver_pay), 2) AS avg_driver_pay,
    ROUND(SUM(tf.driver_pay), 2) AS total_revenue,
    ROUND(AVG(t.wait_time_minutes), 2) AS avg_wait_time_min,
    ROUND(AVG(tf.tips), 2) AS avg_tips
FROM trips t
JOIN locations l ON t.pickup_location_id = l.location_id
JOIN trip_financials tf ON t.trip_id = tf.trip_id
WHERE l.location_name IS NOT NULL
GROUP BY l.location_name, l.borough
HAVING COUNT(t.trip_id) >= 100
ORDER BY total_revenue DESC
LIMIT 25;


-- ANALYSIS 4: AIRPORT TRIP PROFITABILITY ANALYSIS
-- Business Question: Are airport trips worth prioritizing?
SELECT 
    CASE 
        WHEN tf.airport_fee > 0 THEN 'Airport Trip'
        ELSE 'Regular Trip'
    END AS trip_type,
    COUNT(*) AS trip_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
    ROUND(AVG(t.trip_miles), 2) AS avg_miles,
    ROUND(AVG(t.trip_duration_minutes), 2) AS avg_duration_min,
    ROUND(AVG(tf.driver_pay), 2) AS avg_driver_pay,
    ROUND(AVG(tf.driver_pay / NULLIF(t.trip_duration_minutes, 0)), 2) AS earnings_per_minute,
    ROUND(AVG(tf.tips), 2) AS avg_tips,
    ROUND(AVG(tf.total_amount), 2) AS avg_total_fare,
    ROUND(AVG(tf.airport_fee), 2) AS avg_airport_fee
FROM trips t
JOIN trip_financials tf ON t.trip_id = tf.trip_id
WHERE t.trip_duration_minutes > 0 AND t.trip_duration_minutes < 300
GROUP BY trip_type
ORDER BY avg_driver_pay DESC;


-- ANALYSIS 5: CONGESTION FEE IMPACT & REVENUE
-- Business Question: How much revenue comes from congestion fees?
SELECT 
    DATE(pickup_datetime) AS trip_date,
    COUNT(*) AS total_trips,
    COUNT(CASE WHEN tf.congestion_surcharge > 0 THEN 1 END) AS trips_with_congestion_fee,
    ROUND(100.0 * COUNT(CASE WHEN tf.congestion_surcharge > 0 THEN 1 END) / COUNT(*), 2) AS congestion_fee_pct,
    ROUND(SUM(tf.congestion_surcharge), 2) AS total_congestion_fees,
    ROUND(SUM(tf.cbd_congestion_fee), 2) AS total_cbd_fees,
    ROUND(SUM(tf.congestion_surcharge + tf.cbd_congestion_fee), 2) AS total_surcharges,
    ROUND(AVG(CASE WHEN tf.congestion_surcharge > 0 THEN tf.congestion_surcharge END), 2) AS avg_congestion_fee
FROM trips t
JOIN trip_financials tf ON t.trip_id = tf.trip_id
GROUP BY trip_date
ORDER BY trip_date
LIMIT 31;


-- ANALYSIS 6: DRIVER EFFICIENCY BY TRIP DISTANCE
-- Business Question: What trip lengths maximize driver earnings?
WITH trip_categories AS (
    SELECT 
        CASE 
            WHEN t.trip_miles < 1 THEN 'Very Short (< 1 mi)'
            WHEN t.trip_miles BETWEEN 1 AND 3 THEN 'Short (1-3 mi)'
            WHEN t.trip_miles BETWEEN 3 AND 5 THEN 'Medium (3-5 mi)'
            WHEN t.trip_miles BETWEEN 5 AND 10 THEN 'Long (5-10 mi)'
            WHEN t.trip_miles BETWEEN 10 AND 20 THEN 'Very Long (10-20 mi)'
            ELSE 'Extra Long (> 20 mi)'
        END AS distance_category,
        CASE 
            WHEN t.trip_miles < 1 THEN 1
            WHEN t.trip_miles BETWEEN 1 AND 3 THEN 2
            WHEN t.trip_miles BETWEEN 3 AND 5 THEN 3
            WHEN t.trip_miles BETWEEN 5 AND 10 THEN 4
            WHEN t.trip_miles BETWEEN 10 AND 20 THEN 5
            ELSE 6
        END AS sort_order,
        t.trip_miles,
        tf.driver_pay,
        t.trip_duration_minutes,
        tf.tips
    FROM trips t
    JOIN trip_financials tf ON t.trip_id = tf.trip_id
    WHERE t.trip_duration_minutes > 0 
        AND t.trip_duration_minutes < 180
        AND t.trip_miles > 0
)
SELECT 
    distance_category,
    COUNT(*) AS trip_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_trips,
    ROUND(AVG(trip_miles), 2) AS avg_miles,
    ROUND(AVG(driver_pay), 2) AS avg_driver_pay,
    ROUND(AVG(trip_duration_minutes), 2) AS avg_duration,
    ROUND(AVG(driver_pay / NULLIF(trip_duration_minutes, 0)), 2) AS earnings_per_minute,
    ROUND(AVG(tips), 2) AS avg_tips
FROM trip_categories
GROUP BY distance_category, sort_order
ORDER BY sort_order;



-- ANALYSIS 7: SHARED RIDE ECONOMICS
-- Business Question: Are shared rides beneficial for drivers?
SELECT 
    CASE 
        WHEN is_shared_request AND is_shared_match THEN 'Shared - Matched'
        WHEN is_shared_request AND NOT is_shared_match THEN 'Shared - Not Matched'
        ELSE 'Not Shared'
    END AS ride_type,
    COUNT(*) AS trip_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage,
    ROUND(AVG(t.trip_miles), 2) AS avg_miles,
    ROUND(AVG(t.trip_duration_minutes), 2) AS avg_duration,
    ROUND(AVG(tf.driver_pay), 2) AS avg_driver_pay,
    ROUND(AVG(tf.tips), 2) AS avg_tips,
    ROUND(AVG(tf.driver_pay / NULLIF(t.trip_duration_minutes, 0)), 2) AS earnings_per_minute
FROM trips t
JOIN trip_financials tf ON t.trip_id = tf.trip_id
WHERE t.trip_duration_minutes > 0 AND t.trip_duration_minutes < 180
GROUP BY ride_type
ORDER BY trip_count DESC;



-- ANALYSIS 8: WHEELCHAIR ACCESSIBLE VEHICLE (WAV) SERVICE
-- Business Question: Are we meeting accessibility requirements?
SELECT 
    CASE 
        WHEN is_wav_request AND is_wav_match THEN 'WAV Requested & Provided'
        WHEN is_wav_request AND NOT is_wav_match THEN 'WAV Requested - NOT Available'
        ELSE 'Standard Vehicle'
    END AS service_type,
    COUNT(*) AS trip_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS percentage,
    ROUND(AVG(t.wait_time_minutes), 2) AS avg_wait_time,
    ROUND(AVG(t.trip_duration_minutes), 2) AS avg_trip_duration,
    ROUND(AVG(tf.driver_pay), 2) AS avg_driver_pay,
    ROUND(AVG(tf.tips), 2) AS avg_tips
FROM trips t
JOIN trip_financials tf ON t.trip_id = tf.trip_id
WHERE t.wait_time_minutes IS NOT NULL 
    AND t.wait_time_minutes >= 0 
    AND t.wait_time_minutes < 60
GROUP BY service_type
ORDER BY trip_count DESC;



-- ANALYSIS 9: TOP 30 POPULAR TRIP ROUTES
-- Business Question: What are the most common origin-destination pairs?
SELECT 
    l1.location_name AS pickup_location,
    l1.borough AS pickup_borough,
    l2.location_name AS dropoff_location,
    l2.borough AS dropoff_borough,
    COUNT(*) AS trip_count,
    ROUND(AVG(t.trip_miles), 2) AS avg_distance,
    ROUND(AVG(t.trip_duration_minutes), 2) AS avg_duration,
    ROUND(AVG(tf.driver_pay), 2) AS avg_driver_earnings,
    ROUND(SUM(tf.driver_pay), 2) AS total_route_revenue
FROM trips t
JOIN locations l1 ON t.pickup_location_id = l1.location_id
JOIN locations l2 ON t.dropoff_location_id = l2.location_id
JOIN trip_financials tf ON t.trip_id = tf.trip_id
WHERE l1.location_name IS NOT NULL 
    AND l2.location_name IS NOT NULL
    AND l1.location_id != l2.location_id
GROUP BY l1.location_name, l1.borough, l2.location_name, l2.borough
HAVING COUNT(*) >= 50
ORDER BY trip_count DESC
LIMIT 30;



-- ANALYSIS 10: TIP PATTERNS BY DAY OF WEEK
-- Business Question: When do drivers receive best tips?
SELECT 
    EXTRACT(DOW FROM t.pickup_datetime) AS day_of_week_num,
    CASE EXTRACT(DOW FROM t.pickup_datetime)
        WHEN 0 THEN 'Sunday'
        WHEN 1 THEN 'Monday'
        WHEN 2 THEN 'Tuesday'
        WHEN 3 THEN 'Wednesday'
        WHEN 4 THEN 'Thursday'
        WHEN 5 THEN 'Friday'
        WHEN 6 THEN 'Saturday'
    END AS day_name,
    COUNT(*) AS total_trips,
    COUNT(CASE WHEN tf.tips > 0 THEN 1 END) AS trips_with_tips,
    ROUND(100.0 * COUNT(CASE WHEN tf.tips > 0 THEN 1 END) / COUNT(*), 2) AS tip_rate_pct,
    ROUND(AVG(tf.tips), 2) AS avg_tip_all_trips,
    ROUND(AVG(CASE WHEN tf.tips > 0 THEN tf.tips END), 2) AS avg_tip_when_given,
    ROUND(AVG(CASE WHEN tf.tips > 0 THEN 100.0 * tf.tips / NULLIF(tf.driver_pay, 0) END), 2) AS avg_tip_pct_of_fare,
    ROUND(SUM(tf.tips), 2) AS total_tips
FROM trips t
JOIN trip_financials tf ON t.trip_id = tf.trip_id
GROUP BY day_of_week_num, day_name
ORDER BY day_of_week_num;



-- ANALYSIS 11: BOROUGH-TO-BOROUGH TRIP FLOW
-- Business Question: Which borough connections have highest demand?
SELECT 
    COALESCE(l1.borough, 'Unknown') AS origin_borough,
    COALESCE(l2.borough, 'Unknown') AS destination_borough,
    COUNT(*) AS trip_count,
    ROUND(100.0 * COUNT(*) / SUM(COUNT(*)) OVER (), 2) AS pct_of_total,
    ROUND(AVG(t.trip_miles), 2) AS avg_distance,
    ROUND(AVG(t.trip_duration_minutes), 2) AS avg_duration,
    ROUND(AVG(tf.driver_pay), 2) AS avg_earnings,
    ROUND(SUM(tf.driver_pay), 2) AS total_revenue
FROM trips t
JOIN locations l1 ON t.pickup_location_id = l1.location_id
JOIN locations l2 ON t.dropoff_location_id = l2.location_id
JOIN trip_financials tf ON t.trip_id = tf.trip_id
WHERE l1.borough IS NOT NULL AND l2.borough IS NOT NULL
GROUP BY l1.borough, l2.borough
HAVING COUNT(*) >= 100
ORDER BY trip_count DESC
LIMIT 20;



-- ANALYSIS 12: DRIVER RESPONSE TIME PERFORMANCE
-- Business Question: How quickly do drivers respond to requests?
SELECT 
    COALESCE(c.company_name, 'Unknown') AS company_name,
    COUNT(*) AS total_trips_with_wait_data,
    ROUND(AVG(t.wait_time_minutes)::numeric, 2) AS avg_wait_time_minutes,
    ROUND(PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY t.wait_time_minutes)::numeric, 2) AS median_wait_time,
    ROUND(PERCENTILE_CONT(0.75) WITHIN GROUP (ORDER BY t.wait_time_minutes)::numeric, 2) AS p75_wait_time,
    ROUND(PERCENTILE_CONT(0.9) WITHIN GROUP (ORDER BY t.wait_time_minutes)::numeric, 2) AS p90_wait_time,
    COUNT(CASE WHEN t.wait_time_minutes <= 5 THEN 1 END) AS within_5_min,
    ROUND(100.0 * COUNT(CASE WHEN t.wait_time_minutes <= 5 THEN 1 END) / COUNT(*), 2) AS pct_within_5_min,
    COUNT(CASE WHEN t.wait_time_minutes <= 10 THEN 1 END) AS within_10_min,
    ROUND(100.0 * COUNT(CASE WHEN t.wait_time_minutes <= 10 THEN 1 END) / COUNT(*), 2) AS pct_within_10_min
FROM trips t
LEFT JOIN companies c ON t.company_id = c.company_id
WHERE t.wait_time_minutes IS NOT NULL 
    AND t.wait_time_minutes >= 0 
    AND t.wait_time_minutes <= 60
GROUP BY c.company_name
ORDER BY avg_wait_time_minutes;



-- ANALYSIS 13: REVENUE BREAKDOWN BY COMPONENT
-- Business Question: What are the main revenue drivers?
WITH revenue_components AS (
    SELECT 
        SUM(base_passenger_fare) AS base_fare_total,
        SUM(tips) AS tips_total,
        SUM(congestion_surcharge) AS congestion_total,
        SUM(airport_fee) AS airport_total,
        SUM(cbd_congestion_fee) AS cbd_total,
        SUM(tolls) AS tolls_total,
        SUM(total_amount) AS grand_total
    FROM trip_financials
),
revenue_breakdown AS (
    SELECT 
        'Base Passenger Fare' AS revenue_component,
        1 AS sort_order,
        ROUND(base_fare_total, 2) AS total_amount,
        ROUND(100.0 * base_fare_total / grand_total, 2) AS pct_of_total_revenue
    FROM revenue_components
    UNION ALL
    SELECT 
        'Tips',
        2,
        ROUND(tips_total, 2),
        ROUND(100.0 * tips_total / grand_total, 2)
    FROM revenue_components
    UNION ALL
    SELECT 
        'Congestion Surcharge',
        3,
        ROUND(congestion_total, 2),
        ROUND(100.0 * congestion_total / grand_total, 2)
    FROM revenue_components
    UNION ALL
    SELECT 
        'Airport Fees',
        4,
        ROUND(airport_total, 2),
        ROUND(100.0 * airport_total / grand_total, 2)
    FROM revenue_components
    UNION ALL
    SELECT 
        'CBD Congestion Fee',
        5,
        ROUND(cbd_total, 2),
        ROUND(100.0 * cbd_total / grand_total, 2)
    FROM revenue_components
    UNION ALL
    SELECT 
        'Tolls',
        6,
        ROUND(tolls_total, 2),
        ROUND(100.0 * tolls_total / grand_total, 2)
    FROM revenue_components
    UNION ALL
    SELECT 
        'TOTAL',
        7,
        ROUND(grand_total, 2),
        100.00
    FROM revenue_components
)
SELECT 
    revenue_component,
    total_amount,
    pct_of_total_revenue
FROM revenue_breakdown
ORDER BY sort_order;

