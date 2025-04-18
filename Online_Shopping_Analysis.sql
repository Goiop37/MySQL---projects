create database mavenfuzzyfactory;
use mavenfuzzyfactory;

/*import tables */


-- problem1
/*Gsearch seems to be the biggest driver of our business. Pull monthly 
trends for gsearch sessions and orders so that we can showcase the growth there? 
*/ 
SELECT YEAR(website_sessions.created_at) AS Year ,Month(website_sessions.created_at) AS Month,
COUNT(website_sessions.website_session_id) as Sessions,
count(orders.order_id) as Orders
from website_sessions left join orders on
website_sessions.website_session_id=orders.website_session_id
where utm_source='gsearch'
group by 1,2
order by 1,2;


-- problem2
/*Provide similar monthly trend for Gsearch, but this time splitting out nonbrand 
and brand campaigns separately to check if brand is picking up at all. 
*/ 
select 
YEAR(website_sessions.created_at) as Year ,Month(website_sessions.created_at) as Month, 
COUNT(CASE WHEN utm_campaign='nonbrand' THEN website_sessions.website_session_id END) as non_brand_sessions,
COUNT(CASE WHEN utm_campaign='nonbrand' THEN orders.order_id END) as non_brand_orders,
COUNT(CASE WHEN utm_campaign='brand' THEN website_sessions.website_session_id END) as brand_sessions,
COUNT(CASE WHEN utm_campaign='brand' THEN orders.order_id END) as brand_orders
from  website_sessions
left JOIN ORDERS ON website_sessions.website_session_id=orders.website_session_id
where utm_source='gsearch'
group by 1,2
order by 1,2;


-- problem3
/* While we’re on Gsearch, dive into nonbrand, and pull monthly sessions and orders split by device type? 
*/ 
select 
YEAR(website_sessions.created_at) as Year ,Month(website_sessions.created_at) as Month, 
COUNT(CASE WHEN device_type='desktop' then website_sessions.website_session_id END) as desktop_sessions,
COUNT(CASE WHEN device_type='desktop'  THEN orders.order_id END) as desktop_orders,
COUNT(CASE WHEN device_type='mobile'  THEN website_sessions.website_session_id END) as mobile_sessions,
COUNT(CASE WHEN device_type='mobile'  THEN orders.order_id END) as mobile_orders
from  website_sessions
left JOIN ORDERS ON website_sessions.website_session_id=orders.website_session_id
where utm_source='gsearch' and utm_campaign='nonbrand'
group by 1,2
order by 1,2;

-- problem4
/* Pull the monthly trends for Gsearch, alongside monthly trends for each of our other channels?
First, find the various utm sources and referers to see the traffic we're getting */ 
SELECT DISTINCT 
	utm_source,
    utm_campaign, 
    http_referer
FROM website_sessions
WHERE website_sessions.created_at < '2012-11-27';


SELECT
	YEAR(website_sessions.created_at) AS Year, 
    MONTH(website_sessions.created_at) AS Month, 
    COUNT(DISTINCT CASE WHEN utm_source = 'gsearch' THEN website_sessions.website_session_id ELSE NULL END) AS gsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source = 'bsearch' THEN website_sessions.website_session_id ELSE NULL END) AS bsearch_paid_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NOT NULL THEN website_sessions.website_session_id ELSE NULL END) AS organic_search_sessions,
    COUNT(DISTINCT CASE WHEN utm_source IS NULL AND http_referer IS NULL THEN website_sessions.website_session_id ELSE NULL END) AS direct_type_in_sessions
FROM website_sessions
GROUP BY 1,2;


-- problem5
/*Tell the story of our website performance improvements over the course of the first 8 months. 
Pull session to order conversion rates, by month for first 8 months? */
SELECT
YEAR(website_sessions.created_at) AS Year,
MONTH(website_sessions.created_at) AS Month,
count(website_sessions.website_session_id) AS sessions,
count(orders.order_id) AS orders,
count(orders.order_id)/count(website_sessions.website_session_id) AS CONVERSION_RATES
FROM website_sessions LEFT JOIN orders ON
website_sessions.website_session_id=orders.website_session_id
GROUP BY 1,2
ORDER BY 1,2
LIMIT 8;


-- problem6
/* Between 10 Sept 2012 and 10 Nov 2012, find the number of sessions that landed in /billing and /billing-2 urls,
orders that were placed and revenue that was generated. Also find the revenue obtained per session
*/
select pageview_url,
count(distinct website_sessions.website_session_id) as sessions,
count(distinct order_id) as orders,
sum(price_usd) as revenue,
sum(price_usd) / count(distinct website_sessions.website_session_id) as revenue_per_session
from website_sessions
left join website_pageviews on website_sessions.website_session_id=website_pageviews.website_session_id
left join orders on orders.website_session_id=website_pageviews.website_session_id
where pageview_url in ('/billing','/billing-2') and website_sessions.created_at between '2012-09-10' and '2012-11-10'
group by 1
;

 -- problem7
 /* Analyze the lift generated from the billing test (Sep 10 – Nov 10), in terms of revenue per billing page session, and then pull the number 
of billing page sessions for the past month to understand monthly impact.
*/ 


SELECT
	billing_version_seen, 
    COUNT(DISTINCT website_session_id) AS sessions, 
    SUM(price_usd)/COUNT(DISTINCT website_session_id) AS revenue_per_billing_page_seen
 FROM( 
SELECT 
	website_pageviews.website_session_id, 
    website_pageviews.pageview_url AS billing_version_seen, 
    orders.order_id, 
    orders.price_usd
FROM website_pageviews 
	LEFT JOIN orders
		ON orders.website_session_id = website_pageviews.website_session_id
WHERE website_pageviews.created_at > '2012-09-10' -- prescribed in question
	AND website_pageviews.created_at < '2012-11-10' -- prescribed in question
    AND website_pageviews.pageview_url IN ('/billing','/billing-2')
) AS billing_pageviews_and_order_data
GROUP BY 1
;
-- $22.83 revenue per billing page seen for the old version
-- $31.34 for the new version
-- LIFT: (31.34-22.83) $8.51 per billing page view 

SELECT 
	COUNT(website_session_id) AS billing_sessions_past_month
FROM website_pageviews 
WHERE website_pageviews.pageview_url IN ('/billing','/billing-2') 
	AND created_at BETWEEN '2012-10-27' AND '2012-11-27' -- past month

-- 1,194 billing sessions past month
-- LIFT: $8.51 per billing session
-- VALUE OF BILLING TEST: (1194*8.51) $10,160 over the past month