USE master
GO

IF DB_ID('InventoryManagement') IS NOT NULL
    DROP DATABASE InventoryManagement
CREATE DATABASE InventoryManagement
GO

USE InventoryManagement
GO

--------------------- TABLES ---------------------

-- Stores product categories (Категории товаров)
CREATE TABLE Categories (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,


    CONSTRAINT CHK_Categories_Name CHECK (Name <> '')
);


-- Stores supplier information (Информация о поставщиках)
CREATE TABLE Suppliers (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    ContactPerson NVARCHAR(100),
    Phone NVARCHAR(20),
    Email NVARCHAR(100),


    CONSTRAINT CHK_Suppliers_Name CHECK (Name <> ''),
    CONSTRAINT CHK_Suppliers_Email CHECK (Email LIKE '%_@__%.__%'),
    CONSTRAINT CHK_Suppliers_Phone CHECK (Phone LIKE '[0-9]%' OR Phone IS NULL)
);


-- Stores product information (Информация о товарах)
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    PurchasePrice DECIMAL(10,2),
    SellingPrice DECIMAL(10,2),
    CreatedDate DATETIME DEFAULT GETDATE(),


    CONSTRAINT CHK_Products_Name CHECK (Name <> ''),
    CONSTRAINT CHK_Positive_Prices CHECK (PurchasePrice > 0 AND SellingPrice > 0),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(Id),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(Id)
);



-- Tracks inventory levels (Учет товарных запасов)
CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    LastUpdated DATETIME DEFAULT GETDATE(),
    MinStock INT DEFAULT 1,


    CONSTRAINT CHK_Inventory_MinStock CHECK (MinStock > 0),
    CONSTRAINT CHK_Inventory_Name CHECK (Name <> ''),
    CONSTRAINT FK_Inventory_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);



-- Stores system alerts (Системные уведомления)
CREATE TABLE Alerts (
    AlertID INT PRIMARY KEY IDENTITY(1,1),
    AlertType NVARCHAR(50) NOT NULL,
    Message NVARCHAR(500) NOT NULL,
    ProductID INT NOT NULL FOREIGN KEY REFERENCES Products(ProductID),
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsRead BIT DEFAULT 0,
    LastUpdated DATETIME DEFAULT GETDATE(),


    CONSTRAINT CHK_Alert_Type CHECK (AlertType IN ('Low_Stock', 'Auto_Reorder'))
);




-- Stores purchase orders (Заказы на закупку)
CREATE TABLE PurchaseOrders (
    PurchaseOrderID INT PRIMARY KEY IDENTITY(1,1),
    SupplierID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending',
    TotalAmount DECIMAL(10,2),


    CONSTRAINT CHK_PurchaseOrders_Status CHECK (Status IN ('Pending', 'Processing', 'Completed', 'Cancelled')),
    CONSTRAINT FK_PurchaseOrders_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(Id)
);



-- Stores purchase order items (Позиции заказов)
CREATE TABLE PurchaseOrderItems (
    PurchaseOrderItemID INT PRIMARY KEY IDENTITY(1,1),
    PurchaseOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2),


    CONSTRAINT FK_PurchaseOrderItems_PurchaseOrders FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrders(PurchaseOrderID),
    CONSTRAINT FK_PurchaseOrderItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);



-- Tracks inventory transactions (Транзакции инвентаря)
CREATE TABLE InventoryTransactions (
    TransactionID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL,
    Notes NVARCHAR(255),
    PreviousQuantity INT,
    NewQuantity INT,
    TransactionDate DATETIME DEFAULT GETDATE(),
    CreatedBy NVARCHAR(50) DEFAULT SUSER_NAME(),


    CONSTRAINT FK_InventoryTransactions_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CHK_InventoryTransactions_Type CHECK (TransactionType IN ('Purchase', 'Sale', 'Adjustment', 'Return', 'Write-off'))
);





--------------------- INDEXES ---------------------

CREATE INDEX IX_Products_Name ON Products(Name);
CREATE INDEX IX_Inventory_ProductID ON Inventory(ProductID);





--------------------- SAMPLE DATA ---------------------

-- Categories
INSERT INTO Categories (Name) VALUES
('Tobacco Products'),
('Alcoholic Beverages'),
('Dairy Products'),
('Bakery Goods'),
('Frozen Foods'),
('Snacks');


-- Suppliers
INSERT INTO Suppliers (Name, ContactPerson, Phone, Email) VALUES
('Tobacco Distributors LLC', 'Mike Smirnov', '380501112233', 'mike@tobacco-dist.com'),
('Beverage Partners Co.', 'Oleg Ivanov', '380502223344', 'oleg@bevpartners.com'),
('Fresh Dairy Ltd.', 'Anna Petrova', '380503334455', 'anna@freshdairy.ua'),
('Bakery Supplies Inc.', 'Ivan Sidorov', '380504445566', 'ivan@bakerysupplies.com'),
('Frosty Foods', 'Elena Frost', '380505556677', 'elena@frostyfoods.com');


