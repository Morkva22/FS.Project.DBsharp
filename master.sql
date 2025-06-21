USE master
GO

-- Drop database if it exists (Удаление базы данных если она существует)
IF DB_ID('InventoryManagement') IS NOT NULL
    DROP DATABASE InventoryManagement
GO

CREATE DATABASE InventoryManagement
GO

USE InventoryManagement
GO

--------------------- TABLES ---------------------

-- Stores product categories (Таблица категорий товаров)
CREATE TABLE Categories (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    CONSTRAINT CHK_Categories_Name CHECK (Name <> '')
);

-- Queue for category operations (Очередь операций с категориями)
CREATE TABLE CategoryInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    OperationType NVARCHAR(10) NOT NULL,
    CategoryID INT NULL,
    Name NVARCHAR(100) NULL,
    ProcessedFlag BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CHK_CategoryInput_OperationType CHECK (OperationType IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- Stores supplier information (Таблица поставщиков)
CREATE TABLE Suppliers (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    ContactPerson NVARCHAR(100),
    Phone NVARCHAR(20),
    Email NVARCHAR(100),
    CONSTRAINT CHK_Suppliers_Name CHECK (Name <> ''),
    CONSTRAINT CHK_Suppliers_Email CHECK (Email LIKE '%_@__%.__%' OR Email IS NULL),
    CONSTRAINT CHK_Suppliers_Phone CHECK (Phone LIKE '[0-9]%' OR Phone IS NULL)
);

-- Queue for supplier operations (Очередь операций с поставщиками)
CREATE TABLE SupplierInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    OperationType NVARCHAR(10) NOT NULL,
    SupplierID INT NULL,
    Name NVARCHAR(100) NULL,
    ContactPerson NVARCHAR(100) NULL,
    Phone NVARCHAR(20) NULL,
    Email NVARCHAR(100) NULL,
    ProcessedFlag BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),

    CONSTRAINT CHK_SupplierInput_OperationType CHECK (OperationType IN ('INSERT', 'UPDATE', 'DELETE')),
    CONSTRAINT CHK_SupplierInput_Email CHECK (Email IS NULL OR Email LIKE '%_@__%.__%')
);

-- Stores product information (Таблица товаров)
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    PurchasePrice DECIMAL(10,2) NOT NULL,
    SellingPrice DECIMAL(10,2) NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT CHK_Products_Name CHECK (Name <> ''),
    CONSTRAINT CHK_Positive_Prices CHECK (PurchasePrice > 0 AND SellingPrice > 0),
    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(Id),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(Id)
);

-- Queue for product operations (Очередь операций с товарами)
CREATE TABLE ProductInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    OperationType NVARCHAR(10) NOT NULL,
    ProductID INT NULL,
    Name NVARCHAR(100) NULL,
    Description NVARCHAR(500) NULL,
    CategoryID INT NULL,
    SupplierID INT NULL,
    PurchasePrice DECIMAL(10,2) NULL,
    SellingPrice DECIMAL(10,2) NULL,
    InitialQuantity INT NULL,
    MinStock INT NULL,
    ProcessedFlag BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT CHK_ProductInput_OperationType CHECK (OperationType IN ('INSERT', 'UPDATE', 'DELETE')),
    CONSTRAINT CHK_ProductInput_Prices CHECK (
        (PurchasePrice IS NULL OR PurchasePrice > 0) AND
        (SellingPrice IS NULL OR SellingPrice > 0)
    ),
    CONSTRAINT CHK_ProductInput_Stock CHECK (
        (InitialQuantity IS NULL OR InitialQuantity >= 0) AND
        (MinStock IS NULL OR MinStock > 0)
    )
);

-- Tracks inventory levels (Таблица запасов товаров)
CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 0,
    LastUpdated DATETIME DEFAULT GETDATE(),
    MinStock INT NOT NULL DEFAULT 1,
    CONSTRAINT CHK_Inventory_MinStock CHECK (MinStock > 0),
    CONSTRAINT FK_Inventory_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Stores system alerts (Таблица уведомлений системы)
