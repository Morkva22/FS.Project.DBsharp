USE master
GO

-- Check if the database exists
IF DB_ID('InventoryManagment') IS NOT NULL
    DROP DATABASE InventoryManagment
IF DB_ID('InventoryManagment') IS NULL
    CREATE DATABASE InventoryManagment

USE InventoryManagment
GO

-- Create Products table
CREATE TABLE Products (
    ProductID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    Description NVARCHAR(500),
    CategoryID INT NOT NULL,
    SupplierID INT NOT NULL,
    PurchasePrice DECIMAL(10,2),
    SellingPrice DECIMAL(10,2),
    CreatedDate DATETIME DEFAULT GETDATE()


    CONSTRAINT CHK_Products_Name CHECK (Name <> ''),
    CONSTRAINT CHK_Product_Price CHECK (PurchasePrice > 0 AND SellingPrice > 0),
    FOREIGN KEY (CategoryID) REFERENCES Categories(Id),
    FOREIGN KEY (SupplierID) REFERENCES Suppliers(Id)
);

-- Create Categories table
CREATE TABLE Categories (
    Id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL


    CONSTRAINT CHK_Categories_Name CHECK (Name <> '')
);

-- Create Suppliers table
CREATE TABLE Suppliers (
    Id INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    ContactPerson NVARCHAR(100),
    Phone NVARCHAR(20),
    Email NVARCHAR(100)


    CONSTRAINT CHK_Suppliers_Name CHECK (Name <> ''),
    CONSTRAINT CHK_Suppliers_Email CHECK (Email LIKE '%_@__%.__%'),
    CONSTRAINT CHK_Suppliers_Phone CHECK (Phone LIKE '[0-9]%' OR Phone IS NULL)
);

-- Create Inventory table
CREATE TABLE Inventory (
    InventoryID NOT NULL INT PRIMARY KEY IDENTITY(1,1),
    Name NVARCHAR(100) NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    LastUpdated DATETIME DEFAULT GETDATE(),
    MinimumStockLevel INT DEFAULT 1,


    CONSTRAINT CHK_Inventory_Name CHECK (Name <> ''),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);

-- Create PurchaseOrders table (for ordering from suppliers)
CREATE TABLE PurchaseOrders (
    PurchaseOrderID INT NOT NULL PRIMARY KEY IDENTITY(1,1),
    SupplierID INT NOT NULL,
    OrderDate DATETIME DEFAULT GETDATE(),
    Status NVARCHAR(20) DEFAULT 'Pending',
    TotalAmount DECIMAL(10,2),


    FOREIGN KEY (SupplierID) REFERENCES Suppliers(SupplierID)
);

-- Create PurchaseOrderItems table
CREATE TABLE PurchaseOrderItems (
    PurchaseOrderItemID INT PRIMARY KEY IDENTITY(1,1),
    PurchaseOrderID INT NOT NULL,
    ProductID INT NOT NULL,
    Quantity INT NOT NULL,
    UnitPrice DECIMAL(10,2),


    FOREIGN KEY (PurchaseOrderID) REFERENCES PurchaseOrders(PurchaseOrderID),
    FOREIGN KEY (ProductID) REFERENCES Products(ProductID)
);
