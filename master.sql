-- =============================================
-- INVENTORY MANAGEMENT SYSTEM DATABASE
-- СИСТЕМА УПРАВЛЕНИЯ ЗАПАСАМИ - БАЗА ДАННЫХ
-- =============================================

USE MASTER
GO

-- DROP DATABASE IF EXISTS (УДАЛЕНИЕ БАЗЫ ЕСЛИ СУЩЕСТВУЕТ)
IF DB_ID('InventoryManagement') IS NOT NULL
    DROP DATABASE InventoryManagement
GO

CREATE DATABASE InventoryManagement
GO

USE InventoryManagement
GO

-- =====================
-- CORE TABLES (ОСНОВНЫЕ ТАБЛИЦЫ)
-- =====================

-- CATEGORIES TABLE (ТАБЛИЦА КАТЕГОРИЙ)
CREATE TABLE Categories (
    Id INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,


    CONSTRAINT CHK_Categories_Name CHECK (Name <> '')
);

-- SUPPLIERS TABLE (ТАБЛИЦА ПОСТАВЩИКОВ)
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

-- PRODUCTS TABLE (ТАБЛИЦА ТОВАРОВ)
CREATE TABLE Products (
    ProductID INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL UNIQUE,
    Description NVARCHAR(500),
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    PurchasePrice DECIMAL(10,2) NOT NULL,
    SellingPrice DECIMAL(10,2) NOT NULL,
    CreatedDate DATETIME DEFAULT GETDATE(),


    CONSTRAINT FK_Products_Categories FOREIGN KEY (CategoryID) REFERENCES Categories(Id),
    CONSTRAINT FK_Products_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(Id),
    CONSTRAINT CHK_Products_Name CHECK (Name <> ''),
    CONSTRAINT CHK_Positive_Prices CHECK (PurchasePrice > 0 AND SellingPrice > 0)
);

-- INVENTORY TABLE (ТАБЛИЦА ЗАПАСОВ)
CREATE TABLE Inventory (
    InventoryID INT PRIMARY KEY IDENTITY(1,1),
    ProductID INT NOT NULL,
    Quantity INT NOT NULL DEFAULT 0,
    LastUpdated DATETIME DEFAULT GETDATE(),
    MinStock INT NOT NULL DEFAULT 1,


    CONSTRAINT FK_Inventory_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID),
    CONSTRAINT CHK_Inventory_MinStock CHECK (MinStock > 0)
);

-- =====================
-- TRANSACTION TABLES (ТРАНЗАКЦИОННЫЕ ТАБЛИЦЫ)
-- =====================

-- INVENTORY TRANSACTIONS (ТАБЛИЦА ТРАНЗАКЦИЙ)
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

-- PURCHASE ORDERS (ТАБЛИЦА ЗАКАЗОВ)
CREATE TABLE PurchaseOrders (
    PurchaseOrderID INT PRIMARY KEY IDENTITY(1,1),
    SupplierID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending',
    TotalAmount DECIMAL(10,2),


    CONSTRAINT FK_PurchaseOrders_Suppliers FOREIGN KEY (SupplierID) REFERENCES Suppliers(Id),
    CONSTRAINT CHK_PurchaseOrders_Status CHECK (Status IN ('Pending', 'Processing', 'Completed', 'Cancelled'))
);

-- PURCHASE ORDER ITEMS (ПОЗИЦИИ ЗАКАЗОВ)
CREATE TABLE PurchaseOrderItems (
    PurchaseOrderItemID INT PRIMARY KEY IDENTITY(1,1),
    PurchaseOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2) NOT NULL,


    CONSTRAINT FK_PurchaseOrderItems_PurchaseOrders FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrders(PurchaseOrderID),
    CONSTRAINT FK_PurchaseOrderItems_Products FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- =====================
-- QUEUE TABLES (ТАБЛИЦЫ ОЧЕРЕДЕЙ)
-- =====================