CREATE TABLE Alerts (
    AlertID INT PRIMARY KEY IDENTITY(1,1),
    AlertType NVARCHAR(50) NOT NULL,
    Message NVARCHAR(500) NOT NULL,
    ProductID INT NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),
    IsRead BIT DEFAULT 0,
    LastUpdated DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_Alerts_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CHK_Alert_Type CHECK (AlertType IN ('Low_Stock', 'Auto_Reorder'))
);

-- Stores purchase orders (Таблица заказов на закупку)
CREATE TABLE PurchaseOrders (
    PurchaseOrderID INT PRIMARY KEY IDENTITY(1,1),
    SupplierID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending',
    TotalAmount DECIMAL(10,2),
    CONSTRAINT CHK_PurchaseOrders_Status CHECK (Status IN ('Pending', 'Processing', 'Completed', 'Cancelled')),
    CONSTRAINT FK_PurchaseOrders_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(Id)
);

-- Stores purchase order items (Таблица позиций заказов)
CREATE TABLE PurchaseOrderItems (
    PurchaseOrderItemID INT PRIMARY KEY IDENTITY(1,1),
    PurchaseOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,
    CONSTRAINT FK_PurchaseOrderItems_PurchaseOrders FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrders(PurchaseOrderID),
    CONSTRAINT FK_PurchaseOrderItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Purchase order data entry (Очередь ввода данных заказов)
CREATE TABLE PurchaseOrderInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    PurchaseOrderID INT NOT NULL,
    Status NVARCHAR(20) NOT NULL DEFAULT 'Completed',
    Notes NVARCHAR(255) NULL,
    ProcessedFlag BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),
    CONSTRAINT FK_PurchaseOrderInput_PurchaseOrders FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrders(PurchaseOrderID),
    CONSTRAINT CHK_PurchaseOrderInput_Status CHECK (Status IN ('Pending', 'Processing', 'Completed', 'Cancelled'))
);

-- Tracks inventory transactions (Таблица транзакций инвентаря)
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

-- Input transactions (Очередь транзакций)
CREATE TABLE TransactionInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    TransactionType NVARCHAR(20) NOT NULL,
    Notes NVARCHAR(255) NULL,
    ProcessedFlag BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_TransactionInput_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CHK_TransactionInput_Type CHECK (TransactionType IN ('Purchase', 'Sale', 'Adjustment', 'Return', 'Write-off')),
    CONSTRAINT CHK_TransactionInput_NotZero CHECK (Quantity != 0)
);

--------------------- INDEXES ---------------------

-- Performance optimization indexes (Индексы для оптимизации производительности)
CREATE INDEX IX_Products_Name ON Products(Name);
CREATE INDEX IX_Inventory_ProductID ON Inventory(ProductID);
CREATE INDEX IX_TransactionInput_ProcessedFlag ON TransactionInput(ProcessedFlag);
CREATE INDEX IX_PurchaseOrderInput_ProcessedFlag ON PurchaseOrderInput(ProcessedFlag);
CREATE INDEX IX_CategoryInput_ProcessedFlag ON CategoryInput(ProcessedFlag);
CREATE INDEX IX_SupplierInput_ProcessedFlag ON SupplierInput(ProcessedFlag);
CREATE INDEX IX_ProductInput_ProcessedFlag ON ProductInput(ProcessedFlag);

--------------------- SAMPLE DATA ---------------------

-- Insert sample categories (Добавление тестовых категорий)
INSERT INTO Categories (Name) VALUES
('Tobacco Products'),
('Alcoholic Beverages'),
('Dairy Products'),
('Bakery Goods'),
('Frozen Foods'),
('Snacks');

