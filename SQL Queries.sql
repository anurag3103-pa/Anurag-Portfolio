1. Using the given Salary, Income and Deduction tables, first write an SQL query to populate the Emp_transaction table 
   and then generate a salary report

create extension tablefunc;
SELECT employee,
basic, allowance,
others,
(basic+allowance+others)
as gross,
insurance, health, house,
(insurance+health+house)
as total_deductions,
(basic+allowance+others) - 
(insurance+health+house) as net_pay FROM crosstab('SELECT emp_name, trns_type, amount FROM
					   emp_transaction ORDER BY emp_name, trns_type',
					   'SELECT DISTINCT trns_type
					   FROM emp_transaction ORDER BY trns_type') as result
					   (employee varchar, allowance numeric, basic numeric,
					   health numeric, house numeric, insurance numeric,
					   others numeric)




2.You are given a table having the marks of one student in every test. You have to output the tests in which the student has
 improved his performance. For a student to improve his performance he has to score more than the previous test. Provide 2
 solutions, one including the first test score and second excluding it.


-- OUTPUT 1
SELECT test_id,marks FROM (
SELECT *, LAG(marks,1,0) OVER(ORDER BY test_id) as prev_test_marks
FROM student_tests) A
WHERE A.marks > A.prev_test_marks

--OUTPUT 2

SELECT test_id,marks  FROM (
SELECT *, LAG(marks,1,marks) OVER(ORDER BY test_id) as prev_test_marks
FROM student_tests) A
WHERE A.marks > A.prev_test_marks


3. Write a SQL query to merge products as per customer for each day.

SELECT customer_id,dates, product_id::varchar FROM orders
GROUP BY customer_id,dates,product_id
UNION
SELECT customer_id, dates, string_agg(product_id::varchar,',')FROM orders
GROUP BY customer_id,dates
ORDER BY  dates, customer_id, product_id





4. Write a SQL query to split the hierarchy and show the employees corresponding to their team

with recursive cte as (
select c1.employee as manager1, c2.employee, CONCAT('Team',' ',ROW_NUMBER() OVER(PARTITION BY c1.employee ORDER BY c1.employee)) as rw FROM company c1
JOIN company c2 ON c1.employee = c2.manager
WHERE c1.manager IS NULL
UNION
SELECT company.manager, company.employee, rw  FROM cte
JOIN company ON company.manager  = cte.employee
),
cte2 as (
SELECT manager1, rw FROM cte
UNION
SELECT employee, rw FROM cte
)
SELECT rw AS Team, string_agg(manager1,',') as Members FROM cte2
GROUP BY rw
ORDER BY rw


5. Write a SQL query to find number of employees managed by each manager

SELECT manager_name AS MANAGER, count(emp_id) AS NO_OF_EMPLOYEES FROM(
select e1.id as emp_id, e1.name as emp_name, e2.id as manager_id,
e2.name as manager_name from employee_managers e1
join employee_managers e2 ON e1.manager = e2.id
ORDER BY e2.name) a
GROUP BY manager_name
ORDER BY count(emp_id) DESC







6. Given table contains reported covid cases in 2020. Calculate the percentage increase in covid cases each month versus cumulative cases             as of the prior month. Return the month number, and the percentage increase rounded to one decimal. Order the result by the month.


with cte as 
		(select extract(month from dates) as month
		, sum(cases_reported) as monthly_cases
		from covid_cases
		group by extract(month from dates)),
	cte_final as
		(select *
		, sum(monthly_cases) over(order by month) as total_cases
		from cte)
select month
, case when month > 1 
			then cast(round((monthly_cases/lag(total_cases) over(order by month))*100,1) as varchar)
	   else '-' end as percentage_increase
from cte_final;


7. Write a SQL query find out the employees who attended all the company events

with cte as (
Select emp_id, COUNT(DISTINCT(event_name)) AS No_of_events FROM events
Group by emp_id)
select employees.name, No_of_events FROM cte
JOIN employees ON cte.emp_id = employees.id
WHERE No_of_events = (SELECT COUNT(Distinct(No_of_events)) from cte)








8. Given table showcases details of pizza delivery order for the year of 2023.If an order is delayed then the whole order
  is given for free. Any order that takes 30 minutes more than the order time is considered as delayed order. Identify the
  percentage of delayed order for each month and also display the total no of free pizzas given each month.
  Sort the result in order of month as shown in expected output


select to_char(order_time,'Mon-YYYY') as period,
round((cast(sum(CASE WHEN CAST(to_char(actual_delivery - order_time,'MI') AS INT)>30
THEN 1 else 0 END) as decimal)/count(1))*100,1) delayed_flag,

SUM(CASE WHEN CAST(to_char(actual_delivery - order_time,'MI') AS INT)>30
THEN no_of_pizzas else 0 END) as free_pizza
FROM pizza_delivery
where actual_delivery is not null
group by to_char(order_time,'Mon-YYYY')
order by extract(month from to_date(to_char(order_time,'Mon-YYYY'),'Mon-YYYY'))


9. The column 'perc_viewed' in the table 'post_views' denotes the percentage of the session duration time the user spent viewing a post. Using it, calculate the total time that each post was viewed by users. Output post ID and the total viewing time in seconds, but only for posts with a total viewing time of over 5 seconds.


with cte as(
select user_sessions.session_id,session_starttime,session_endtime,post_views.*,
extract('epoch'from (session_endtime - session_starttime)) as times from user_sessions
join post_views on user_sessions.session_id = post_views.session_id)

select  post_id, sum((perc_viewed/100)*times) as total_viewtime
 from cte	
group by post_id
having sum((perc_viewed/100)*times) > 5


10. Given table has details of every IPL 2023 matches. Identify the maximum winning streak for each team. 
    Additional test cases: 
1) Update the dataset such that when Chennai Super Kings win match no 17, your query shows the updated streak.
2) Update the dataset such that Royal Challengers Bangalore loose all match and your query should populate the winning streak as 0


with cte as(
select home_team as teams from ipl_results
union
select away_team as teams from ipl_results),
cte2 as(
select dates, home_team, away_team, teams,result from cte
join ipl_results on ipl_results.home_team = cte.teams or
	ipl_results.away_team = cte.teams
	order by teams, dates),
cte3 as (
select *, 
row_number() over(partition by teams) as rnt from cte2),
cte4 as (
select *, 
row_number() over(partition by teams) as rnt2 from cte3
where teams = result),
cte5 as(
select *, count(rnt-rnt2) over(partition by teams, rnt-rnt2) as win from cte4)

select  teams, MAx(win) from cte5
group by teams
Order by MAX(win) desc	