-- CATEGORY OPERATIONS QUEUE (ОЧЕРЕДЬ ОПЕРАЦИЙ С КАТЕГОРИЯМИ)
CREATE TABLE CategoryInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    OperationType NVARCHAR(10) NOT NULL,
    CategoryID INT NULL,
    Name NVARCHAR(100) NULL,
    ProcessedFlag BIT NOT NULL DEFAULT 0,
    CreatedDate DATETIME NOT NULL DEFAULT GETDATE(),


    CONSTRAINT CHK_CategoryInput_OperationType CHECK (OperationType IN ('INSERT', 'UPDATE', 'DELETE'))
);

-- SUPPLIER OPERATIONS QUEUE (ОЧЕРЕДЬ ОПЕРАЦИЙ С ПОСТАВЩИКАМИ)
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

-- PRODUCT OPERATIONS QUEUE (ОЧЕРЕДЬ ОПЕРАЦИЙ С ТОВАРАМИ)
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

-- TRANSACTION QUEUE (ОЧЕРЕДЬ ТРАНЗАКЦИЙ)
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

-- PURCHASE ORDER QUEUE (ОЧЕРЕДЬ ЗАКАЗОВ)
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

-- =====================
-- SYSTEM TABLES (СИСТЕМНЫЕ ТАБЛИЦЫ)
-- =====================

-- SYSTEM ALERTS (СИСТЕМНЫЕ УВЕДОМЛЕНИЯ)
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

-- =====================
-- INDEXES (ИНДЕКСЫ)
-- =====================

-- PRODUCTS INDEXES (ИНДЕКСЫ ТОВАРОВ)
CREATE INDEX IX_Products_Name ON Products(Name);

-- INVENTORY INDEXES (ИНДЕКСЫ ЗАПАСОВ)
CREATE INDEX IX_Inventory_ProductID ON Inventory(ProductID);

-- QUEUE PROCESSING INDEXES (ИНДЕКСЫ ОБРАБОТКИ ОЧЕРЕДЕЙ)
CREATE INDEX IX_TransactionInput_ProcessedFlag ON TransactionInput(ProcessedFlag);
CREATE INDEX IX_PurchaseOrderInput_ProcessedFlag ON PurchaseOrderInput(ProcessedFlag);
CREATE INDEX IX_CategoryInput_ProcessedFlag ON CategoryInput(ProcessedFlag);
CREATE INDEX IX_SupplierInput_ProcessedFlag ON SupplierInput(ProcessedFlag);
CREATE INDEX IX_ProductInput_ProcessedFlag ON ProductInput(ProcessedFlag);

-- =====================
-- SAMPLE DATA (ТЕСТОВЫЕ ДАННЫЕ)
-- =====================

-- CATEGORIES (КАТЕГОРИИ)
INSERT INTO Categories (Name) VALUES
('Tobacco Products'),
('Alcoholic Beverages'),
('Dairy Products'),
('Bakery Goods'),
('Frozen Foods'),
('Snacks');

-- SUPPLIERS (ПОСТАВЩИКИ)
INSERT INTO Suppliers (Name, ContactPerson, Phone, Email) VALUES
('Tobacco Distributors LLC', 'Mike Smirnov', '380501112233', 'mike@tobacco-dist.com'),
('Beverage Partners Co.', 'Oleg Ivanov', '380502223344', 'oleg@bevpartners.com'),
('Fresh Dairy Ltd.', 'Anna Petrova', '380503334455', 'anna@freshdairy.ua'),
('Bakery Supplies Inc.', 'Ivan Sidorov', '380504445566', 'ivan@bakerysupplies.com'),
('Frosty Foods', 'Elena Frost', '380505556677', 'elena@frostyfoods.com');

-- PRODUCTS (ТОВАРЫ)
INSERT INTO Products (Name, Description, CategoryID, SupplierID, PurchasePrice, SellingPrice) VALUES
('Marlboro Red (Pack)', 'Cigarettes 20 pieces', 1, 1, 45.00, 65.00),
('Lvivske Beer 0.5L', 'Ukrainian lager beer', 2, 2, 15.00, 28.00),
('Ice Cream Vanilla 500ml', 'Premium vanilla ice cream', 3, 3, 32.00, 49.99),
('White Bread Loaf', 'Fresh wheat bread 700g', 4, 4, 8.50, 14.99),
('Potato Chips 150g', 'Classic salted chips', 6, 5, 18.00, 32.50);

