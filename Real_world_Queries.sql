# Queries

-- 1. Get All Orders by a User (Customer or Vendor)
SELECT o.OrderID, o.OrderDate, o.TotalAmount, o.UserID, u.FullName
FROM Orders o JOIN Users u
ON o.UserID = u.UserID WHERE o.UserID = 2;

-- Vendor Query
SELECT o.OrderID, o.OrderDate, o.TotalAmount, o.UserID, v.VendorName
FROM Orders o JOIN Vendors v
ON o.VendorID = v.VendorID WHERE o.VendorID = 2;

-- 2. Order Summary with Items (Orders, OrderItems, Products)
SELECT o.OrderID, p.Name, oi.Quantity, oi.Price
FROM Orders o JOIN OrderItems oi 
ON o.OrderID = oi.OrderID
JOIN Products p
ON p.ProductID = oi.ProductID;

-- 3. Total Revenue Generated by Each Vendor
SELECT v.VendorName AS 'Vendor Name', SUM(o.TotalAmount) as 'Total Revenue'
FROM Orders o JOIN Vendors v
ON o.VendorID = v.VendorID
GROUP BY v.VendorName
ORDER BY 'Total Revenue' DESC;

-- 4. Top 3 Most Ordered Products Per Category
with productordercounts as (
select p.ProductID,p.Name as ProductName,
pc.CategoryName, sum(oi.Quantity) as TotalOrdered,
dense_rank() over(partition by pc.CategoryName order by sum(oi.Quantity)desc) as rnk
from orderitems oi
join products p on p.ProductID=oi.ProductID
join productcategories pc on p.CategoryID=pc.CategoryID
group by ProductID, pc.CategoryName)
select * from productordercounts
where rnk<=3 ;

-- 5. Users With More Than 1 Order in the Last 30 Days

select u.FullName,
count(o.OrderID) as OrderCount
from users u
join orders o on o.UserID=u.UserID
where o.OrderDate >= curdate() - interval 30 day
group by u.UserID
having OrderCount>1;

-- 6. Daily Revenue with 7-Day Rolling Average
with dailyrevenue as (
select 
date(OrderDate) as OrderDay,
sum(TotalAmount) as Revenue 
from orders group by date(OrderDate)
)
select OrderDay , Revenue,
Round(avg(Revenue) over (order by OrderDay rows
between 6 preceding and current row),2) as Rolling7DayAvg
from dailyrevenue;

-- 7. Top Vendors by Inventory Value

select v.VendorName,
sum(i.QuantityAvailable*p.Price) as InventoryValue
from inventory i
join vendors v on i.VendorID=v.VendorID
JOIN PRODUCTS P ON i.ProductID = p.ProductID
group by v.VendorID
order by InventoryValue DESC;

-- 8. Latest Review Per Product (Window Function)
select * 
from (
select r.* , row_number() over(partition by r.productID
order by  r.CreatedAt desc) as rn
from reviews r) latest
where rn=1;

-- 9. Average Rating of Products with Minimum 5 Reviews

SELECT 
  p.Name,
  COUNT(r.ReviewID) AS ReviewCount,
  ROUND(AVG(r.Rating), 2) AS AvgRating
FROM products p
JOIN reviews r ON p.ProvductID = r.ProductID
GROUP BY p.ProductID
HAVING COUNT(r.ReviewID) >= 5
ORDER BY AvgRating DESC;

-- 10. Payment Success Rate by Payment Mode
SELECT 
  PaymentMode,
  COUNT(*) AS TotalPayments,
  SUM(CASE WHEN PaymentStatus = 'Paid' THEN 1 ELSE 0 END) AS SuccessfulPayments,
  ROUND(SUM(CASE WHEN PaymentStatus = 'Paid' THEN 1 ELSE 0 END) / COUNT(*) * 100, 2) AS SuccessRate
FROM payments
GROUP BY PaymentMode;

-- 11. List of Users Who Never Made Any Orders

SELECT u.UserID, u.FullName
FROM users u
LEFT JOIN orders o ON o.UserID = u.UserID
WHERE o.OrderID IS NULL;

-- 12. Product Restock Alert (Subquery)