-- Insert sample suppliers (Добавление тестовых поставщиков)
INSERT INTO Suppliers (Name, ContactPerson, Phone, Email) VALUES
('Tobacco Distributors LLC', 'Mike Smirnov', '380501112233', 'mike@tobacco-dist.com'),
('Beverage Partners Co.', 'Oleg Ivanov', '380502223344', 'oleg@bevpartners.com'),
('Fresh Dairy Ltd.', 'Anna Petrova', '380503334455', 'anna@freshdairy.ua'),
('Bakery Supplies Inc.', 'Ivan Sidorov', '380504445566', 'ivan@bakerysupplies.com'),
('Frosty Foods', 'Elena Frost', '380505556677', 'elena@frostyfoods.com');

-- Insert sample products (Добавление тестовых товаров)
INSERT INTO Products (Name, Description, CategoryID, SupplierID, PurchasePrice, SellingPrice) VALUES
('Marlboro Red (Pack)', 'Cigarettes 20 pieces', 1, 1, 45.00, 65.00),
('Lvivske Beer 0.5L', 'Ukrainian lager beer', 2, 2, 15.00, 28.00),
('Ice Cream Vanilla 500ml', 'Premium vanilla ice cream', 3, 3, 32.00, 49.99),
('White Bread Loaf', 'Fresh wheat bread 700g', 4, 4, 8.50, 14.99),
('Potato Chips 150g', 'Classic salted chips', 6, 5, 18.00, 32.50),
('Vodka 0.5L', 'Premium Ukrainian vodka', 2, 2, 85.00, 129.99),
('Rye Bread', 'Traditional rye bread 600g', 4, 4, 9.00, 16.50),
('Cigarettes Winston (Pack)', 'International brand cigarettes', 1, 1, 50.00, 72.00);

-- Insert sample inventory (Добавление тестовых данных запасов)
INSERT INTO Inventory (ProductID, Quantity, MinStock) VALUES
(1, 50, 20),
(2, 120, 40),
(3, 35, 15),
(4, 30, 10),
(5, 80, 25),
(6, 25, 5),
(7, 20, 8),
(8, 40, 15);

-- Insert sample purchase orders (Добавление тестовых заказов)
INSERT INTO PurchaseOrders (SupplierID, Status, TotalAmount) VALUES
(1, 'Completed', 5250.00),
(2, 'Pending', 3850.00),
(3, 'Processing', 2240.00),
(4, 'Completed', 1275.00),
(5, 'Pending', 2160.00);

-- Insert sample purchase order items (Добавление тестовых позиций заказов)
INSERT INTO PurchaseOrderItems (PurchaseOrderID, ProductID, Quantity, UnitPrice) VALUES
(1, 1, 100, 45.00),
(1, 8, 50, 50.00),
(2, 2, 200, 15.00),
(2, 6, 20, 85.00),
(3, 3, 70, 32.00),
(4, 4, 150, 8.50),
(4, 7, 100, 9.00),
(5, 5, 120, 18.00);

-- Insert sample inventory transactions (Добавление тестовых транзакций)
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

-- Insert test transaction data (Добавление тестовых данных транзакций)
INSERT INTO TransactionInput (ProductID, Quantity, TransactionType, Notes) VALUES
(1, -5, 'Sale', 'Retail sale to customer'),
(2, -3, 'Sale', 'Regular purchase'),
(3, -1, 'Sale', 'Weekend promotion'),
(6, -2, 'Sale', 'Bulk purchase discount'),
(5, 15, 'Purchase', 'Restocking chips'),
(4, 10, 'Purchase', 'Weekly bread delivery'),
(7, 5, 'Adjustment', 'Inventory correction after audit'),
(8, -2, 'Write-off', 'Damaged products');