-- INVENTORY (ЗАПАСЫ)
INSERT INTO Inventory (ProductID, Quantity, MinStock) VALUES
(1, 50, 20),
(2, 120, 40),
(3, 35, 15),
(4, 30, 10),
(5, 80, 25);

-- =====================
-- VIEWS (ПРЕДСТАВЛЕНИЯ)
-- =====================

-- CURRENT INVENTORY STATUS (ТЕКУЩЕЕ СОСТОЯНИЕ ЗАПАСОВ)
CREATE VIEW V_InventoryStatus AS
SELECT
    P.ProductID,
    P.Name AS ProductName,
    C.Name AS CategoryName,
    S.Name AS SupplierName,
    I.Quantity AS CurrentStock,
    I.MinStock,
    P.PurchasePrice,
    P.SellingPrice,
    I.Quantity * P.PurchasePrice AS InventoryValue,
    I.LastUpdated
FROM Products P
JOIN Inventory I ON P.ProductID = I.ProductID
JOIN Categories C ON P.CategoryID = C.Id
JOIN Suppliers S ON P.SupplierID = S.Id;
GO

-- TRANSACTION HISTORY (ИСТОРИЯ ТРАНЗАКЦИЙ)
CREATE VIEW V_TransactionHistory AS
SELECT
    T.TransactionID,
    P.Name AS ProductName,
    T.Quantity,
    T.TransactionType,
    T.PreviousQuantity,
    T.NewQuantity,
    T.Notes,
    T.TransactionDate,
    T.CreatedBy
FROM InventoryTransactions T
JOIN Products P ON T.ProductID = P.ProductID;
GO

-- =====================
-- TRIGGERS (ТРИГГЕРЫ)
-- =====================

-- UPDATE INVENTORY ON TRANSACTION (ОБНОВЛЕНИЕ ЗАПАСОВ ПРИ ТРАНЗАКЦИИ)
CREATE TRIGGER TRG_UpdateInventory
ON InventoryTransactions
AFTER INSERT
AS
BEGIN
    UPDATE I
    SET
        I.Quantity = INS.NewQuantity,
        I.LastUpdated = GETDATE()
    FROM Inventory I
    JOIN inserted INS ON I.ProductID = INS.ProductID;
END
GO

-- LOW STOCK ALERT (УВЕДОМЛЕНИЕ О НИЗКОМ ЗАПАСЕ)
CREATE TRIGGER TRG_LowStockAlert
ON Inventory
AFTER UPDATE
AS
BEGIN
    INSERT INTO Alerts (AlertType, Message, ProductID)
    SELECT
        'LOW_STOCK',
        'Low stock: ' + P.Name + ' (Current: ' + CAST(I.Quantity AS NVARCHAR) + ', Min: ' + CAST(I.MinStock AS NVARCHAR) + ')',
        I.ProductID
    FROM inserted I
    JOIN Products P ON I.ProductID = P.ProductID
    WHERE I.Quantity < I.MinStock;
END
GO

-- =====================
-- STORED PROCEDURES (ХРАНИМЫЕ ПРОЦЕДУРЫ)
-- =====================