-- Products
INSERT INTO Products (Name, Description, CategoryID, SupplierID, PurchasePrice, SellingPrice) VALUES
('Marlboro Red (Pack)', 'Cigarettes 20 pieces', 1, 1, 45.00, 65.00),
('Lvivske Beer 0.5L', 'Ukrainian lager beer', 2, 2, 15.00, 28.00),
('Ice Cream Vanilla 500ml', 'Premium vanilla ice cream', 3, 3, 32.00, 49.99),
('White Bread Loaf', 'Fresh wheat bread 700g', 4, 4, 8.50, 14.99),
('Potato Chips 150g', 'Classic salted chips', 6, 5, 18.00, 32.50),
('Vodka 0.5L', 'Premium Ukrainian vodka', 2, 2, 85.00, 129.99),
('Rye Bread', 'Traditional rye bread 600g', 4, 4, 9.00, 16.50),
('Cigarettes Winston (Pack)', 'International brand cigarettes', 1, 1, 50.00, 72.00);


-- Inventory
INSERT INTO Inventory (Name, ProductID, Quantity, MinStock) VALUES
('Tobacco Shelf - Marlboro', 1, 50, 20),
('Beer Cooler - Lvivske', 2, 120, 40),
('Freezer - Ice Cream', 3, 35, 15),
('Bakery Section - White Bread', 4, 30, 10),
('Snack Aisle - Chips', 5, 80, 25),
('Liquor Cabinet - Vodka', 6, 25, 5),
('Bakery Section - Rye Bread', 7, 20, 8),
('Tobacco Shelf - Winston', 8, 40, 15);


-- Purchase Orders
INSERT INTO PurchaseOrders (SupplierID, Status, TotalAmount) VALUES
(1, 'Completed', 5250.00),
(2, 'Pending', 3850.00),
(3, 'Processing', 2240.00),
(4, 'Completed', 1275.00),
(5, 'Pending', 2160.00);


-- Purchase Order Items
INSERT INTO PurchaseOrderItems (PurchaseOrderID, ProductID, Quantity, UnitPrice) VALUES
(1, 1, 100, 45.00),
(1, 8, 50, 50.00),
(2, 2, 200, 15.00),
(2, 6, 20, 85.00),
(3, 3, 70, 32.00),
(4, 4, 150, 8.50),
(4, 7, 100, 9.00),
(5, 5, 120, 18.00);


-- Inventory Transactions
INSERT INTO InventoryTransactions (ProductID, Quantity, TransactionType, Notes, PreviousQuantity, NewQuantity, CreatedBy) VALUES
(1, 50, 'Adjustment', 'Initial tobacco stock', 0, 50, 'System'),
(2, 120, 'Adjustment', 'Initial beer stock', 0, 120, 'System'),
(3, 35, 'Adjustment', 'Initial ice cream stock', 0, 35, 'System'),
(4, 30, 'Adjustment', 'Initial bread stock', 0, 30, 'System'),
(5, 80, 'Adjustment', 'Initial snacks stock', 0, 80, 'System'),
(1, -5, 'Sale', 'Retail sale', 50, 45, 'Cashier1'),
(2, -12, 'Sale', 'Bulk purchase', 120, 108, 'Cashier2'),
(3, -3, 'Sale', 'Weekend sale', 35, 32, 'Cashier3'),
(4, -8, 'Sale', 'Morning rush', 30, 22, 'Cashier1'),
(6, 25, 'Purchase', 'Vodka delivery', 0, 25, 'Warehouse');




--------------------- VIEWS ---------------------

-- Shows current inventory status (Текущее состояние запасов)
CREATE VIEW InvStatus AS
SELECT P.ProductID, P.Name AS ProductName, C.Name AS CategoryName, S.Name AS SupplierName, I.Quantity AS CurrentStock, I.MinStock, P.PurchasePrice, P.SellingPrice,I.Quantity * P.PurchasePrice AS InventoryValue,I.LastUpdated FROM Products P
JOIN Inventory I ON P.ProductID = I.ProductID
JOIN Categories C ON P.CategoryID = C.Id
JOIN Suppliers S ON P.SupplierID = S.Id;
GO


-----------------------------
SELECT * FROM InvStatus;
GO
----------------------



-- Shows transaction history (История транзакций)
CREATE VIEW TransHistory AS
SELECT  T.TransactionID, P.Name AS ProductName, T.Quantity, T.TransactionType, T.PreviousQuantity, T.NewQuantity, T.Notes, T.TransactionDate, T.CreatedBy FROM InventoryTransactions T
JOIN Products P ON T.ProductID = P.ProductID;
GO


