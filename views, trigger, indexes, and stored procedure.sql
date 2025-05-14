# Get the order detail summary

CREATE VIEW vw_OrderSummary AS
SELECT o.OrderID, u.FullName AS 'Customer Name', v.VendorName ' Vendor Name',
o.OrderDate, o.TotalAmount, s.StatusName
FROM Orders o JOIN Users u ON o.UserID = u.UserID
JOIN Vendors v ON o.VendorID = v.VendorID
JOIN DeliveryStatus ds ON o.OrderID = ds.OrderID
JOIN Status s ON s.StatusID = ds.StatusID;

select * from vw_OrderSummary;

-- Product Sales Summary
CREATE VIEW vw_ProductSalesSummary AS
SELECT p.Name AS 'Product Name', SUM(oi.Quantity) AS 'Total Product Sold'
FROM OrderItems oi JOIN Products p
ON oi.ProductID = p.ProductID
GROUP BY p.Name;

SELECT * FROM vw_ProductSalesSummary;

CREATE INDEX idx_ProductName ON Products(Name);

select * from Products where name like '%2%';

CREATE  INDEX idx_OrderItems_Order_Product
ON OrderItems(OrderID, ProductID);

DELIMITER //

CREATE TRIGGER trg_UpdateInventoryOnOrder
AFTER INSERT ON orderitems
FOR EACH ROW
BEGIN
    UPDATE inventory
    SET QuantityAvailable = QuantityAvailable - NEW.Quantity
    WHERE ProductID = NEW.ProductID;
END;

//
DELIMITER ;



-- STEP 1: Create a temporary table for order items
CREATE TEMPORARY TABLE TempOrderItems (
    ProductID INT,
    Quantity INT,
    Price DECIMAL(10,2)
);

-- STEP 2: Define the stored procedure
DELIMITER //

CREATE PROCEDURE sp_PlaceOrder(
    IN p_UserID INT,
    IN p_VendorID INT,
    IN p_TotalAmount DECIMAL(10,2)
)
BEGIN
    DECLARE NewOrderID INT;

    -- 1. Insert into Orders table
    INSERT INTO Orders(UserID, VendorID, OrderDate, TotalAmount)
    VALUES (p_UserID, p_VendorID, NOW(), p_TotalAmount);

    -- 2. Get the auto-generated OrderID
    SET NewOrderID = LAST_INSERT_ID();

    -- 3. Insert into OrderItems table using data from TempOrderItems
    INSERT INTO OrderItems(OrderID, ProductID, Quantity, Price)
    SELECT NewOrderID, ProductID, Quantity, Price FROM TempOrderItems;

    -- 4. Update Inventory
    UPDATE Inventory i
    JOIN TempOrderItems t ON i.ProductID = t.ProductID
    SET i.QuantityAvailable = i.QuantityAvailable - t.Quantity;
END;
//

DELIMITER ;