-- PROCESS CATEGORY OPERATIONS (ОБРАБОТКА ОПЕРАЦИЙ С КАТЕГОРИЯМИ)
CREATE PROCEDURE USP_ProcessCategoryOperations
AS
BEGIN
    -- INSERT OPERATIONS (ОПЕРАЦИИ ДОБАВЛЕНИЯ)
    INSERT INTO Categories (Name)
    SELECT Name
    FROM CategoryInput
    WHERE OperationType = 'INSERT'
    AND ProcessedFlag = 0
    AND Name IS NOT NULL;

    -- UPDATE OPERATIONS (ОПЕРАЦИИ ОБНОВЛЕНИЯ)
    UPDATE C
    SET C.Name = CI.Name
    FROM Categories C
    JOIN CategoryInput CI ON C.Id = CI.CategoryID
    WHERE CI.OperationType = 'UPDATE'
    AND CI.ProcessedFlag = 0
    AND CI.Name IS NOT NULL;

    -- DELETE OPERATIONS (ОПЕРАЦИИ УДАЛЕНИЯ)
    DELETE C
    FROM Categories C
    JOIN CategoryInput CI ON C.Id = CI.CategoryID
    WHERE CI.OperationType = 'DELETE'
    AND CI.ProcessedFlag = 0;

    -- MARK AS PROCESSED (ПОМЕТКА КАК ОБРАБОТАННЫХ)
    UPDATE CategoryInput
    SET ProcessedFlag = 1
    WHERE ProcessedFlag = 0;
END
GO

-- GET CATEGORIES LIST (ПОЛУЧЕНИЕ СПИСКА КАТЕГОРИЙ)
CREATE PROCEDURE USP_GetCategories
AS
BEGIN
    SELECT * FROM Categories ORDER BY Name;
END
GO

-- =====================
-- TEST DATA (ТЕСТОВЫЕ ДАННЫЕ)
-- =====================

-- TEST CATEGORY OPERATIONS (ТЕСТОВЫЕ ОПЕРАЦИИ С КАТЕГОРИЯМИ)
INSERT INTO CategoryInput (OperationType, Name)
VALUES ('INSERT', 'Test Category');

-- EXECUTE PROCEDURES (ВЫПОЛНЕНИЕ ПРОЦЕДУР)
EXEC USP_ProcessCategoryOperations;
EXEC USP_GetCategories;











-- =============================================
-- AUTHENTICATION SYSTEM DATABASE STRUCTURE
-- =============================================

-- =====================
-- CORE TABLES
-- =====================

-- Users table (Таблица пользователей)
CREATE TABLE Users (
    UserID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL UNIQUE,
    PasswordHash NVARCHAR(128) NOT NULL,
    Email NVARCHAR(100),
    FullName NVARCHAR(100),
    Role NVARCHAR(20) NOT NULL,
    IsActive BIT DEFAULT 1,
    LastLogin DATETIME,
    CreatedDate DATETIME DEFAULT GETDATE(),


    CONSTRAINT CHK_Users_Role CHECK (Role IN ('Admin', 'Manager', 'Cashier', 'Warehouse')),
    CONSTRAINT CHK_Users_Email CHECK (Email LIKE '%_@__%.__%' OR Email IS NULL),
    CONSTRAINT CHK_Users_FullName CHECK (FullName <> ''),
    CONSTRAINT CHK_Users_Username CHECK (Username <> '')
);

-- User activity logs (Логи активности пользователей)
CREATE TABLE UserLogs (
    LogID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT,
    ActionType NVARCHAR(50) NOT NULL,
    ActionDetails NVARCHAR(500),
    ActionTime DATETIME DEFAULT GETDATE(),
    IPAddress NVARCHAR(45),


    CONSTRAINT FK_UserLogs_Users FOREIGN KEY (UserID) REFERENCES Users(UserID),
);

-- =====================
-- AUTHENTICATION TABLES
-- =====================

-- Authentication requests (Запросы на авторизацию)
CREATE TABLE AuthenticationInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL,
    Password NVARCHAR(50) NOT NULL,
    ProcessedFlag BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE(),


    CONSTRAINT CHK_AuthenticationInput_Username CHECK (Username <> ''),
    CONSTRAINT CHK_AuthenticationInput_Password CHECK (Password <> '')
);