SELECT 
  p.Name,
  i.QuantityAvailable
FROM inventory i
JOIN products p ON i.ProductID = p.ProductID
WHERE i.QuantityAvailable < (
  SELECT AVG(QuantityAvailable) FROM inventory
);

-- 13. Revenue by City and Month Using CTE + CASE
WITH OrderDetails AS (
  SELECT 
    a.City,
    MONTH(o.OrderDate) AS OrderMonth,
    o.TotalAmount
  FROM orders o
  JOIN addresses a ON a.UserID = o.UserID
)

-- 14. CTE + Window Function: Top 3 products with the highest average rating per category
WITH ProductAvgRatings AS (
    SELECT 
        p.ProductID,
        p.Name AS ProductName,
        pc.CategoryName,
        AVG(r.Rating) AS AvgRating,
        RANK() OVER (PARTITION BY p.CategoryID ORDER BY AVG(r.Rating) DESC) AS rank_within_category
    FROM products p
    JOIN reviews r ON p.ProductID = r.ProductID
    JOIN productcategories pc ON p.CategoryID = pc.CategoryID
    GROUP BY p.ProductID, p.Name, pc.CategoryName, p.CategoryID
)
SELECT * 
FROM ProductAvgRatings 
WHERE rank_within_category <= 3;


-- 15. CASE + Subquery: Order summary with user status
SELECT 
    o.OrderID,
    u.FullName,
    o.OrderDate,
    o.TotalAmount,
    CASE 
        WHEN o.TotalAmount > 5000 THEN 'High Value'
        WHEN o.TotalAmount BETWEEN 1000 AND 5000 THEN 'Medium Value'
        ELSE 'Low Value'
    END AS OrderValueCategory,
    (SELECT COUNT(*) FROM orders o2 WHERE o2.UserID = o.UserID) AS TotalOrdersByUser
FROM orders o
JOIN users u ON o.UserID = u.UserID;

-- 16. CTE + Window Function: Cumulative revenue by vendor over time
WITH VendorRevenue AS (
    SELECT 
        o.VendorID,
        o.OrderDate,
        o.TotalAmount,
        SUM(o.TotalAmount) OVER (PARTITION BY o.VendorID ORDER BY o.OrderDate) AS CumulativeRevenue
    FROM orders o
)
SELECT v.VendorName, vr.OrderDate, vr.TotalAmount, vr.CumulativeRevenue
FROM VendorRevenue vr
JOIN vendors v ON vr.VendorID = v.VendorID
ORDER BY v.VendorName, vr.OrderDate;

-- 17. Multiple joins + aggregation + filtering: Delivery partner performance summary
SELECT 
    dp.FullName AS DeliveryPartner,
    COUNT(DISTINCT ds.DeliveryID) AS TotalDeliveries,
    AVG(o.TotalAmount) AS AvgOrderValue,
    SUM(CASE WHEN s.StatusName = 'Delivered' THEN 1 ELSE 0 END) AS SuccessfulDeliveries
FROM deliverystatus ds
JOIN deliverypartners dp ON ds.DeliveryID = dp.PartnerID
JOIN status s ON ds.StatusID = s.StatusID
JOIN orders o ON ds.OrderID = o.OrderID
GROUP BY dp.PartnerID, dp.FullName
ORDER BY SuccessfulDeliveries DESC;

-- 18. CTE + Join + Window Function: Find users who placed repeat orders within 7 days
WITH OrderDates AS (
    SELECT 
        UserID,
        OrderID,
        OrderDate,
        LEAD(OrderDate) OVER (PARTITION BY UserID ORDER BY OrderDate) AS NextOrderDate
    FROM orders
)
SELECT 
    u.FullName,
    o1.OrderDate AS FirstOrder,
    o2.OrderDate AS NextOrder,
    DATEDIFF(o2.OrderDate, o1.OrderDate) AS DaysBetween
FROM OrderDates o1
JOIN OrderDates o2 ON o1.UserID = o2.UserID AND o1.NextOrderDate = o2.OrderDate
JOIN users u ON o1.UserID = u.UserID
WHERE DATEDIFF(o2.OrderDate, o1.OrderDate) <= 7;