-----------------------------
SELECT * FROM TransHistory;
GO
-------------------------------------


-- Combines different alert types (Объединенные уведомления)
CREATE OR ALTER VIEW CombinedAlerts AS SELECT AlertType AS AlertCategory, Message, CreatedDate, ProductID FROM Alerts

UNION ALL

SELECT 'AUTO_REORDER' AS AlertCategory, 'Ordered ' + P.Name + ' from ' + S.Name + ' (Qty: ' + CAST(POI.Quantity AS NVARCHAR) + ')', PO.OrderDate, P.ProductID FROM PurchaseOrderItems POI
JOIN Products P ON POI.ProductID = P.ProductID
JOIN PurchaseOrders PO ON POI.PurchaseOrderID = PO.PurchaseOrderID
JOIN Suppliers S ON PO.SupplierID = S.Id WHERE PO.Status = 'Pending';
GO


------------------------------
SELECT * FROM CombinedAlerts;
GO
--------------------------------



--------------------- TRIGGERS ---------------------

-- Updates inventory when transactions occur (Обновляет запасы при транзакциях)
CREATE TRIGGER UpdateInvTrans
ON InventoryTransactions
AFTER INSERT
AS
BEGIN UPDATE I SET I.Quantity = INS.NewQuantity, I.LastUpdated = GETDATE() FROM Inventory I
JOIN inserted INS ON I.ProductID = INS.ProductID;
END
GO

-- Creates alerts when stock is low (Создает уведомления при низком запасе)
CREATE TRIGGER LowStockAlert
ON Inventory
AFTER UPDATE
AS
BEGIN INSERT INTO Alerts (AlertType, Message, ProductID)
SELECT 'LOW_STOCK','Low stock: ' + P.Name + ' (Current: ' + CAST(I.Quantity AS NVARCHAR) + ', Min: ' + CAST(I.MinStock AS NVARCHAR) + ')', I.ProductID FROM inserted AS I
JOIN Products P ON I.ProductID = P.ProductID WHERE I.Quantity < I.MinStock;
END
GO

-- Automatically creates purchase orders when stock is low(Автоматически создает заказы)
CREATE TRIGGER AutoReorder
ON Inventory
AFTER UPDATE
AS
BEGIN INSERT INTO PurchaseOrders (SupplierID, Status, TotalAmount)
SELECT P.SupplierID, 'Pending', 0 FROM inserted I
JOIN Products P ON I.ProductID = P.ProductID WHERE I.Quantity < I.MinStock
GROUP BY P.SupplierID;

INSERT INTO PurchaseOrderItems (PurchaseOrderID, ProductID, Quantity, UnitPrice)
SELECT PO.PurchaseOrderID, I.ProductID, (I.MinStock * 2) - I.Quantity, P.PurchasePrice FROM inserted I
JOIN Products P ON I.ProductID = P.ProductID
JOIN PurchaseOrders PO ON P.SupplierID = PO.SupplierID WHERE I.Quantity < I.MinStock AND PO.Status = 'Pending';

UPDATE PO
SET TotalAmount = (SELECT SUM(Quantity * UnitPrice) FROM PurchaseOrderItems WHERE PurchaseOrderID = PO.PurchaseOrderID) FROM PurchaseOrders PO
WHERE PO.Status = 'Pending';

INSERT INTO Alerts (AlertType, Message, ProductID)
SELECT 'AUTO_REORDER','Order created: ' + P.Name + ' (Qty: ' + CAST((I.MinStock*2 - I.Quantity) AS NVARCHAR) + ')', I.ProductID FROM inserted I
JOIN Products P ON I.ProductID = P.ProductID WHERE I.Quantity < I.MinStock;
END
GO


--------------------- PROCEDURES ---------------------

-- Gets product transaction history (История транзакций товара)
CREATE PROCEDURE ProdTransactions
AS
BEGIN
SELECT T.TransactionID, P.Name AS ProductName, T.Quantity, T.TransactionType, T.TransactionDate, T.Notes FROM InventoryTransactions T
JOIN Products P ON T.ProductID = P.ProductID
ORDER BY T.TransactionDate DESC;
END
GO


----------------------------
EXEC ProdTransactions;
GO
---------------------



-- Gets inventory report (Отчет по запасам)
CREATE PROCEDURE InvReport
AS
BEGIN
SELECT C.Name AS CategoryName, P.Name AS ProductName, I.Quantity AS CurrentStock, P.PurchasePrice, P.SellingPrice, P.PurchasePrice * I.Quantity AS TotalValue FROM Products P
JOIN Inventory I ON P.ProductID = I.ProductID
JOIN Categories C ON P.CategoryID = C.Id
ORDER BY C.Name, P.Name;
END
GO


------------------------------
EXEC InvReport;
GO
-----------------------------