-- Authentication results (Результаты авторизации)
CREATE TABLE AuthenticationOutput (
    OutputID INT PRIMARY KEY IDENTITY(1,1),
    InputID INT NOT NULL,
    UserID INT,
    Username NVARCHAR(50),
    FullName NVARCHAR(100),
    Role NVARCHAR(20),
    Success BIT DEFAULT 0,
    Message NVARCHAR(100),
    ProcessedFlag BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- =====================
-- USER MANAGEMENT TABLES
-- =====================

-- User creation requests (Запросы на создание пользователей)
CREATE TABLE UserCreationInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    Username NVARCHAR(50) NOT NULL,
    Password NVARCHAR(50) NOT NULL,
    Email NVARCHAR(100),
    FullName NVARCHAR(100),
    Role NVARCHAR(20) NOT NULL,
    CreatorUserID INT,
    ProcessedFlag BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE(),


    CONSTRAINT CHK_UserCreationInput_Role CHECK (Role IN ('Admin', 'Manager', 'Cashier', 'Warehouse'))
);

-- Password change requests (Запросы на смену пароля)
CREATE TABLE PasswordChangeInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    OldPassword NVARCHAR(50) NOT NULL,
    NewPassword NVARCHAR(50) NOT NULL,
    ProcessedFlag BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- Password change results (Результаты смены пароля)
CREATE TABLE PasswordChangeOutput (
    OutputID INT PRIMARY KEY IDENTITY(1,1),
    InputID INT NOT NULL,
    Success BIT DEFAULT 0,
    Message NVARCHAR(100),
    ProcessedFlag BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE()
);

-- =====================
-- SESSION MANAGEMENT TABLES
-- =====================