-- Insert sample data for PurchaseOrderInput (Добавление тестовых данных заказов)
INSERT INTO PurchaseOrderInput (PurchaseOrderID, Status, Notes) VALUES
(1, 'Completed', 'Full order received on time'),
(2, 'Processing', 'Partially shipped, awaiting remainder'),
(3, 'Completed', 'Order received with minor damages, accepted'),
(4, 'Cancelled', 'Supplier unable to fulfill order'),
(5, 'Completed', 'Order received and inventory updated');



--------------------- VIEWS ---------------------


-- Shows current inventory status (Представление текущего состояния запасов)
CREATE VIEW InvStatus AS
SELECT P.ProductID, P.Name AS ProductName, C.Name AS CategoryName, S.Name AS SupplierName, I.Quantity AS CurrentStock, I.MinStock, P.PurchasePrice, P.SellingPrice, I.Quantity * P.PurchasePrice AS InventoryValue, I.LastUpdated FROM Products P
JOIN Inventory I ON P.ProductID = I.ProductID
JOIN Categories C ON P.CategoryID = C.Id
JOIN Suppliers S ON P.SupplierID = S.Id;
GO



-- Shows transaction history (Представление истории транзакций)
CREATE VIEW TransHistory AS
SELECT T.TransactionID, P.Name AS ProductName, T.Quantity, T.TransactionType, T.PreviousQuantity, T.NewQuantity, T.Notes, T.TransactionDate, T.CreatedBy FROM InventoryTransactions T
JOIN Products P ON T.ProductID = P.ProductID;
GO



-- Combines different alert types (Объединенное представление уведомлений)
CREATE OR ALTER VIEW CombinedAlerts AS
SELECT AlertType AS AlertCategory, Message, CreatedDate, ProductID FROM Alerts

UNION ALL

SELECT 'AUTO_REORDER' AS AlertCategory, 'Ordered ' + P.Name + ' from ' + S.Name + ' (Qty: ' + CAST(POI.Quantity AS NVARCHAR) + ')', PO.OrderDate, P.ProductID FROM PurchaseOrderItems POI
JOIN Products P ON POI.ProductID = P.ProductID
JOIN PurchaseOrders PO ON POI.PurchaseOrderID = PO.PurchaseOrderID
JOIN Suppliers S ON PO.SupplierID = S.Id WHERE PO.Status = 'Pending';
GO


--------------------- TRIGGERS ---------------------


-- Updates inventory when transactions occur (Триггер обновления запасов при транзакциях)
CREATE TRIGGER UpdateInvTrans
ON InventoryTransactions
AFTER INSERT
AS
BEGIN
UPDATE I
SET I.Quantity = INS.NewQuantity, I.LastUpdated = GETDATE() FROM Inventory I
JOIN inserted INS ON I.ProductID = INS.ProductID;
END
GO




-- Creates alerts when stock is low (Триггер создания уведомлений при низком запасе)
CREATE TRIGGER LowStockAlert
ON Inventory
AFTER UPDATE
AS
BEGIN
INSERT INTO Alerts (AlertType, Message, ProductID) SELECT'LOW_STOCK', 'Low stock: ' + P.Name + ' (Current: ' + CAST(I.Quantity AS NVARCHAR) + ', Min: ' + CAST(I.MinStock AS NVARCHAR) + ')', I.ProductID FROM inserted AS I
JOIN Products P ON I.ProductID = P.ProductID WHERE I.Quantity < I.MinStock;
END
GO



-- Automatically creates purchase orders when stock is low (Триггер автоматического заказа при низком запасе)
CREATE TRIGGER AutoReorder
ON Inventory
AFTER UPDATE
AS
BEGIN
INSERT INTO PurchaseOrders (SupplierID, Status, TotalAmount)
SELECT P.SupplierID, 'Pending', 0 FROM inserted I
JOIN Products P ON I.ProductID = P.ProductID WHERE I.Quantity < I.MinStock
GROUP BY P.SupplierID;

