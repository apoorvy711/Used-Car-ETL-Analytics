
USE used_car_analytics;
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS fact_vehicle_sales;
DROP TABLE IF EXISTS dim_vehicle;
DROP TABLE IF EXISTS dim_location;
DROP TABLE IF EXISTS dim_date;

SET FOREIGN_KEY_CHECKS = 1;

-- DATE DIMENSION
CREATE TABLE dim_date (
    date_key INT PRIMARY KEY,
    sold_date DATE,
    sold_year INT,
    sold_month VARCHAR(20),
    sold_month_num INT,
    sold_month_name VARCHAR(20),
    is_festive_season TINYINT
);

-- LOCATION DIMENSION
CREATE TABLE dim_location (
    location_id INT AUTO_INCREMENT PRIMARY KEY,
    city VARCHAR(100),
    state VARCHAR(100),
    region VARCHAR(100)
);

-- VEHICLE DIMENSION
CREATE TABLE dim_vehicle (
    vehicle_id INT PRIMARY KEY,
    brand VARCHAR(100),
    model VARCHAR(100),
    fuel_type VARCHAR(50),
    transmission VARCHAR(50),
    car_condition VARCHAR(50),
    is_premium_brand TINYINT,
    manufacturing_year INT,
    vehicle_age INT,
    kms_driven INT
);

CREATE TABLE fact_vehicle_sales (
    sale_id INT AUTO_INCREMENT PRIMARY KEY,
    vehicle_id INT,
    date_key INT,
    location_id INT,
    listed_price DECIMAL(12,2),
    sold_price DECIMAL(12,2),
    price_difference DECIMAL(12,2),
    expected_market_price DECIMAL(12,2),
    days_on_platform INT,
    conversion_rate DECIMAL(5,2),
    sale_flag TINYINT,

    FOREIGN KEY (vehicle_id) REFERENCES dim_vehicle(vehicle_id),
    FOREIGN KEY (date_key) REFERENCES dim_date(date_key),
    FOREIGN KEY (location_id) REFERENCES dim_location(location_id)
);

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_date.csv'
IGNORE
INTO TABLE dim_date
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @skip,
  @sold_date,
  @sold_year,
  @sold_month,
  @sold_month_num,
  @sold_month_name,
  @is_festive_season,
  @csv_date_key
)
SET
  date_key = @csv_date_key,
  sold_date = STR_TO_DATE(@sold_date, '%Y-%m-%d'),
  sold_year = @sold_year,
  sold_month = @sold_month,
  sold_month_num = @sold_month_num,
  sold_month_name = @sold_month_name,
  is_festive_season = @is_festive_season;

SELECT COUNT(*) FROM dim_date;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_location.csv'
INTO TABLE dim_location
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
  @city,
  @state,
  @region
)
SET
  city = @city,
  state = @state,
  region = @region;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/dim_vehicle.csv'
INTO TABLE dim_vehicle
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS;

LOAD DATA INFILE
'C:/ProgramData/MySQL/MySQL Server 8.0/Uploads/fact_vehicle_sales.csv'
INTO TABLE fact_vehicle_sales
FIELDS TERMINATED BY ','
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
IGNORE 1 ROWS
(
    @vehicle_id,
    @date_key,
    @location_id,
    @listed_price,
    @sold_price,
    @price_difference,
    @expected_market_price,
    @days_on_platform,
    @conversion_rate,
    @sale_flag
)
SET
    vehicle_id = @vehicle_id,
    date_key = @date_key,
    location_id = @location_id,
    listed_price = @listed_price,
    sold_price = @sold_price,
    price_difference = @price_difference,
    expected_market_price = @expected_market_price,
    days_on_platform = @days_on_platform,
    conversion_rate = @conversion_rate,
    sale_flag = @sale_flag;

SELECT COUNT(*) AS total_dates FROM dim_date;
SELECT COUNT(*) AS total_locations FROM dim_location;
SELECT COUNT(*) AS total_vehicles FROM dim_vehicle;
SELECT COUNT(*) AS total_sales FROM fact_vehicle_sales;