-- User sessions (Сессии пользователей)
CREATE TABLE UserSessions (
    SessionID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    Token NVARCHAR(128) NOT NULL,
    ExpiryDate DATETIME NOT NULL,
    IsActive BIT DEFAULT 1,
    IPAddress NVARCHAR(45),
    LastActivity DATETIME DEFAULT GETDATE(),
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_UserSessions_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- Logout requests (Запросы выхода из системы)
CREATE TABLE LogoutInput (
    InputID INT PRIMARY KEY IDENTITY(1,1),
    UserID INT NOT NULL,
    SessionToken NVARCHAR(128),
    ProcessedFlag BIT DEFAULT 0,
    CreatedDate DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_LogoutInput_Users FOREIGN KEY (UserID) REFERENCES Users(UserID)
);

-- =====================
-- INDEXES
-- =====================

-- Users table indexes (Индексы таблицы пользователей)
CREATE INDEX IX_Users_Username ON Users(Username);

-- User logs indexes (Индексы логов пользователей)
CREATE INDEX IX_UserLogs_UserID ON UserLogs(UserID);

-- Authentication indexes (Индексы аутентификации)
CREATE INDEX IX_AuthenticationInput_ProcessedFlag ON AuthenticationInput(ProcessedFlag);

-- Password change indexes (Индексы смены пароля)
CREATE INDEX IX_PasswordChangeInput_ProcessedFlag ON PasswordChangeInput(ProcessedFlag);

-- User creation indexes (Индексы создания пользователей)
CREATE INDEX IX_UserCreationInput_ProcessedFlag ON UserCreationInput(ProcessedFlag);

-- Session indexes (Индексы сессий)
CREATE INDEX IX_UserSessions_Token ON UserSessions(Token);
CREATE INDEX IX_UserSessions_UserID ON UserSessions(UserID);

-- Logout indexes (Индексы выхода из системы)
CREATE INDEX IX_LogoutInput_ProcessedFlag ON LogoutInput(ProcessedFlag);



-- Process user creation (Обработка создания пользователя)
CREATE PROCEDURE ProcessUserCreation
AS
BEGIN
    -- Check for duplicate users (Проверка дубликатов)
    INSERT INTO UserLogs (UserID, ActionType, ActionDetails)
    SELECT CreatorUserID, 'User Creation Failed', 'Username exists: ' + Username
    FROM UserCreationInput
    WHERE ProcessedFlag = 0 AND Username IN (SELECT Username FROM Users);

    -- Create new users (Создание пользователей)
    INSERT INTO Users (Username, PasswordHash, Email, FullName, Role)
    SELECT
        Username,
        CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', Password), 2),
        Email,
        FullName,
        Role
    FROM UserCreationInput
    WHERE ProcessedFlag = 0 AND Username NOT IN (SELECT Username FROM Users);

    -- Log successful creations (Логирование успешных созданий)
    INSERT INTO UserLogs (UserID, ActionType, ActionDetails)
    SELECT CreatorUserID, 'User Creation', 'Created user: ' + Username
    FROM UserCreationInput
    WHERE ProcessedFlag = 0 AND Username NOT IN (SELECT Username FROM Users);

    -- Mark processed requests (Пометка обработанных запросов)
    UPDATE UserCreationInput
    SET ProcessedFlag = 1
    WHERE ProcessedFlag = 0;
END;
GO

-- Process authentication (Обработка аутентификации)
CREATE PROCEDURE ProcessAuthentication
AS
BEGIN
    -- Clear old results (Очистка старых результатов)
    DELETE FROM AuthenticationOutput
    WHERE ProcessedFlag = 1 AND DATEDIFF(MINUTE, CreatedDate, GETDATE()) > 5;

    -- Process successful authentications (Обработка успешных авторизаций)
    INSERT INTO AuthenticationOutput (InputID, UserID, Username, FullName, Role, Success, Message)
    SELECT
        AI.InputID,
        U.UserID,
        U.Username,
        U.FullName,
        U.Role,
        1,
        'Login successful'
    FROM AuthenticationInput AI
    JOIN Users U ON AI.Username = U.Username
    WHERE AI.ProcessedFlag = 0
    AND CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', AI.Password), 2) = U.PasswordHash
    AND U.IsActive = 1;

    -- Process failed authentications (Обработка неудачных авторизаций)
    INSERT INTO AuthenticationOutput (InputID, UserID, Username, FullName, Role, Success, Message)
    SELECT
        AI.InputID,
        U.UserID,
        U.Username,
        NULL,
        NULL,
        0,
        'Incorrect password'
    FROM AuthenticationInput AI
    JOIN Users U ON AI.Username = U.Username
    WHERE AI.ProcessedFlag = 0
    AND CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', AI.Password), 2) <> U.PasswordHash;

    -- Process inactive users (Обработка неактивных пользователей)
    INSERT INTO AuthenticationOutput (InputID, UserID, Username, FullName, Role, Success, Message)
    SELECT
        AI.InputID,
        U.UserID,
        U.Username,
        NULL,
        NULL,
        0,
        'Account is inactive'
    FROM AuthenticationInput AI
    JOIN Users U ON AI.Username = U.Username
    WHERE AI.ProcessedFlag = 0 AND U.IsActive = 0;

    -- Process non-existent users (Обработка несуществующих пользователей)
    INSERT INTO AuthenticationOutput (InputID, UserID, Username, FullName, Role, Success, Message)
    SELECT
        AI.InputID,
        NULL,
        AI.Username,
        NULL,
        NULL,
        0,
        'User not found'
    FROM AuthenticationInput AI
    LEFT JOIN Users U ON AI.Username = U.Username
    WHERE AI.ProcessedFlag = 0 AND U.UserID IS NULL;

    -- Create sessions (Создание сессий)
    EXEC CreateUserSession;

    -- Update last login (Обновление времени входа)
    UPDATE U
    SET LastLogin = GETDATE()
    FROM Users U
    JOIN AuthenticationOutput AO ON U.UserID = AO.UserID
    JOIN AuthenticationInput AI ON AO.InputID = AI.InputID
    WHERE AI.ProcessedFlag = 0 AND AO.Success = 1;

    -- Log successful logins (Логирование успешных входов)
    INSERT INTO UserLogs (UserID, ActionType, ActionDetails)
    SELECT
        AO.UserID,
        'Login Success',
        'Successful login'
    FROM AuthenticationOutput AO
    JOIN AuthenticationInput AI ON AO.InputID = AI.InputID
    WHERE AI.ProcessedFlag = 0 AND AO.Success = 1;

    -- Log failed logins (Логирование неудачных входов)
    INSERT INTO UserLogs (UserID, ActionType, ActionDetails)
    SELECT
        AO.UserID,
        'Login Failed',
        AO.Message
    FROM AuthenticationOutput AO
    JOIN AuthenticationInput AI ON AO.InputID = AI.InputID
    WHERE AI.ProcessedFlag = 0 AND AO.Success = 0;

    -- Mark processed requests (Пометка обработанных запросов)
    UPDATE AuthenticationInput
    SET ProcessedFlag = 1
    WHERE ProcessedFlag = 0;
END;
GO

-- Process password change (Обработка смены пароля)
CREATE PROCEDURE ProcessPasswordChange
AS
BEGIN
    -- Clear old results (Очистка старых результатов)
    DELETE FROM PasswordChangeOutput
    WHERE ProcessedFlag = 1 AND DATEDIFF(MINUTE, CreatedDate, GETDATE()) > 5;

    -- Process password changes (Обработка смены пароля)
    INSERT INTO PasswordChangeOutput (InputID, Success, Message)
    SELECT
        PCI.InputID,
        CASE
            WHEN U.UserID IS NULL THEN 0
            WHEN CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', PCI.OldPassword), 2) != U.PasswordHash THEN 0
            ELSE 1
        END,
        CASE
            WHEN U.UserID IS NULL THEN 'User not found'
            WHEN CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', PCI.OldPassword), 2) != U.PasswordHash THEN 'Incorrect current password'
            ELSE 'Password changed successfully'
        END
    FROM PasswordChangeInput PCI
    LEFT JOIN Users U ON PCI.UserID = U.UserID
    WHERE PCI.ProcessedFlag = 0;

    -- Update passwords (Обновление паролей)
    UPDATE U
    SET PasswordHash = CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', PCI.NewPassword), 2)
    FROM Users U
    JOIN PasswordChangeInput PCI ON U.UserID = PCI.UserID
    JOIN PasswordChangeOutput PCO ON PCI.InputID = PCO.InputID
    WHERE PCI.ProcessedFlag = 0 AND PCO.Success = 1;

    -- Log password changes (Логирование смены пароля)
    INSERT INTO UserLogs (UserID, ActionType, ActionDetails)
    SELECT
        PCI.UserID,
        CASE
            WHEN PCO.Success = 1 THEN 'Password Changed'
            ELSE 'Password Change Failed'
        END,
        PCO.Message
    FROM PasswordChangeOutput PCO
    JOIN PasswordChangeInput PCI ON PCO.InputID = PCI.InputID
    WHERE PCI.ProcessedFlag = 0;

    -- Mark processed requests (Пометка обработанных запросов)
    UPDATE PasswordChangeInput
    SET ProcessedFlag = 1
    WHERE ProcessedFlag = 0;
END;
GO

-- Create user session (Создание сессии пользователя)
CREATE PROCEDURE CreateUserSession
AS
BEGIN
    -- Deactivate previous sessions (Деактивация предыдущих сессий)
    UPDATE US
    SET IsActive = 0
    FROM UserSessions US
    JOIN AuthenticationOutput AO ON US.UserID = AO.UserID
    JOIN AuthenticationInput AI ON AO.InputID = AI.InputID
    WHERE AI.ProcessedFlag = 0 AND AO.Success = 1 AND US.IsActive = 1;

    -- Create new sessions (Создание новых сессий)
    INSERT INTO UserSessions (UserID, Token, ExpiryDate, IPAddress)
    SELECT
        AO.UserID,
        CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256',
            CONVERT(NVARCHAR(50), AO.UserID) + CONVERT(NVARCHAR(50), NEWID()) +
            CONVERT(NVARCHAR(50), GETDATE())), 2),
        DATEADD(HOUR, 24, GETDATE()),
        NULL
    FROM AuthenticationOutput AO
    JOIN AuthenticationInput AI ON AO.InputID = AI.InputID
    WHERE AI.ProcessedFlag = 0 AND AO.Success = 1;

    -- Log session creation (Логирование создания сессии)
    INSERT INTO UserLogs (UserID, ActionType, ActionDetails)
    SELECT
        AO.UserID, 'Session Created', 'New login session created'
    FROM AuthenticationOutput AO
    JOIN AuthenticationInput AI ON AO.InputID = AI.InputID
    WHERE AI.ProcessedFlag = 0 AND AO.Success = 1;
