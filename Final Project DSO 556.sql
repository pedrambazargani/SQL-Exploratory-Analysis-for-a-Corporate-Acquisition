--Q1) How big is the customer base of ParchandPosey (i.e., how many customers/ accounts does the company have?
SELECT COUNT(DISTINCT id) customer_count FROM accounts;
/*
"customer_count"
351
*/

--Q2) How many areas do they sell at? 7 regions
SELECT COUNT(DISTINCT id) area_count FROM region;
/*
"area_count"
7
*/

--Q3)
--a) How many types of paper do they sell and what percentage each one of them makes out of the total quantity sold? 
SELECT 
(SUM(standard_qty) * 100.0 / SUM(total)) standard_qty_percent,
(SUM(gloss_qty) * 100.0 / SUM(total)) gloss_qty_percent,
(SUM(poster_qty) * 100.0 / SUM(total)) poster_qty_percent 
FROM orders;
/*
"standard_qty_percent"	"gloss_qty_percent"	"poster_qty_percent"
52.7331317426440482	27.5799187380041978	19.6869495193517540
*/

--b) What percentage of revenues comes from which type of paper? 
SELECT 
(SUM(standard_amt_usd) * 100.0 / SUM(total_amt_usd)) standard_rev_percent,
(SUM(gloss_amt_usd) * 100.0 / SUM(total_amt_usd)) gloss_rev_percent,
(SUM(poster_amt_usd) * 100.0 / SUM(total_amt_usd)) poster_rev_percent 
FROM orders;
/*
"standard_rev_percent"	"gloss_rev_percent"	"poster_rev_percent"
41.7965196528821600	32.8118570030348791	25.3916233440829609
*/

--Q4) Is the business is growing? 
--a) How have revenues been year over year? For this, only take into account years with full data (2017 just started, so we don’t know how yearly revenues will be and 2013 seems to have data only from December).
SELECT o.year, o.total_rev, 
ROUND(((o.total_rev - LAG(o.total_rev, 1) OVER (ORDER BY o.year)) 
	   / LAG(o.total_rev, 1) OVER (ORDER BY o.year)) * 100, 2) AS percentage_diff
FROM(SELECT EXTRACT(YEAR FROM occurred_at) AS year, 
	 SUM(total_amt_usd) AS total_rev FROM orders
	 WHERE EXTRACT(YEAR FROM occurred_at) BETWEEN '2014' AND '2016'
	 GROUP BY year
	 ORDER BY year) o;

/* Yes, the business is growing.
"year"	"total_rev"	"percentage_diff"
2014	4069106.54	
2015	5752004.94	41.36
2016	12864917.92	123.66
*/

--b) How have units sold evolved year over year? Here too, only take into account the past years’ data.
SELECT o.year, o.total_unit_sold, 
ROUND(1.0*(o.total_unit_sold - LAG(o.total_unit_sold, 1) OVER (ORDER BY o.year)) 
	   / LAG(o.total_unit_sold, 1) OVER (ORDER BY o.year) * 100, 2) AS percentage_diff
FROM(SELECT EXTRACT(YEAR FROM occurred_at) AS year, 
	 SUM(total) AS total_unit_sold FROM orders
	 WHERE EXTRACT(YEAR FROM occurred_at) BETWEEN '2014' AND '2016'
	 GROUP BY year
	 ORDER BY year) o;
/* Yes, there was increase in units sold. 
"year"	"total_unit_sold"	"percentage_diff"
2014	650896	
2015	912972	40.26
2016	2041600	123.62
*/

--Q5) How many sales reps do they have in each region? Sort the result by alphabetical order and include the regions that do not have any sales reps
SELECT region.name region, COUNT(sales_reps.id) salesrep_count FROM region
LEFT JOIN sales_reps ON region.id = sales_reps.region_id
GROUP BY region.name
ORDER BY region.name;
/*
"region"	"salesrep_count"
"International"	1
"Midwest"	9
"North"	0
"Northeast"	21
"South"	0
"Southeast"	10
"West"	10
*/

--Q6)
--a)Fr om Parch and Posey’s leadership team you know that North, South and International are 3 newly added regions. If Dunder Mifflin decided to buy Parch and Posey, they would need to jump start sales in those areas. How would you suggest reallocating sales reps from the old to the new regions to cover the needs of the latter, i.e. which old regions would you recommend to pull sales reps from? To answer this question, compute in one query the following, only including data from the last year (year 2016):
/*The total number of orders per region name?
The number of reps per region name?
The number of accounts per region name?
The total revenues per region name?
The average revenues per region name?*/
SELECT r.name region, 
COUNT(DISTINCT o.id) order_count, 
COUNT(DISTINCT sr.name) rep_count,
COUNT(DISTINCT a.name) accounts_count,
ROUND(SUM(total_amt_usd),2) total_rev,
ROUND(AVG(total_amt_usd),2) avg_rev
FROM orders o JOIN accounts a ON a.id=o.account_id
JOIN sales_reps sr ON a.sales_rep_id = sr.id
JOIN region r ON sr.region_id=r.id 
WHERE EXTRACT(YEAR from occurred_at)=2016
GROUP BY region;
/*
"region"	"order_count"	"rep_count"	"accounts_count"	"total_rev"	"avg_rev"
"Midwest"	483	9	41	1711747.25	3543.99
"Northeast"	1196	21	97	3999036.82	3343.68
"Southeast"	1110	10	86	3545487.49	3194.13
"West"	968	10	93	3608646.36	3727.94
*/