-- ANALYTICS QUERIES

-- Monthly Revenue
SELECT 
    d.sold_year,
    d.sold_month_num,
    d.sold_month_name,
    SUM(f.sold_price) AS total_revenue
FROM fact_vehicle_sales f
JOIN dim_date d 
    ON f.date_key = d.date_key
GROUP BY 
    d.sold_year, 
    d.sold_month_num,
    d.sold_month_name
ORDER BY 
    d.sold_year,
    d.sold_month_num;

-- Top Brands by Revenue
SELECT 
    v.brand,
    SUM(f.sold_price) AS total_revenue
FROM fact_vehicle_sales f
JOIN dim_vehicle v 
    ON f.vehicle_id = v.vehicle_id
GROUP BY v.brand
ORDER BY total_revenue DESC;

-- City-wise Sales Performance
SELECT 
    l.city,
    COUNT(f.sale_id) AS total_sales,
    SUM(f.sold_price) AS total_revenue
FROM fact_vehicle_sales f
JOIN dim_location l 
    ON f.location_id = l.location_id
GROUP BY l.city
ORDER BY total_revenue DESC;

-- Check total rows (should be 982)
SELECT COUNT(*) AS total_dates FROM dim_date;

-- Check min and max date
SELECT MIN(sold_date), MAX(sold_date)
FROM dim_date;

-- Check month ordering logic
SELECT DISTINCT sold_month_num, sold_month_name
FROM dim_date
ORDER BY sold_month_num;

-- Total locations
SELECT COUNT(*) AS total_locations FROM dim_location;

-- Check sample data
SELECT * FROM dim_location LIMIT 10;

-- Check unique cities
SELECT COUNT(DISTINCT city) FROM dim_location;

-- Total vehicles
SELECT COUNT(*) AS total_vehicles FROM dim_vehicle;

-- Check NULL manufacturing year
SELECT COUNT(*) 
FROM dim_vehicle 
WHERE manufacturing_year IS NULL;

-- Top 10 brands
SELECT brand, COUNT(*) AS total_cars
FROM dim_vehicle
GROUP BY brand
ORDER BY total_cars DESC
LIMIT 10;

-- Check premium brands
SELECT is_premium_brand, COUNT(*)
FROM dim_vehicle
GROUP BY is_premium_brand;

-- Total sales rows
SELECT COUNT(*) AS total_sales FROM fact_vehicle_sales;

-- Monthly Revenue
SELECT 
    d.sold_year,
    d.sold_month_num,
    d.sold_month_name,
    SUM(f.sold_price) AS total_revenue
FROM fact_vehicle_sales f
JOIN dim_date d 
    ON f.date_key = d.date_key
GROUP BY 
    d.sold_year,
    d.sold_month_num,
    d.sold_month_name
ORDER BY 
    d.sold_year,
    d.sold_month_num;

-- Top 10 Brands by Revenue
SELECT 
    v.brand,
    SUM(f.sold_price) AS total_revenue
FROM fact_vehicle_sales f
JOIN dim_vehicle v 
    ON f.vehicle_id = v.vehicle_id
GROUP BY v.brand
ORDER BY total_revenue DESC
LIMIT 10;

-- City-wise Sales Performance
SELECT 
    l.city,
    COUNT(*) AS total_sales,
    SUM(f.sold_price) AS total_revenue
FROM fact_vehicle_sales f
JOIN dim_location l 
    ON f.location_id = l.location_id
GROUP BY l.city
ORDER BY total_revenue DESC;

-- Average Price Difference
SELECT 
    AVG(price_difference) AS avg_price_difference
FROM fact_vehicle_sales;

-- Conversion Rate by Brand
SELECT 
    v.brand,
    AVG(f.conversion_rate) AS avg_conversion_rate
FROM fact_vehicle_sales f
JOIN dim_vehicle v 
    ON f.vehicle_id = v.vehicle_id
GROUP BY v.brand
ORDER BY avg_conversion_rate DESC;