INSERT INTO PurchaseOrderItems (PurchaseOrderID, ProductID, Quantity, UnitPrice)
SELECT  PO.PurchaseOrderID, I.ProductID, (I.MinStock * 2) - I.Quantity, P.PurchasePrice FROM inserted I
JOIN Products P ON I.ProductID = P.ProductID
JOIN PurchaseOrders PO ON P.SupplierID = PO.SupplierID WHERE I.Quantity < I.MinStock AND PO.Status = 'Pending';

UPDATE PO
SET TotalAmount = (SELECT SUM(Quantity * UnitPrice)FROM PurchaseOrderItems WHERE PurchaseOrderID = PO.PurchaseOrderID ) FROM PurchaseOrders PO WHERE PO.Status = 'Pending';

INSERT INTO Alerts (AlertType, Message, ProductID)
SELECT 'AUTO_REORDER', 'Order created: ' + P.Name + ' (Qty: ' + CAST((I.MinStock*2 - I.Quantity) AS NVARCHAR) + ')', I.ProductID FROM inserted I
JOIN Products P ON I.ProductID = P.ProductID WHERE I.Quantity < I.MinStock;
END
GO



--------------------- PROCEDURES ---------------------

-- Gets product transaction history (Процедура получения истории транзакций товара)
CREATE PROCEDURE ProdTransactions
AS
BEGIN
SELECT T.TransactionID, P.Name AS ProductName, T.Quantity, T.TransactionType, T.TransactionDate, T.Notes FROM InventoryTransactions T
JOIN Products P ON T.ProductID = P.ProductID
ORDER BY T.TransactionDate DESC;
END
GO




-- Gets inventory report (Процедура получения отчета по запасам)
CREATE PROCEDURE InvReport
AS
BEGIN
SELECT C.Name AS CategoryName, P.Name AS ProductName, I.Quantity AS CurrentStock, P.PurchasePrice, P.SellingPrice, P.PurchasePrice * I.Quantity AS TotalValue FROM Products P
JOIN Inventory I ON P.ProductID = I.ProductID
JOIN Categories C ON P.CategoryID = C.Id
ORDER BY C.Name, P.Name;
END
GO




-- Records inventory transactions based on input data (Процедура записи транзакций)
CREATE PROCEDURE RecordInvTransaction
AS
BEGIN
INSERT INTO InventoryTransactions (ProductID, Quantity,TransactionType, Notes, PreviousQuantity, NewQuantity )
SELECT TI.ProductID, TI.Quantity, TI.TransactionType, TI.Notes, I.Quantity, I.Quantity + TI.Quantity FROM TransactionInput TI
JOIN Inventory I ON I.ProductID = TI.ProductID WHERE TI.ProcessedFlag = 0;

UPDATE TransactionInput
SET ProcessedFlag = 1
WHERE ProcessedFlag = 0;
END
GO




-- Processes purchase orders and updates inventory (Процедура обработки заказов)
CREATE PROCEDURE PurchaseOrder
AS
BEGIN
UPDATE po
SET Status = poi.Status FROM PurchaseOrders po
JOIN PurchaseOrderInput poi ON po.PurchaseOrderID = poi.PurchaseOrderID WHERE poi.ProcessedFlag = 0;

INSERT INTO InventoryTransactions ( ProductID, Quantity, TransactionType, Notes, PreviousQuantity,NewQuantity)
SELECT  POI.ProductID,  POI.Quantity, 'Purchase', ISNULL(PIN.Notes, 'PO #' + CAST(PIN.PurchaseOrderID AS NVARCHAR)), I.Quantity, I.Quantity + POI.Quantity FROM PurchaseOrderItems POI
JOIN Inventory I ON POI.ProductID = I.ProductID
JOIN PurchaseOrderInput PIN ON POI.PurchaseOrderID = PIN.PurchaseOrderID WHERE PIN.ProcessedFlag = 0 AND PIN.Status = 'Completed';

UPDATE PurchaseOrderInput
SET ProcessedFlag = 1
WHERE ProcessedFlag = 0;
END
GO