END;
GO

-- Process logout (Обработка выхода из системы)
CREATE PROCEDURE ProcessLogout
AS
BEGIN
    -- Deactivate all user sessions (Деактивация всех сессий пользователя)
    UPDATE US
    SET IsActive = 0
    FROM UserSessions US
    JOIN LogoutInput LI ON US.UserID = LI.UserID
    WHERE LI.ProcessedFlag = 0 AND LI.SessionToken IS NULL;

    -- Deactivate specific session (Деактивация конкретной сессии)
    UPDATE US
    SET IsActive = 0
    FROM UserSessions US
    JOIN LogoutInput LI ON US.UserID = LI.UserID AND US.Token = LI.SessionToken
    WHERE LI.ProcessedFlag = 0 AND LI.SessionToken IS NOT NULL;

    -- Log logout (Логирование выхода)
    INSERT INTO UserLogs (UserID, ActionType, ActionDetails)
    SELECT
        LI.UserID, 'Logout', 'User logged out from system'
    FROM LogoutInput LI
    WHERE LI.ProcessedFlag = 0;

    -- Mark processed requests (Пометка обработанных запросов)
    UPDATE LogoutInput
    SET ProcessedFlag = 1
    WHERE ProcessedFlag = 0;
END;
GO

-- Validate session (Проверка валидности сессии)
CREATE PROCEDURE ValidateSession
AS
BEGIN
    -- Create temp results table (Создание временной таблицы)
    CREATE TABLE #SessionResults (
        UserID INT,
        Username NVARCHAR(50),
        FullName NVARCHAR(100),
        Role NVARCHAR(20),
        SessionID INT,
        ExpiryDate DATETIME,
        SessionStatus NVARCHAR(10)
    );

    -- Add valid sessions (Добавление валидных сессий)
    INSERT INTO #SessionResults
    SELECT
        U.UserID,
        U.Username,
        U.FullName,
        U.Role,
        US.SessionID,
        US.ExpiryDate,
        'VALID'
    FROM UserSessions US
    JOIN Users U ON US.UserID = U.UserID
    WHERE US.IsActive = 1
        AND US.ExpiryDate > GETDATE()
        AND U.IsActive = 1;

    -- Update last activity (Обновление времени активности)
    UPDATE US
    SET LastActivity = GETDATE()
    FROM UserSessions US
    JOIN #SessionResults SR ON US.SessionID = SR.SessionID;

    -- Return results (Возврат результатов)
    SELECT * FROM #SessionResults;

    -- Drop temp table (Удаление временной таблицы)
    DROP TABLE #SessionResults;