--b) Based on the previous result, compute also by region: 
/*- average number of orders per representative (across all representatives) 
- average number of accounts handled per representative (across all representatives)
- average revenues per representative (across all representatives)*/
WITH q6a AS 
(SELECT r.name region, 
COUNT(DISTINCT o.id) order_count, 
COUNT(DISTINCT sr.name) rep_count,
COUNT(DISTINCT a.name) accounts_count,
ROUND(SUM(total_amt_usd),2) total_rev,
ROUND(AVG(total_amt_usd),2) avg_rev
FROM orders o JOIN accounts a ON a.id=o.account_id
JOIN sales_reps sr ON a.sales_rep_id = sr.id
JOIN region r ON sr.region_id=r.id 
WHERE EXTRACT(YEAR from occurred_at)=2016
GROUP BY region
)

SELECT 
region,
order_count / rep_count AS avg_orders_per_rep,
accounts_count / rep_count AS avg_accounts_per_rep,
total_rev / rep_count AS avg_revenue_per_rep
FROM q6a;
/*
"region"	"avg_orders_per_rep"	"avg_accounts_per_rep"	"avg_revenue_per_rep"
"Midwest"	53	4	190194.138888888889
"Northeast"	56	4	190430.324761904762
"Southeast"	111	8	354548.749000000000
"West"	96	9	360864.636000000000
*/

--c)Based on your calculations above, how would you recommend reallocating sales_reps to cover the new regions?
/*We have the flexibility to strategically redistribute sales representatives from the Northeast region for several reasons:

The Northeast currently has the largest contingent of sales representatives, suggesting we can afford to reassign some to other regions while maintaining sufficient coverage.
Northeastern sales reps manage an average of five accounts each, a manageable workload given their efficiency in processing a high volume of orders.
The average revenue per representative in the Northeast stands at $368,781, indicating strong performance that could be emulated in other regions.
Additionally, there is one sales representative who has yet to be assigned to a specific region and could be placed strategically. With these considerations in mind, the reallocation could be as follows:

Increase the International team by three representatives for four, enhancing our global presence.
Augment the North region with four representatives; three from the Northeast and the unassigned sales rep, bolstering our efforts in this growing market.
Assign four representatives to the South to tap into the market potential there.
This would leave the Northeast with ten sales representatives, aligning with the staffing levels in the Southeast, West, and Midwest regions.
As the markets in the International, North, and South regions expand, we can further adjust our allocation to meet the increasing demand. This reallocation plan aims to optimize our sales force distribution to support growth and market penetration across all regions.*/

--Q7)You suspect that accounts with the word ‘group ’ at the end of their name are likely to bring in more revenues, since they may represent a group of multiple businesses. This would be useful to know, in order to try to understand if these accounts should be given more attention after a possible acquisition by Dunder Mifflin. To answer if this is true, create a new column in your output that is: - ‘group’ if the name of the account ends with the word ‘group’ - ‘not group’ otherwise. 
--Then, based on the above result, compute the average (per account) revenues that came respectively from ‘group’ and from ‘not group’ accounts. (Hint: Here we would need 2 numbers, the average revenues for ‘group’ accounts and the average revenues for ‘not group’ accounts). Finally, comment on the result and on whether your assumption was correct. 

SELECT group_name, AVG(revenue)
FROM (SELECT name, SUM(total_amt_usd) revenue,
	  CASE 
	  WHEN LOWER(name) LIKE '%group' THEN 'group'
	  ELSE 'not group' 
	  END as group_name
	  FROM accounts a JOIN orders o ON a.id=o.account_id
	  GROUP BY name, group_name)
	  GROUP BY group_name;
/*"group_name"	"avg"
"not group"	66351.025481927711
"group"	61831.742777777778

Our initial assumption was incorrect. 
On average, non-group accounts generated significantly higher revenue, 
averaging $66351.03, compared to group accounts, which had an average revenue of $61831.74.
Other areas we can explore to identity bigger accounts are the number of orders a company makes, 
how often they order and how long they have been a customer.
*/

--Q8) The Marketing team needs to focus on channels for the newly added sales regions, and because of its limited resources, it will have to deprioritize/deactivate temporarily some channels in the old areas. Specifically, it decided to deactivate, for every old region, the channel that is used the least for web events in that region. Which channels should they deactivate in each region? Use a window function to answer here.
 
SELECT * FROM 
(SELECT r.name region, we.channel, COUNT(we.channel) 
 OVER (PARTITION BY sr.region_id ORDER BY COUNT(we.channel) DESC) AS ranking
 FROM sales_reps sr INNER JOIN region r ON r.id = sr.region_id
 INNER JOIN accounts a ON a.sales_rep_id = sr.id
 INNER JOIN web_events we ON we.account_id = a.id
 GROUP BY sr.region_id, r.name, we.channel) 
WHERE ranking = 6;
/*
"region"	"channel"	"ranking"
"Northeast"	"twitter"	6
"Midwest"	"banner"	6
"Southeast"	"twitter"	6
"West"	"banner"	6

For the Northeast region, we should deactivate Twitter.
For the Midwest region, we should deactivate banner.
For the Southeast region, we should deactivate Twitter.
For the West region, we should deactivate banner.*/