-- Processes category operations (Процедура обработки операций с категориями)
CREATE PROCEDURE ProcessCategoryOperations
AS
BEGIN


-- INSERT operations (Операции вставки)
INSERT INTO Categories (Name)
SELECT Name FROM CategoryInput WHERE OperationType = 'INSERT' AND ProcessedFlag = 0 AND Name IS NOT NULL;


-- UPDATE operations (Операции обновления)
UPDATE C
SET C.Name = CI.Name FROM Categories C
JOIN CategoryInput CI ON C.Id = CI.CategoryID WHERE CI.OperationType = 'UPDATE' AND CI.ProcessedFlag = 0 AND CI.Name IS NOT NULL;


-- DELETE operations (Операции удаления)
DELETE C FROM Categories C
JOIN CategoryInput CI ON C.Id = CI.CategoryID WHERE CI.OperationType = 'DELETE' AND CI.ProcessedFlag = 0;

UPDATE CategoryInput
SET ProcessedFlag = 1 WHERE ProcessedFlag = 0;
END;
GO




-- Gets list of categories (Процедура получения списка категорий)
CREATE PROCEDURE GetCategories
AS
BEGIN
SELECT * FROM Categories ORDER BY Name;
END;
GO






-- Processes supplier operations (Процедура обработки операций с поставщиками)
CREATE PROCEDURE ProcessSupplierOperations
AS
BEGIN


-- INSERT operations (Операции вставки)
INSERT INTO Suppliers (Name, ContactPerson, Phone, Email)
SELECT Name, ContactPerson, Phone, Email FROM SupplierInput
WHERE OperationType = 'INSERT' AND ProcessedFlag = 0 AND Name IS NOT NULL;


-- UPDATE operations (Операции обновления)
UPDATE S
SET S.Name = ISNULL(SI.Name, S.Name), S.ContactPerson = SI.ContactPerson, S.Phone = SI.Phone, S.Email = SI.Email FROM Suppliers S
JOIN SupplierInput SI ON S.Id = SI.SupplierID WHERE SI.OperationType = 'UPDATE' AND SI.ProcessedFlag = 0;


-- DELETE operations (Операции удаления)
DELETE S FROM Suppliers S
JOIN SupplierInput SI ON S.Id = SI.SupplierID WHERE SI.OperationType = 'DELETE' AND SI.ProcessedFlag = 0;


UPDATE SupplierInput
SET ProcessedFlag = 1
WHERE ProcessedFlag = 0;
END;
GO






-- Gets list of suppliers (Процедура получения списка поставщиков)
CREATE PROCEDURE GetSuppliers
AS
BEGIN
SELECT * FROM Suppliers ORDER BY Name;
END;
GO






-- Processes product operations (Процедура обработки операций с товарами)
CREATE PROCEDURE ProcessProductOperations
AS
BEGIN



-- INSERT operations with automatic inventory creation (Операции вставки)
INSERT INTO Products (Name, Description, CategoryID, SupplierID, PurchasePrice, SellingPrice)
SELECT Name, Description, CategoryID, SupplierID, PurchasePrice, SellingPrice FROM ProductInput
WHERE OperationType = 'INSERT' AND ProcessedFlag = 0 AND Name IS NOT NULL AND CategoryID IS NOT NULL AND SupplierID IS NOT NULL;



-- Add inventory records for new products (Добавление записей в инвентарь)
INSERT INTO Inventory (ProductID, Quantity, MinStock)
SELECT P.ProductID, ISNULL(PI.InitialQuantity, 0), ISNULL(PI.MinStock, 5) FROM Products P
JOIN ProductInput PI ON P.Name = PI.Name WHERE PI.OperationType = 'INSERT' AND PI.ProcessedFlag = 0;