END;
GO


-- Cleanup expired sessions (Очистка истекших сессий)
CREATE PROCEDURE CleanupExpiredSessions
AS
BEGIN
    -- Log auto logout (Логирование автоматического выхода)
    INSERT INTO UserLogs (UserID, ActionType, ActionDetails)
    SELECT UserID, 'Auto Logout', 'Session expired'
    FROM UserSessions
    WHERE ExpiryDate < GETDATE() AND IsActive = 1;

    -- Deactivate expired sessions (Деактивация истекших сессий)
    UPDATE UserSessions
    SET IsActive = 0
    WHERE ExpiryDate < GETDATE() AND IsActive = 1;
END;
GO


-- Add test users (Добавление тестовых пользователей)
INSERT INTO Users (Username, PasswordHash, Email, FullName, Role, IsActive)
VALUES
('admin', CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', 'admin123'), 2), 'admin@inventory.com', 'Main Administrator', 'Admin', 1),
('manager', CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', 'manager123'), 2), 'manager@inventory.com', 'John Manager', 'Manager', 1),
('cashier', CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', 'cashier123'), 2), 'cashier@inventory.com', 'Anna Cashier', 'Cashier', 1),
('warehouse', CONVERT(NVARCHAR(128), HASHBYTES('SHA2_256', 'warehouse123'), 2), 'warehouse@inventory.com', 'Peter Warehouse', 'Warehouse', 1);
