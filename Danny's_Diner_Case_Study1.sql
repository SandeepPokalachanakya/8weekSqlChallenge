CREATE DATABASE dannys_diner;
use  dannys_diner;

CREATE TABLE sales (
    customer_id VARCHAR(1),
    order_date DATE,
    product_id INTEGER
);

INSERT INTO sales
  (customer_id, order_date, product_id)
VALUES
  ('A', '2021-01-01', '1'),
  ('A', '2021-01-01', '2'),
  ('A', '2021-01-07', '2'),
  ('A', '2021-01-10', '3'),
  ('A', '2021-01-11', '3'),
  ('A', '2021-01-11', '3'),
  ('B', '2021-01-01', '2'),
  ('B', '2021-01-02', '2'),
  ('B', '2021-01-04', '1'),
  ('B', '2021-01-11', '1'),
  ('B', '2021-01-16', '3'),
  ('B', '2021-02-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-01', '3'),
  ('C', '2021-01-07', '3');
 

CREATE TABLE menu (
    product_id INTEGER,
    product_name VARCHAR(5),
    price INTEGER
);

INSERT INTO menu
  (product_id,product_name, price)
VALUES
  ('1', 'sushi', '10'),
  ('2', 'curry', '15'),
  ('3', 'ramen', '12');
  

CREATE TABLE members (
    customer_id VARCHAR(1),
    join_date DATE
);

INSERT INTO members
  (customer_id, join_date)
VALUES
  ('A', '2021-01-07'),
  ('B', '2021-01-09');
  
SELECT 
    *
FROM
    members;
SELECT 
    *
FROM
    menu;
SELECT 
    *
FROM
    sales;
  /* --------------------
   Case Study Questions
   --------------------*/

SELECT 
    s.customer_id, SUM(price)
FROM
    sales AS s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY customer_id;


-- 2. How many days has each customer visited the restaurant?
SELECT 
    customer_id, COUNT(DISTINCT order_date) AS visited_days
FROM
    sales
GROUP BY customer_id;

-- 3. What was the first item from the menu purchased by each customer?

SELECT 
    s.customer_id, s.product_id, m.product_name
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    (SELECT 
        customer_id, MIN(order_date) AS first_order_date
    FROM
        sales
    GROUP BY customer_id) AS first_order ON s.customer_id = first_order.customer_id
        AND s.order_date = first_order.first_order_date;



-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
SELECT 
    s.product_id, m.product_name, COUNT(*) AS times_pruchased
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY s.product_id , m.product_name
ORDER BY COUNT(*) DESC
LIMIT 1;

-- 5. Which item was the most popular for each customer?


SELECT 
    t.customer_id,
    t.product_name,
    t.total_count AS maximum_count
FROM
    (SELECT 
        s.customer_id, m.product_name, COUNT(*) AS total_count
    FROM
        sales s
    JOIN menu m ON s.product_id = m.product_id
    GROUP BY s.customer_id , m.product_name) t
        JOIN
    (SELECT 
        customer_id, MAX(total_count) AS max_count
    FROM
        (SELECT 
        s.customer_id, s.product_id, COUNT(*) AS total_count
    FROM
        sales s
    GROUP BY s.customer_id , s.product_id) y
    GROUP BY customer_id) z ON t.customer_id = z.customer_id
        AND t.total_count = z.max_count;

-- 6. Which item was purchased first by the customer after they became a member?
SELECT 
    s.customer_id, m.product_name, s.order_date
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members mm ON s.customer_id = mm.customer_id
WHERE
    s.order_date >= mm.join_date
        AND s.order_date = (SELECT 
            MIN(order_date)
        FROM
            sales
        WHERE
            customer_id = s.customer_id
                AND order_date >= mm.join_date);


-- 7. Which item was purchased just before the customer became a member?

SELECT 
    s.customer_id, m.product_name, s.order_date
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members mm ON s.customer_id = mm.customer_id
WHERE
    s.order_date <= mm.join_date
        AND s.order_date = (SELECT 
            MIN(order_date)
        FROM
            sales
        WHERE
            customer_id = s.customer_id
                AND order_date <= mm.join_date);

-- 8. What is the total items and amount spent for each member before they became a member?
SELECT 
    s.customer_id,
    COUNT(*) AS total_count,
    SUM(m.price) AS total_price
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members mm ON s.customer_id = mm.customer_id
WHERE
    s.order_date < mm.join_date
GROUP BY s.customer_id;


-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?
SELECT 
    s.customer_id,
    SUM(CASE
        WHEN m.product_name = 'sushi' THEN m.price * 20
        ELSE m.price * 10
    END) AS total_points
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
GROUP BY s.customer_id
ORDER BY total_points DESC;



-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

SELECT 
    s.customer_id,
    SUM(CASE
        WHEN s.order_date BETWEEN mm.join_date AND DATE_ADD(mm.join_date, INTERVAL 6 DAY) THEN m.price * 20
        WHEN mm.join_date IS NULL THEN 0
        ELSE CASE
            WHEN m.product_name = 'sushi' THEN m.price * 20
            ELSE m.price * 10
        END
    END) AS total_points
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        LEFT JOIN
    members mm ON s.customer_id = mm.customer_id
WHERE
    s.order_date < '2021-02-01'
GROUP BY s.customer_id
ORDER BY total_points DESC;



/*
---BONUS----
-- Join All The Things
The following questions are related creating basic data tables that Danny and his team can use to quickly derive insights without needing to join the underlying tables using SQL.
*/
SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE
        WHEN
            mm.customer_id IS NOT NULL
                AND s.order_date >= mm.join_date
        THEN
            'Y'
        ELSE 'N'
    END AS membership
FROM
    sales s
        JOIN
    menu m ON s.product_id = m.product_id
        JOIN
    members mm ON s.customer_id = mm.customer_id
ORDER BY customer_id , s.order_date;



/*Rank All The Things
Danny also requires further information about the ranking of customer products, but he purposely does not need the ranking for non-member purchases so he expects null ranking values for the records when customers are not yet part of the loyalty program.*/

WITH member_ranks AS (
    SELECT 
        s.customer_id,
        s.order_date,
        RANK() OVER (
            PARTITION BY s.customer_id 
            ORDER BY s.order_date
        ) AS ranking
    FROM sales s
    JOIN members mm ON s.customer_id = mm.customer_id
    WHERE s.order_date >= mm.join_date
    GROUP BY s.customer_id, s.order_date
)
SELECT 
    s.customer_id,
    s.order_date,
    m.product_name,
    m.price,
    CASE 
        WHEN s.order_date >= mm.join_date THEN 'Y'
        ELSE 'N'
    END AS member,
    mr.ranking
FROM sales s
JOIN menu m ON s.product_id = m.product_id
LEFT JOIN members mm ON s.customer_id = mm.customer_id
LEFT JOIN member_ranks mr ON s.customer_id = mr.customer_id AND s.order_date = mr.order_date
ORDER BY s.customer_id, s.order_date, m.product_name;