-- Add inventory transactions for initial quantity (Добавление транзакций)
INSERT INTO InventoryTransactions (ProductID, Quantity, TransactionType, Notes, PreviousQuantity, NewQuantity)
SELECT P.ProductID, ISNULL(PI.InitialQuantity, 0), 'Adjustment', 'Initial product setup', 0, ISNULL(PI.InitialQuantity, 0) FROM Products P
JOIN ProductInput PI ON P.Name = PI.Name WHERE PI.OperationType = 'INSERT' AND PI.ProcessedFlag = 0 AND PI.InitialQuantity > 0;

UPDATE P
SET P.Name = ISNULL(PI.Name, P.Name),P.Description = ISNULL(PI.Description, P.Description),P.CategoryID = ISNULL(PI.CategoryID, P.CategoryID), P.SupplierID = ISNULL(PI.SupplierID, P.SupplierID), P.PurchasePrice = ISNULL(PI.PurchasePrice, P.PurchasePrice),P.SellingPrice = ISNULL(PI.SellingPrice, P.SellingPrice) FROM Products P
JOIN ProductInput PI ON P.ProductID = PI.ProductID WHERE PI.OperationType = 'UPDATE' AND PI.ProcessedFlag = 0;




-- Update inventory min stock (Обновление минимального запаса)
UPDATE I
SET I.MinStock = PI.MinStock FROM Inventory I
JOIN ProductInput PI ON I.ProductID = PI.ProductID WHERE PI.OperationType = 'UPDATE' AND PI.ProcessedFlag = 0 AND PI.MinStock IS NOT NULL;




-- DELETE operations (Операции удаления)
DELETE FROM InventoryTransactions WHERE ProductID IN (
SELECT P.ProductID FROM Products P
JOIN ProductInput PI ON P.ProductID = PI.ProductID WHERE PI.OperationType = 'DELETE' AND PI.ProcessedFlag = 0
);

DELETE FROM Inventory WHERE ProductID IN (
SELECT P.ProductID FROM Products P
JOIN ProductInput PI ON P.ProductID = PI.ProductID WHERE PI.OperationType = 'DELETE' AND PI.ProcessedFlag = 0
);

DELETE FROM Products WHERE ProductID IN (
SELECT PI.ProductID FROM ProductInput PI
WHERE PI.OperationType = 'DELETE' AND PI.ProcessedFlag = 0
);

UPDATE ProductInput
SET ProcessedFlag = 1
WHERE ProcessedFlag = 0;
END;
GO





-- Gets list of products (Процедура получения списка товаров)
CREATE PROCEDURE GetProducts
AS
BEGIN
SELECT P.*, C.Name AS CategoryName, S.Name AS SupplierName, I.Quantity AS CurrentStock, I.MinStock FROM Products P
JOIN Categories C ON P.CategoryID = C.Id
JOIN Suppliers S ON P.SupplierID = S.Id
JOIN Inventory I ON P.ProductID = I.ProductID
ORDER BY P.Name;
END;
GO

-- Insert test data for category operations (Добавление тестовых данных операций с категориями)
INSERT INTO CategoryInput (OperationType, Name)
VALUES ('DELETE', 'Iddf');


-- Insert test data for supplier operations (Добавление тестовых данных операций с поставщиками)
INSERT INTO SupplierInput (OperationType, SupplierID, Phone, Email)
VALUES ('DELETE', 1, '380501234567', 'new_email@example.com');


-- Insert test data for product operations (Добавление тестовых данных операций с товарами)
INSERT INTO ProductInput (
    OperationType, Name, Description, CategoryID, SupplierID,
    PurchasePrice, SellingPrice, InitialQuantity, MinStock)
VALUES (
        'DELETE', 'fgtvyjt ', 'sr6jsr',
    3, 3, 28.50, 45.99, 30, 10
);

-- Execute procedures (Выполнение процедур)
EXEC ProcessCategoryOperations;

EXEC ProcessSupplierOperations;

EXEC ProcessProductOperations;

EXEC GetProducts;
